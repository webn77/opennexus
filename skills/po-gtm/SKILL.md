---
name: po-gtm
description: PRD 또는 서비스 설명을 받아 타겟 세그먼트·채널·메시지·일정·성공 지표가 포함된 GTM 출시 플랜 생성. "출시 계획", "GTM", "런치 플랜", "출시 전략", "/po-gtm" 요청 시 실행.
트리거: 출시 계획, GTM, 런치 플랜, 출시 전략, /po-gtm
완료: obsidian/03_Projects/[domain]/[work]/gtm-[date].md 저장
실행: 직접
version: 1.0
verified_at: 2026-05-09
---

# /po-gtm
> PRD/서비스 설명 → 타겟 세그먼트 + 채널/메시지/일정 + 성공 지표 GTM 플랜

## YAML 명세

```yaml
skill:
  id: po-gtm
  name: GTM 출시 플랜
  domain: po/GTM
  trigger:
    - "출시 계획"
    - "GTM"
    - "런치 플랜"
    - "출시 전략"
    - "/po-gtm"
  inputs:
    - "PRD 또는 서비스 설명"
    - "출시 일정 (선택)"
    - "타겟 세그먼트 (선택)"
  outputs:
    - path: "obsidian/03_Projects/[domain]/[work]/gtm-[date].md"
      type: md
    - path: context/events.jsonl
      type: log
  passes:
    - "타겟 세그먼트 정의됨"
    - "채널·메시지·일정 3요소 포함됨"
    - "성공 지표 명시됨"
  reviewer: passes 항목 체크 후 APPROVE/REVISE
```

## 트리거

- `/po-gtm` — 직접 실행
- `출시 계획` — 신규 서비스/기능 출시 플랜
- `GTM` — Go-To-Market 전략
- `런치 플랜` — 런칭 계획서
- `출시 전략` — 출시 전략 수립

## 실행 순서

### Step 1. 타겟 세그먼트 정의
- 주요 타겟 사용자 그룹 1~3개
- 각 세그먼트별 Pain Point
- 세그먼트별 메시지 포인트

**출력:** 타겟 세그먼트 정의

### Step 2. 채널·메시지·일정 수립
**채널**: 어디서 알릴 것인가
- 온드 미디어 (앱 내, 이메일, 웹사이트)
- 언드 미디어 (SNS, PR)
- 페이드 미디어 (광고, 제휴)

**메시지**: 무엇을 말할 것인가
- 핵심 가치 제안 1문장
- 세그먼트별 맞춤 메시지

**일정**: 언제 어떻게 진행할 것인가
- Pre-launch (출시 전 예열)
- Launch day
- Post-launch (후속 활동)

**출력:** 채널/메시지/일정 계획

### Step 3. 성공 지표 정의
- 정량 지표 (가입자 수, 전환율, DAU 등)
- 측정 방법
- 목표값

**출력:** 성공 지표 목록

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
[STUCK] po-gtm | retry=[count]회
실패 조건: [failed_passes]
마지막 오류: [error]
→ 직접 개입 필요
```

### Step 5. Obsidian 저장
파일명: `gtm-[YYYY-MM-DD].md`
저장 경로: `obsidian/03_Projects/[domain]/[work]/`

## 출력 형식

```
## /po-gtm 완료

# [서비스명] GTM 플랜

## 타겟 세그먼트
1. [세그먼트A] — Pain Point: [설명]
2. [세그먼트B] — Pain Point: [설명]

## 채널·메시지·일정

| 단계 | 채널 | 메시지 | 일정 |
|------|------|--------|------|
| Pre-launch | [채널] | [메시지] | D-[N] |
| Launch | [채널] | [메시지] | [날짜] |
| Post-launch | [채널] | [메시지] | D+[N] |

## 성공 지표
| 지표 | 측정 방법 | 목표값 |
|------|----------|--------|
| [지표1] | [방법] | [목표] |

passes:
✅ 타겟 세그먼트 정의됨
✅ 채널·메시지·일정 3요소 포함됨
✅ 성공 지표 명시됨

저장: obsidian/03_Projects/[domain]/[work]/gtm-[date].md
```

## passes 조건

| 조건 | 확인 방법 |
|------|----------|
| 타겟 세그먼트 정의 | 세그먼트 섹션 + 1개 이상 존재 |
| 채널·메시지·일정 | 3요소 테이블 또는 섹션 존재 |
| 성공 지표 명시 | 지표 목록 + 목표값 존재 |

## 사용 예시

```
/po-gtm
서비스: 모두충전 v2.0 (예약 기능 추가)
출시 예정: 2026-06-01
```

## 트리거 제외

- ROI 분석 → /po-roi 사용
- 로드맵 계획 → /roadmap 사용
