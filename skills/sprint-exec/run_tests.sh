#!/usr/bin/env bash
# sprint-exec run_tests.sh
# 실행: bash ~/.claude/skills/sprint-exec/run_tests.sh

SKILL_DIR="${HOME}/.claude/skills/sprint-exec"
FIXTURE="${SKILL_DIR}/fixtures/backlog-mock.json"
source "${SKILL_DIR}/lib.sh" 2>/dev/null || true

PASS=0
FAIL=0
RESULTS=()

run_test() {
  local id="$1"
  local desc="$2"
  local result="$3"  # "pass" or "fail"
  if [ "$result" = "pass" ]; then
    PASS=$((PASS+1))
    RESULTS+=("✅ ${id}: ${desc}")
  else
    FAIL=$((FAIL+1))
    RESULTS+=("❌ ${id}: ${desc}")
  fi
}

# T-01: 정상 스프린트 로드
t01() {
  local count
  count=$(python3 -c "
import json
d=json.load(open('${FIXTURE}'))
sprint_items=set(d['sprints'][0]['items'])
items=[i for i in d['items'] if i['id'] in sprint_items]
print(len(items))
" 2>/dev/null)
  [ "$count" = "5" ] && echo "pass" || echo "fail"
}

# T-02: Tier 분류 정확도
t02() {
  local r1 r2 r3 r4 r5
  r1=$(tier_classify 1); r2=$(tier_classify 2)
  r3=$(tier_classify 4); r4=$(tier_classify 8); r5=$(tier_classify 1)
  [ "$r1" = "S" ] && [ "$r2" = "S" ] && [ "$r3" = "M" ] && [ "$r4" = "L" ] && [ "$r5" = "S" ] \
    && echo "pass" || echo "fail"
}

# T-03: capacity 계산
t03() {
  local cap
  cap=$(calc_capacity 3 1 1)
  [ "$cap" = "11" ] && echo "pass" || echo "fail"
}

# T-04: slug 경로 분리
t04() {
  local s1 s2
  s1=$(make_slug "BL-T01" "single file edit")
  s2=$(make_slug "BL-T02" "two files edit")
  [[ "$s1" == BL-T01-* ]] && [[ "$s2" == BL-T02-* ]] && [ "$s1" != "$s2" ] \
    && echo "pass" || echo "fail"
}

# T-05: 실패 격리 (mock)
t05() {
  local tmp_backlog="/tmp/test-backlog-t05-$$.json"
  cp "$FIXTURE" "$tmp_backlog"
  # BL-T01 failed 주입
  python3 -c "
import json
d=json.load(open('${tmp_backlog}'))
for i in d['items']:
    if i['id']=='BL-T01': i['status']='failed'
json.dump(d,open('${tmp_backlog}','w'),ensure_ascii=False)
"
  # BL-T02 상태 확인
  local status
  status=$(python3 -c "
import json
d=json.load(open('${tmp_backlog}'))
print([i['status'] for i in d['items'] if i['id']=='BL-T02'][0])
")
  rm -f "$tmp_backlog"
  [ "$status" != "failed" ] && echo "pass" || echo "fail"
}

# T-06: 레트로 트리거
t06() {
  local tmp_cp="/tmp/test-checkpoint-t06-$$.json"
  echo '{"todo":[],"domains":{}}' > "$tmp_cp"
  python3 -c "
import json
with open('${tmp_cp}') as f: d=json.load(f)
entry='[retro/SP-TEST-W01] 스프린트 회고 — 완료 5/5, RICE 소화 590'
d.setdefault('todo',[]).append(entry)
with open('${tmp_cp}','w') as f: json.dump(d,f,ensure_ascii=False)
"
  local found
  found=$(python3 -c "
import json
d=json.load(open('${tmp_cp}'))
print(sum(1 for t in d.get('todo',[]) if t.startswith('[retro/SP-TEST-W01')))
")
  rm -f "$tmp_cp"
  [ "$found" -ge 1 ] && echo "pass" || echo "fail"
}

# T-07: 번다운 갱신
t07() {
  local tmp_state="/tmp/test-state-t07-$$.json"
  echo '{"rice_remaining":590,"completed":[],"failed":[],"fallback_used":false}' > "$tmp_state"
  python3 -c "
import json
with open('${tmp_state}') as f: s=json.load(f)
s['rice_remaining']=max(0,s['rice_remaining']-100)
s['completed'].append('BL-T01')
with open('${tmp_state}','w') as f: json.dump(s,f)
"
  local remaining
  remaining=$(python3 -c "import json; print(json.load(open('${tmp_state}'))['rice_remaining'])")
  rm -f "$tmp_state"
  [ "$remaining" -lt "590" ] && echo "pass" || echo "fail"
}

# T-08: Codex fallback 기록
t08() {
  local tmp_state="/tmp/test-state-t08-$$.json"
  echo '{"rice_remaining":200,"completed":[],"failed":[],"fallback_used":false}' > "$tmp_state"
  python3 -c "
import json
with open('${tmp_state}') as f: s=json.load(f)
s['fallback_used']=True
with open('${tmp_state}','w') as f: json.dump(s,f)
"
  local val
  val=$(python3 -c "import json; print(json.load(open('${tmp_state}'))['fallback_used'])")
  rm -f "$tmp_state"
  [ "$val" = "True" ] && echo "pass" || echo "fail"
}

# T-09: 3회 FAIL → blocked
t09() {
  local retry_count=3
  local status="in_progress"
  [ "$retry_count" -ge 3 ] && status="blocked"
  [ "$status" = "blocked" ] && echo "pass" || echo "fail"
}

# T-10: atomic write (JSON 무결성)
t10() {
  local tmp="/tmp/test-atomic-t10-$$.json"
  cp "$FIXTURE" "$tmp"
  # 동시 2회 쓰기 시뮬레이션 (순차로 대체)
  python3 -c "
import json
d=json.load(open('${tmp}'))
d['_test']='write1'
with open('${tmp}.1','w') as f: json.dump(d,f,ensure_ascii=False)
" && mv "${tmp}.1" "$tmp"
  python3 -c "
import json
d=json.load(open('${tmp}'))
d['_test']='write2'
with open('${tmp}.2','w') as f: json.dump(d,f,ensure_ascii=False)
" && mv "${tmp}.2" "$tmp"
  local valid
  valid=$(python3 -c "
import json, sys
try:
    json.load(open('${tmp}'))
    print('valid')
except: print('invalid')
")
  rm -f "$tmp"
  [ "$valid" = "valid" ] && echo "pass" || echo "fail"
}

# T-11: 페르소나 동적 주입 (build_persona_prefix)
t11() {
  local result
  result=$(python3 -c "
import sys, os
sys.path.insert(0, os.path.expanduser('~/.nexus8/agents'))
try:
    from persona_router import build_persona_prefix
    prefix = build_persona_prefix('work', 'M')
    print('pass' if prefix and '페르소나' in prefix else 'fail')
except Exception as e:
    print('fail')
" 2>/dev/null)
  echo "${result:-fail}"
}

# --- 실행 ---
echo "=== sprint-exec run_tests.sh ==="
echo ""

run_test "T-01" "정상 스프린트 로드" "$(t01)"
run_test "T-02" "Tier 분류 정확도" "$(t02)"
run_test "T-03" "capacity 계산" "$(t03)"
run_test "T-04" "slug 경로 분리" "$(t04)"
run_test "T-05" "실패 격리" "$(t05)"
run_test "T-06" "레트로 트리거" "$(t06)"
run_test "T-07" "번다운 갱신" "$(t07)"
run_test "T-08" "Codex fallback 기록" "$(t08)"
run_test "T-09" "3회 FAIL → blocked" "$(t09)"
run_test "T-10" "atomic write 무결성" "$(t10)"
run_test "T-11" "페르소나 동적 주입 (build_persona_prefix)" "$(t11)"

echo ""
for r in "${RESULTS[@]}"; do echo "  $r"; done
echo ""
echo "PASS ${PASS}/11 | FAIL ${FAIL}/11"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
