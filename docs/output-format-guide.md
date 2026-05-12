---
title: open-nexus8 산출물 표준 가이드
version: v1.0
updated: 2026-05-10
---

# 산출물 표준 가이드

open-nexus8의 모든 산출물은 **보고형 문서**로 작성되어 PDF/CSV/HTML로 변환 가능해야 한다.

## 1. 기본 원칙

- **모든 산출물은 `.md` 기반** — 일관된 형식, 버전 관리, 변환 용이
- **frontmatter 필수** — 메타데이터로 추적 가능
- **표준 섹션 구조** — 산출물 종류별 정해진 구조 준수
- **검수 단계 거침** — reviewer 페르소나가 표준 준수 확인

## 2. 산출물 분류

| 카테고리 | 기본 포맷 | 변환 | 예시 스킬 |
|---|---|---|---|
| **문서** | `.md` | → `.pdf` (md-to-pdf) | spec-define · po-gtm · stakeholder-report · retro · service-intro · legal-review |
| **데이터** | `.md` (표) | → `.csv` | metric-dashboard · data-insight · po-roi · pricing-strategy |
| **시각** | `.md` (Mermaid) | → `.html` (pandoc) | roadmap · user-journey · prototype-flow · growth-loop · diagram-gen |

## 3. 표준 frontmatter

모든 산출물 첫 줄에 아래 형식 포함:

```yaml
---
title: <명확한 제목>
type: PRD | report | data | visual | spec | retro
version: v1.0
created: 2026-05-10
updated: 2026-05-10
author: <NEXUS_USER_NAME>
status: draft | review | approved
related: <BL-ID 또는 SP-ID, 없으면 비움>
formats: [md, pdf]
---
```

## 4. 보고형 문서 표준 구조

문서 산출물은 아래 6개 섹션을 순서대로 포함한다:

```markdown
# 1. 요약 (Executive Summary)
3줄 이내. 무엇을, 왜, 어떤 결과로.

# 2. 배경
현재 상황 / 문제 / 기회

# 3. 본문
산출물 종류별 표준 섹션 (PRD라면 솔루션·범위·KPI 등)

# 4. 결론
핵심 결론 1~3줄

# 5. 다음 액션
- [ ] 액션 1 (담당: , 기한: )
- [ ] 액션 2

# 6. 부록 (선택)
참고 자료 / 데이터 / 다이어그램
```

## 5. 산출물 종류별 본문 가이드

### PRD (spec-define)
- 배경 / 문제정의 / 솔루션 / 범위 (포함·제외) / KPI / 일정 / 리스크

### 보고서 (stakeholder-report)
- 기간 / 완료 항목 / 지표 변화 / 인사이트 / 다음 계획

### 회고 (retro)
- 스프린트 ID·기간 / 완료율 / Keep / Problem / Try / 다음 액션

### GTM (po-gtm)
- 타겟 세그먼트 / 채널 / 메시지 / 일정 / KPI

### ROI (po-roi)
- 투자 비용 / 예상 수익 / 회수 기간 / 가정 / 민감도

### 데이터 분석 (data-insight)
- 데이터 출처 / 기간 / 트렌드 / 이상치 / 인사이트 / 백로그 제안

### 지표 대시보드 (metric-dashboard)
- KPI 목록 / 현재값 / 목표값 / 갭 / Mermaid 시각화 / 우선순위

### 사용자 여정 (user-journey)
- 페르소나 / 단계별 행동·감정·접점·개선기회 / Mermaid 다이어그램

### 화면 흐름 (prototype-flow)
- 화면 목록 / 전환 조건 / 주요 경로 / Mermaid flowchart

## 6. 변환 가이드

```bash
# PDF 변환 (문서)
md-to-pdf [파일.md]

# CSV 추출 (데이터 — md 표 → csv)
pandoc [파일.md] -t csv -o [파일.csv]

# HTML 변환 (시각)
pandoc [파일.md] -s -o [파일.html]
```

## 7. 저장 경로

```
$NEXUS_VAULT/03_Projects/[도메인]/[산출물].md
예: ~/obsidian-vault/03_Projects/work/PRD-신규결제.md
```

`config.sh`의 `NEXUS_VAULT` 변수가 기본 저장 위치.

## 8. 버전 관리

- **신규 작성**: `v1.0`, `created` = `updated` = 오늘
- **수정**: minor 변경 → `v1.x`, 구조 변경 → `v2.0`
- **수정 시 항상**: `updated` 날짜 갱신

## 9. 검수 (reviewer 페르소나)

모든 산출물은 작성 후 reviewer 페르소나가 자동 검수한다:

| 판정 | 의미 | 다음 단계 |
|---|---|---|
| ✅ PASS | 표준 준수, 내용 충분 | 저장 확정 |
| ⚠️ WARN | 일부 보완 권장 | 사용자 확인 후 진행 |
| ❌ FAIL | 표준 위반 또는 내용 부족 | 자동 수정 후 재검수 (최대 2회) |

3회 FAIL 시 사용자 호출.
