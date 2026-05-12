# openNexus v8 — 사용 가이드

> 설치부터 일상 사용까지 단계별 안내

---

## 목차

1. [설치](#1-설치)
2. [첫 실행 체크리스트](#2-첫-실행-체크리스트)
3. [스킬 사용법](#3-스킬-사용법)
4. [세션 기억 동기화 (context-sync)](#4-세션-기억-동기화-context-sync)
5. [훅 시스템](#5-훅-시스템)
6. [CLAUDE.md 커스터마이징](#6-claudemd-커스터마이징)
7. [자주 묻는 질문](#7-자주-묻는-질문)

---

## 1. 설치

### 사전 요구사항

| 도구 | 버전 | 설치 |
|------|------|------|
| [Claude Code CLI](https://claude.ai/code) | 최신 | 링크 참고 |
| Python | 3.10+ | `brew install python` |
| jq | - | `brew install jq` |
| git | - | 기본 설치 |

### 설치 실행

```bash
git clone https://github.com/webn77/opennexus
cd opennexus
bash install.sh
```

설치 중 단계별 안내:

```
[1/9] 의존성 확인    — claude / git / python3 / jq
[2/9] .env 설정      — .env.example → .env 복사
[3/9] 디렉토리 생성  — ~/.claude/, ~/context/
[4/9] 인증 연결      — 격리 환경 전용 (일반 설치 시 스킵)
[5/9] 훅 배포        — ~/.claude/hooks/
[6/9] 스킬 배포      — ~/.claude/skills/
[7/9] settings.json  — SessionStart / PostToolUse / Stop 훅 등록
[8/9] context-sync   — 선택 입력 (Enter 건너뜀 가능)
[9/9] 설치 완료
```

### 환경변수 설정

설치 후 `.env` 파일을 열어 API 키를 설정합니다:

```bash
open opennexus/.env
```

```env
ANTHROPIC_API_KEY=sk-ant-...
LINEAR_API_KEY=lin_api_...   # 백로그 Linear 연동 시 (선택)
```

---

## 2. 첫 실행 체크리스트

설치 후 Claude Code를 실행하면 세션 시작 메시지가 표시됩니다:

```
=== openNexus v8 ===
▶ 다음 액션: 첫 백로그를 추가해보세요
📋 백로그: 0개

💡 추천 명령어:
   백로그 추가해줘 [도메인] [제목]
   /news
   /brainstorm
==================
```

**첫 실행 순서:**

- [ ] `claude` 실행 → 세션 시작 메시지 확인
- [ ] 백로그 추가: `백로그 추가해줘 work 첫 번째 태스크`
- [ ] 스프린트 시작: `/backlog-sprint activate`
- [ ] 세션 저장: `/save`

---

## 3. 스킬 사용법

스킬은 Claude Code 대화창에서 `/스킬명` 형태로 실행합니다.

### PO / 기획

| 스킬 | 설명 | 예시 |
|------|------|------|
| `/prd` | 백로그 항목 → PRD 자동 생성 | `/prd BL-001` |
| `/spec-define` | 버전업 설계 (PRD + plan.md) | `/spec-define work v2.0` |
| `/spec-build` | TDD + 구현 실행 | `/spec-build work` |
| `/spec-up` | 구현 완료 게이트 + 문서 동기화 | `/spec-up work` |
| `/brainstorm` | 아이디어 탐색 및 요구사항 정리 | `/brainstorm 알림 시스템 설계` |

### 분석

| 스킬 | 설명 | 예시 |
|------|------|------|
| `/service-analysis` | 서비스 심층 분석 (7단계) | `/service-analysis https://...` |
| `/data-insight` | SQL 결과 → 트렌드/이상치 분석 | SQL 텍스트 붙여넣기 후 실행 |
| `/diagram-gen` | Mermaid 다이어그램 생성 | `/diagram-gen flowchart 주문 흐름` |
| `/growth-loop` | 성장 루프 분석 | `/growth-loop` |

### 스프린트 / 백로그

| 스킬 | 설명 | 예시 |
|------|------|------|
| `/backlog-view` | RICE 점수 순 백로그 표시 | `/backlog-view` |
| `/backlog-add` | 새 백로그 항목 추가 | `/backlog-add work 다크모드 지원` |
| `/backlog-sprint` | 스프린트 확인·활성화 | `/backlog-sprint activate` |
| `/sprint-exec` | 스프린트 배치 자동 실행 | `/sprint-exec` |

### 문서

| 스킬 | 설명 | 예시 |
|------|------|------|
| `/flow-design` | 서비스 플로우 설계 문서 | `/flow-design 결제 플로우` |
| `/prototype-flow` | 화면 흐름도 생성 | `/prototype-flow` |
| `/user-journey` | 사용자 여정 지도 | `/user-journey 신규 가입` |
| `/roadmap` | 분기별 로드맵 생성 | `/roadmap 2026 H2` |

### 세션 관리

| 스킬 | 설명 | 예시 |
|------|------|------|
| `/save` | 세션 종료 + context 저장 + git push | `/save` |
| `/current-context` | 현재 작업 상태 확인 | `/current-context` |
| `/checkpoint` | 중간 상태 저장 (세션 유지) | `/checkpoint` |

---

## 4. 세션 기억 동기화 (context-sync)

여러 컴퓨터에서 동일한 세션 기억을 유지하는 기능입니다.

### 초기 설정

**1단계: GitHub private repo 생성**

[github.com/new](https://github.com/new) 에서 private repo 생성  
예: `yourname/nexus-context`

**2단계: context-sync 실행**

```bash
bash scripts/context-sync.sh https://github.com/yourname/nexus-context.git
```

성공 시:
```
  git init: ~/context
  push: origin main...
  OK: context-sync 완료. /save 시 자동 push됩니다.
```

### 이후 동작

| 시점 | 동작 |
|------|------|
| `/save` 실행 | checkpoint.json + memory → 자동 git push |
| 세션 시작 | 자동 git pull (최신 context 반영) |
| 새 컴퓨터 설치 | `install.sh` 중 repo URL 입력 → 동일 기억 복원 |

### 동기화 파일 목록

```
~/context/
├── checkpoint.json      ← 세션 간 기억 (next 액션, todo, blocked)
├── backlog.json         ← 백로그 데이터
├── work-index.jsonl     ← 작업 인덱스
└── .gitignore           ← events.jsonl, search.db 등 제외
```

---

## 5. 훅 시스템

openNexus는 Claude Code 훅을 통해 자동화를 구현합니다.

### 기본 등록 훅

| 훅 | 이벤트 | 역할 |
|----|--------|------|
| `session-start-welcome.sh` | SessionStart | 세션 시작 메시지 + git pull |
| `post-output-detect.sh` | PostToolUse (Write/Edit) | 파일 수정 후 검증 |
| `stop-review-gate.sh` | Stop | 세션 종료 전 리뷰 게이트 |

### 훅 커스터마이징

`~/.claude/settings.json` 에서 직접 수정하거나 `/update-config` 스킬을 사용합니다:

```json
{
  "hooks": {
    "SessionStart": [{
      "hooks": [{
        "type": "command",
        "command": "bash ~/.claude/hooks/session-start-welcome.sh"
      }]
    }]
  }
}
```

---

## 6. CLAUDE.md 커스터마이징

openNexus의 동작은 `~/.claude/CLAUDE.md` 로 제어합니다.

설치 후 기본 템플릿이 없으면 `templates/CLAUDE.md.template` 를 복사해서 시작하세요:

```bash
cp templates/CLAUDE.md.template ~/.claude/CLAUDE.md
```

**필수 설정 항목:**

```markdown
# 역할
[당신의 역할을 한 줄로 정의]

# 도메인 라우팅
| 키워드 | CLAUDE.md |
|--------|-----------|
| 개발·자동화 | ~/projects/work/CLAUDE.md |

# 파일 단일 소스
- ~/context/checkpoint.json — 세션 간 기억
```

---

## 7. 자주 묻는 질문

**Q. 설치 후 스킬이 보이지 않아요**

`~/.claude/skills/` 에 스킬 폴더가 있는지 확인하세요:
```bash
ls ~/.claude/skills/ | head -10
```

**Q. context-sync push가 실패해요**

GitHub 인증을 확인하세요:
```bash
git -C ~/context push
```
HTTPS 인증 오류면 personal access token(repo 권한)이 필요합니다.

**Q. /save 후 push가 안 돼요**

`~/context`가 git repo인지 확인하세요:
```bash
git -C ~/context remote -v
```
remote가 없으면 context-sync 초기 설정을 먼저 실행하세요.

**Q. 스킬을 직접 만들 수 있나요?**

`~/.claude/skills/my-skill/SKILL.md` 파일을 만들면 됩니다.  
형식은 기존 스킬 파일(`skills/brainstorm/SKILL.md` 등)을 참고하세요.

**Q. 기존 Claude Code 설정에 영향을 주나요?**

`settings.json` 에 훅 3개를 추가하고 `~/.claude/skills/` 에 스킬을 복사합니다.  
기존 설정은 덮어쓰지 않습니다.

---

## 문의 / 기여

- Issues: [github.com/webn77/opennexus/issues](https://github.com/webn77/opennexus/issues)
- 스킬 추가 PR 환영합니다
