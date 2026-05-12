#!/bin/bash
# isok 스킬 품질 테스트 — ab-test용
# 출력: JSON {scenarios: [...], pass: N, fail: N, quality_score: X}

PASS=0
FAIL=0
RESULTS=()

# 시나리오 1: 기본 체크리스트 항목 수 검증
ITEMS=$(grep -c "^□" ~/.claude/skills/isok/SKILL.md 2>/dev/null)
if [ "$ITEMS" -ge 5 ]; then
    PASS=$((PASS+1))
    RESULTS+=('{"scenario":"체크리스트_항목수","status":"PASS","value":'$ITEMS'}')
else
    FAIL=$((FAIL+1))
    RESULTS+=('{"scenario":"체크리스트_항목수","status":"FAIL","value":'$ITEMS'}')
fi

# 시나리오 2: office-hours 패턴 파일 존재
if [ -f ~/.claude/skills/isok/patterns/office-hours.md ]; then
    OH_ITEMS=$(grep -c "^□" ~/.claude/skills/isok/patterns/office-hours.md 2>/dev/null)
    PASS=$((PASS+1))
    RESULTS+=('{"scenario":"office_hours_패턴","status":"PASS","items":'$OH_ITEMS'}')
else
    FAIL=$((FAIL+1))
    RESULTS+=('{"scenario":"office_hours_패턴","status":"FAIL","items":0}')
fi

# 시나리오 3: isok --deep 모드 트리거 문구 존재
if grep -q "deep" ~/.claude/skills/isok/SKILL.md 2>/dev/null; then
    PASS=$((PASS+1))
    RESULTS+=('{"scenario":"deep_모드_트리거","status":"PASS"}')
else
    FAIL=$((FAIL+1))
    RESULTS+=('{"scenario":"deep_모드_트리거","status":"FAIL"}')
fi

QUALITY=$(echo "scale=0; $PASS * 100 / ($PASS + $FAIL)" | bc)
echo "{\"pass\":$PASS,\"fail\":$FAIL,\"quality_score\":$QUALITY,\"scenarios\":[$(IFS=,; echo "${RESULTS[*]}")]}"
exit $FAIL
