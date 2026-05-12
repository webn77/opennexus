---
name: stakeholder-report
description: 완료 항목과 지표 변화를 받아 이해관계자용 주간/월간 보고서 생성. "이해관계자 보고", "주간 보고", "월간 보고", "/stakeholder-report" 요청 시 실행.
트리거: 이해관계자 보고, 주간 보고, 월간 보고, /stakeholder-report
완료: obsidian/03_Projects/[domain]/[work]/stakeholder-report-[date].md 저장
실행: 직접
version: 1.0
verified_at: 2026-05-09
---

# /stakeholder-report
> 완료 항목 + 지표 변화 → 이해관계자용 주간/월간 보고서

## YAML 명세

```yaml
skill:
  id: stakeholder-report
  name: 이해관계자 보고서
  domain: po/문서
  trigger:
    - "이해관계자 보고"
    - "주간 보고"
    - "월간 보고"
    - "/stakeholder-report"
  inputs:
    - "기간 (주간/월간 + 날짜 범위)"
    - "완료 항목 목록"
    - "핵심 지표 현재값 (선택)"
    - "다음 기간 계획 (선택)"
  outputs:
    - path: "obsidian/03_Projects/[domain]/[work]/stakeholder-report-[date].md"
      type: md
    - path: context/events.jsonl
      type: log
  passes:
    - "완료 항목 목록 포함됨"
    - "핵심 지표 변화 포함됨"
    - "다음 주/월 계획 포함됨"
    - "이해관계자 수준 언어 사용 — 기술 용어 최소화"
  reviewer: passes 항목 체크 후 APPROVE/REVISE
```

## 트리거

- `/stakeholder-report` — 직접 실행
- `이해관계자 보고` — 보고서 생성 요청
- `주간 보고` — 주간 단위 보고서
- `월간 보고` — 월간 단위 보고서

## 실행 순서

### Step 1. 기간 및 완료 항목 파싱
- 기간(주간/월간) 확인
- 완료 항목 목록 구조화
- 항목별 영향도/가치 평가

**출력:** 완료 항목 정리

### Step 2. 지표 변화 분석
입력된 지표 데이터 기반:
- 현재값 vs 이전 기간 비교
- 트렌드 방향 표시 (↑/↓/→)
- 목표 대비 갭 계산

**출력:** 지표 변화 테이블

### Step 3. 보고서 초안 작성
이해관계자 수준 언어로 작성:
- 기술 용어 배제
- 비즈니스 임팩트 중심
- 다음 기간 계획 포함

**출력:** 보고서 초안

### Step 4. Reviewer — passes 조건 체크

```
Worker 산출물
  → Reviewer (passes 조건 1:1 대조)
    APPROVE → 저장 + 텔레그램 알림
    REVISE  → Worker 재실행
              입력: 원본 inputs + Reviewer 피드백 + 실패한 passes 조건 목록
              (최대 3회)
    REJECT  → Stuck Detector 발동
```

**Stuck Detector 텔레그램 포맷:**
```
[STUCK] stakeholder-report | retry=[count]회
실패 조건: [failed_passes]
마지막 오류: [error]
→ 직접 개입 필요
```

### Step 5. Obsidian 저장
파일명: `stakeholder-report-[YYYY-MM-DD].md`
저장 경로: `obsidian/03_Projects/[domain]/[work]/`

## 출력 형식

```
## /stakeholder-report 완료

# [기간] 이해관계자 보고 ([날짜 범위])

## 완료 항목
- ✅ [항목1] — [비즈니스 임팩트]
- ✅ [항목2] — [비즈니스 임팩트]

## 핵심 지표
| 지표 | 이전 | 현재 | 변화 |
|------|------|------|------|
| [지표1] | [값] | [값] | ↑/↓ |

## 다음 [주/월] 계획
- [ ] [계획1]
- [ ] [계획2]

passes:
✅ 완료 항목 목록 포함됨
✅ 핵심 지표 변화 포함됨
✅ 다음 기간 계획 포함됨
✅ 이해관계자 수준 언어 사용

저장: obsidian/03_Projects/[domain]/[work]/stakeholder-report-[date].md
```

## passes 조건

| 조건 | 확인 방법 |
|------|----------|
| 완료 항목 목록 포함 | 완료 섹션 존재 + 항목 1개 이상 |
| 핵심 지표 변화 포함 | 지표 테이블 또는 지표 목록 존재 |
| 다음 기간 계획 포함 | 계획 섹션 존재 + 항목 1개 이상 |
| 이해관계자 언어 | 기술 용어 미사용 확인 |

## 사용 예시

```
/stakeholder-report 주간 (5/5~5/9)
완료: backlog 정리, 스킬 16개 구현, nexus v8 배포
지표: 스킬 수 32→48, eval 통과율 85%
```

## 트리거 제외

- 팀 내부 개발 스프린트 리뷰 → /retro 사용
- 단순 작업 목록 정리 → 별도 요청으로 처리
