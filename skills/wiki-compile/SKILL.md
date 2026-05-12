---
name: wiki-compile
description: raw/ → wiki 페이지 생성. 수동 실행 전용.
트리거: /wiki-compile, /wiki-compile [파일명], /wiki-compile 최근 N개
완료: $NEXUS_VAULT/01_지식위키/[카테고리]/ 페이지 생성
실행: 직접
---

# /wiki-compile
> raw → wiki 페이지 생성 스킬 | 수동 실행 전용

## 트리거
- `/wiki-compile` — 미compile raw 전체 처리
- `/wiki-compile [파일명]` — 특정 raw 파일만
- `/wiki-compile 최근 N개` — 최근 N개만

## 경로
- raw: `$NEXUS_VAULT/01_지식위키/raw/`
- wiki: `$NEXUS_VAULT/01_지식위키/[카테고리]/[주제].md`
- allow_paths: AI툴/, claude-code/, workflow/, tools/, infra/, 시장조사/, queries/
- exclude_paths: 포트폴리오/ (절대 접근 금지)

## 실행 순서

### Step 1. 미compile 목록 파악
- raw/ 스캔 → 대응하는 wiki 파일 없는 것 목록화
- 출력: "raw/ 미compile 항목 N건 발견"

### Step 2. 카테고리 결정
- 기존 디렉토리 구조 준수 (AI툴/, 시장조사/ 등)
- 신규 카테고리면 사용자 확인 후 생성

### Step 3. wiki 페이지 생성
각 raw 파일에 대해:
1. raw 파일 읽기
2. frontmatter 작성 (LLM이 tags 자동 부여)
3. 본문 재구성 (개념 정리 + 인사이트 추출)
4. 기존 wiki 페이지와 중복 개념이면 병합
5. 관련 페이지에 backlink 추가

**wiki 페이지 형식:**
```markdown
---
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags: [태그1, 태그2]
source: raw/YYYY-MM-DD-[주제].md
type: concept|source-summary|insight|how-to
status: active
---

# [제목]

[본문]

## 관련 문서
- [[관련페이지]]
```

### Step 4. index.md 갱신
- 해당 카테고리 테이블에 새 행 추가
- 형식: `| [[경로/파일]] | tags | type | YYYY-MM-DD |`

### Step 5. log.md append
```
## YYYY-MM-DD compile | [제목]
- raw: raw/YYYY-MM-DD-[주제].md
- wiki: [카테고리]/[주제].md
- type: [type]
```

### Step 6. 완료 출력
```
compile 완료 ✅  index.md 갱신  log.md 기록
생성: N건 | 병합: N건
```

## 규칙
- 수동 실행 전용 (자동 compile 절대 금지)
- raw 파일 수정 금지 (원본 불변)
- 포트폴리오/ 경로 절대 접근 금지
- 기존 wiki 페이지 덮어쓰기 전 내용 병합 여부 확인
