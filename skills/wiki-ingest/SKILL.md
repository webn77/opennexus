---
name: wiki-ingest
description: raw/ 저장 스킬. Karpathy 패턴. URL·텍스트·대화 인사이트 저장.
트리거: wiki에 저장, 지식 저장, wiki에 저장해줘, /wiki-ingest [내용]
완료: $NEXUS_VAULT/01_지식위키/raw/YYYY-MM-DD-[슬러그].md 저장
실행: 직접
---

# /wiki-ingest
> raw/ 저장 스킬 | Karpathy 패턴 | 원본 불변

## 트리거
- "wiki에 저장 [URL|텍스트]"
- "지식 저장 [URL|텍스트]"
- "wiki에 저장해줘"
- `/wiki-ingest [내용]`
- Claude 작업 중 인사이트 자동 감지 → "wiki에 저장할까요?" 제안

## 저장 경로
`$NEXUS_VAULT/01_지식위키/raw/YYYY-MM-DD-[주제-슬러그].md`

## 실행 순서

### Step 1. 입력 파악
- URL이면: 페이지 제목 + 핵심 내용 추출 (WebFetch)
- 텍스트이면: 그대로
- 대화 내용이면: 인사이트 요약

### Step 2. 파일명 결정
- 형식: `YYYY-MM-DD-[주제-슬러그].md`
- 슬러그: 소문자, 하이픈 구분, 한국어 가능
- 예: `2026-04-20-chromadb-chunk-전략.md`

### Step 3. raw 파일 작성
```markdown
# [제목]
> 저장: YYYY-MM-DD | 출처: [URL 또는 "대화"]

[원본 내용 또는 요약 — 가공 없이 그대로]
```

### Step 4. 완료 메시지
```
raw/YYYY-MM-DD-[주제].md 저장 완료 ✅
compile 하려면 /wiki-compile
```

## 규칙
- raw 파일은 원본 그대로 저장 (LLM 재작성 금지)
- compile 전까지 wiki/ 미변경
- 포트폴리오/ 경로 절대 접근 금지

## 파이프라인 연결
연결 위치: doc-sync 후
방식: 조건부
조건: 인사이트 저장 의도 시

## 파이프라인 연결
연결 위치: doc-sync 후
방식: 조건부
조건: 인사이트 저장 의도 시
