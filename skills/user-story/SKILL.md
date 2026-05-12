---
name: user-story
description: 페르소나와 기능 목록을 받아 "As a/I want/So that" 형식과 인수 조건이 포함된 유저 스토리 생성. "유저 스토리", "사용자 스토리", "user story", "/user-story" 요청 시 실행.
트리거: 유저 스토리, 사용자 스토리, user story, /user-story
완료: obsidian/03_Projects/[domain]/[work]/user-stories-[date].md 저장
실행: 직접
version: 1.0
verified_at: 2026-05-09
---

# /user-story
> 페르소나 + 기능 목록 → "As a/I want/So that" + AC 유저 스토리

## YAML 명세

```yaml
skill:
  id: user-story
  name: 유저 스토리
  domain: po/스토리보드
  trigger:
    - "유저 스토리"
    - "사용자 스토리"
    - "user story"
    - "/user-story"
  inputs:
    - "페르소나 (역할/특성)"
    - "기능 목록"
    - "비즈니스 목적 (선택)"
  outputs:
    - path: "obsidian/03_Projects/[domain]/[work]/user-stories-[date].md"
      type: md
    - path: context/events.jsonl
      type: log
  passes:
    - "'As a [페르소나], I want [기능], So that [목적]' 형식 사용됨"
    - "각 스토리에 인수 조건(AC) 정의됨"
    - "페르소나 기반 시나리오 포함됨"
  reviewer: passes 항목 체크 후 APPROVE/REVISE
```

## 트리거

- `/user-story` — 직접 실행
- `유저 스토리` — 유저 스토리 생성 요청
- `사용자 스토리` — 한국어 동의어
- `user story` — 영어 명령어

## 실행 순서

### Step 1. 페르소나 정의
입력된 페르소나 분석:
- 역할 (예: EV 차량 사용자, 관리자, 드라이버)
- 핵심 니즈와 목표
- 페르소나별 우선순위 기능

**출력:** 페르소나 프로필

### Step 2. 유저 스토리 작성
각 기능별 스토리 생성:
```
As a [페르소나],
I want [기능/행동],
So that [목적/가치].
```

기능 수만큼 스토리 작성.

**출력:** 유저 스토리 목록

### Step 3. 인수 조건(AC) 정의
각 스토리별 Given/When/Then 또는 체크리스트 형식:
- 정상 경로 (Happy Path) 최소 1개
- 예외/에러 경로 최소 1개

**출력:** AC 포함된 스토리 목록

### Step 4. 페르소나 시나리오 추가
핵심 스토리를 시나리오로 연결:
- 사용자가 목표를 달성하는 전체 흐름
- 각 스토리 간 연결 관계

**출력:** 시나리오 섹션

### Step 5. Reviewer — passes 조건 체크

```
Worker 산출물
  → Reviewer (passes 조건 1:1 대조)
    APPROVE → 저장 + 텔레그램 알림
    REVISE  → Worker 재실행 (최대 3회)
    REJECT  → Stuck Detector 발동
```

**Stuck Detector 텔레그램 포맷:**
```
[STUCK] user-story | retry=[count]회
실패 조건: [failed_passes]
마지막 오류: [error]
→ 직접 개입 필요
```

### Step 6. Obsidian 저장
파일명: `user-stories-[YYYY-MM-DD].md`
저장 경로: `obsidian/03_Projects/[domain]/[work]/`

## 출력 형식

```
## /user-story 완료

# 유저 스토리: [서비스/기능명]

## 페르소나: [페르소나명]
[페르소나 설명 1~2줄]

## 스토리 목록

### US-001: [기능명]
As a [페르소나],
I want [기능],
So that [목적].

**인수 조건 (AC)**
- [ ] Given [전제] When [행동] Then [결과]
- [ ] 에러 케이스: [조건] → [에러 메시지]

### US-002: ...

## 페르소나 시나리오
[시나리오 흐름 설명]

passes:
✅ As a/I want/So that 형식 사용됨
✅ 각 스토리에 AC 정의됨
✅ 페르소나 기반 시나리오 포함됨

저장: obsidian/03_Projects/[domain]/[work]/user-stories-[date].md
```

## passes 조건

| 조건 | 확인 방법 |
|------|----------|
| As a/I want/So that 형식 | 3구문 모두 존재 여부 |
| AC 정의됨 | 각 스토리 하단 AC 섹션 존재 |
| 페르소나 시나리오 | 시나리오 섹션 존재 |

## 사용 예시

```
/user-story
페르소나: EV 차량 사용자
기능: 충전소 검색, 예약, 결제, 충전 상태 확인
```

## 트리거 제외

- 기능 명세서 작성 → /spec-define 사용
- 화면 흐름도 → /prototype-flow 사용
