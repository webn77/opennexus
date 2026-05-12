---
name: review
version: 1.0
description: 직전 작성된 산출물(.md)을 reviewer 페르소나로 검수. PASS시 마커 제거, FAIL시 자동 수정 최대 2회. Stop hook 차단 해제용.
트리거: /review, 검수해줘, 검수 다시
완료: ~/.nexus8/.pending-review 제거 (PASS) 또는 retry 카운터 증가 (FAIL)
실행: 직접
---

# /review

> Stop hook이 차단한 산출물을 검수해 마커 해제. 자동 수정·재검수 루프 포함.

## 트리거

- `/review` — `~/.nexus8/.pending-review` 마커 대상 자동 검수
- `/review [경로]` — 특정 파일 강제 검수 (마커 무시)
- `검수해줘`, `검수 다시`

## 진입 규칙

### 1. 마커 확인

```bash
MARKER="$HOME/context/.pending-review"
if [ ! -f "$MARKER" ]; then
  echo "검수 대상 없음. /prd 등으로 산출물 작성 후 다시 호출."
  exit 0
fi

TARGET=$(jq -r '.path' "$MARKER")
RETRY=$(jq -r '.retry' "$MARKER")
```

### 2. 인자로 경로 주어진 경우

`$1`이 있으면 해당 파일 검수 (마커 path 무시, retry=0으로 임시 처리).

## 실행 순서

### Step 1. 컨텍스트 로드

```bash
cat $HOME/.nexus8/_libs/personas/reviewer.yaml
cat $HOME/.nexus8/docs/output-format-guide.md
cat "$TARGET"
```

### Step 2. reviewer 페르소나 검수

`reviewer.yaml`의 `system_prompt`에 따라 4개 항목 모두 명시적으로 ✅/⚠️/❌ 표시:

- frontmatter
- 표준 6 섹션
- 산출물 종류별 본문 (type 기준)
- PO 관점 품질

### Step 3. 판정별 처리

| 판정 | 동작 |
|---|---|
| ✅ PASS | 마커 제거 (`rm -f $MARKER`) → "검수 완료. 종료 가능합니다." |
| ⚠️ WARN | 사용자에게 보완 항목 표시 + "이대로 통과할까요? (y/n)" → y면 마커 제거, n면 Step 4 |
| ❌ FAIL (retry < 2) | Step 4 자동 수정 → 재검수 |
| ❌ FAIL (retry ≥ 2) | 마커 제거하지 말고 사용자 호출: "2회 자동 수정 실패. 수동 보완 후 /review 재실행 또는 /review-skip로 강제 종료." |

### Step 4. 자동 수정 (FAIL 시)

검수 결과의 "보완 필요" 항목을 직접 Edit으로 수정:
- frontmatter 누락 → 표준 frontmatter 삽입
- 섹션 누락 → 해당 섹션 추가 (내용은 백로그·기존 내용 기반 보강)
- 수치 목표 누락 → 기존 정성 표현을 수치 추정값으로 치환 + (추정) 표기

수정 후 마커 retry 카운터 증가:
```bash
NEW_RETRY=$((RETRY + 1))
jq --argjson r "$NEW_RETRY" '.retry = $r' "$MARKER" > "$MARKER.tmp" && mv "$MARKER.tmp" "$MARKER"
```

→ Step 2부터 재실행.

### Step 5. PASS 시 마커 제거

```bash
rm -f "$HOME/context/.pending-review"
```

### Step 6. 완료 출력

```
## /review 완료

📄 대상: [경로]
판정: ✅ PASS | ⚠️ WARN(통과) | ❌ FAIL(사용자 호출)
재시도: [N]회

[FAIL인 경우]
다음 단계:
- 수동 보완 후 /review
- 또는 /review-skip 으로 강제 종료
```

## 사람이 해야 하는 것

- WARN 판정 시 통과 여부 결정 (y/n)
- 2회 자동 수정 실패 시 수동 보완

## 주의

- 마커 파일이 없으면 즉시 종료 (검수 대상 없음)
- 인자 경로 검수는 마커 retry에 영향 주지 않음
- 자동 수정으로 본문 내용을 추론·삽입할 때는 (추정) 또는 [확인필요] 마커를 남겨 사용자가 검토할 수 있게 함
