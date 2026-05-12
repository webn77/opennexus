---
name: spec-hardening
description: spec-define 완료 후 병렬 실행을 위한 구조 강화. 5개 산출물 생성.
트리거: /spec-hardening [도메인] [버전]
완료: ownership-map 등 5개 산출물 생성
실행: Agent+직접
requires: [spec.md, PRD.md, plan.md]
---

# /spec-hardening
> spec-define 완료 후 병렬 실행을 위한 구조 강화 단계
> 5개 산출물 생성 → ownership-map 기반 spec-build 병렬화 준비


## 트리거
- `/spec-hardening [도메인] [버전]`
- 예: `/spec-hardening hire v7.0`
- 예: `/spec-hardening nexus v8.0`

**전제 조건:**
- `/spec-define` 완료 후 실행 (spec.md + PRD + plan 존재 필수)

**사용 기준 (아래 중 1개 이상 해당 시에만 실행):**
- DB 스키마 신규 설계 또는 구조 변경 포함
- 에이전트 병렬 실행이 필요한 복잡한 구현 (3개 이상 독립 태스크)
- 마이크로서비스 또는 레이어 간 의존성 설계 필요

**생략 가능한 경우 (→ spec-define 후 바로 spec-build):**
- 운영 개선·설정 변경·문서 작업
- 단일 파일/단일 기능 수정
- UI 개선 (DB 변경 없는 경우)

---

## 사람이 해야 하는 것
없음. 완료 후 ownership-map 확인 → ok면 `/spec-build [도메인]` 입력.

---

## Step 0. 전제 조건 확인 — 필수 게이트
⛔ **아래 3개 파일 미존재 시 즉시 중단.**

확인 순서:
1. `obsidian/03_Projects/[도메인]/[버전]-spec.md` 또는 도메인 spec 파일
2. `obsidian/03_Projects/[도메인]/[버전]-PRD.md`
3. `obsidian/03_Projects/[도메인]/[버전]-plan.md`

누락 파일 있으면:
```
⛔ spec-hardening 중단
누락: [파일명]
→ /spec-define [도메인] [버전] 먼저 실행하세요.
```

---

## Fan-out 실행 — Step 1~3 병렬

Step 0 통과 후 3개 파일을 읽고 Agent 3개를 **단일 메시지에 동시에** 호출한다.

**사전 작업 (Claude 직접):**
```
spec_content  = Read([버전]-spec.md)
prd_content   = Read([버전]-PRD.md)
plan_content  = Read([버전]-plan.md)
```

**에이전트 계약:**
```
입력:  spec + PRD + plan 전문 (대화 이력 공유 안 됨 — 명시적 전달 필수)
출력:  각 산출물 파일을 obsidian 경로에 직접 Write
모델:  general-purpose (Sonnet)
실패:  한 에이전트 실패 시 해당 Step만 Claude 직접 실행으로 폴백 + 실패 명시
SLA:   각 ≤ 240s
```

**Agent 1 — db-schema 프롬프트:**
```
[spec-hardening] 아래 spec/PRD 기반으로 DB 스키마 문서를 작성해 저장하라.
저장 경로: obsidian/03_Projects/[도메인]/[버전]-db-schema.md

[SPEC]: <spec_content>
[PRD]: <prd_content>

작성 형식: Step 1 템플릿 준수 (테이블 목록 + 상세 + 인덱스 + Mermaid ERD)
```

**Agent 2 — architecture 프롬프트:**
```
[spec-hardening] 아래 spec/plan 기반으로 아키텍처 문서를 작성해 저장하라.
저장 경로: obsidian/03_Projects/[도메인]/[버전]-architecture.md

[SPEC]: <spec_content>
[PLAN]: <plan_content>

작성 형식: Step 2 템플릿 준수 (시스템 구성도 + 레이어 + 데이터 흐름 + 외부 의존성)
```

**Agent 3 — dependency-graph 프롬프트:**
```
[spec-hardening] 아래 plan의 Phase 정의 기반으로 의존성 그래프를 작성해 저장하라.
저장 경로: obsidian/03_Projects/[도메인]/[버전]-dependency-graph.md

[PLAN]: <plan_content>

작성 형식: Step 3 템플릿 준수 (Mermaid 그래프 + 병렬 그룹 + 크리티컬 패스)
```

3개 완료 확인 후 Step 4로 진행.

---

## Step 1. db-schema 생성

저장 경로: `obsidian/03_Projects/[도메인]/[버전]-db-schema.md`

PRD 기능 요구사항 + spec 🆕 항목 기반으로 작성:
```markdown
# [도메인] [버전] DB Schema

## 테이블 목록
| 테이블명 | 역할 | 주요 컬럼 |
|---|---|---|

## 테이블 상세
### [테이블명]
- id: PK
- [컬럼명]: [타입] [제약조건] — [설명]
...

## 인덱스 전략
- [인덱스명]: [컬럼] — [이유]

## 관계 다이어그램 (Mermaid)
\`\`\`mermaid
erDiagram
  ...
\`\`\`
```

PRD 필드명과 db-schema 컬럼명 일치 확인:
- 불일치 발견 시 → db-schema 기준으로 통일 후 PRD에 노트 추가

---

## Step 2. architecture-diagram 생성

저장 경로: `obsidian/03_Projects/[도메인]/[버전]-architecture.md`

```markdown
# [도메인] [버전] 아키텍처

## 시스템 구성도 (Mermaid)
\`\`\`mermaid
graph TD
  ...
\`\`\`

## 레이어 설명
| 레이어 | 역할 | 주요 컴포넌트 |
|---|---|---|

## 데이터 흐름
1. [단계] → [컴포넌트] → [출력]
...

## 외부 의존성
| 시스템 | 용도 | 인터페이스 |
|---|---|---|
```

---

## Step 3. dependency-graph 생성

저장 경로: `obsidian/03_Projects/[도메인]/[버전]-dependency-graph.md`

plan.md Phase 정의 기반으로 작성:
```markdown
# [도메인] [버전] Dependency Graph

## 태스크 의존성 (Mermaid)
\`\`\`mermaid
graph TD
  T1[DB 스키마] --> T2[API 레이어]
  T1 --> T3[데이터 마이그레이션]
  T2 --> T4[프론트엔드 연동]
  T5[인증 모듈] --> T2
  T2 & T4 --> T6[통합 테스트]
\`\`\`

## 병렬 가능 그룹
| 그룹 | 태스크 목록 | 선행 완료 필요 |
|---|---|---|
| 그룹 A | T2, T3 | T1 완료 후 |
| 그룹 B | T4, T5 | T1 완료 후 |
| 최종 | T6 | 그룹 A+B 완료 후 |

## 크리티컬 패스
T1 → T2 → T4 → T6 (예상 N일)
```

---

## Step 4. ownership-map 생성 — 필수 산출물

⛔ **이 파일 없으면 spec-build 실행 불가.**

저장 경로: `obsidian/03_Projects/[도메인]/[버전]-ownership-map.md`

dependency-graph 병렬 그룹 기반으로 작성:
```markdown
# [도메인] [버전] Ownership Map

## 에이전트별 담당 파일/디렉토리

| 에이전트 | 담당 태스크 | 독점 파일/경로 | 읽기 전용 파일 |
|---|---|---|---|
| Agent-A | T1 (DB) | src/db/, migrations/ | - |
| Agent-B | T2 (API) | src/api/, src/routes/ | src/db/schema.py |
| Agent-C | T4 (Frontend) | src/frontend/, public/ | src/api/types.ts |

## 공유 파일 (충돌 주의)
| 파일 | 읽기 허용 에이전트 | 쓰기 허용 에이전트 | 처리 방식 |
|---|---|---|---|
| config.py | ALL | Agent-A만 | propose→validate→commit |
| README.md | ALL | 마지막 에이전트 | 순차 처리 |

## 충돌 해결 규칙
1. 동일 파일 쓰기 충돌 → propose-validate-commit 패턴
2. 공유 config 변경 → Agent-A 선 처리 후 다른 에이전트 읽기
3. 미해결 충돌 → Assembly 에이전트 또는 사람 게이트
```

생성 후 검증:
- 모든 🆕 태스크가 담당 에이전트에 할당됐는지 확인
- 동일 파일에 쓰기 에이전트 2명 이상이면 → 공유 파일 테이블로 이동

---

## Step 5. parallel-strategy 생성

저장 경로: `obsidian/03_Projects/[도메인]/[버전]-parallel-strategy.md`

```markdown
# [도메인] [버전] Parallel Strategy

## 실행 단계

### Phase 0: 선행 필수 (순차)
- [ ] T1: DB 스키마 확정 + 마이그레이션 파일 생성
- 완료 조건: schema.py 커밋 + 마이그레이션 파일 존재

### Phase 1: 병렬 실행 (Phase 0 완료 후)
| 에이전트 | 태스크 | worktree 브랜치 |
|---|---|---|
| Agent-B | T2 API 구현 | feat/api-v7 |
| Agent-C | T4 Frontend 구현 | feat/frontend-v7 |

병렬 실행 명령:
\`\`\`bash
# worktree 분리 후 에이전트 실행
git worktree add ../[도메인]-api feat/api-v7
git worktree add ../[도메인]-frontend feat/frontend-v7
\`\`\`

### Phase 2: 통합 (Phase 1 완료 후)
- [ ] T6: 통합 테스트
- merge 순서: API → Frontend → main

## context_filter (에이전트별 컨텍스트 주입)
| 에이전트 | 주입 파일 | 제외 파일 |
|---|---|---|
| Agent-B | db-schema.md, api-spec | frontend/, public/ |
| Agent-C | api-spec(읽기), design-tokens | db/, migrations/ |

## 비용 예측
| Phase | 에이전트 수 | 예상 토큰 | 예상 시간 |
|---|---|---|---|
| Phase 0 | 1 | ~50K | 10분 |
| Phase 1 | 2 (병렬) | ~150K | 20분 |
| Phase 2 | 1 | ~30K | 10분 |
```

---

## Step 6. consistency check

spec-hardening 5개 산출물 간 일관성 최종 검증:

| 체크 항목 | 기준 | 확인 방법 |
|---|---|---|
| PRD 필드명 ↔ db-schema 컬럼명 | db-schema 기준 | 불일치 목록 출력 |
| plan Phase ↔ dependency-graph 그룹 | 1:1 대응 | Phase 누락 확인 |
| ownership-map 에이전트 ↔ parallel-strategy 에이전트 | 동일 목록 | 불일치 시 ownership-map 수정 |
| context_filter ↔ ownership-map 담당 파일 | 담당 파일만 주입 | 초과 주입 파일 제거 |

불일치 발견 시 즉시 수정 후 재확인.

---

## 완료 후 출력

```
## /spec-hardening [도메인] [버전] 완료

### 생성된 산출물
✅ db-schema.md — [테이블 N개]
✅ architecture.md — [레이어 N개]
✅ dependency-graph.md — [태스크 N개 / 병렬 그룹 N개]
✅ ownership-map.md — [에이전트 N명 / 공유 파일 N개]
✅ parallel-strategy.md — [Phase N단계 / 예상 비용 ~NK토큰]

### Consistency Check
- PRD ↔ db-schema: ✅ 일치 / ⚠️ N건 수정됨
- plan ↔ dependency-graph: ✅ 일치
- ownership ↔ parallel-strategy: ✅ 일치

### ownership-map 요약
| 에이전트 | 태스크 | 독점 경로 |
|---|---|---|
...

---
ownership-map ✅ 확인 후 → /spec-build [도메인]
```

---

## 도메인별 산출물 경로

| 도메인 | 저장 경로 |
|---|---|
| hire | $NEXUS_VAULT/03_Projects/hire/[버전]-*.md |
| nexus | $NEXUS_VAULT/03_Projects/work/nexus-v[N]-*.md |
| work | $NEXUS_VAULT/03_Projects/work/[워크]-[버전]-*.md |

## 파이프라인 연결
연결 위치: spec-build 후
방식: 조건부
조건: L급
