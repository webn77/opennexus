#!/usr/bin/env bash
# log_event.sh <json_payload>
# Layer: util | 직접 호출 전용 — settings.json 등록 없음
# 용도: events.jsonl에 타임스탬프 포함 이벤트 append

export LANG=en_US.UTF-8
EVENTS_FILE="${HOME}/context/events.jsonl"
PAYLOAD="${1:-}"
[ -z "$PAYLOAD" ] && exit 0

TS=$(date -Iseconds)

RESULT=$(echo "$PAYLOAD" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    d.setdefault('ts', '${TS}')
    print(json.dumps(d, ensure_ascii=False))
except Exception as e:
    # JSON 파싱 실패 → error 이벤트로 fallback 기록
    raw = sys.argv[1] if len(sys.argv) > 1 else ''
    print(json.dumps({'ts': '${TS}', 'type': 'log_error', 'error': str(e)}, ensure_ascii=False))
" 2>/dev/null)

[ -n "$RESULT" ] && echo "$RESULT" >> "$EVENTS_FILE"
exit 0  # 항상 0 — hook 실패가 Claude 동작 차단하지 않도록
