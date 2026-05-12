#!/usr/bin/env bash
# stop-review-gate.sh
# Trigger : Stop
# Blocking: true (decision: block)
# 용도    : 세션별 .pending-review-{session_id} 마커 있으면 종료 차단

set -uo pipefail

INPUT=$(cat)

# 세션별 독립 마커
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "default"' 2>/dev/null || echo "default")
MARKER="$HOME/context/.pending-review-${SESSION_ID}"

# 마커 없음 → 통과
[[ ! -f "$MARKER" ]] && exit 0

# 루프 방지: stop_hook_active=true → 통과
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null || echo "false")
[[ "$STOP_HOOK_ACTIVE" == "true" ]] && exit 0

# 마커 파싱
FILE_PATH=$(jq -r '.file // ""' "$MARKER" 2>/dev/null || echo "")
RETRY=$(jq -r '.retry // 0' "$MARKER" 2>/dev/null || echo "0")

# 깨진 마커 → 자동 정리 후 통과
if [[ -z "$FILE_PATH" ]]; then
    rm -f "$MARKER"
    exit 0
fi

# retry >= 2 → 사용자 호출 단계, 통과
if [[ "$RETRY" -ge 2 ]]; then
    exit 0
fi

# retry 증가
jq --argjson r "$((RETRY + 1))" '.retry = $r' "$MARKER" > "${MARKER}.tmp" && mv "${MARKER}.tmp" "$MARKER"

# 잔여 마커 목록 수집
PENDING_COUNT=$(find "$HOME/context" -maxdepth 1 -name ".pending-review-*" 2>/dev/null | wc -l | tr -d ' ')

# 차단 — /goal 스타일 반복 루프 지시문
python3 -c "
import json, sys
file = sys.argv[1]; marker = sys.argv[2]; count = int(sys.argv[3])
reason = (
    '[검수 반복 루프] 완료 조건: ~/context/.pending-review-* 마커 전부 제거될 때까지 반복.\n\n'
    f'현재 대기: {file} ({count}개 잔여)\n\n'
    '실행 순서:\n'
    '1. Agent 도구로 code-reviewer 서브에이전트 스폰 → 위 파일 검토\n'
    '   기준: frontmatter 완전성 / 필수 섹션 / TODO·빈 섹션 없음\n'
    f'2. PASS → 마커({marker}) 삭제\n'
    '3. FAIL → 피드백 출력 후 수정 제안\n'
    '4. Stop 재시도 → 잔여 마커 있으면 루프 반복\n'
    '5. 마커 전부 없어지면 종료'
)
print(json.dumps({'decision': 'block', 'reason': reason}, ensure_ascii=False))
" "$FILE_PATH" "$MARKER" "$PENDING_COUNT"
exit 0
