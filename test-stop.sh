#!/usr/bin/env bash
# test-stop.sh — openNexus8 테스트 종료, 원복

set -euo pipefail

REAL_SET="$HOME/.claude/settings.json"
BAK_SET="$HOME/.claude/settings.json.nexus-bak"

REAL_BL="$HOME/context/backlog.json"
BAK_BL="$HOME/context/backlog.json.nexus-bak"

REAL_CP="$HOME/context/checkpoint.json"
BAK_CP="$HOME/context/checkpoint.json.nexus-bak"

if [[ ! -f "$BAK_SET" ]]; then
    echo "백업 없음. 이미 원복됐거나 test-start.sh를 먼저 실행하세요."
    exit 1
fi

mv "$BAK_SET" "$REAL_SET"
echo "✅ settings.json 복구"

[[ -f "$BAK_BL" ]] && mv "$BAK_BL" "$REAL_BL" && echo "✅ backlog.json 복구"
[[ -f "$BAK_CP" ]] && mv "$BAK_CP" "$REAL_CP" && echo "✅ checkpoint.json 복구"

echo "원복 완료"
