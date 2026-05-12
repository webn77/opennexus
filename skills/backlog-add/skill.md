---
name: backlog-add
version: 2.1
description: 백로그 항목 추가. 자연어 진입 가능. 도메인+제목+마감일로 즉시 등록.
트리거: /backlog-add, 백로그 추가, 할 일 추가
완료: ~/.nexus8/backlog.json 항목 추가 + RICE 자동 계산
실행: 직접
---

# backlog-add

백로그에 항목을 추가합니다. 도메인 + 제목 + (선택)마감일.

## 트리거

- `백로그 추가해줘 [내용]`
- `할 일 추가 [내용]`
- `/backlog-add [도메인] [제목]`

## 진입 규칙

### 1. 도메인 + 제목 + 마감일 모두 있는 경우 → 바로 등록

예시:

- `백로그 추가해줘: work 신규 결제 화면 기획 12월 31일까지`
- `/backlog-add study AWS 자격증 정리 --due 2026-06-30`

자연어로 받은 마감일은 YYYY-MM-DD 형식으로 변환해서 `--due` 인자로 전달.

### 2. 도메인 + 제목만 있는 경우 → 마감일 넛지 한 번

```text
✅ 등록 준비됐습니다. 마감일도 함께 정할까요?
   예: "다음주 금요일", "12월 31일", "없음"
```

- 날짜 답변 → YYYY-MM-DD로 변환 후 `--due`로 등록
- `없음`/`나중에`/`스킵` → 마감일 없이 등록

### 3. 제목만 있고 도메인이 없는 경우 → 도메인 한 번 묻기

```text
어느 도메인에 추가할까요?
work(업무) / hire(채용) / study(학습) / analyze(분석)
```

답변 받으면 마감일도 함께 묻고 등록.

### 4. 내용 없이 호출된 경우 → 한 줄 안내

```text
어떤 걸 추가할까요?
예: "신규 결제 화면 기획 work에 12월 31일까지"
```

## 실행

### RICE 추정 (Claude가 직접)

add.py를 호출하기 전, Claude가 직접 RICE를 추정한다.

```text
[RICE 추정 기준]
- reach (1~10):     이 기능이 영향을 주는 사용자/업무 규모
- impact (1~10):    한 명/한 건당 효과 크기
- confidence (1~10): 예상대로 될 확신도
- effort (1~10):    구현·실행 노력 (클수록 비용 큼)
```

### add.py 호출

```bash
python3 ~/.claude/skills/backlog-add/add.py [도메인] [제목] --rice '{"reach":N,"impact":N,"confidence":N,"effort":N}' [--due YYYY-MM-DD]
```

예시:

- `python3 ~/.claude/skills/backlog-add/add.py work 신규 결제 화면 기획 --rice '{"reach":7,"impact":8,"confidence":6,"effort":5}' --due 2026-12-31`
- `python3 ~/.claude/skills/backlog-add/add.py study AWS 자격증 정리 --rice '{"reach":3,"impact":5,"confidence":8,"effort":3}'`

## 출력 예시

```text
✍️  RICE 점수 추정 중...
✅ BL-001 추가됨: [work] 신규 결제 화면 기획
   RICE: R7 I8 C6 E4 → ★84
   📅 마감: 2026-12-31
```

## 추가 정보가 필요할 때

큰 작업이면 `/spec-define [BL-ID]` 로 description·인수조건·기대효과를 자동 생성할 수 있습니다.
