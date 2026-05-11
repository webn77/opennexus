#!/usr/bin/env bash
# test-start.sh — openNexus8 테스트 시작
# settings.json + 사용자 데이터(backlog/checkpoint)를 빈 상태로 교체
# 나머지 ~/.claude, ~/context는 건드리지 않음

set -euo pipefail

NEXUS_DIR="$(cd "$(dirname "$0")" && pwd)"

# settings.json
REAL_SET="$HOME/.claude/settings.json"
BAK_SET="$HOME/.claude/settings.json.nexus-bak"
NEXUS_SET="$NEXUS_DIR/.claude/settings.json"

# context 데이터 (사용자별)
REAL_BL="$HOME/context/backlog.json"
BAK_BL="$HOME/context/backlog.json.nexus-bak"

REAL_CP="$HOME/context/checkpoint.json"
BAK_CP="$HOME/context/checkpoint.json.nexus-bak"

if [[ -f "$BAK_SET" ]]; then
    echo "이미 테스트 중입니다. test-stop.sh로 먼저 종료하세요."
    exit 1
fi

# 백업
cp "$REAL_SET" "$BAK_SET"
cp "$REAL_BL" "$BAK_BL"
cp "$REAL_CP" "$BAK_CP"

# 교체
cp "$NEXUS_SET" "$REAL_SET"
echo '{"items":[],"sprints":[]}' > "$REAL_BL"
echo '{}' > "$REAL_CP"

echo "✅ openNexus8 테스트 시작 (신규 사용자 시뮬레이션)"
echo "   settings.json  → openNexus8"
echo "   backlog.json   → 빈 상태"
echo "   checkpoint.json → 빈 상태"
echo ""
echo "   새 터미널에서 아래 명령어로 실행하세요:"
echo ""
echo "   BACKLOG_BACKEND=json claude"
echo ""
echo "   종료: bash test-stop.sh"
