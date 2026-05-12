---
name: po-interview
description: 인터뷰 목적과 대상 페르소나를 받아 10개 이상의 인터뷰 질문과 인터뷰 플랜을 생성. "인터뷰 설계", "고객 인터뷰", "사용자 인터뷰 준비", "/po-interview" 요청 시 실행. 실행 후 인터뷰 결과는 /interview-summary로 처리.
트리거: 인터뷰 설계, 고객 인터뷰, 사용자 인터뷰 준비, /po-interview
완료: obsidian/03_Projects/[domain]/[work]/interview-plan-[date].md 저장
실행: 직접
version: 1.0
verified_at: 2026-05-09
---

# /po-interview
> 인터뷰 목적 + 페르소나 → 질문 10개+ + 인터뷰 플랜

## YAML 명세

```yaml
skill:
  id: po-interview
  name: 고객 인터뷰 워크플로우
  domain: po/리서치
  trigger:
    - "인터뷰 설계"
    - "고객 인터뷰"
    - "사용자 인터뷰 준비"
    - "/po-interview"
  inputs:
    - "인터뷰 목적 (검증하려는 가설 또는 궁금증)"
    - "대상 페르소나"
    - "인터뷰 시간 (선택, 기본: 30분)"
  outputs:
    - path: "obsidian/03_Projects/[domain]/[work]/interview-plan-[date].md"
      type: md
    - path: context/events.jsonl
      type: log
  passes:
    - "인터뷰 질문 10개 이상 생성됨"
    - "질문이 주제별로 그룹핑됨"
    - "인터뷰 진행 가이드(시간 배분) 포함됨"
  reviewer: passes 항목 체크 후 APPROVE/REVISE
```

## 트리거

- `/po-interview` — 직접 실행
- `인터뷰 설계` — 인터뷰 질문 및 플랜 설계
- `고객 인터뷰` — 고객 인터뷰 준비
- `사용자 인터뷰 준비` — 사용자 리서치 준비

## 실행 순서

### Step 1. 목적 및 가설 명확화
- 인터뷰로 검증할 가설 1~3개
- 성공 기준 (어떤 답변이 나오면 검증된 것인가)

**출력:** 가설 + 검증 기준

### Step 2. 질문 설계 (10개 이상)
주제별 그룹핑:
1. **배경 (Warm-up)**: 2~3개 — 참여자 이해
2. **현재 상황 (Exploratory)**: 3~4개 — Pain Point 발굴
3. **구체적 행동 (Specific)**: 3~4개 — 실제 사용 패턴
4. **솔루션 반응 (Evaluative)**: 2~3개 — 제안 검증

**출력:** 주제별 질문 목록

### Step 3. 진행 가이드 작성
시간 배분:
- 인트로 (2~3분)
- 배경 질문 (5분)
- 현재 상황 (10분)
- 구체적 행동 (10분)
- 솔루션 반응 (5분)
- 마무리 (2~3분)

**출력:** 인터뷰 진행 가이드

### Step 4. Reviewer — passes 조건 체크

```
Worker 산출물
  → Reviewer (passes 조건 1:1 대조)
    APPROVE → 저장 + 텔레그램 알림
    REVISE  → Worker 재실행 (최대 3회)
    REJECT  → Stuck Detector 발동
```

**Stuck Detector 텔레그램 포맷:**
```
[STUCK] po-interview | retry=[count]회
실패 조건: [failed_passes]
마지막 오류: [error]
→ 직접 개입 필요
```

### Step 5. Obsidian 저장
파일명: `interview-plan-[YYYY-MM-DD].md`
저장 경로: `obsidian/03_Projects/[domain]/[work]/`

> 인터뷰 완료 후 결과 정리는 `/interview-summary` 사용

## 출력 형식

```
## /po-interview 완료

# 인터뷰 플랜: [목적]

**페르소나**: [페르소나]
**검증 가설**: [가설 1~3개]
**총 시간**: [N]분

## 인터뷰 질문

### 배경 (Warm-up, 5분)
1. [질문]
2. [질문]

### 현재 상황 (Exploratory, 10분)
3. [질문]
4. [질문]
5. [질문]

### 구체적 행동 (Specific, 10분)
6. [질문]
7. [질문]
8. [질문]

### 솔루션 반응 (Evaluative, 5분)
9. [질문]
10. [질문]
11. [질문]

## 진행 가이드
[시간 배분 + 주의 사항]

passes:
✅ 인터뷰 질문 [N]개 이상 생성됨
✅ 질문이 주제별로 그룹핑됨
✅ 인터뷰 진행 가이드 포함됨

저장: obsidian/03_Projects/[domain]/[work]/interview-plan-[date].md
```

## passes 조건

| 조건 | 확인 방법 |
|------|----------|
| 질문 10개 이상 | 번호 매긴 질문 10개 이상 존재 |
| 주제별 그룹핑 | 배경/현황/행동/반응 섹션 존재 |
| 진행 가이드 포함 | 시간 배분 섹션 존재 |

## 사용 예시

```
/po-interview
목적: EV 충전 예약 기능 필요성 검증
페르소나: EV 차량 사용자 (출퇴근 1시간 이상)
시간: 45분
```

## 트리거 제외

- 인터뷰 결과 요약 → /interview-summary 사용
- 설문 설계 → 별도 요청으로 처리
