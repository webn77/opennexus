# baseline 캡처 패턴

v1.1 | 2026-05-04

## 실행 순서

1. `--script` 경로 확인 (기본: `./run_tests.sh`)
2. 스크립트 존재 여부 확인
3. N=3회 반복 실행
4. 각 실행에서 메트릭 수집
5. 평균 + 표준편차 계산
6. `~/.nexus8/ab-test/baseline-{target}.json` 저장

## bash 구현 패턴

```bash
#!/usr/bin/env bash
TARGET=""
SCRIPT="./run_tests.sh"
TYPE="all"
N=3

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) TARGET="$2"; shift 2 ;;
    --script) SCRIPT="$2"; shift 2 ;;
    --type)   TYPE="$2";   shift 2 ;;
    --n)      N="$2";      shift 2 ;;
    *)        shift ;;
  esac
done

# target 기본값: git branch → 디렉토리명 순
if [ -z "$TARGET" ]; then
  TARGET=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || basename "$PWD")
  TARGET=$(echo "$TARGET" | tr '/' '-' | tr ' ' '_')
fi

# 스크립트 확인
[ -f "$SCRIPT" ] || { echo "오류: $SCRIPT 없음. --script PATH로 지정하세요."; exit 1; }

mkdir -p ~/.nexus8/ab-test
FAIL_CNT=0
TIMES=()
ERRORS=()

for i in $(seq 1 $N); do
  START=$(python3 -c 'import time; print(int(time.time()*1000))')
  OUTPUT=$(bash "$SCRIPT" 2>&1)
  EXIT_CODE=$?
  END=$(python3 -c 'import time; print(int(time.time()*1000))')
  ELAPSED=$((END - START))

  if [ $EXIT_CODE -ne 0 ]; then
    FAIL_CNT=$((FAIL_CNT + 1))
    echo "  Run $i: FAIL (exit $EXIT_CODE)"
  else
    FAIL_COUNT=$(echo "$OUTPUT" | grep -cE "FAIL|ERROR|Exception|Traceback" 2>/dev/null || echo 0)
    TIMES+=($ELAPSED)
    ERRORS+=($FAIL_COUNT)
    echo "  Run $i: ${ELAPSED}ms, errors=${FAIL_COUNT}"
  fi
done

if [ $FAIL_CNT -ge 2 ]; then
  echo "ABORT: ${FAIL_CNT}/${N}회 실패. baseline 저장 안 함."
  exit 1
fi

if [ ${#TIMES[@]} -eq 0 ]; then
  echo "ABORT: 수집된 성공 실행 없음."
  exit 1
fi

# 평균 계산 (Python 활용)
python3 - <<EOF
import json, statistics, datetime, re

times = $( IFS=,; echo "[${TIMES[*]}]" )
errors = $( IFS=,; echo "[${ERRORS[*]}]" )

import re
target_safe = re.sub(r'[/\\\\: ]', '_', "$TARGET")

data = {
    "target": target_safe,
    "timestamp": datetime.datetime.now().isoformat(),
    "n_runs": $N,
    "script": "$SCRIPT",
    "metrics": {
        "execution_time_ms": {
            "mean": round(statistics.mean(times), 1),
            "std": round(statistics.stdev(times) if len(times) > 1 else 0.0, 1)
        },
        "error_count": {
            "mean": round(statistics.mean(errors), 1),
            "std": round(statistics.stdev(errors) if len(errors) > 1 else 0.0, 1)
        }
    },
    "raw_runs": [{"time_ms": t, "error_count": e} for t, e in zip(times, errors)]
}

path = f"{__import__('os').path.expanduser('~')}/context/ab-test/baseline-{target_safe}.json"
with open(path, 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
print(f"baseline 저장: {path}")
print(f"실행시간: {data['metrics']['execution_time_ms']['mean']}ms (±{data['metrics']['execution_time_ms']['std']})")
print(f"에러 수:  {data['metrics']['error_count']['mean']}건 (±{data['metrics']['error_count']['std']})")
EOF
```

## baseline.json 형식

```json
{
  "target": "scheduled_ingestor",
  "timestamp": "2026-05-04T10:00:00+09:00",
  "n_runs": 3,
  "script": "./run_tests.sh",
  "metrics": {
    "execution_time_ms": { "mean": 3200.0, "std": 180.5 },
    "error_count":       { "mean": 2.0,    "std": 0.0 },
    "quality_score":     { "mean": 0.72,   "std": 0.05 }
  },
  "raw_runs": [
    { "time_ms": 3020, "error_count": 2 },
    { "time_ms": 3380, "error_count": 2 },
    { "time_ms": 3200, "error_count": 2 }
  ]
}
```

## 실패 처리

- 3회 중 2회 이상 실패(exit_code != 0) → ABORT, baseline 저장 안 함
- 1회 실패 → 경고 출력 후 나머지 2회로 계산 진행
- 성공 실행 0건 → ABORT (FAIL_CNT가 2 미만이어도)
