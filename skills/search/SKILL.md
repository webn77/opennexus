---
name: search
description: FTS5 + 인지 메모리 재랭킹 통합 검색. 파일·문서·프로젝트·소스·메모리 전체 탐색. 위치 탐색 요청 시 무조건 먼저 실행. (nexus v8.2: search.db FTS5 우선, grep fallback)
트리거: /search "키워드", 찾아줘, 검색해줘, 예전에 관련 뭐 있었지
완료: 검색 결과 N건 + score 출력
실행: shell (~/.nexus8/search.sh → search_fts.py)
---

# /search
> ~/.nexus8/search.sh 기반 통합 검색 | 파일·문서·프로젝트·소스 전체 탐색

## 트리거
- `/search "키워드"`
- `/search "키워드" [도메인] [타입]`
- "찾아줘 [키워드]", "검색해줘 [키워드]"
- "예전에 [키워드] 관련 뭐 있었지"
- 파일·문서 위치 탐색 요청 시 **무조건 먼저 실행**

## 소스 (search.sh 탐색 대상)

**FTS5 모드** (search.db 존재 시 — 기본):
| 타입 | 중요도 | 내용 |
|------|--------|------|
| memory | 0.9 | ~/.claude/…/memory/*.md |
| project | 0.8 | ~/.nexus8/projects-index.jsonl |
| work | 0.7 | ~/.nexus8/work-index.jsonl |
| source | 0.5 | ~/.nexus8/source-index.jsonl |

결과 포맷: `[타입/도메인] 날짜 | 요약 | score=0.0~1.0 | 파일경로`

**grep fallback** (search.db 없을 때):
| 타입 | 경로 |
|------|------|
| work/log | ~/.nexus8/work-index.jsonl |
| work/wiki | $NEXUS_VAULT/01_지식위키/ |
| work/post | $NEXUS_VAULT/03_Projects/work/linkedin-series/ |
| */project | ~/.nexus8/projects-index.jsonl |
| */source | ~/.nexus8/source-index.jsonl |
| ai/memory | ~/.claude/projects/memory/ |

인덱스 갱신: `python3 ~/.nexus8/build_search_index.py` (매일 00:05 자동)

## 실행 순서

### Step 1. 인자 파싱
- `키워드` 추출 (필수)
- `도메인` 추출 (선택: work / hire / analyze / study)
- `타입` 추출 (선택: log / wiki / post / project / source)

### Step 2. search.sh 실행
```bash
~/.nexus8/search.sh "키워드" [도메인] [타입]
```

### Step 3. 결과 출력
```
검색: "키워드" | N건

① [work/wiki] 2026-04-24 | GPT-5.5 vs Claude 비교 | 03_Projects/work/linkedin-series/R_gpt-5.5.md
② [work/log]  2026-04-24 | R_gpt-5.5.md 완성 | ...
...

→ 관련 파일 열어볼까요? [파일명]
```

- 결과 0건이면: "검색 결과 없음 — find/grep fallback 시도할까요?" 제안
- 결과 있으면: 상위 5건 요약 후 필요 시 파일 직접 읽기

## 규칙
- find / grep 직접 사용 금지 — 이 스킬이 먼저
- search.sh 실패(0건) 시에만 find fallback 허용
- Telegram 채널에서 탐색 요청 수신 시도 동일하게 적용
