#!/usr/bin/env bash
# harness.sh — opennexus 테스트 하네스
# 가짜 HOME(mktemp -d) 격리: 실제 ~/.claude 절대 건드리지 않음
# 사용법: source tests/lib/harness.sh

# ── 전역 카운터 ────────────────────────────────────────────────────
PASS=0
FAIL=0
_CURRENT_SUITE=""
HOOKS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/hooks"
TEST_SESSION_ID="test-session-001"

# ── fake HOME 생성/해제 ────────────────────────────────────────────
setup_fake_home() {
    local fake_home
    fake_home=$(mktemp -d /tmp/nexus-test-XXXXXX)

    # Claude Code가 기대하는 최소 디렉토리 구조
    mkdir -p \
        "$fake_home/.claude/hooks" \
        "$fake_home/context" \
        "$fake_home/obsidian-vault/03_Projects/work" \
        "$fake_home/obsidian-vault/03_Projects/hire"

    export FAKE_HOME="$fake_home"
    export NEXUS_VAULT="$fake_home/obsidian-vault"
    echo "$fake_home"
}

teardown_fake_home() {
    local target="${1:-${FAKE_HOME:-}}"
    [[ -n "$target" && -d "$target" ]] && rm -rf "$target"
    unset FAKE_HOME NEXUS_VAULT
}

# ── 픽스처 헬퍼 ───────────────────────────────────────────────────
# 03_Projects 하위에 type: frontmatter MD 파일 생성
make_project_md() {
    local path="$1"         # 절대 경로
    local type="${2:-prd}"  # frontmatter type 값
    mkdir -p "$(dirname "$path")"
    cat > "$path" <<EOF
---
type: $type
title: 테스트 문서
---

테스트 내용입니다.
EOF
}

# 03_Projects 하위에 type: 없는 MD 파일 생성
make_plain_md() {
    local path="$1"
    mkdir -p "$(dirname "$path")"
    cat > "$path" <<EOF
# 일반 마크다운
type 없음 (frontmatter 아님)
EOF
}

# .pending-review-{session_id} 마커 직접 주입
inject_marker() {
    local fake_home="$1"
    local file_path="$2"
    local retry="${3:-0}"
    local session_id="${4:-$TEST_SESSION_ID}"
    local marker="$fake_home/context/.pending-review-${session_id}"
    mkdir -p "$fake_home/context"
    echo "{\"file\":\"$file_path\",\"retry\":$retry,\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" > "$marker"
}

# 현재 세션 마커 경로 반환 (테스트 케이스에서 경로 참조용)
marker_path() {
    local fake_home="$1"
    local session_id="${2:-$TEST_SESSION_ID}"
    echo "$fake_home/context/.pending-review-${session_id}"
}

# ── 훅 실행 헬퍼 ──────────────────────────────────────────────────
# PostToolUse JSON 빌드
build_post_tooluse_input() {
    local tool_name="$1"
    local file_path="$2"
    local session_id="${3:-$TEST_SESSION_ID}"
    jq -n \
        --arg tn "$tool_name" \
        --arg fp "$file_path" \
        --arg sid "$session_id" \
        '{"tool_name":$tn,"tool_input":{"file_path":$fp},"session_id":$sid}'
}

# Stop hook JSON 빌드
build_stop_input() {
    local stop_hook_active="${1:-false}"
    local session_id="${2:-$TEST_SESSION_ID}"
    jq -n \
        --argjson sha "$stop_hook_active" \
        --arg sid "$session_id" \
        '{"stop_hook_active":$sha,"session_id":$sid}'
}

# 훅을 fake HOME 환경에서 실행, stdout/exit_code 반환
# run_hook <hook_name> <stdin> [fake_home] [custom_nexus_vault]
run_hook() {
    local hook_name="$1"
    local stdin_data="$2"
    local fake_home="${3:-${FAKE_HOME:-}}"
    local vault="${4:-$fake_home/obsidian-vault}"  # 항상 fake_home 기준 파생

    local hook_path="$HOOKS_DIR/$hook_name"
    if [[ ! -f "$hook_path" ]]; then
        echo "[ERROR] 훅 없음: $hook_path" >&2
        return 99
    fi

    HOME="$fake_home" NEXUS_VAULT="$vault" \
        bash "$hook_path" <<< "$stdin_data"
    return $?
}

# ── assertion ─────────────────────────────────────────────────────
_pass() { PASS=$((PASS + 1)); echo "  PASS $1"; }
_fail() { FAIL=$((FAIL + 1)); echo "  FAIL $1"; [[ -n "${2:-}" ]] && echo "       $2"; }

assert_exit() {
    local desc="$1" expected="$2" actual="$3"
    if [[ "$expected" == "$actual" ]]; then _pass "$desc"
    else _fail "$desc" "exit 기대=$expected 실제=$actual"
    fi
}

assert_eq() {
    local desc="$1" expected="$2" actual="$3"
    if [[ "$expected" == "$actual" ]]; then _pass "$desc"
    else _fail "$desc" "기대='$expected' 실제='$actual'"
    fi
}

assert_file_exists() {
    local desc="$1" path="$2"
    if [[ -f "$path" ]]; then _pass "$desc"
    else _fail "$desc" "파일 없음: $path"
    fi
}

assert_file_not_exists() {
    local desc="$1" path="$2"
    if [[ ! -f "$path" ]]; then _pass "$desc"
    else _fail "$desc" "파일이 존재하면 안 됨: $path"
    fi
}

assert_contains() {
    local desc="$1" needle="$2" haystack="$3"
    if echo "$haystack" | grep -qF "$needle"; then _pass "$desc"
    else _fail "$desc" "찾는 문자열='$needle' 실제='$haystack'"
    fi
}

assert_json_field() {
    local desc="$1" field="$2" expected="$3" file="$4"
    local actual
    actual=$(jq -r "$field" "$file" 2>/dev/null || echo "__PARSE_ERROR__")
    if [[ "$actual" == "$expected" ]]; then _pass "$desc"
    else _fail "$desc" "jq $field → 기대='$expected' 실제='$actual'"
    fi
}

# ── 스위트 경계 ───────────────────────────────────────────────────
suite() {
    _CURRENT_SUITE="$1"
    echo ""
    echo "── $1"
}

# ── 최종 리포트 (test.sh에서 호출) ───────────────────────────────
report() {
    local total=$((PASS + FAIL))
    echo ""
    echo "══════════════════════════════"
    if [[ $FAIL -eq 0 ]]; then
        echo "  PASS $PASS/$total"
    else
        echo "  FAIL $FAIL/$total 실패"
    fi
    echo "══════════════════════════════"
    [[ $FAIL -eq 0 ]]   # exit 0 if all pass, exit 1 if any fail
}
