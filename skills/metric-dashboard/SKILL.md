---
name: metric-dashboard
description: KPI 목록·현재값·목표값을 받아 현재값/목표/갭 테이블과 Mermaid 시각화·갭 기준 우선순위 제안이 포함된 지표 대시보드 생성. "지표 대시보드", "KPI 현황", "대시보드 만들어줘", "/metric-dashboard" 요청 시 실행.
트리거: 지표 대시보드, KPI 현황, 대시보드 만들어줘, /metric-dashboard
완료: obsidian/03_Projects/[domain]/[work]/metrics-[date].md 저장
실행: 직접
version: 1.0
verified_at: 2026-05-09
---

# /metric-dashboard
> KPI 목록 + 현재값/목표값 → 갭 테이블 + 시각화 + 우선순위 제안

## YAML 명세

```yaml
skill:
  id: metric-dashboard
  name: 지표 대시보드
  domain: po/데이터
  trigger:
    - "지표 대시보드"
    - "KPI 현황"
    - "대시보드 만들어줘"
    - "/metric-dashboard"
  inputs:
    - "KPI 목록"
    - "현재값"
    - "목표값"
    - "기간 (선택)"
  outputs:
    - path: "obsidian/03_Projects/[domain]/[work]/metrics-[date].md"
      type: md
    - path: context/events.jsonl
      type: log
  passes:
    - "현재값/목표/갭 3요소 테이블 포함됨"
    - "Mermaid 차트 또는 ASCII 시각화 포함됨"
    - "갭 기준 우선순위 제안 포함됨"
  reviewer: passes 항목 체크 후 APPROVE/REVISE
```

## 트리거

- `/metric-dashboard` — 직접 실행
- `지표 대시보드` — KPI 대시보드 생성
- `KPI 현황` — 현재 KPI 상태 시각화
- `대시보드 만들어줘` — 대시보드 생성 요청

## 실행 순서

### Step 1. KPI 입력 파싱
- KPI명, 현재값, 목표값 정리
- 단위 확인 (%, 건, 원, 분 등)
- 갭 계산 (현재 - 목표 또는 목표 달성률)

**출력:** KPI 갭 테이블

### Step 2. 시각화 생성
Mermaid xychart-beta 또는 ASCII 바 차트:
```mermaid
xychart-beta
  title "KPI 달성률"
  x-axis [KPI1, KPI2, KPI3]
  bar [현재값1, 현재값2, 현재값3]
  line [목표값1, 목표값2, 목표값3]
```
복잡한 경우 ASCII 바 차트 대체.

**출력:** 시각화 코드

### Step 3. 갭 기준 우선순위 제안
갭이 큰 순서로 정렬:
- 갭 % 계산
- 임팩트 추정
- 개선 액션 제안

**출력:** 우선순위 목록

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
[STUCK] metric-dashboard | retry=[count]회
실패 조건: [failed_passes]
마지막 오류: [error]
→ 직접 개입 필요
```

### Step 5. Obsidian 저장
파일명: `metrics-[YYYY-MM-DD].md`
저장 경로: `obsidian/03_Projects/[domain]/[work]/`

## 출력 형식

```
## /metric-dashboard 완료

# KPI 대시보드 ([기간])

## 현황 테이블
| KPI | 현재 | 목표 | 갭 | 달성률 |
|-----|------|------|-----|--------|
| [KPI1] | [값] | [값] | [갭] | [%]% |
| [KPI2] | [값] | [값] | [갭] | [%]% |

## 시각화

```mermaid
xychart-beta
  ...
```

## 우선순위 제안 (갭 기준)
1. [KPI명] — 갭 [값] → 개선 액션: [액션]
2. [KPI명] — 갭 [값] → 개선 액션: [액션]

passes:
✅ 현재값/목표/갭 3요소 테이블 포함됨
✅ Mermaid 차트 시각화 포함됨
✅ 갭 기준 우선순위 제안 포함됨

저장: obsidian/03_Projects/[domain]/[work]/metrics-[date].md
```

## passes 조건

| 조건 | 확인 방법 |
|------|----------|
| 3요소 테이블 | 현재값/목표/갭 열 존재 |
| 시각화 포함 | Mermaid 코드 블록 또는 ASCII 차트 존재 |
| 우선순위 제안 | 갭 기준 정렬된 제안 목록 존재 |

## 사용 예시

```
/metric-dashboard
KPI: 충전 완료율 현재 72% 목표 85%
KPI: 결제 성공률 현재 94% 목표 98%
KPI: 월간 활성 사용자 현재 1200 목표 2000
```

## 트리거 제외

- 데이터 분석 인사이트 → /data-insight 사용
- 단순 수치 계산 → 직접 계산
