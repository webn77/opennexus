---
name: wiki-query
description: index.md 기반 검색 + 답변 합성. 벡터DB 없음.
트리거: /wiki-query "질문", wiki에서 찾아줘, 예전에 어떻게 했지
완료: 관련 wiki 내용 답변 합성 출력
실행: 직접
---

# /wiki-query
> index.md 기반 검색 + 답변 합성 | 벡터DB 없음

## 트리거
- `/wiki-query "질문"`
- "wiki에서 [주제] 찾아줘"
- "예전에 [주제] 어떻게 했지"

## 경로
- index: $NEXUS_VAULT/01_지식위키/index.md
- wiki: $NEXUS_VAULT/01_지식위키/
- queries: $NEXUS_VAULT/01_지식위키/queries/

## 실행 순서

### Step 1. index.md 검색
- index.md 읽기
- 질문 키워드로 관련 행 필터 (tags + 파일명 매칭)
- 관련 파일 목록 추출 (최대 5개)

### Step 2. 파일 직접 읽기
- 관련 파일 본문 읽기
- 핵심 내용 추출

### Step 3. 답변 합성
출력 형식:
```
관련 문서 N건
① [카테고리/파일명]  (tags: ...)
   [핵심 내용 한 줄]
② ...

[종합 답변]
```

### Step 4. queries/ 자동 저장
- 파일명: `queries/YYYY-MM-DD-[질문-슬러그].md`
- 형식:
```markdown
---
created: YYYY-MM-DD
query: "[질문]"
sources: [파일1, 파일2]
---
# [질문]
[답변]
```

## 규칙
- 벡터DB 없음 — index.md + 파일 직접 읽기
- 포트폴리오/ 경로 접근 금지
- 답변은 반드시 queries/에 저장

## 인지 메모리 점수 공식

wiki-query 검색 랭킹 산출 공식:

```
검색 랭킹 = 0.55 × 유사도 + 0.20 × 중요도 + 0.15 × 최신성 + 0.10 × 빈도
```

| 구성 요소 | 가중치 | 설명 |
|----------|--------|------|
| 유사도 (Similarity) | 0.55 | 질문 키워드 ↔ 문서 태그/제목 매칭 점수 |
| 중요도 (Importance) | 0.20 | 위키 내 참조 횟수, 수동 중요도 태그 |
| 최신성 (Recency) | 0.15 | 최근 수정일 기준 점수 (최신일수록 높음) |
| 빈도 (Frequency) | 0.10 | 동일 쿼리 반복 조회 횟수 |

> 가중치 합계 = 1.00
> 인덱스 없는 환경에서는 키워드 매칭(유사도)을 주요 기준으로 사용.

## 파이프라인 연결
연결 위치: spec-define 전
방식: 조건부
조건: 유사 사례 있을 때
