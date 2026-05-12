#!/usr/bin/env bash
# sprint-exec 헬퍼 함수 라이브러리

SPRINT_CACHE="${HOME}/.claude/cache/sprint-exec"
BACKLOG="${HOME}/context/backlog.json"
BACKLOG_BACKEND="${BACKLOG_BACKEND:-json}"
BB_CMD="python3 $(eval echo ~)/projects/work/nexus/backlog-os/agents/backlog_backend.py"
CHECKPOINT="${HOME}/context/checkpoint.json"
STATE_FILE="${SPRINT_CACHE}/sprint-exec-state.json"

# Tier 분류: file_count 기반
# S: 1-2개, M: 3-6개, L: 7개+
tier_classify() {
  local file_count="${1:-1}"
  if [ "$file_count" -ge 7 ]; then
    echo "L"
  elif [ "$file_count" -ge 3 ]; then
    echo "M"
  else
    echo "S"
  fi
}

# capacity 계산: S×1 + M×3 + L×5
calc_capacity() {
  local s_count="$1"
  local m_count="$2"
  local l_count="$3"
  echo $(( s_count * 1 + m_count * 3 + l_count * 5 ))
}

# slug 생성: BL-ID + kebab-case 제목
make_slug() {
  local bl_id="$1"
  local title="$2"
  local kebab
  kebab=$(echo "$title" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//' | cut -c1-30)
  echo "${bl_id}-${kebab}"
}

# spec-action 출력 경로 (slug 기반 분리)
spec_action_path() {
  local slug="$1"
  if [ -n "$slug" ]; then
    echo "${SPRINT_CACHE}/spec-action-${slug}-latest.md"
  else
    echo "${HOME}/.claude/cache/spec-action-latest.md"
  fi
}

# backlog.json atomic write
# 사용법: backlog_update_status "BL-ID" "completed"
backlog_update_status() {
  local bl_id="$1"
  local new_status="$2"
  local tmp="${BACKLOG}.tmp.$$"
  python3 -c "
import json, sys
with open('${BACKLOG}') as f:
    d = json.load(f)
for item in d['items']:
    if item['id'] == '${bl_id}':
        item['status'] = '${new_status}'
        break
with open('${tmp}', 'w') as f:
    json.dump(d, f, ensure_ascii=False, indent=2)
" && mv "$tmp" "$BACKLOG"
}

# 번다운 갱신
burndown_update() {
  local bl_id="$1"
  local rice="$2"
  local state_tmp="${STATE_FILE}.tmp.$$"
  python3 -c "
import json, os
state_file = '${STATE_FILE}'
if os.path.exists(state_file):
    with open(state_file) as f:
        s = json.load(f)
else:
    s = {'rice_remaining': 0, 'completed': [], 'failed': [], 'fallback_used': False}
s['rice_remaining'] = max(0, s.get('rice_remaining', 0) - ${rice})
s.setdefault('completed', []).append('${bl_id}')
with open('${state_tmp}', 'w') as f:
    json.dump(s, f, ensure_ascii=False, indent=2)
" && mv "$state_tmp" "$STATE_FILE"
}

# 레트로 트리거: checkpoint.json todo[] 추가
retro_trigger() {
  local sprint_id="$1"
  local done="$2"
  local total="$3"
  local rice_done="$4"
  local tmp="${CHECKPOINT}.tmp.$$"
  python3 -c "
import json
with open('${CHECKPOINT}') as f:
    d = json.load(f)
entry = '[retro/${sprint_id}] 스프린트 회고 — 완료 ${done}/${total}, RICE 소화 ${rice_done}'
if 'todo' not in d:
    d['todo'] = []
if not any(entry in t for t in d['todo']):
    d['todo'].append(entry)
with open('${tmp}', 'w') as f:
    json.dump(d, f, ensure_ascii=False, indent=2)
" && mv "$tmp" "$CHECKPOINT"
}

# 페르소나 prefix 생성 — M/L 서브에이전트 프롬프트 앞에 주입 (BL-286)
# 사용법: build_persona_prefix "work" "M"
# 반환: "## 페르소나\n{yaml}\n\n---\n\n" 또는 빈 문자열
build_persona_prefix() {
  local domain="${1:-work}"
  local tier="${2:-}"
  python3 - <<PYEOF
import sys
sys.path.insert(0, '$HOME/projects/work/nexus/backlog-os/agents')
from persona_router import build_persona_prefix
print(build_persona_prefix('${domain}', '${tier}' if '${tier}' else None), end='')
PYEOF
}

# DoD 파일 생성
create_dod() {
  local bl_id="$1"
  local title="$2"
  local dod_file="${SPRINT_CACHE}/${bl_id}-dod.md"
  cat > "$dod_file" << EOF
# DoD: ${bl_id}
제목: ${title}
생성: $(date +%Y-%m-%dT%H:%M:%S)

## 완료 기준 (Definition of Done)
- [ ] spec-action 명세 파일 생성
- [ ] spec-build TEST-SPEC 작성
- [ ] run_tests.sh PASS
- [ ] spec-up PASS
- [ ] backlog.json status=completed
EOF
}
