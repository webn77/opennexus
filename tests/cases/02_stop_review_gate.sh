#!/usr/bin/env bash
# 02_stop_review_gate.sh — stop-review-gate.sh 단위 테스트 (12케이스)
# source harness.sh 후 실행

# ── 스위트 E: 통과 조건 ──────────────────────────────────────────
suite "E. 통과 조건"

H=$(setup_fake_home)

# 마커 없음 → 통과
input=$(build_stop_input "false")
out=$(run_hook "stop-review-gate.sh" "$input" "$H" 2>/dev/null); ec=$?
assert_exit "E-1 마커 없음 → exit 0" "0" "$ec"
assert_eq   "E-2 마커 없음 → 출력 없음" "" "$out"

# stop_hook_active=true → 통과 (루프 방지)
inject_marker "$H" "$H/obsidian-vault/03_Projects/work/prd.md" 0
input=$(build_stop_input "true")
out=$(run_hook "stop-review-gate.sh" "$input" "$H" 2>/dev/null); ec=$?
assert_exit "E-3 stop_hook_active=true → exit 0" "0" "$ec"
assert_eq   "E-4 stop_hook_active=true → 출력 없음" "" "$out"

# retry >= 2 → 통과
inject_marker "$H" "$H/obsidian-vault/03_Projects/work/prd.md" 2
input=$(build_stop_input "false")
out=$(run_hook "stop-review-gate.sh" "$input" "$H" 2>/dev/null); ec=$?
assert_exit "E-5 retry=2 → exit 0" "0" "$ec"
assert_eq   "E-6 retry=2 → 출력 없음" "" "$out"

inject_marker "$H" "$H/obsidian-vault/03_Projects/work/prd.md" 5
out=$(run_hook "stop-review-gate.sh" "$input" "$H" 2>/dev/null); ec=$?
assert_exit "E-7 retry=5 → exit 0" "0" "$ec"

teardown_fake_home "$H"

# ── 스위트 F: 차단 조건 ──────────────────────────────────────────
suite "F. 차단 조건"

H=$(setup_fake_home)
MD="$H/obsidian-vault/03_Projects/work/prd.md"
make_project_md "$MD"

inject_marker "$H" "$MD" 0
input=$(build_stop_input "false")
out=$(run_hook "stop-review-gate.sh" "$input" "$H" 2>/dev/null); ec=$?
assert_exit     "F-1 마커 있음(retry=0) → exit 0" "0" "$ec"
assert_contains "F-2 decision=block 출력" '"decision":"block"' "$out"
assert_contains "F-3 reason에 파일 경로 포함" "$MD" "$out"

inject_marker "$H" "$MD" 1
out=$(run_hook "stop-review-gate.sh" "$input" "$H" 2>/dev/null)
assert_contains "F-4 retry=1도 차단" '"decision":"block"' "$out"

# Producer-Reviewer 패턴: block reason에 Agent 호출 지시 포함
inject_marker "$H" "$MD" 0
out=$(run_hook "stop-review-gate.sh" "$input" "$H" 2>/dev/null)
assert_contains "F-5 reason에 Agent 지시 포함" "Agent" "$out"
assert_contains "F-6 reason에 마커 경로 포함" "$(marker_path "$H")" "$out"

teardown_fake_home "$H"

# ── 스위트 G: 깨진 마커 자동 정리 ───────────────────────────────
suite "G. 깨진 마커 자동 정리"

H=$(setup_fake_home)
MARKER="$(marker_path "$H")"
mkdir -p "$H/context"

# 빈 JSON
echo '{}' > "$MARKER"
input=$(build_stop_input "false")
out=$(run_hook "stop-review-gate.sh" "$input" "$H" 2>/dev/null); ec=$?
assert_exit          "G-1 빈 마커 → exit 0" "0" "$ec"
assert_file_not_exists "G-2 빈 마커 자동 삭제" "$MARKER"

# 손상된 JSON
echo 'NOT_JSON' > "$MARKER"
out=$(run_hook "stop-review-gate.sh" "$input" "$H" 2>/dev/null); ec=$?
assert_exit          "G-3 손상 마커 → exit 0" "0" "$ec"
assert_file_not_exists "G-4 손상 마커 자동 삭제" "$MARKER"

teardown_fake_home "$H"
