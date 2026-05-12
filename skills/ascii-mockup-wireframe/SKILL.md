---
name: ascii-mockup-wireframe
description: ASCII 목업, 텍스트 와이어프레임, A/B 박스 레이아웃 제안. "ASCII 목업", "텍스트 와이어프레임", "화면 그려줘", "레이아웃 잡아줘", "페이지 구성 보여줘", "어떻게 생겼는지 보여줘", "박스로 그려줘", "PPT 구성해줘", "슬라이드 짜줘", "덱 스토리보드", "보고서 레이아웃", "문서 구조 잡아줘" 요청 시 실행. HTML/CSS 없이 구조만 먼저 보고 싶을 때. PRD나 기능명세 파일이 주어지면 화면 목록을 자동 추출해 목업 생성.
---

# ASCII Mockup Wireframe

## 인덱스

| # | 카테고리 | 패턴 파일 | 트리거 |
|---|----------|-----------|--------|
| 1 | Product / Dashboard | `patterns/web.txt`, `patterns/mobile.txt` | 화면, 대시보드, 앱, 레이아웃 |
| 2 | Overlay | `patterns/overlay.txt` | 모달, 팝업, 드로어, 토스트 |
| 3 | Content / Docs | `patterns/docs.txt` | 문서, 보고서, Notion |
| 4 | Presentation | `patterns/ppt.txt` | 슬라이드, PPT, 스토리보드 |
| 5 | States | `patterns/states.txt` | 상태별로, empty/error, 인터랙션 |
| 6 | Promptframe | `patterns/promptframe.txt` | 콘텐츠 의도, 데이터 출처, promptframe |
| 7 | Handoff | `patterns/handoff.txt` | 코드로 변환, 개발자한테 넘길게, v0에 넣을게 |

패턴 파일 경로: `~/.claude/skills/ascii-mockup-wireframe/patterns/`
필요한 카테고리 파일만 Read로 참조해서 사용할 것.

---

<rules>
## 실행 흐름

1. **카테고리 판단** → 해당 `patterns/*.txt` Read
2. **입력 파악** — PRD 파일 있으면 읽고 화면 목록 추출 / 없으면 바로 초안
3. **화면 3개 이상** → 목록 먼저 제시 후 확인
4. **목업 생성** — 기본 A안+B안, 방향 잡혔으면 단일 상세
5. **추천안 한 줄** 제시
6. **저장 요청 시** → `$NEXUS_VAULT/03_Projects/[도메인]/[워크]/mockup.md`

---

## 뷰포트

| 유형 | 너비 | 조건 |
|------|------|------|
| 웹/대시보드 | 80자 | 기본값 |
| 태블릿 | 60자 | "태블릿" 언급 |
| 모바일 | 40자 | "모바일", "앱 화면" 언급 |

"더 크게" → 너비 먼저 늘림 (높이 아님)

---

## 범례

```
[버튼]    기본      [*버튼*]  주요액션   [!버튼!]  위험/삭제   [버튼▼]  드롭다운
[좋음]    긍정      [주의]    확인필요   [하락]    악화        [잠정]   미확정
▲+N%      개선      ▼-N%      감소       ─N%       변화없음    ░░░      로딩
```

---

## 출력 규칙

- 모든 목업은 반드시 ` ```text ` 코드블록 안에 출력 (정렬 유지)
- 페이지 제목: `=== [페이지명] ===`
- 비교 행 박스는 동일 너비
- 한글 뒤 공백 1~2개 패딩으로 정렬 보정
- HTML/CSS/React 생성 금지 (요청 시 제외)
- "상태별로" → `patterns/states.txt` 참조해 5-state 자동 적용
- "개발자한테" / "인터랙션 포함" → `patterns/states.txt` 인터랙션 어노테이션 적용
- "excalidraw로" → `.excalidraw` JSON 파일 생성

---

## 판단 기준

| 상황 | 행동 |
|------|------|
| 탐색 중 | A/B/C 다중 안 |
| 방향 확정 | 단일 화면 크게 |
| 기존 페이지 참조 | 정보 구조 미러링 |
| 정렬 오류 지적 | 즉시 교정 우선 |

## 파이프라인 연결
연결 위치: scope-scan 후
방식: 조건부
조건: UI 관련 시
