---
name: bs-detector
description: 코드 파일 경로 또는 코드 블록을 받아 하드코딩 시크릿/빈 catch/as any/console.log 등 품질 이슈를 PASS/WARN/BLOCK으로 판정. "코드 검사", "품질 감사", "bs-detector", "/bs-detector" 요청 시 실행.
트리거: 코드 검사, 품질 감사, bs-detector, /bs-detector
완료: PASS/WARN/BLOCK 판정 + 발견 목록 출력
실행: 직접
version: 1.0
verified_at: 2026-05-09
---

# /bs-detector
> 코드 파일/블록 → PASS/WARN/BLOCK 판정 + 발견 목록 + 수정 제안

## YAML 명세

```yaml
skill:
  id: bs-detector
  name: BS 감지기 (코드 품질)
  domain: po/운영
  trigger:
    - "코드 검사"
    - "품질 감사"
    - "bs-detector"
    - "/bs-detector"
  inputs:
    - "코드 파일 경로 또는 코드 블록"
  outputs:
    - PASS/WARN/BLOCK 판정 + 발견 목록 (인라인 출력)
  passes:
    - "하드코딩 시크릿 감지 시 BLOCK 판정됨"
    - "빈 catch/as any/console.log 감지 시 WARN 판정됨"
    - "이슈별 수정 제안 포함됨"
  reviewer: passes 항목 체크 후 APPROVE/REVISE
```

## 판정 기준

### BLOCK 조건 (즉시 차단)
- 하드코딩 API 키 (패턴: `sk-`, `Bearer `, `api_key =`, `password =`)
- 하드코딩 비밀번호 / 토큰
- 하드코딩 DB 접속 정보

### WARN 조건 (경고)
- 빈 catch 블록 (`catch (e) {}` 또는 `catch {}`)
- TypeScript `as any` 사용
- `console.log` / `print` 잔존 (프로덕션 코드)
- `TODO` / `FIXME` 주석 잔존
- 미사용 import

## 트리거

- `/bs-detector` — 직접 실행
- `코드 검사` — 코드 파일 또는 블록 제공 후 실행
- `품질 감사` — 품질 이슈 전체 스캔
- `bs-detector` — 슬래시 없는 명령어

## 실행 순서

### Step 1. 입력 확인
- 파일 경로: Read 도구로 파일 로드
- 코드 블록: 직접 분석

**출력:** 대상 파일/코드 확인

### Step 2. BLOCK 조건 스캔
하드코딩 시크릿 패턴 검색:
- 정규식 패턴 매칭
- 파일별 라인 번호 명시
- 발견 시 즉시 BLOCK 판정

**출력:** BLOCK 이슈 목록 (없으면 빈 목록)

### Step 3. WARN 조건 스캔
코드 품질 이슈 검색:
- 빈 catch, as any, console.log 등
- 라인 번호 + 코드 스니펫 포함

**출력:** WARN 이슈 목록

### Step 4. 수정 제안
각 이슈별:
- 문제 설명
- 수정 방법 (Before/After 코드)

**출력:** 수정 제안 목록

### Step 5. 최종 판정

```
BLOCK 이슈 1개 이상 → 판정: BLOCK
WARN 이슈만 → 판정: WARN
이슈 없음 → 판정: PASS
```

## 출력 형식

```
## /bs-detector 결과

판정: [PASS/WARN/BLOCK]

### BLOCK 이슈 (N건)
- L[라인번호]: [코드 스니펫] → [문제 설명]
  수정: [수정 방법]

### WARN 이슈 (N건)
- L[라인번호]: [코드 스니펫] → [문제 설명]
  수정: [수정 방법]

passes:
✅ 하드코딩 시크릿 감지 시 BLOCK 판정됨
✅ 빈 catch/as any/console.log 감지 시 WARN 판정됨
✅ 이슈별 수정 제안 포함됨
```

## passes 조건

| 조건 | 확인 방법 |
|------|----------|
| BLOCK 판정 | 시크릿 발견 시 "판정: BLOCK" 출력 |
| WARN 판정 | WARN 이슈 발견 시 "판정: WARN" 출력 |
| 수정 제안 포함 | 각 이슈에 수정 방법 존재 |

## 사용 예시

```
/bs-detector ~/projects/my-app/src/api.ts
```

```
/bs-detector
[코드 블록 붙여넣기]
```

## 트리거 제외

- 보안 취약점 전체 감사 → /security-review 사용
- 예외 처리 전체 검토 → /exception-audit 사용
