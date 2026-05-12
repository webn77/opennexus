---
name: ab-test
description: 구현 전/후 성능·품질을 N=3회 평균으로 비교해 실제 개선 여부 검증
트리거: "A/B 테스트", "ab테스트", "abtest", "개선됐는지 확인", "개선 확인", "전후 비교", "before/after 비교", "구현 전 baseline", "baseline 찍어줘", "비교해줘", "/ab-test"
완료: ~/.nexus8/ab-test/baseline-{target}.json 저장 + 텔레그램 리포트
사람: /ab [baseline|compare] — target 자동 감지, 최소 입력
AI: spec-build 착수 시 baseline 자동 / spec-up 직전 compare 자동
파이프라인: spec-build Step 0(baseline) · spec-up Step 0(compare)에 연동
---

# /ab-test — 구현 전후 개선 검증

v1.0 | 2026-05-04

## 설계 산출물

### 플로우차트

```text
[baseline]
사용자: /ab-test baseline --target X
    │
    ├─ run_tests.sh 존재? NO → 오류: "--script로 경로 지정"
    │
    ▼ YES
    3회 반복 실행
    │
    ├─ 2회 이상 실패? → FAIL 리포트, baseline 저장 안 함
    │
    ▼
    메트릭 수집 (시간·에러율·품질)
    │
    ▼
    baseline-{target}.json 저장
    │
    ▼
    완료 알림

[compare]
사용자: /ab-test compare --target X
    │
    ├─ baseline-{target}.json 없음? → 오류: "baseline 먼저 실행"
    │
    ▼
    3회 반복 실행
    │
    ▼
    메트릭 수집 → baseline과 비교
    │
    ├─ IMPROVED  → spec-up 진행 권장
    ├─ NEUTRAL   → 사용자 판단
    └─ DEGRADED  → /debug 권장 (자동 실행 X)
    │
    ▼
    history.jsonl append + 텔레그램 리포트
```

### 시퀀스 다이어그램

```text
사용자       스킬        run_tests.sh    저장소            텔레그램
  │           │               │              │                │
  │─baseline─>│               │              │                │
  │           │──3회 실행────>│              │                │
  │           │<─결과─────────│              │                │
  │           │──baseline.json 저장─────────>│                │
  │<─완료─────│               │              │                │
  │           │               │              │                │
  │─compare──>│               │              │                │
  │           │──baseline 로드──────────────>│                │
  │           │<─────────────────────────────│                │
  │           │──3회 실행────>│              │                │
  │           │<─결과─────────│              │                │
  │           │──판정 + history append──────>│                │
  │           │──리포트──────────────────────────────────────>│
  │<─결과─────│               │              │                │
```

### 예외처리 표

| 상황 | 처리 |
|------|------|
| baseline 파일 없음 | 오류: "/ab-test baseline 먼저 실행하세요" |
| run_tests.sh 없음 | 오류: "--script PATH로 경로 지정하세요" |
| 3회 중 2회 이상 실패 | FAIL 리포트, baseline 저장 안 함 |
| LLM-judge 60s 초과 | quality 메트릭 null 기록, 나머지로 판정 |
| 텔레그램 전송 실패 | 콘솔 출력으로 fallback |
| compare 시 target 불일치 | 경고 출력 후 계속 진행 |

### 타임아웃 표

| 지점 | 기준 | 초과 시 |
|------|------|---------|
| 단회 run_tests.sh 실행 | 300s | TIMEOUT 기록, 실패 처리 |
| baseline 3회 전체 | 1200s | 완료된 것만 사용 |
| compare 3회 전체 | 1200s | 완료된 것만 사용 |
| LLM-judge 호출 | 60s | quality 메트릭 skip |
| 텔레그램 전송 | 10s | 콘솔 fallback |

---

## 명령어

```text
/ab-test baseline [--target NAME] [--script PATH] [--type perf|quality|func|all]
/ab-test compare  [--target NAME]
```

> dual 모드 (`--a CMD_A --b CMD_B`) — v2 예정

- `--target`: baseline 파일 구분자 (기본: 현재 디렉토리명)
- `--script`: 테스트 스크립트 경로 (기본: `./run_tests.sh`)
- `--type`: 측정 메트릭 타입 (기본: all)

## 워크플로우 통합

TDD 기준선 실행 단계를 대체. 메트릭 캡처가 추가된 형태.

```text
spec-build 착수 전   →  /ab-test baseline  (TDD 기준선 + 메트릭 캡처)
구현 완료 후         →  /ab-test compare
IMPROVED             →  spec-up 진행
NEUTRAL / DEGRADED   →  /debug 권장 후 재구현
```

## 판정 기준

| 메트릭 | IMPROVED | NEUTRAL | DEGRADED |
|--------|----------|---------|----------|
| 실행시간 | -20% 이상 감소 | ±20% 이내 | +20% 초과 증가 |
| 에러 수 | -1건 이상 감소 | ±0건 | +1건 이상 증가 |
| 품질 점수 | +15% 이상 향상 | ±15% 이내 | -15% 이상 하락 |

**최종 판정**: 핵심 메트릭 1개 이상 IMPROVED + DEGRADED 0개 → **IMPROVED**

> 참고: N=3은 빠른 heuristic gate. 통계적 검정 아님. 실행시간 노이즈가 큰 환경은 결과 해석 주의.

## 저장 위치

```text
~/.nexus8/ab-test/
├── baseline-{target}.json   ← baseline 캡처 (덮어쓰기)
└── history.jsonl            ← 비교 이력 (append-only)
```

---

상세 패턴:

- @patterns/baseline.md — baseline 캡처 방법
- @patterns/compare.md  — 비교·판정·리포트 로직
- @patterns/metrics.md  — 메트릭 타입별 측정법
