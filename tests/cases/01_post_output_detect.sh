#!/usr/bin/env bash
# 01_post_output_detect.sh — post-output-detect.sh 단위 테스트 (18케이스)
# source harness.sh 후 실행

# ── 스위트 A: 스킵 조건 (마커 생성 안 됨) ─────────────────────────
suite "A. 스킵 조건"

H=$(setup_fake_home)

input=$(build_post_tooluse_input "Bash" "$H/obsidian-vault/03_Projects/work/doc.md")
run_hook "post-output-detect.sh" "$input" "$H" > /dev/null 2>&1
assert_file_not_exists "A-1 Bash 툴은 스킵" "$(marker_path "$H")"

input=$(build_post_tooluse_input "Read" "$H/obsidian-vault/03_Projects/work/doc.md")
run_hook "post-output-detect.sh" "$input" "$H" > /dev/null 2>&1
assert_file_not_exists "A-2 Read 툴은 스킵" "$(marker_path "$H")"

make_project_md "$H/obsidian-vault/03_Projects/work/doc.md"
input=$(build_post_tooluse_input "Write" "$H/obsidian-vault/doc.md")
run_hook "post-output-detect.sh" "$input" "$H" > /dev/null 2>&1
assert_file_not_exists "A-3 03_Projects 밖 경로는 스킵" "$(marker_path "$H")"

input=$(build_post_tooluse_input "Write" "$H/obsidian-vault/03_Projects/work/readme.txt")
run_hook "post-output-detect.sh" "$input" "$H" > /dev/null 2>&1
assert_file_not_exists "A-4 .md 아닌 파일은 스킵" "$(marker_path "$H")"

make_plain_md "$H/obsidian-vault/03_Projects/work/plain.md"
input=$(build_post_tooluse_input "Write" "$H/obsidian-vault/03_Projects/work/plain.md")
run_hook "post-output-detect.sh" "$input" "$H" > /dev/null 2>&1
assert_file_not_exists "A-5 type: frontmatter 없으면 스킵" "$(marker_path "$H")"

input=$(build_post_tooluse_input "Write" "")
run_hook "post-output-detect.sh" "$input" "$H" > /dev/null 2>&1
assert_file_not_exists "A-6 빈 file_path는 스킵" "$(marker_path "$H")"

run_hook "post-output-detect.sh" "" "$H" > /dev/null 2>&1
assert_file_not_exists "A-7 빈 stdin은 스킵" "$(marker_path "$H")"

teardown_fake_home "$H"

# ── 스위트 B: 마커 생성 ───────────────────────────────────────────
suite "B. 마커 생성"

H=$(setup_fake_home)
MD="$H/obsidian-vault/03_Projects/work/prd.md"
make_project_md "$MD"

input=$(build_post_tooluse_input "Write" "$MD")
run_hook "post-output-detect.sh" "$input" "$H" > /dev/null 2>&1
assert_file_exists "B-1 Write 후 마커 생성됨" "$(marker_path "$H")"
assert_json_field "B-2 마커 file 필드 정확" '.file' "$MD" "$(marker_path "$H")"
assert_json_field "B-3 마커 retry 초기값 0" '.retry' "0" "$(marker_path "$H")"

teardown_fake_home "$H"

H=$(setup_fake_home)
MD="$H/obsidian-vault/03_Projects/hire/spec.md"
make_project_md "$MD" "spec"

input=$(build_post_tooluse_input "Edit" "$MD")
run_hook "post-output-detect.sh" "$input" "$H" > /dev/null 2>&1
assert_file_exists "B-4 Edit 후 마커 생성됨" "$(marker_path "$H")"
assert_json_field "B-5 Edit 마커 file 정확" '.file' "$MD" "$(marker_path "$H")"

teardown_fake_home "$H"

# ── 스위트 C: 동일 파일 재저장 (retry 유지) ──────────────────────
suite "C. 동일 파일 retry 유지"

H=$(setup_fake_home)
MD="$H/obsidian-vault/03_Projects/work/prd.md"
make_project_md "$MD"

inject_marker "$H" "$MD" 1   # retry=1 주입

input=$(build_post_tooluse_input "Write" "$MD")
run_hook "post-output-detect.sh" "$input" "$H" > /dev/null 2>&1
assert_json_field "C-1 동일 파일 retry 유지됨 (1→1)" '.retry' "1" "$(marker_path "$H")"

inject_marker "$H" "$MD" 2
run_hook "post-output-detect.sh" "$input" "$H" > /dev/null 2>&1
assert_json_field "C-2 retry=2 유지" '.retry' "2" "$(marker_path "$H")"

teardown_fake_home "$H"

# ── 스위트 D: 다른 파일 저장 (retry 리셋) ────────────────────────
suite "D. 다른 파일 retry=0 리셋"

H=$(setup_fake_home)
MD1="$H/obsidian-vault/03_Projects/work/prd.md"
MD2="$H/obsidian-vault/03_Projects/work/spec.md"
make_project_md "$MD1"
make_project_md "$MD2"

inject_marker "$H" "$MD1" 1

input=$(build_post_tooluse_input "Write" "$MD2")
run_hook "post-output-detect.sh" "$input" "$H" > /dev/null 2>&1
assert_json_field "D-1 다른 파일 저장 시 file 교체" '.file' "$MD2" "$(marker_path "$H")"
assert_json_field "D-2 retry 0으로 리셋" '.retry' "0" "$(marker_path "$H")"

teardown_fake_home "$H"
