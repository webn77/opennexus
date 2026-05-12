---
name: diagram-gen
description: 다이어그램 유형(flowchart/sequence/architecture/erd)과 설명을 받아 Mermaid 또는 ASCII 다이어그램 생성. "다이어그램", "플로우차트", "시퀀스", "아키텍처 그려줘", "/diagram-gen" 요청 시 실행. ~/projects/_libs/diagrams/ai-patterns.md 10개 패턴 기반.
트리거: 다이어그램, 플로우차트, 시퀀스, 아키텍처 그려줘, /diagram-gen
완료: Mermaid 코드 블록 또는 ASCII 다이어그램 출력
실행: 직접
version: 1.0
verified_at: 2026-05-09
---

# /diagram-gen
> 다이어그램 유형 + 설명 → Mermaid 또는 ASCII 다이어그램

## YAML 명세

```yaml
skill:
  id: diagram-gen
  name: 다이어그램 생성
  domain: po/프로토타입
  trigger:
    - "다이어그램"
    - "플로우차트"
    - "시퀀스"
    - "아키텍처 그려줘"
    - "/diagram-gen"
  inputs:
    - "다이어그램 유형 (flowchart/sequence/architecture/erd)"
    - "설명 또는 시스템/프로세스 내용"
  outputs:
    - Mermaid 코드 블록 또는 ASCII 다이어그램 (인라인 출력)
  passes:
    - "요청 유형에 맞는 다이어그램 생성됨"
    - "모든 노드/컴포넌트에 레이블 있음"
    - "시퀀스의 경우 모든 메시지에 응답 있음"
  reviewer: passes 항목 체크 후 APPROVE/REVISE
```

## 패턴 소스

`~/projects/_libs/diagrams/ai-patterns.md` (10개 패턴)

패턴 분류:
- `flowchart` — 사용자 흐름/업무 프로세스 (graph TD/LR)
- `sequenceDiagram` — API/서비스 통신 (participant, ->>)
- `ASCII` — 아키텍처/레이어 구조 (박스+화살표)
- `erDiagram` — 데이터 모델/관계 (entities, relationships)

## 트리거

- `/diagram-gen` — 직접 실행
- `다이어그램` — 유형 포함 요청 시 실행
- `플로우차트` → flowchart 유형 자동 선택
- `시퀀스` → sequenceDiagram 유형 자동 선택
- `아키텍처 그려줘` → ASCII 아키텍처 자동 선택
- `ERD` 또는 `데이터 모델` → erDiagram 자동 선택

## 실행 순서

### Step 1. 유형 판별
요청 텍스트에서 다이어그램 유형 자동 판별:
- 키워드 기반 유형 매핑
- 유형 불명확 시 4가지 옵션 제시 후 선택

**출력:** 선택된 유형 + 패턴 참조

### Step 2. ai-patterns.md 참조
`~/projects/_libs/diagrams/ai-patterns.md`에서 해당 유형 패턴 로드:
- 기본 템플릿 구조 확인
- 예시 노드/컴포넌트 스타일 확인

**출력:** 패턴 기반 초안

### Step 3. 다이어그램 생성
설명 내용을 패턴에 맞게 적용:
- 모든 노드/컴포넌트 레이블 부여
- 시퀀스 → 모든 메시지에 응답 포함
- 예외/에러 경로 표시 (복잡한 경우)

**출력:** 완성된 Mermaid 코드 블록 또는 ASCII

### Step 4. Reviewer — passes 조건 체크

```
Worker 산출물
  → Reviewer (passes 조건 1:1 대조)
    APPROVE → 인라인 출력
    REVISE  → Worker 재실행 (최대 3회)
    REJECT  → Stuck Detector 발동
```

**Stuck Detector 텔레그램 포맷:**
```
[STUCK] diagram-gen | retry=[count]회
실패 조건: [failed_passes]
마지막 오류: [error]
→ 직접 개입 필요
```

## 출력 형식

```
## /diagram-gen 완료 ([유형])

```mermaid
[다이어그램 코드]
```

passes:
✅ 요청 유형에 맞는 다이어그램 생성됨
✅ 모든 노드/컴포넌트에 레이블 있음
✅ [시퀀스: 모든 메시지에 응답 있음]
```

## passes 조건

| 조건 | 확인 방법 |
|------|----------|
| 요청 유형 일치 | flowchart/sequence/ASCII/erd 키워드 일치 확인 |
| 레이블 존재 | 노드 선언에 모두 레이블 포함 여부 |
| 시퀀스 응답 | -->> 또는 응답 화살표 존재 여부 |

## 사용 예시

```
/diagram-gen sequence
사용자가 로그인 → API 서버 → DB 조회 → 토큰 발급
```

```
/diagram-gen architecture
3-tier: 프론트엔드 / API 서버 / PostgreSQL
```

## 트리거 제외

- 화면 UI 와이어프레임 → /ascii-mockup-wireframe 사용
- 화면 흐름도 → /prototype-flow 사용
