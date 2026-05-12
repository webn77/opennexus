---
name: isok
description: 구현 시작 전 사전 검토 게이트. "이거 해도 되냐" 검증. Trigger: /isok, isok, 사전검토, 구현 전 확인. spec-define Step 6에서 plan.md+vs 통합 검증용.
---

# /isok 스킬

구현 전 1~2분 내 PASS/FAIL 판정. 중간 롤백 방지.

## 실행

### 입력
`/isok <대상> <작업설명>`
예: `/isok save_daemon.py Python 데몬으로 checkpoint 저장`

### Step 1. 체크리스트 (Sonnet 직접 판단)

아래 항목을 현재 컨텍스트·파일로 확인:

```
□ 대상 파일/경로가 실제 존재하는가?
□ 의존하는 파일·함수·API가 현재 동작하는가?
□ 기존 코드와 충돌하는 부분이 있는가?
□ 되돌리기 어려운 변경인가? (DB 마이그레이션, 파일 삭제 등)
□ 이 작업이 완료 기준을 만족하는가?
```

### Step 1-b. 가정·전제 체크 (office-hours 패턴)

> @patterns/office-hours.md 온디맨드 로드

구현이 옳은 방향인지 전제를 검증. Step 1과 동시에 판단.

빠른 모드(`/isok`): Step 1만 실행
심층 모드(`/isok --deep` 또는 L급 작업): Step 1 + Step 1-b 모두 실행

### Step 2. 판정

PASS: 모든 항목 확인됨 → "isok PASS: 진행 가능"
WARN: 불확실 항목 있음 → "isok WARN: [항목] 확인 후 진행"
FAIL: 블로커 발견 → "isok FAIL: [이유] — 진행 금지"

### spec-define Step 6 통합 검증 모드

`/isok --spec <plan.md 경로>` 형태로 실행 시:
- plan.md 읽기
- vs 결과 있으면 함께 검토
- 아키텍처 일관성 + 누락 단계 확인
- PASS/FAIL + 리스크 요약 출력
