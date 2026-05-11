#!/usr/bin/env bash
# tests/test.sh — opennexus 메인 테스트 러너
#
# 실행: bash tests/test.sh
# 특정 케이스만: bash tests/test.sh 01  (파일명 prefix)
#
# 격리 방식: 각 케이스가 setup_fake_home() 으로 mktemp -d 생성
#           → HOME=$FAKE_HOME 환경에서 훅 실행
#           → 실제 ~/.claude, ~/context 절대 건드리지 않음
#           → SIGKILL 당해도 /tmp/ 임시 파일만 남음

set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CASES_DIR="$TESTS_DIR/cases"

# 필터: bash tests/test.sh 01 → 01로 시작하는 케이스만
FILTER="${1:-}"

# harness 로드 (전역 카운터 초기화)
source "$TESTS_DIR/lib/harness.sh"

# 실패 시 fake HOME 정리
_cleanup_on_exit() {
    if [[ -n "${FAKE_HOME:-}" && -d "${FAKE_HOME:-}" ]]; then
        rm -rf "$FAKE_HOME"
    fi
}
trap _cleanup_on_exit EXIT

# ── 의존성 확인 ───────────────────────────────────────────────────
if ! command -v jq &> /dev/null; then
    echo "ERROR: jq 필요 (brew install jq)"
    exit 1
fi

# ── 케이스 파일 수집 ──────────────────────────────────────────────
CASE_FILES=()
for f in "$CASES_DIR"/[0-9][0-9]_*.sh; do
    [[ -f "$f" ]] || continue
    if [[ -z "$FILTER" ]] || [[ "$(basename "$f")" == "${FILTER}"* ]]; then
        CASE_FILES+=("$f")
    fi
done

if [[ ${#CASE_FILES[@]} -eq 0 ]]; then
    echo "케이스 파일 없음 (filter: '${FILTER:-전체}')"
    exit 1
fi

# ── 헤더 ──────────────────────────────────────────────────────────
echo "openNexus Hook Tests"
echo "실행 경로: $TESTS_DIR"
echo "훅 경로:   $HOOKS_DIR"
echo "케이스:    ${#CASE_FILES[@]}개"
[[ -n "$FILTER" ]] && echo "필터:      $FILTER"

# ── 케이스 실행 ───────────────────────────────────────────────────
for case_file in "${CASE_FILES[@]}"; do
    echo ""
    echo "▶ $(basename "$case_file")"
    source "$case_file"
done

# ── 최종 리포트 ───────────────────────────────────────────────────
report
