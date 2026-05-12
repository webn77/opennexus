---
name: backlog-view
version: 2.0
description: 백로그를 RICE 점수 순으로 표시 (마감일 포함). /backlog-view 또는 백로그 보여줘.
트리거: /backlog-view, 백로그 보여줘, 할 일 목록, backlog 확인
완료: RICE 순 백로그 목록 출력
실행: 직접
---

# backlog-view

백로그를 RICE 점수 순으로 표시합니다. 마감일이 있으면 D-day로 함께 표시됩니다.

## 트리거

`/backlog-view`, `백로그 보여줘`, `할 일 목록`, `backlog 확인`

## 실행

```bash
python3 ~/.claude/skills/backlog-view/view.py
```

## 출력 예시

```text
🏃 스프린트 SP-001
  🔄 [work   ] ★ 156 ⚠️ D-2   결제 모듈 리팩토링
  ✅ [work   ] ★  98 📅 D-10  알림 정책 업데이트

📋 백로그 (5개, RICE 순)
                    ★점수 마감     제목
   1. [work   ] ★ 240 📅 D-7   신규 결제 화면 기획
   2. [study  ] ★ 125          AWS 자격증 정리
   3. [hire   ] ★  84 ❗D+3    JD 정리
```

마감일 표시:

- `🔥오늘` — 오늘 마감
- `⚠️ D-N` — 3일 이내
- `📅 D-N` — 4일 이상 남음
- `❗D+N` — N일 지남
- (공백) — 마감일 없음

## 정렬 기준

RICE 점수 내림차순 (= 우선순위 높은 항목 위에).
마감 임박해도 RICE가 낮으면 아래로 갑니다.
