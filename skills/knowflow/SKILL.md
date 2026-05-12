---
name: knowflow
description: raw 콘텐츠(URL/텍스트/파일)를 받아 위키 카테고리 분류·갭 분석·백로그 ingest 제안까지 수행하는 지식 흐름 파이프라인. "knowflow", "지식 정리", "위키 갱신", "/knowflow" 요청 시 실행.
트리거: knowflow, 지식 정리, 위키 갱신, /knowflow
완료: obsidian/01_지식위키/[카테고리]/[제목].md 저장 + 백로그 ingest 제안
실행: 직접
version: 1.0
verified_at: 2026-05-09
---

# /knowflow
> raw 콘텐츠 → 위키 카테고리 분류 + 갭 분석 + 백로그 ingest 제안

## YAML 명세

```yaml
skill:
  id: knowflow
  name: 지식 흐름 파이프라인
  domain: po/운영
  trigger:
    - "knowflow"
    - "지식 정리"
    - "위키 갱신"
    - "/knowflow"
  inputs:
    - "raw 콘텐츠 (URL/텍스트/파일)"
    - "카테고리 힌트 (선택)"
  outputs:
    - path: "obsidian/01_지식위키/[카테고리]/[제목].md"
      type: md
    - path: context/backlog.json
      type: json
  passes:
    - "위키 카테고리 분류됨"
    - "갭 분석 (기존 위키 대비 신규 인사이트) 도출됨"
    - "백로그 ingest 제안 포함됨"
  reviewer: passes 항목 체크 후 APPROVE/REVISE
```

## 트리거

- `/knowflow` — 직접 실행
- `지식 정리` — 콘텐츠 → 위키 저장
- `위키 갱신` — 기존 위키 업데이트
- `knowflow` — 슬래시 없는 명령어

## 실행 순서

### Step 1. 콘텐츠 수집
입력 유형별 처리:
- URL → WebFetch 또는 wiki-ingest로 내용 수집
- 텍스트 → 직접 분석
- 파일 → Read 도구로 로드

**출력:** 원본 콘텐츠 요약

### Step 2. 카테고리 분류
`obsidian/01_지식위키/` 하위 카테고리로 분류:
- AI툴 / 개발 / 데이터 / 비즈니스 / 핀테크 / EV충전 / 기타
- 기존 index.md 참조해 적합한 카테고리 선택

**출력:** 분류된 카테고리 + 파일명 제안

### Step 3. 갭 분석
기존 위키 대비 신규 인사이트 도출:
- `wiki-query`로 유사 기존 문서 검색
- 새로운 정보 vs 중복 정보 구분
- 갭 (신규 인사이트) 명시

**출력:** 갭 분석 결과

### Step 4. 위키 페이지 생성
Karpathy 패턴 기반 구조:
```markdown
---
created: YYYY-MM-DD
tags: [태그1, 태그2]
source: [출처]
---
# [제목]
[요약 3~5줄]

## 핵심 내용
[인사이트 목록]

## 갭 (기존 위키 대비 신규)
[신규 인사이트]

## 출처
[링크 또는 출처]
```

**출력:** 위키 페이지

### Step 5. 백로그 ingest 제안
갭 분석에서 도출된 실행 가능한 항목:
- 백로그 추가 가능한 아이디어
- RICE 점수 추정
- `/backlog-add` 실행 제안

**출력:** 백로그 후보 목록

### Step 6. Reviewer — passes 조건 체크

```
Worker 산출물
  → Reviewer (passes 조건 1:1 대조)
    APPROVE → 저장 + 텔레그램 알림
    REVISE  → Worker 재실행 (최대 3회)
    REJECT  → Stuck Detector 발동
```

**Stuck Detector 텔레그램 포맷:**
```
[STUCK] knowflow | retry=[count]회
실패 조건: [failed_passes]
마지막 오류: [error]
→ 직접 개입 필요
```

### Step 7. Obsidian 저장
파일명: `[제목-슬러그].md`
저장 경로: `obsidian/01_지식위키/[카테고리]/`

## 출력 형식

```
## /knowflow 완료

**카테고리**: [카테고리]
**제목**: [파일명]

### 갭 분석
기존 위키 대비 신규 인사이트:
- [신규 인사이트1]
- [신규 인사이트2]

### 백로그 ingest 제안
| 항목 | RICE 추정 | 제안 |
|------|----------|------|
| [항목] | [점수] | /backlog-add [도메인] [제목] |

passes:
✅ 위키 카테고리 분류됨 ([카테고리])
✅ 갭 분석 도출됨 ([N]개 신규 인사이트)
✅ 백로그 ingest 제안 포함됨

저장: obsidian/01_지식위키/[카테고리]/[파일명].md
```

## passes 조건

| 조건 | 확인 방법 |
|------|----------|
| 카테고리 분류 | 카테고리 명시 + 저장 경로 포함 |
| 갭 분석 도출 | 신규 인사이트 섹션 존재 |
| 백로그 ingest 제안 | 백로그 후보 목록 존재 |

## 사용 예시

```
/knowflow https://example.com/ai-article
```

```
/knowflow
[텍스트 붙여넣기]
```

## 트리거 제외

- 단순 URL 저장 → /wiki-ingest 사용
- 위키 검색 → /wiki-query 사용
