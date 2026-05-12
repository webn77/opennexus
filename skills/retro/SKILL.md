---
name: retro
description: 스프린트 ID 또는 기간과 완료 항목 목록을 받아 완료율·Keep/Problem/Try·다음 액션이 포함된 스프린트 회고 문서 생성. "회고", "스프린트 회고", "retrospective", "/retro" 요청 시 실행.
트리거: 회고, 스프린트 회고, retrospective, /retro
완료: obsidian/03_Projects/[domain]/sprint-retro-[sprint_id].md 저장
실행: 직접
version: 1.0
verified_at: 2026-05-09
---

# /retro
> 스프린트 완료 항목 → 완료율 + Keep/Problem/Try + 다음 액션

## YAML 명세

```yaml
skill:
  id: retro
  name: 스프린트 회고
  domain: po/스프린트
  trigger:
    - "회고"
    - "스프린트 회고"
    - "retrospective"
    - "/retro"
  inputs:
    - "스프린트 ID 또는 기간"
    - "완료된 항목 목록"
    - "미완료 항목 목록 (선택)"
    - "팀 코멘트 (선택)"
  outputs:
    - path: "obsidian/03_Projects/[domain]/sprint-retro-[sprint_id].md"
      type: md
    - path: context/events.jsonl
      type: log
  passes:
    - "완료율 계산됨"
    - "Keep/Problem/Try 각 1개 이상 정의됨"
    - "다음 스프린트 액션아이템 1개 이상 정의됨"
  reviewer: passes 항목 체크 후 APPROVE/REVISE
```

## 트리거

- `/retro` — 직접 실행
- `회고` — 스프린트 회고 시작
- `스프린트 회고` — 스프린트 ID와 함께 실행
- `retrospective` — 영어 명령어

## 실행 순서

### Step 1. 완료율 계산
- 총 항목 수 vs 완료 항목 수
- 완료율 = 완료 / 계획 × 100
- 미완료 항목 이유 분석 (입력된 경우)

**출력:** 완료율 + 미완료 항목 목록

### Step 2. KPT 도출
완료/미완료 패턴 분석:
- **Keep**: 잘 된 것, 계속할 것
- **Problem**: 문제였던 것, 개선 필요한 것
- **Try**: 다음 스프린트에 시도할 것

각 1개 이상 필수.

**출력:** KPT 목록

### Step 3. 다음 스프린트 액션아이템 정의
Problem → Try 전환으로 구체적 액션 도출:
- 담당자 (명시 가능한 경우)
- 기한
- 우선순위

**출력:** 액션아이템 목록

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
[STUCK] retro | retry=[count]회
실패 조건: [failed_passes]
마지막 오류: [error]
→ 직접 개입 필요
```

### Step 5. Obsidian 저장
파일명: `sprint-retro-[sprint_id].md`
저장 경로: `obsidian/03_Projects/[domain]/`

## 출력 형식

```
## /retro 완료

# Sprint [ID] 회고

## 완료율
계획: [N]개 | 완료: [M]개 | 완료율: [%]%

## Keep (잘 된 것)
- [Keep1]
- [Keep2]

## Problem (문제)
- [Problem1]
- [Problem2]

## Try (다음에 시도)
- [Try1]
- [Try2]

## 다음 스프린트 액션아이템
- [ ] [액션1] — 담당: [이름] | 기한: [날짜]
- [ ] [액션2]

passes:
✅ 완료율 계산됨 ([%]%)
✅ Keep/Problem/Try 각 1개 이상 정의됨
✅ 다음 스프린트 액션아이템 1개 이상 정의됨

저장: obsidian/03_Projects/[domain]/sprint-retro-[sprint_id].md
```

## passes 조건

| 조건 | 확인 방법 |
|------|----------|
| 완료율 계산됨 | "[%]%" 형태 수치 존재 |
| KPT 각 1개 이상 | Keep/Problem/Try 섹션 + 항목 존재 |
| 액션아이템 1개 이상 | 다음 스프린트 섹션 + 항목 존재 |

## 사용 예시

```
/retro Sprint-12
완료: WON-221 skill-eval 강화, WON-222 문서 스킬 3개
미완료: WON-230 openNexus (70% 진행)
```

## 트리거 제외

- 이해관계자 보고 → /stakeholder-report 사용
- 로드맵 계획 → /roadmap 사용
