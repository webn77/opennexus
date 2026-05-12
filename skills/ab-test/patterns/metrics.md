# 메트릭 타입별 측정 가이드

v1.0 | 2026-05-04

## --type 플래그

| type | 측정 대상 | 적합한 경우 |
|------|-----------|------------|
| `perf` | 실행시간(ms), 에러 수 | 파이프라인·스크립트 최적화 |
| `quality` | LLM 응답 품질 점수 (0~1.0) | 스킬·프롬프트 개선 |
| `func` | PASS/FAIL 카운트 | 코드 로직·기능 변경 |
| `all` | 전체 (기본값) | 처음 사용 시, 종합 검증 |

---

## perf — 성능 측정

```bash
# 실행시간 (ms)
START=$(python3 -c 'import time; print(int(time.time()*1000))')
bash "$SCRIPT" > /tmp/ab_out.txt 2>&1
EXIT_CODE=$?
END=$(python3 -c 'import time; print(int(time.time()*1000))')
ELAPSED=$((END - START))

# 에러 수
FAIL_COUNT=$(grep -cE "FAIL|ERROR|Exception|Traceback" /tmp/ab_out.txt 2>/dev/null || echo 0)
```

**임계값**: 실행시간 ±20%, 에러 수 ±1건

---

## quality — LLM 품질 측정

스킬·프롬프트 개선 시 사용. Claude Haiku로 출력 비교.

**Position bias 처리**: 순서 반전 2회 호출 후 평균. (LLM은 두 번째 답변을 선호하는 편향이 있음)

```python
import anthropic

client = anthropic.Anthropic()

def _call_judge(a: str, b: str, label_a: str, label_b: str) -> float:
    response = client.messages.create(
        model="claude-haiku-4-5-20251001",
        max_tokens=10,
        messages=[{
            "role": "user",
            "content": f"""{label_b}가 {label_a}보다 나은 정도를 0.0~1.0 숫자 하나로만 답하세요.
0.0=훨씬 나쁨, 0.5=동일, 1.0=훨씬 나음

{label_a}:
{a[:1000]}

{label_b}:
{b[:1000]}

점수:"""
        }]
    )
    try:
        return float(response.content[0].text.strip())
    except:
        return 0.5

def score_quality(baseline_output: str, current_output: str) -> float:
    """position bias 제거: 순서 반전 2회 평균"""
    score1 = _call_judge(baseline_output, current_output, "이전", "현재")
    score2 = 1.0 - _call_judge(current_output, baseline_output, "현재", "이전")
    return round((score1 + score2) / 2, 3)
```

**타임아웃**: 60s (2회 합산). 초과 시 quality 메트릭 null 기록, 나머지 메트릭으로 판정.
**임계값**: ±15% (0.5 기준 ±0.075)

---

## func — 기능 테스트 측정

```bash
# run_tests.sh 출력에서 PASS/FAIL 카운트
OUTPUT=$(bash "$SCRIPT" 2>&1)
PASS=$(echo "$OUTPUT" | grep -cE "✅|PASS|OK|passed" || echo 0)
FAIL=$(echo "$OUTPUT" | grep -cE "❌|FAIL|ERROR|failed" || echo 0)
TOTAL=$((PASS + FAIL))

# 성공률 계산
if [ $TOTAL -gt 0 ]; then
    PASS_RATE=$(python3 -c "print(round($PASS / $TOTAL, 3))")
else
    PASS_RATE=0
fi
```

**임계값**: 성공률 ±5% (예: 0.80 → 0.85 이상이면 IMPROVED)

---

## dual 모드 (v2 예정)

두 버전 병렬 비교 기능. 현재 미구현.

---

## 메트릭 없는 경우 처리

| 상황 | 처리 |
|------|------|
| quality_score만 null | perf+func으로만 판정 |
| 모든 메트릭 측정 불가 | UNKNOWN 판정, 사용자에게 --type 명시 요청 |
| baseline에 없는 메트릭 | compare 시 해당 메트릭 skip |
