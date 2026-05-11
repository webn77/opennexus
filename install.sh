#!/usr/bin/env bash
set -euo pipefail

# openNexus 설치 스크립트
# 사용법:
#   bash install.sh                          # 실제 환경 ($HOME)
#   NEXUS_PREFIX=/tmp/nexus-test bash install.sh  # 격리 테스트 환경

NEXUS_VERSION="8.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── 설치 경로 결정 ────────────────────────────────────────────────
PREFIX="${NEXUS_PREFIX:-$HOME}"
CLAUDE_DIR="${PREFIX}/.claude"
SKILLS_DIR="${CLAUDE_DIR}/skills"
HOOKS_DIR="${CLAUDE_DIR}/hooks"
CONTEXT_DIR="${PREFIX}/context"
SETTINGS_FILE="${CLAUDE_DIR}/settings.json"

echo "=================================="
echo " openNexus v${NEXUS_VERSION} 설치"
echo "=================================="
if [[ "$PREFIX" != "$HOME" ]]; then
    echo " 모드: 격리 테스트 (PREFIX=${PREFIX})"
fi
echo ""

# ============================================================
# Step 1. 의존성 확인
# ============================================================
echo "[1/8] 의존성 확인..."

if ! command -v claude &> /dev/null; then
    echo "  FAIL: Claude Code CLI를 찾을 수 없습니다."
    echo "        설치: https://claude.ai/code"
    exit 1
fi
CLAUDE_VERSION=$(claude --version 2>/dev/null | head -1 || echo "unknown")
echo "  OK: claude ${CLAUDE_VERSION}"

if ! command -v git &> /dev/null; then
    echo "  FAIL: git을 찾을 수 없습니다."
    exit 1
fi
echo "  OK: git $(git --version | awk '{print $3}')"

if ! command -v python3 &> /dev/null; then
    echo "  FAIL: python3를 찾을 수 없습니다."
    exit 1
fi
PYTHON_VERSION=$(python3 --version | awk '{print $2}')
PYTHON_MINOR=$(echo "${PYTHON_VERSION}" | cut -d. -f2)
if [[ "${PYTHON_MINOR}" -lt 9 ]]; then
    echo "  WARN: python3 ${PYTHON_VERSION} — 3.9 이상 권장"
else
    echo "  OK: python3 ${PYTHON_VERSION}"
fi

if ! command -v jq &> /dev/null; then
    echo "  FAIL: jq를 찾을 수 없습니다."
    echo "        설치: brew install jq"
    exit 1
fi
echo "  OK: jq $(jq --version)"

echo ""

# ============================================================
# Step 2. .env 복사
# ============================================================
echo "[2/8] 환경변수 설정..."

if [[ -f "${SCRIPT_DIR}/.env" ]]; then
    echo "  OK: .env 이미 존재 — 건너뜀"
else
    if [[ -f "${SCRIPT_DIR}/.env.example" ]]; then
        cp "${SCRIPT_DIR}/.env.example" "${SCRIPT_DIR}/.env"
        echo "  OK: .env.example → .env 복사"
        echo "  !! ANTHROPIC_API_KEY를 .env에 설정하세요"
    else
        echo "  WARN: .env.example 없음"
    fi
fi

echo ""

# ============================================================
# Step 3. 디렉토리 구조 생성
# ============================================================
echo "[3/8] 디렉토리 구조 생성..."

for dir in "$CLAUDE_DIR" "$SKILLS_DIR" "$HOOKS_DIR" "$CONTEXT_DIR"; do
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
        echo "  OK: $dir 생성"
    else
        echo "  OK: $dir 존재"
    fi
done

# context 필수 파일 초기화
for file in "${CONTEXT_DIR}/checkpoint.json" "${CONTEXT_DIR}/backlog.json"; do
    if [[ ! -f "$file" ]]; then
        echo '{}' > "$file"
        echo "  OK: $file 초기화"
    fi
done

echo ""

# ============================================================
# Step 4. 인증 연결 (격리 환경 전용)
# ============================================================
if [[ "$PREFIX" != "$HOME" ]]; then
    echo "[4/8] 인증 연결..."
    REAL_CREDS="${HOME}/.claude/.credentials.json"
    TEST_CREDS="${CLAUDE_DIR}/.credentials.json"
    if [[ -f "$REAL_CREDS" ]]; then
        ln -sf "$REAL_CREDS" "$TEST_CREDS"
        echo "  OK: .credentials.json 심볼릭 링크 (항상 최신 토큰)"
    else
        echo "  WARN: ~/.claude/.credentials.json 없음 — 첫 실행 시 로그인 필요"
    fi
    echo ""
fi

# ============================================================
# Step 5. 훅 배포
# ============================================================
echo "[5/8] 훅 배포..."

HOOKS_SRC="${SCRIPT_DIR}/hooks"
if [[ ! -d "$HOOKS_SRC" ]]; then
    echo "  WARN: hooks/ 소스 없음 — 건너뜀"
else
    for hook_file in "${HOOKS_SRC}"/*.sh; do
        [[ -f "$hook_file" ]] || continue
        HOOK_NAME=$(basename "$hook_file")
        DEST="${HOOKS_DIR}/${HOOK_NAME}"
        cp "$hook_file" "$DEST"
        chmod +x "$DEST"
        echo "  OK: $HOOK_NAME → $HOOKS_DIR/"
    done
fi

echo ""

# ============================================================
# Step 5-b. 스킬 배포
# ============================================================
echo "[6/8] 스킬 배포..."

SKILLS_SRC="${SCRIPT_DIR}/skills"
if [[ ! -d "$SKILLS_SRC" ]]; then
    echo "  WARN: skills/ 소스 없음 — 건너뜀"
else
    for skill_dir in "${SKILLS_SRC}"/*/; do
        [[ -d "$skill_dir" ]] || continue
        SKILL_NAME=$(basename "$skill_dir")
        DEST_DIR="${SKILLS_DIR}/${SKILL_NAME}"
        mkdir -p "$DEST_DIR"
        cp "${skill_dir}"SKILL.md "$DEST_DIR/SKILL.md"
        echo "  OK: ${SKILL_NAME}/SKILL.md → $SKILLS_DIR/"
    done
fi

echo ""

# ============================================================
# Step 5-c. settings.json 훅 등록
# ============================================================
echo "[7/8] settings.json 훅 등록..."

SESSION_HOOK="${HOOKS_DIR}/session-start-welcome.sh"
POST_HOOK="${HOOKS_DIR}/post-output-detect.sh"
STOP_HOOK="${HOOKS_DIR}/stop-review-gate.sh"

# settings.json 없으면 기본 골격 생성
if [[ ! -f "$SETTINGS_FILE" ]]; then
    echo '{}' > "$SETTINGS_FILE"
fi

# 기존 settings.json에 훅 병합 (jq)
UPDATED=$(jq \
    --arg session_cmd "bash ${SESSION_HOOK}" \
    --arg post_cmd "bash ${POST_HOOK}" \
    --arg stop_cmd "bash ${STOP_HOOK}" \
    '
    .hooks.SessionStart = (
        (.hooks.SessionStart // []) |
        map(select(.hooks[0].command != $session_cmd)) +
        [{"hooks":[{"type":"command","command":$session_cmd}]}]
    ) |
    .hooks.PostToolUse = (
        (.hooks.PostToolUse // []) |
        map(select(.hooks[0].command != $post_cmd)) +
        [{"matcher":"Write|Edit","hooks":[{"type":"command","command":$post_cmd,"async":true}]}]
    ) |
    .hooks.Stop = (
        (.hooks.Stop // []) |
        map(select(.hooks[0].command != $stop_cmd)) +
        [{"hooks":[{"type":"command","command":$stop_cmd}]}]
    )
    ' "$SETTINGS_FILE")

echo "$UPDATED" > "$SETTINGS_FILE"
echo "  OK: SessionStart → session-start-welcome.sh"
echo "  OK: PostToolUse(Write|Edit) → post-output-detect.sh"
echo "  OK: Stop → stop-review-gate.sh"
echo "  위치: $SETTINGS_FILE"

echo ""

# ============================================================
# Step 6. 설치 완료
# ============================================================
echo "[8/8] 설치 완료"
echo ""
echo "=================================="
echo " openNexus v${NEXUS_VERSION} 설치 완료!"
echo "=================================="
echo ""

if [[ "$PREFIX" != "$HOME" ]]; then
    echo "격리 환경 실행 방법:"
    echo ""
    echo "  CLAUDE_CONFIG_DIR=${CLAUDE_DIR} claude"
    echo ""
    echo "정리 (테스트 후):"
    echo "  rm -rf ${PREFIX}"
else
    echo "다음 단계:"
    echo "  1. .env 열기: open ${SCRIPT_DIR}/.env"
    echo "     → ANTHROPIC_API_KEY 설정"
    echo ""
    echo "  2. Claude Code 실행:"
    echo "     claude"
fi
echo ""
echo "문서: https://github.com/webn77/nexus"
