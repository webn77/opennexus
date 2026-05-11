#!/usr/bin/env bash
# 04_idempotency.sh — 멱등성 테스트 (16케이스)
# 같은 입력을 N번 실행해도 결과가 동일해야 함

# ── 스위트 M: detect 멱등성 ───────────────────────────────────────
suite "M. post-output-detect 멱등성"

H=$(setup_fake_home)
MD="$H/obsidian-vault/03_Projects/work/prd.md"
make_project_md "$MD"
input=$(build_post_tooluse_input "Write" "$MD")

# 첫 실행
run_hook "post-output-detect.sh" "$input" "$H" > /dev/null 2>&1
FIRST_CONTENT=$(cat "$(marker_path "$H")" 2>/dev/null)
FIRST_FILE=$(jq -r '.file' "$(marker_path "$H")" 2>/dev/null)
FIRST_RETRY=$(jq -r '.retry' "$(marker_path "$H")" 2>/dev/null)

# 동일 입력 2회 추가 실행
run_hook "post-output-detect.sh" "$input" "$H" > /dev/null 2>&1
run_hook "post-output-detect.sh" "$input" "$H" > /dev/null 2>&1

assert_json_field "M-1 3회 실행 후 file 동일" '.file' "$FIRST_FILE" "$(marker_path "$H")"
assert_json_field "M-2 3회 실행 후 retry 동일" '.retry' "$FIRST_RETRY" "$(marker_path "$H")"
assert_file_exists "M-3 마커 1개만 존재" "$(marker_path "$H")"

teardown_fake_home "$H"

# ── 스위트 N: gate 통과 멱등성 ───────────────────────────────────
suite "N. stop-review-gate 통과 멱등성"

H=$(setup_fake_home)
input=$(build_stop_input "false")

# 마커 없는 상태로 3회
out1=$(run_hook "stop-review-gate.sh" "$input" "$H" 2>/dev/null); ec1=$?
out2=$(run_hook "stop-review-gate.sh" "$input" "$H" 2>/dev/null); ec2=$?
out3=$(run_hook "stop-review-gate.sh" "$input" "$H" 2>/dev/null); ec3=$?

assert_exit "N-1 1회 통과" "0" "$ec1"
assert_exit "N-2 2회 통과" "0" "$ec2"
assert_exit "N-3 3회 통과" "0" "$ec3"
assert_eq   "N-4 1·2회 출력 동일" "$out1" "$out2"

teardown_fake_home "$H"

# ── 스위트 O: gate 차단 멱등성 ───────────────────────────────────
suite "O. stop-review-gate 차단 멱등성"

H=$(setup_fake_home)
MD="$H/obsidian-vault/03_Projects/work/prd.md"
make_project_md "$MD"
inject_marker "$H" "$MD" 0
input=$(build_stop_input "false")

out1=$(run_hook "stop-review-gate.sh" "$input" "$H" 2>/dev/null)
out2=$(run_hook "stop-review-gate.sh" "$input" "$H" 2>/dev/null)
out3=$(run_hook "stop-review-gate.sh" "$input" "$H" 2>/dev/null)

assert_contains "O-1 1회 차단" '"decision":"block"' "$out1"
assert_contains "O-2 2회 차단" '"decision":"block"' "$out2"
assert_contains "O-3 3회 차단" '"decision":"block"' "$out3"
assert_eq       "O-4 출력 동일" "$out1" "$out2"

teardown_fake_home "$H"

# ── 스위트 P: 마커 삭제 후 detect 재실행 ─────────────────────────
suite "P. 마커 삭제 후 detect 재실행"

H=$(setup_fake_home)
MD="$H/obsidian-vault/03_Projects/work/prd.md"
make_project_md "$MD"
input=$(build_post_tooluse_input "Write" "$MD")

# 1차 detect
run_hook "post-output-detect.sh" "$input" "$H" > /dev/null 2>&1
assert_file_exists "P-1 1차 마커 생성" "$(marker_path "$H")"

# 리뷰 완료 시뮬레이션: 마커 삭제
rm -f "$(marker_path "$H")"

# 2차 detect (같은 파일 재저장)
run_hook "post-output-detect.sh" "$input" "$H" > /dev/null 2>&1
assert_file_exists     "P-2 마커 재생성됨" "$(marker_path "$H")"
assert_json_field      "P-3 retry 0으로 초기화" '.retry' "0" "$(marker_path "$H")"
assert_json_field      "P-4 file 경로 동일" '.file' "$MD" "$(marker_path "$H")"

teardown_fake_home "$H"
