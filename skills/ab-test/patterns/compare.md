# compare 비교·판정·리포트 패턴

v1.1 | 2026-05-04

## 실행 스캐폴드

```bash
TARGET=""
SCRIPT="./run_tests.sh"
N=3

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) TARGET="$2"; shift 2 ;;
    --script) SCRIPT="$2"; shift 2 ;;
    *) shift ;;
  esac
done

if [ -z "$TARGET" ]; then
  TARGET=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || basename "$PWD")
  TARGET=$(echo "$TARGET" | tr '/' '-' | tr ' ' '_')
fi

BASELINE="$HOME/context/ab-test/baseline-${TARGET}.json"
[ -f "$BASELINE" ] || { echo "오류: baseline 없음. /ab-test baseline 먼저 실행."; exit 1; }

# 3회 실행 (baseline.md와 동일 패턴)
TIMES=() ERRORS=() FAIL_CNT=0
for i in $(seq 1 $N); do
  START=$(python3 -c 'import time; print(int(time.time()*1000))')
  OUTPUT=$(bash "$SCRIPT" 2>&1)
  EXIT_CODE=$?
  END=$(python3 -c 'import time; print(int(time.time()*1000))')
  ELAPSED=$((END - START))
  [ $EXIT_CODE -ne 0 ] && FAIL_CNT=$((FAIL_CNT+1)) && continue
  FAIL_COUNT=$(echo "$OUTPUT" | grep -cE "FAIL|ERROR|Exception|Traceback" || echo 0)
  TIMES+=($ELAPSED)
  ERRORS+=($FAIL_COUNT)
done

[ $FAIL_CNT -ge 2 ] && echo "ABORT: ${FAIL_CNT}/${N}회 실패" && exit 1

# Python 판정 + history append + 텔레그램 리포트
python3 - <<'EOF'
import json, statistics, datetime, os, subprocess

TARGET = os.environ.get('AB_TARGET', 'unknown')
# baseline 로드
baseline_path = os.path.expanduser(f"~/.nexus8/ab-test/baseline-{TARGET}.json")
with open(baseline_path) as f:
    baseline = json.load(f)

# after 메트릭 계산 (TIMES/ERRORS는 env로 전달)
times = [int(x) for x in os.environ.get('AB_TIMES', '').split(',') if x]
errors = [int(x) for x in os.environ.get('AB_ERRORS', '').split(',') if x]

after = {
    "execution_time_ms": {"mean": round(statistics.mean(times), 1)},
    "error_count": {"mean": round(statistics.mean(errors), 1)}
}

# 판정 로직 (compare.md 기존 코드 참조)
# ... (기존 judge() 함수 호출)

# history.jsonl append
history_path = os.path.expanduser("~/.nexus8/ab-test/history.jsonl")
record = {
    "ts": datetime.datetime.now().isoformat(),
    "target": TARGET,
    "verdict": verdict,
    "baseline_ts": baseline.get("timestamp"),
}
with open(history_path, 'a') as f:
    f.write(json.dumps(record, ensure_ascii=False) + '\n')
EOF
```

## 실행 순서

1. `baseline-{target}.json` 로드
2. 동일 스크립트로 N=3회 실행
3. 메트릭 수집 (baseline과 동일 방법)
4. 변화율 계산
5. 판정 (IMPROVED / NEUTRAL / DEGRADED)
6. `history.jsonl` append
7. 텔레그램 리포트

## 변화율 계산

```text
변화율(%) = (after_mean - baseline_mean) / baseline_mean × 100
```

에러 수는 절대값(건수) 기준으로 비교 (% 아님, baseline이 0이면 % 계산 불가)

## 판정 로직 (Python)

```python
def judge(baseline, after):
    improved, degraded = [], []

    # 실행시간: % 기준
    time_b = baseline["metrics"]["execution_time_ms"]["mean"]
    time_a = after["metrics"]["execution_time_ms"]["mean"]
    time_delta = (time_a - time_b) / time_b * 100
    if time_delta <= -20:
        improved.append(f"실행시간 {time_delta:.1f}%")
    elif time_delta >= 20:
        degraded.append(f"실행시간 +{time_delta:.1f}%")

    # 에러 수: 절대값 기준
    err_b = baseline["metrics"]["error_count"]["mean"]
    err_a = after["metrics"]["error_count"]["mean"]
    err_delta = err_a - err_b
    if err_delta <= -1:
        improved.append(f"에러 {err_delta:.0f}건")
    elif err_delta >= 1:
        degraded.append(f"에러 +{err_delta:.0f}건")

    # 품질 점수: % 기준 (있을 때만)
    q_b = baseline["metrics"].get("quality_score", {}).get("mean")
    q_a = after["metrics"].get("quality_score", {}).get("mean")
    if q_b and q_a:
        q_delta = (q_a - q_b) / q_b * 100
        if q_delta >= 15:
            improved.append(f"품질 +{q_delta:.1f}%")
        elif q_delta <= -15:
            degraded.append(f"품질 {q_delta:.1f}%")

    # 최종 판정
    if len(improved) >= 1 and len(degraded) == 0:
        return "IMPROVED", improved, degraded
    elif len(degraded) >= 1:
        return "DEGRADED", improved, degraded
    else:
        return "NEUTRAL", improved, degraded
```

## 리포트 형식

```text
[ab-test] scheduled_ingestor — IMPROVED ✅

실행시간: 3200ms → 2100ms  (-34.4%) ↑
에러 수:  2건    → 0건      (-2건)   ↑
품질점수: 0.72   → 0.78    (+8.3%)  →

→ spec-up 진행 권장
```

```text
[ab-test] scheduled_ingestor — DEGRADED ❌

실행시간: 3200ms → 4100ms  (+28.1%) ↓
에러 수:  2건    → 3건      (+1건)   ↓

→ /debug 실행 권장 후 재구현
```

## history.jsonl 형식 (append-only)

```json
{
  "ts": "2026-05-04T10:30:00+09:00",
  "target": "scheduled_ingestor",
  "verdict": "IMPROVED",
  "baseline_ts": "2026-05-04T10:00:00+09:00",
  "metrics_diff": {
    "execution_time_pct": -34.4,
    "error_count_delta": -2,
    "quality_score_pct": 8.3
  },
  "improved": ["실행시간 -34.4%", "에러 -2건"],
  "degraded": []
}
```

## 다음 액션 매핑

| 판정 | 권장 액션 |
|------|-----------|
| IMPROVED | "spec-up 진행하세요" |
| NEUTRAL | "사용자 판단 필요. 추가 개선 후 재측정 권장" |
| DEGRADED | "/debug 실행 후 원인 파악 → 재구현 → /ab-test compare 재실행" |
