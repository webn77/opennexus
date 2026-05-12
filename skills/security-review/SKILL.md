---
name: security-review
description: 코드·스크립트 보안 취약점 검토. OWASP Top 10 기준, 등급별 분류 출력.
트리거: /security-review, /security-review <대상>, 보안 검토, 취약점 확인
완료: 보안 취약점 등급별 분류 출력 (Critical/High/Medium/Low)
실행: 직접
---

# /security-review
> 코드·스크립트 보안 취약점 검토 — OWASP Top 10 기준, 등급별 분류 출력

## 트리거
- `/security-review` — 현재 컨텍스트에서 대상 자동 추론
- `/security-review <대상>` — 명시적 지정
  - 예: `/security-review src/`
  - 예: `/security-review pipeline.sh`

---

## 검토 범위

| 범주 | 확인 항목 |
|---|---|
| 인증·인가 | 하드코딩 자격증명, API 키 노출, 환경변수 미사용 |
| 인젝션 | Shell injection, SQL injection, command substitution 미검증 |
| 입력 검증 | 사용자 입력 unsanitized 사용, 경로 탐색(../), glob 미처리 |
| 암호화 | 평문 저장, 취약 해시(MD5/SHA1), HTTP 사용 |
| 에러 처리 | 스택 트레이스 노출, 민감정보 로그 출력 |
| 파일 권한 | 과도한 chmod(777), .env 추적, 민감파일 repo 저장 |
| 의존성 | known CVE 패키지, outdated 버전 |
| 텔레그램 | parse_mode HTML/Markdown 사용 (XSS 위험) |

---

## 실행 순서

### Step 1. 대상 파악
- 명시된 경우: 해당 파일/디렉토리
- 미명시: 현재 대화의 최근 수정 파일 또는 프로젝트 src/ + scripts/

### Step 2. 정적 분석
대상 파일 읽기 → 위 검토 범위 기준으로 취약점 후보 추출

### Step 3. 등급 분류 및 출력

```
## /security-review: <대상>

### 🔴 Critical (즉시 수정 필수)
- [파일:라인] 문제 설명 → 수정 방향

### 🟡 Warning (수정 권고)
- [파일:라인] 문제 설명 → 수정 방향

### 🟢 Info (참고)
- [파일:라인] 개선 가능 항목

### 종합
🔴 N개 / 🟡 N개 / 🟢 N개
판단: ✅ 진행 가능 / ⚠️ Warning 확인 후 진행 / ❌ Critical 수정 필수
```

**🔴 Critical 존재 시 → 즉시 중단, auditor-fix 에이전트로 수정 후 재실행**

---

## 사용 기준

- ✅ Step 6.5 auditor-scan 단계에서 자동 실행
- ✅ 신규 스크립트·API 엔드포인트 구현 후
- ✅ 배포 전 최종 점검
- ❌ 단순 문서·설정값 변경

---

## 연동

- Step 6.5 파이프라인: auditor-scan.md → `/security-review` → 🔴 발견 시 auditor-fix.md 호출
- 완료 기준: 🔴 0개

## 파이프라인 연결
연결 위치: tdd 후
방식: 조건부
조건: 보안 관련 시
