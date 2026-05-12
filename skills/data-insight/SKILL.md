---
name: data-insight
description: SQL 결과 또는 BigQuery 데이터 텍스트를 받아 트렌드/이상치/기회 인사이트와 백로그 RICE 반영 제안이 포함된 데이터 분석 보고서 생성. "데이터 분석", "지표 분석", "인사이트", "/data-insight" 요청 시 실행.
트리거: 데이터 분석, 지표 분석, 인사이트, /data-insight
완료: obsidian/03_Projects/[domain]/[work]/insight-[date].md 저장
실행: 직접
version: 1.0
verified_at: 2026-05-09
---

# /data-insight
> SQL 결과/데이터 텍스트 → 트렌드/이상치/기회 인사이트 + 백로그 RICE 반영 제안

## YAML 명세

```yaml
skill:
  id: data-insight
  name: 데이터 인사이트
  domain: po/데이터
  trigger:
    - "데이터 분석"
    - "지표 분석"
    - "인사이트"
    - "/data-insight"
  inputs:
    - "SQL 결과 또는 BigQuery 데이터 텍스트"
    - "분석 기간 (선택)"
    - "비교 기준 (선택, 예: 전월 대비)"
  outputs:
    - path: "obsidian/03_Projects/[domain]/[work]/insight-[date].md"
      type: md
    - path: context/events.jsonl
      type: log
  passes:
    - "데이터 출처 명시됨"
    - "트렌드/이상치/기회 인사이트 각 1개 이상 도출됨"
    - "인사이트→액션 연결됨"
    - "백로그 RICE 반영 제안 포함됨"
  reviewer: passes 항목 체크 후 APPROVE/REVISE
```

## 트리거

- `/data-insight` — 직접 실행
- `데이터 분석` — 데이터 붙여넣기 후 실행
- `지표 분석` — KPI/지표 데이터 분석
- `인사이트` — 인사이트 도출 요청

## 실행 순서

### Step 1. 데이터 출처 및 구조 파악
입력 데이터에서:
- 출처 (테이블명, 쿼리, 기간)
- 컬럼 구조
- 데이터 범위

**출력:** 데이터 메타데이터

### Step 2. 인사이트 3가지 도출

**트렌드(Trend)**: 시간 흐름에 따른 패턴
- 증가/감소 방향
- 변화율 계산

**이상치(Anomaly)**: 예상 범위 이탈
- 기준 대비 편차
- 원인 가설

**기회(Opportunity)**: 개선 가능성
- 낮은 성과 영역 → 개선 여지
- 높은 성과 영역 → 확대 가능성

**출력:** 인사이트 3종

### Step 3. 인사이트 → 액션 연결
각 인사이트별 후속 액션 정의:
- 구체적 실행 방안
- 예상 임팩트

**출력:** 인사이트-액션 매핑

### Step 4. 백로그 RICE 반영 제안
액션 중 백로그 추가 가능한 항목:
- RICE 점수 추정 (Reach/Impact/Confidence/Effort)
- /backlog-add 실행 제안

**출력:** 백로그 후보 목록

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
[STUCK] data-insight | retry=[count]회
실패 조건: [failed_passes]
마지막 오류: [error]
→ 직접 개입 필요
```

### Step 6. Obsidian 저장
파일명: `insight-[YYYY-MM-DD].md`
저장 경로: `obsidian/03_Projects/[domain]/[work]/`

## 출력 형식

```
## /data-insight 완료

**데이터 출처**: [테이블명/기간]

## 트렌드
[트렌드 분석 내용]
→ 액션: [후속 액션]

## 이상치
[이상치 발견 내용]
→ 액션: [조사/대응 방안]

## 기회
[개선 기회 내용]
→ 액션: [실행 방안]

## 백로그 RICE 제안
| 항목 | R | I | C | E | RICE |
|------|---|---|---|---|------|
| [항목1] | [값] | [값] | [값] | [값] | [총점] |

passes:
✅ 데이터 출처 명시됨
✅ 트렌드/이상치/기회 인사이트 각 1개 이상 도출됨
✅ 인사이트→액션 연결됨
✅ 백로그 RICE 반영 제안 포함됨

저장: obsidian/03_Projects/[domain]/[work]/insight-[date].md
```

## passes 조건

| 조건 | 확인 방법 |
|------|----------|
| 데이터 출처 명시 | 출처 섹션 또는 메타데이터 존재 |
| 트렌드/이상치/기회 각 1개 | 3개 인사이트 섹션 존재 |
| 인사이트→액션 연결 | 각 인사이트 하단 액션 존재 |
| RICE 제안 포함 | 백로그 RICE 테이블 또는 목록 존재 |

## 사용 예시

```
/data-insight
[SQL 결과 붙여넣기]
기간: 2026-04, 비교: 전월 대비
```

## 트리거 제외

- 지표 대시보드 생성 → /metric-dashboard 사용
- 단순 데이터 조회 → 직접 쿼리 실행
