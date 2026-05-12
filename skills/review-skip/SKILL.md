---
name: review-skip
version: 1.0
description: 검수 미통과 마커를 강제로 제거해 Stop hook 차단을 해제. 검수를 건너뛰려는 명시적 의도일 때만 사용.
트리거: /review-skip, 검수 건너뛰기, 강제 종료
완료: ~/.nexus8/.pending-review 제거
실행: 직접
---

# /review-skip

> 검수 게이트 강제 탈출구. 의도적으로 검수를 건너뛸 때만 사용.

## 트리거

- `/review-skip`
- `검수 건너뛰기`, `검수 스킵`, `강제 종료`

## 실행 순서

### Step 1. 마커 확인 + 사용자 확인

```bash
MARKER="$HOME/context/.pending-review"
if [ ! -f "$MARKER" ]; then
  echo "차단된 검수 없음. 그대로 종료 가능."
  exit 0
fi

TARGET=$(jq -r '.path' "$MARKER")
RETRY=$(jq -r '.retry' "$MARKER")
```

사용자에게 확인:
```
다음 산출물의 검수를 강제로 건너뜁니다.

📄 대상: [TARGET]
재시도: [RETRY]회

이 산출물은 표준 검수를 통과하지 못한 채 저장됩니다.
정말 진행할까요? (y/N)
```

`y` 답변시에만 진행.

### Step 2. 마커 제거 + 사유 기록

```bash
# 사유 기록 (감사 로그)
SKIP_LOG="$HOME/context/review-skip.jsonl"
TS=$(date +%s)
jq -n --arg p "$TARGET" --argjson r "$RETRY" --argjson t "$TS" \
  '{path:$p, retry:$r, ts:$t, skipped:true}' >> "$SKIP_LOG"

# 마커 제거
rm -f "$MARKER"
```

### Step 3. 완료 출력

```
## /review-skip 완료

📄 [TARGET] 검수 건너뜀.
🗒️ 기록: ~/.nexus8/review-skip.jsonl

이제 종료할 수 있습니다. 단, 산출물의 표준 준수 여부는 보장되지 않습니다.
```

## 사람이 해야 하는 것

- 강제 종료 의사 명시 (y 답변)

## 주의

- 마커가 없는데 호출되면 무동작으로 종료
- 모든 스킵은 `~/.nexus8/review-skip.jsonl`에 append-only 기록 (추적용)
- `/review-skip`은 표준 우회 수단이므로 빈번한 사용은 표준 자체 점검 신호
