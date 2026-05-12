---
name: interview-summary
description: 인터뷰 전사 텍스트를 받아 주제별 인사이트·액션아이템·참여자 정보를 구조화 요약. "인터뷰 요약", "인터뷰 정리", "/interview-summary" 요청 시 실행.
트리거: 인터뷰 요약, 인터뷰 정리, /interview-summary
완료: obsidian/03_Projects/[domain]/[work]/interview-[date].md 저장
실행: 직접
version: 1.0
verified_at: 2026-05-09
---

# /interview-summary
> 인터뷰 전사 텍스트 → 주제별 인사이트 + 액션아이템 구조화 요약

## YAML 명세

```yaml
skill:
  id: interview-summary
  name: 인터뷰 요약
  domain: po/리서치
  trigger:
    - "인터뷰 요약"
    - "인터뷰 정리"
    - "/interview-summary"
  inputs:
    - "인터뷰 전사 텍스트 또는 녹음 요약"
    - "인터뷰 날짜 (선택, 없으면 오늘 날짜 사용)"
    - "참여자 목록 (선택)"
  outputs:
    - path: "obsidian/03_Projects/[domain]/[work]/interview-[date].md"
      type: md
    - path: context/events.jsonl
      type: log
  passes:
    - "주제별 인사이트 3개 이상 도출됨"
    - "액션아이템 1개 이상 도출됨"
    - "참여자/날짜/주제 3요소 명시됨"
  reviewer: passes 항목 체크 후 APPROVE/REVISE
```

## 트리거

- `/interview-summary` — 직접 실행
- `인터뷰 요약` — 인터뷰 전사 텍스트 붙여넣기 후 실행
- `인터뷰 정리` — 대화형 정리 요청

## 실행 순서

### Step 1. 입력 파싱
전사 텍스트에서 다음을 추출:
- 참여자 목록 (발화자 구분 기반)
- 인터뷰 날짜 (텍스트 내 명시 또는 오늘 날짜)
- 주제/목적

**출력:** 메타데이터 블록

### Step 2. 주제별 인사이트 도출
전사 내용을 주제 단위로 클러스터링:
- 주제당 핵심 발언 인용
- 인사이트 1~2줄 요약
- 최소 3개 주제 도출

**출력:** 주제별 인사이트 목록

### Step 3. 액션아이템 추출
인터뷰에서 도출된 후속 행동 정의:
- 담당자 (명시 가능한 경우)
- 기한 (명시 가능한 경우)
- 우선순위

**출력:** 액션아이템 목록

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
[STUCK] interview-summary | retry=[count]회
실패 조건: [failed_passes]
마지막 오류: [error]
→ 직접 개입 필요
```

### Step 5. Obsidian 저장
파일명: `interview-[YYYY-MM-DD].md`
저장 경로: `obsidian/03_Projects/[domain]/[work]/`

## 출력 형식

```
## /interview-summary 완료

### 메타데이터
- 날짜: YYYY-MM-DD
- 참여자: [이름1], [이름2]
- 주제: [인터뷰 주제]

### 주제별 인사이트
① [주제1]
  - 인사이트: ...
  - 인용: "..."

② [주제2]
  - 인사이트: ...

③ [주제3]
  - 인사이트: ...

### 액션아이템
- [ ] [액션1] — 담당: [이름] | 기한: [날짜]
- [ ] [액션2]

passes:
✅ 주제별 인사이트 3개 이상 도출됨
✅ 액션아이템 도출됨
✅ 참여자/날짜/주제 명시됨

저장: obsidian/03_Projects/[domain]/[work]/interview-[date].md
```

## passes 조건

| 조건 | 확인 방법 |
|------|----------|
| 주제별 인사이트 3개 이상 | 출력 내 주제 섹션 3개 이상 존재 |
| 액션아이템 도출됨 | 출력 내 액션아이템 목록 존재 |
| 참여자/날짜/주제 명시됨 | 메타데이터 블록 3요소 확인 |

## 사용 예시

```
/interview-summary
[전사 텍스트 붙여넣기]
```

## 트리거 제외

- 단순 회의록 정리 → 인터뷰 목적이 없으면 별도 요청으로 처리
- 인터뷰 설계/질문 준비 → /po-interview 사용
