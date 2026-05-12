---
name: po-roi
description: 비용·예상 수익·기간·시장 규모를 받아 ROI 계산값·수익 모델·비용 추정 근거가 포함된 ROI 분석 및 비즈니스 케이스 생성. "ROI 분석", "비즈니스 케이스", "비용 효과", "/po-roi" 요청 시 실행.
트리거: ROI 분석, 비즈니스 케이스, 비용 효과, /po-roi
완료: obsidian/03_Projects/[domain]/[work]/roi-[date].md 저장
실행: 직접
version: 1.0
verified_at: 2026-05-09
---

# /po-roi
> 비용 + 수익 + 기간 → ROI 계산 + 수익 모델 + 비즈니스 케이스

## YAML 명세

```yaml
skill:
  id: po-roi
  name: ROI 분석 & 비즈니스 케이스
  domain: po/재무
  trigger:
    - "ROI 분석"
    - "비즈니스 케이스"
    - "비용 효과"
    - "/po-roi"
  inputs:
    - "비용 (개발비, 운영비 등)"
    - "예상 수익 또는 절감액"
    - "기간 (개월 또는 연)"
    - "시장 규모 (선택)"
  outputs:
    - path: "obsidian/03_Projects/[domain]/[work]/roi-[date].md"
      type: md
    - path: context/events.jsonl
      type: log
  passes:
    - "시장 규모 정의됨"
    - "수익 모델 명시됨"
    - "ROI = (수익-비용)/비용×100 계산값 포함됨"
    - "비용 추정 근거 있음"
  reviewer: passes 항목 체크 후 APPROVE/REVISE
```

## 트리거

- `/po-roi` — 직접 실행
- `ROI 분석` — ROI 계산 요청
- `비즈니스 케이스` — 사업 타당성 분석
- `비용 효과` — 비용 대비 효과 분석

## 실행 순서

### Step 1. 시장 규모 정의
- TAM (전체 시장 규모)
- SAM (서비스 가능 시장)
- SOM (실질 점유 가능 시장)
- 근거 데이터 또는 추정 방법

**출력:** 시장 규모 분석

### Step 2. 수익 모델 명시
- 수익 유형 (구독, 거래 수수료, 광고 등)
- 수익 발생 시점
- 수익 성장 시나리오 (보수/기본/낙관)

**출력:** 수익 모델

### Step 3. 비용 추정
각 비용 항목별 근거:
- 개발비 (인건비 × 기간)
- 운영비 (서버, 라이선스)
- 마케팅비
- 총 비용 합계

**출력:** 비용 명세

### Step 4. ROI 계산
```
ROI = (총 수익 - 총 비용) / 총 비용 × 100
손익분기점 = 총 비용 / 월 수익
```

3개 시나리오별 계산:
- 보수적 (Pessimistic)
- 기본 (Base)
- 낙관적 (Optimistic)

**출력:** ROI 계산 테이블

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
[STUCK] po-roi | retry=[count]회
실패 조건: [failed_passes]
마지막 오류: [error]
→ 직접 개입 필요
```

### Step 6. Obsidian 저장
파일명: `roi-[YYYY-MM-DD].md`
저장 경로: `obsidian/03_Projects/[domain]/[work]/`

## 출력 형식

```
## /po-roi 완료

# [서비스명] ROI 분석

## 시장 규모
- TAM: [규모]
- SAM: [규모]
- SOM: [규모] (근거: [설명])

## 수익 모델
[수익 유형 및 구조 설명]

## 비용 추정
| 항목 | 비용 | 근거 |
|------|------|------|
| 개발비 | [금액] | [근거] |
| 운영비 | [금액] | [근거] |
| 합계 | [금액] | |

## ROI 계산
| 시나리오 | 수익 | 비용 | ROI | 손익분기 |
|---------|------|------|-----|---------|
| 보수적 | [값] | [값] | [%]% | [N]개월 |
| 기본 | [값] | [값] | [%]% | [N]개월 |
| 낙관적 | [값] | [값] | [%]% | [N]개월 |

passes:
✅ 시장 규모 정의됨
✅ 수익 모델 명시됨
✅ ROI = (수익-비용)/비용×100 계산값 포함됨
✅ 비용 추정 근거 있음

저장: obsidian/03_Projects/[domain]/[work]/roi-[date].md
```

## passes 조건

| 조건 | 확인 방법 |
|------|----------|
| 시장 규모 정의 | TAM/SAM/SOM 또는 시장 규모 섹션 존재 |
| 수익 모델 명시 | 수익 구조 설명 존재 |
| ROI 계산값 포함 | ROI [%]% 형태 수치 존재 |
| 비용 추정 근거 | 각 비용 항목에 근거 존재 |

## 사용 예시

```
/po-roi
비용: 개발 3개월 (2명 × 500만원) + 서버 50만원/월
예상 수익: 거래 수수료 1.5% × 월 거래액 5억
기간: 12개월
```

## 트리거 제외

- GTM 출시 전략 → /po-gtm 사용
- 단순 예산 계획 → 직접 작성
