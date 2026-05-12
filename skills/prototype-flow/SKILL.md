---
name: prototype-flow
description: 기능 목록 또는 서비스 설명을 받아 화면 목록·화면 간 전환 조건·주요 사용자 경로가 포함된 화면 흐름도 생성. "화면 흐름", "화면 설계", "IA", "프로토타입 흐름", "/prototype-flow" 요청 시 실행.
트리거: 화면 흐름, 화면 설계, IA, 프로토타입 흐름, /prototype-flow
완료: obsidian/03_Projects/[domain]/[work]/flow-[date].md 저장
실행: 직접
version: 1.0
verified_at: 2026-05-09
---

# /prototype-flow
> 기능 목록/서비스 설명 → 화면 수 + 전환 조건 + 주요 경로 화면 흐름도

## YAML 명세

```yaml
skill:
  id: prototype-flow
  name: 화면 흐름도
  domain: po/프로토타입
  trigger:
    - "화면 흐름"
    - "화면 설계"
    - "IA"
    - "프로토타입 흐름"
    - "/prototype-flow"
  inputs:
    - "기능 목록 또는 서비스 설명"
    - "타겟 사용자 (선택)"
  outputs:
    - path: "obsidian/03_Projects/[domain]/[work]/flow-[date].md"
      type: md
    - path: context/events.jsonl
      type: log
  passes:
    - "화면 수 명시됨"
    - "각 화면 간 전환 조건(트리거) 정의됨"
    - "주요 사용자 경로 1개 이상 명시됨"
  reviewer: passes 항목 체크 후 APPROVE/REVISE
```

## 트리거

- `/prototype-flow` — 직접 실행
- `화면 흐름` — 화면 흐름도 생성 요청
- `화면 설계` — IA/화면 구조 설계
- `IA` — Information Architecture 설계
- `프로토타입 흐름` — 프로토타입 화면 전환 설계

## 실행 순서

### Step 1. 화면 목록 추출
기능 목록 또는 서비스 설명에서:
- 주요 화면 목록 도출
- 화면별 역할/목적 정의
- 총 화면 수 명시

**출력:** 화면 목록 (번호 + 이름 + 역할)

### Step 2. 전환 조건 정의
각 화면 간 이동을 트리거 기반으로 정의:
- 버튼 클릭 / 폼 제출 / 자동 전환
- 조건부 분기 (로그인 여부, 권한 등)
- 에러/예외 경로

**출력:** 전환 매트릭스 또는 Mermaid flowchart

### Step 3. 주요 사용자 경로 명시
핵심 사용자 시나리오 1개 이상:
- 시작 화면 → 목표 달성 화면까지 순서
- 각 단계 전환 조건

**출력:** 주요 경로 설명

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
[STUCK] prototype-flow | retry=[count]회
실패 조건: [failed_passes]
마지막 오류: [error]
→ 직접 개입 필요
```

### Step 5. Obsidian 저장
파일명: `flow-[YYYY-MM-DD].md`
저장 경로: `obsidian/03_Projects/[domain]/[work]/`

## 출력 형식

```
## /prototype-flow 완료

### 화면 목록 (총 N개)
1. [화면명] — [역할]
2. [화면명] — [역할]
...

### 화면 전환 흐름

```mermaid
flowchart TD
  A[화면1] -->|[조건]| B[화면2]
  B -->|[조건]| C[화면3]
```

### 주요 사용자 경로
시나리오: [시나리오 설명]
① [화면1] → [전환 조건] → ② [화면2] → ... → [목표]

passes:
✅ 화면 수 명시됨 (N개)
✅ 각 화면 간 전환 조건 정의됨
✅ 주요 사용자 경로 1개 이상 명시됨

저장: obsidian/03_Projects/[domain]/[work]/flow-[date].md
```

## passes 조건

| 조건 | 확인 방법 |
|------|----------|
| 화면 수 명시 | 총 N개 문구 또는 번호 목록 존재 |
| 전환 조건 정의 | 각 화면 연결에 레이블/조건 존재 |
| 주요 사용자 경로 | 시나리오 섹션 존재 + 흐름 순서 명시 |

## 사용 예시

```
/prototype-flow
기능: 로그인, 대시보드, 충전소 검색, 충전 시작, 결제, 충전 완료
타겟: EV 차량 사용자
```

## 트리거 제외

- 기술적 API 흐름 → /diagram-gen sequence 사용
- UI 화면 목업 → /ascii-mockup-wireframe 사용
