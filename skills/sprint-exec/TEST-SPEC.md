# sprint-exec TEST-SPEC.md

테스트 실행: `bash ~/.claude/skills/sprint-exec/run_tests.sh`

## 테스트 케이스

### T-01: 정상 스프린트 로드
- **입력**: fixtures/backlog-mock.json (active sprint + 5개 항목)
- **기대**: 항목 5개 추출, sprint_id = SP-TEST-W01
- **검증**: `python3 -c "import json; d=json.load(open(...)); assert len([i for i in d['items'] if i['id'] in d['sprints'][0]['items']]) == 5"`
- **PASS 조건**: exit 0

### T-02: Tier 분류 정확도
- **입력**: file_count 1 → S, 4 → M, 8 → L
- **기대**: BL-T01=S, BL-T02=S, BL-T03=M, BL-T04=L, BL-T05=S
- **검증**: lib.sh의 tier_classify 함수 직접 호출
- **PASS 조건**: 5개 분류 모두 일치

### T-03: capacity 계산
- **입력**: S×3 + M×1 + L×1
- **기대**: capacity = 3×1 + 1×3 + 1×5 = 11
- **검증**: python3 계산 assert
- **PASS 조건**: capacity == 11

### T-04: slug 경로 분리 (충돌 방지)
- **입력**: BL-T01, BL-T02 slug 생성
- **기대**: spec-action-BL-T01-*-latest.md / spec-action-BL-T02-*-latest.md 분리
- **검증**: 파일명 패턴 assert (BL-ID 포함 여부)
- **PASS 조건**: 두 slug에 각 BL-ID 포함

### T-05: 실패 격리
- **입력**: BL-T01 status=failed 주입
- **기대**: BL-T02 status 변경 없음 (계속 진행)
- **검증**: mock backlog에서 T01 failed 후 T02 status 확인
- **PASS 조건**: BL-T02 status != "failed"

### T-06: 레트로 트리거
- **입력**: 전체 항목 completed 상태 mock
- **기대**: checkpoint.json todo[]에 "[retro/SP-TEST-W01]" 추가
- **검증**: `jq '.todo[] | select(startswith("[retro/SP-TEST-W01"))' /tmp/test-checkpoint.json`
- **PASS 조건**: 결과 1줄 이상

### T-07: 번다운 갱신
- **입력**: BL-T01 완료 (rice_score=100)
- **기대**: sprint-exec-state.json rice_remaining 100 감소
- **검증**: 완료 전후 rice_remaining 비교
- **PASS 조건**: after < before

### T-08: Codex 타임아웃 → fallback 기록
- **입력**: fallback_used=true mock 상태
- **기대**: sprint-exec-state.json에 fallback_used=true 기록
- **검증**: `jq '.fallback_used' /tmp/test-state.json`
- **PASS 조건**: true

### T-09: spec-build 3회 FAIL → blocked
- **입력**: retry_count=3 mock 주입
- **기대**: status=blocked
- **검증**: python3 assert status == "blocked"
- **PASS 조건**: status == "blocked"

### T-10: backlog.json atomic write
- **입력**: /tmp/test-backlog.json에 동시 쓰기 시도 (2회)
- **기대**: 최종 파일 valid JSON, 데이터 손실 없음
- **검증**: `python3 -c "import json; json.load(open('/tmp/test-backlog.json'))"`
- **PASS 조건**: json.loads() 오류 없음

## 기준선 예상 (SKILL.md 구현 전)
- PASS: T-01, T-02, T-03, T-04 (단위 로직)
- FAIL: T-05 ~ T-10 (통합 로직, SKILL.md 구현 후 PASS 목표)
