#!/usr/bin/env bash
# stop-review-gate.sh
# Trigger : Stop
# Blocking: true (decision: block)
# 용도    : 세션 flag 있으면 /goal 실행 지시 → 검수 완료 후 통과

set -uo pipefail

INPUT=$(cat)

# 루프 방지: stop_hook_active=true → 통과
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null || echo "false")
[[ "$STOP_HOOK_ACTIVE" == "true" ]] && exit 0

# 세션 flag 확인
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "default"' 2>/dev/null || echo "default")
FLAG="/tmp/review-flag-${SESSION_ID}"
[[ ! -f "$FLAG" ]] && exit 0

# flag 삭제 (한 번만 /goal 실행)
rm -f "$FLAG"

# /goal 실행 지시
NEXUS_VAULT="${NEXUS_VAULT:-$HOME/obsidian-vault}"
PROJECTS_DIR="$NEXUS_VAULT/03_Projects"

python3 << PYEOF
import json

projects_dir = "$PROJECTS_DIR"
reason = (
    "산출물 검수가 필요합니다. 지금 즉시 /goal 스킬을 실행하세요:\n\n"
    f"/goal {projects_dir} 안에서 오늘 작성·수정된 type: frontmatter가 있는 .md 파일을 "
    "모두 찾아 code-reviewer 서브에이전트로 검수하고, "
    "모든 파일이 PASS될 때까지 반복한다"
)
print(json.dumps({"decision": "block", "reason": reason}, ensure_ascii=False))
PYEOF
