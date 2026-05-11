#!/usr/bin/env bash
# 03_edge_cases.sh — 엣지 케이스 및 통합 흐름 (16케이스)
# source harness.sh 후 실행

# ── 스위트 H: 연속 저장 흐름 ─────────────────────────────────────
suite "H. detect → gate 연속 흐름"

H=$(setup_fake_home)
MD="$H/obsidian-vault/03_Projects/work/prd.md"
make_project_md "$MD"

# 1) Write → 마커 생성
input=$(build_post_tooluse_input "Write" "$MD")
run_hook "post-output-detect.sh" "$input" "$H" > /dev/null 2>&1
assert_file_exists "H-1 Write 후 마커 생성" "$(marker_path "$H")"

# 2) Stop → 차단
input=$(build_stop_input "false")
out=$(run_hook "stop-review-gate.sh" "$input" "$H" 2>/dev/null)
assert_contains "H-2 Stop 시 차단" '"decision":"block"' "$out"

# 3) 마커 제거 (리뷰 완료 시뮬레이션)
rm -f "$(marker_path "$H")"

# 4) Stop → 통과
out=$(run_hook "stop-review-gate.sh" "$input" "$H" 2>/dev/null); ec=$?
assert_exit "H-3 리뷰 완료 후 Stop 통과" "0" "$ec"
assert_eq   "H-4 통과 시 출력 없음" "" "$out"

teardown_fake_home "$H"

# ── 스위트 I: 파일 부재 시 동작 ──────────────────────────────────
suite "I. 파일 부재 (파일 미작성 상태)"

H=$(setup_fake_home)
NOT_EXIST="$H/obsidian-vault/03_Projects/work/ghost.md"

# 파일이 없으면 frontmatter 체크 불가 → 스킵 (안전하게 처리)
input=$(build_post_tooluse_input "Write" "$NOT_EXIST")
run_hook "post-output-detect.sh" "$input" "$H" > /dev/null 2>&1
assert_file_not_exists "I-1 존재하지 않는 파일 → 마커 없음" "$(marker_path "$H")"

teardown_fake_home "$H"

# ── 스위트 J: NEXUS_VAULT 커스텀 경로 ───────────────────────────
suite "J. NEXUS_VAULT 커스텀 경로"

H=$(setup_fake_home)
CUSTOM_VAULT="$H/my-vault"
mkdir -p "$CUSTOM_VAULT/03_Projects/work"
export NEXUS_VAULT="$CUSTOM_VAULT"

MD="$CUSTOM_VAULT/03_Projects/work/custom.md"
make_project_md "$MD"

input=$(build_post_tooluse_input "Write" "$MD")
run_hook "post-output-detect.sh" "$input" "$H" "$CUSTOM_VAULT" > /dev/null 2>&1
assert_file_exists "J-1 커스텀 NEXUS_VAULT 경로 인식" "$(marker_path "$H")"
assert_json_field  "J-2 마커 file 경로 정확" '.file' "$MD" "$(marker_path "$H")"

teardown_fake_home "$H"

# ── 스위트 K: 여러 프로젝트 간 파일 전환 ─────────────────────────
suite "K. 여러 파일 전환 시 마커 교체"

H=$(setup_fake_home)
MD_WORK="$H/obsidian-vault/03_Projects/work/prd.md"
MD_HIRE="$H/obsidian-vault/03_Projects/hire/cv.md"
make_project_md "$MD_WORK"
make_project_md "$MD_HIRE" "cv"

# work 파일 저장
input=$(build_post_tooluse_input "Write" "$MD_WORK")
run_hook "post-output-detect.sh" "$input" "$H" > /dev/null 2>&1
assert_json_field "K-1 첫 마커 = work/prd.md" '.file' "$MD_WORK" "$(marker_path "$H")"

# hire 파일 저장 → 교체
input=$(build_post_tooluse_input "Edit" "$MD_HIRE")
run_hook "post-output-detect.sh" "$input" "$H" > /dev/null 2>&1
assert_json_field "K-2 마커 파일 hire로 교체" '.file' "$MD_HIRE" "$(marker_path "$H")"
assert_json_field "K-3 retry 0 리셋" '.retry' "0" "$(marker_path "$H")"

# work 파일 다시 저장 → 재교체
input=$(build_post_tooluse_input "Write" "$MD_WORK")
run_hook "post-output-detect.sh" "$input" "$H" > /dev/null 2>&1
assert_json_field "K-4 마커 work로 재교체" '.file' "$MD_WORK" "$(marker_path "$H")"
assert_json_field "K-5 retry 0 리셋" '.retry' "0" "$(marker_path "$H")"

teardown_fake_home "$H"

# ── 스위트 L: 동시 Stop 호출 멱등성 ──────────────────────────────
suite "L. Stop 반복 호출 동일 결과"

H=$(setup_fake_home)
MD="$H/obsidian-vault/03_Projects/work/prd.md"
make_project_md "$MD"
inject_marker "$H" "$MD" 0

input=$(build_stop_input "false")
out1=$(run_hook "stop-review-gate.sh" "$input" "$H" 2>/dev/null)
out2=$(run_hook "stop-review-gate.sh" "$input" "$H" 2>/dev/null)
assert_eq "L-1 Stop 2회 연속 동일 출력" "$out1" "$out2"
assert_contains "L-2 여전히 차단" '"decision":"block"' "$out2"

teardown_fake_home "$H"
