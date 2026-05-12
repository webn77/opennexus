#!/usr/bin/env bash
# Smart Zone v2 — 토큰 임계값 기반 자동 compact 알림
# Stop 훅에서 호출 (async)
# Registry: auto-compact

TOKEN_THRESHOLD_WARN=150000
TOKEN_THRESHOLD_AUTO=180000

COUNT_FILE="/tmp/claude_turn_count"
WARN_LOCK="/tmp/claude_compact_warned"

# 텔레그램 설정 — setup.sh가 ~/.nexus8/config.sh에 저장
# shellcheck source=/dev/null
source "$HOME/.nexus8/config.sh" 2>/dev/null || true
BOT_TOKEN="${NEXUS_TELEGRAM_BOT_TOKEN:-}"
CHAT_ID="${NEXUS_TELEGRAM_CHAT_ID:-}"

COUNT=$(cat "$COUNT_FILE" 2>/dev/null || echo 0)
COUNT=$(( COUNT + 1 ))
echo "$COUNT" > "$COUNT_FILE"

_send() {
  [ -z "$BOT_TOKEN" ] || [ -z "$CHAT_ID" ] && return
  curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
    -d "chat_id=${CHAT_ID}" \
    -d "text=$1" > /dev/null 2>&1
}

if [ "$COUNT" -ge "$TOKEN_THRESHOLD_AUTO" ]; then
  _send "${COUNT}턴 도달. 자동 compact 실행합니다."
  rm -f "$WARN_LOCK" "$COUNT_FILE"
  sleep 2
  pkill -f "claude --channels plugin:telegram"
elif [ "$COUNT" -ge "$TOKEN_THRESHOLD_WARN" ] && [ ! -f "$WARN_LOCK" ]; then
  touch "$WARN_LOCK"
  _send "${COUNT}턴 경과. /compact 권장합니다. ${TOKEN_THRESHOLD_AUTO}턴에 자동 실행됩니다."
fi

exit 0
