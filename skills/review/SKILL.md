# /review
> 검수 대기 파일을 code-reviewer 서브에이전트로 검토. PASS 시 마커 자동 삭제.

## 트리거
- `/review`
- Stop 훅 차단 후 Claude가 자동 실행 (block 메시지에 마커 경로 포함)

## 실행 순서

### Step 1. 마커 확인
Stop 훅 block 메시지에 포함된 마커 경로 사용.
없으면 glob으로 탐색:
```bash
ls ~/context/.pending-review-* 2>/dev/null | head -1
```
마커 없으면 "검수 대기 파일 없음" 출력 후 종료.

### Step 2. 검토 대상 파일 추출
```bash
FILE_PATH=$(jq -r '.file' "$MARKER")
```

### Step 3. code-reviewer 서브에이전트 스폰
Agent 도구 호출:
- `subagent_type`: `feature-dev:code-reviewer`
- `prompt`:

```
다음 문서를 검토하고 PASS 또는 FAIL을 판정하세요.

파일: {FILE_PATH}
마커: {MARKER_PATH}

## 검토 기준 (모두 통과해야 PASS)
1. frontmatter(`---` 블록)에 type, status, date 필드 존재
2. H1 제목(#) 존재
3. 필수 섹션 (type 기준):
   - type: PRD → 배경, 목표, 기능 요구사항, 성공 기준
   - type: plan → 구현 방식, 데이터 흐름, Phase 분리
   - 그 외 → ## 섹션 2개 이상
4. TODO / FIXME / [placeholder] 텍스트 없음
5. 빈 섹션 없음 (## 바로 다음 줄이 비어있고 ## 가 이어지는 경우)

## 판정 결과
PASS:
- "PASS: {파일명} 검수 완료" 출력
- rm {MARKER_PATH} 실행 (마커 삭제)

FAIL:
- "FAIL: {파일명}" 출력
- 실패 항목 번호 + 구체적 내용
- 마커 삭제하지 마세요
```

### Step 4. 결과 보고
- PASS → "검수 완료. 세션 종료 가능합니다."
- FAIL → 실패 항목 출력 + "위 항목 수정 후 다시 종료하세요."
