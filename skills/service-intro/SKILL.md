---
name: service-intro
description: PRD 또는 서비스 설명을 받아 배경/문제/솔루션/KPI/CTA 5요소로 구성된 A4 1페이지 서비스 소개서 생성. "서비스 소개서", "1페이저", "/service-intro" 요청 시 실행.
트리거: 서비스 소개서, 1페이저, 서비스 소개, /service-intro
완료: obsidian/03_Projects/[domain]/[work]/service-intro-[date].md 저장
실행: 직접
version: 1.0
verified_at: 2026-05-09
---

# /service-intro
> PRD/서비스 설명 → A4 1페이지 서비스 소개서 (비개발자 대상)

## YAML 명세

```yaml
skill:
  id: service-intro
  name: 서비스 소개서
  domain: po/문서
  trigger:
    - "서비스 소개서"
    - "1페이저"
    - "서비스 소개"
    - "/service-intro"
  inputs:
    - "PRD 또는 서비스 설명 텍스트"
    - "독자 대상 (선택, 기본: 비개발자/경영진)"
  outputs:
    - path: "obsidian/03_Projects/[domain]/[work]/service-intro-[date].md"
      type: md
    - path: context/events.jsonl
      type: log
  passes:
    - "배경/문제/솔루션/KPI/CTA 5요소 포함됨"
    - "A4 1페이지 분량 (600자 이하)"
    - "독자(비개발자) 수준 언어 사용 — 기술 용어 최소화"
  reviewer: passes 항목 체크 후 APPROVE/REVISE
```

## 트리거

- `/service-intro` — 직접 실행
- `서비스 소개서` — PRD 또는 설명 제공 후 실행
- `1페이저` — 1페이지 요약 문서 요청
- `서비스 소개` — 간략 소개 문서 요청

## 실행 순서

### Step 1. 입력 분석
PRD 또는 서비스 설명에서 핵심 요소 추출:
- 서비스명
- 타겟 사용자
- 핵심 문제/Pain Point
- 솔루션 핵심 가치
- 측정 가능한 성과 지표
- 기대 CTA (다음 단계)

**출력:** 요소 추출 요약

### Step 2. 1페이저 초안 작성
5요소 구조로 작성:
1. **배경**: 시장/문제 맥락 (1~2줄)
2. **문제**: 구체적 Pain Point (1~2줄)
3. **솔루션**: 서비스가 해결하는 방식 (2~3줄)
4. **KPI**: 성공 지표 (2~3개)
5. **CTA**: 독자에게 요청하는 행동 (1줄)

기술 용어 배제, 600자 이내 유지.

**출력:** 1페이저 초안

### Step 3. Reviewer — passes 조건 체크

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
[STUCK] service-intro | retry=[count]회
실패 조건: [failed_passes]
마지막 오류: [error]
→ 직접 개입 필요
```

### Step 4. Obsidian 저장
파일명: `service-intro-[YYYY-MM-DD].md`
저장 경로: `obsidian/03_Projects/[domain]/[work]/`

## 출력 형식

```
## /service-intro 완료

# [서비스명] 소개

**배경**
[시장 맥락 1~2줄]

**문제**
[Pain Point 1~2줄]

**솔루션**
[해결 방식 2~3줄]

**KPI**
- [지표1]: [목표값]
- [지표2]: [목표값]

**다음 단계**
[CTA 1줄]

passes:
✅ 배경/문제/솔루션/KPI/CTA 5요소 포함됨
✅ A4 1페이지 분량 (600자 이하)
✅ 비개발자 수준 언어 사용

저장: obsidian/03_Projects/[domain]/[work]/service-intro-[date].md
```

## passes 조건

| 조건 | 확인 방법 |
|------|----------|
| 5요소 포함 | 배경/문제/솔루션/KPI/CTA 섹션 존재 확인 |
| 600자 이하 | 본문 글자 수 카운트 |
| 비개발자 언어 | 기술 용어(API/DB/서버 등) 미사용 여부 |

## 사용 예시

```
/service-intro
[PRD 내용 또는 서비스 설명 붙여넣기]
```

## 트리거 제외

- 상세 기술 명세서 요청 → /spec-define 사용
- 풀 PRD 작성 요청 → /spec-define 사용
