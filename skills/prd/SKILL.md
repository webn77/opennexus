---
name: prd
version: 1.0
description: 백로그 항목을 PRD(Product Requirements Document)로 확장. PO 페르소나 + 자체 검수 통합.
트리거: /prd, PRD 만들어줘, PRD 작성, 기획서 작성
완료: $NEXUS_VAULT/03_Projects/[도메인]/[BL-ID]-PRD.md + 검수 PASS
실행: 직접
---

# /prd

> 백로그 항목 → PO 관점의 PRD 작성 → 자체 검수 → 저장

## 트리거

- `/prd [BL-ID]` 예: `/prd BL-001`
- `/prd [주제]` 예: `/prd 신규 결제 화면`
- `BL-001 PRD로 만들어줘`, `PRD 작성해줘`

## 진입 규칙

### 1. BL-ID 주어진 경우
`~/.nexus8/backlog.json`에서 항목 로드 → 도메인·제목·마감일·RICE·description 추출.

### 2. 주제만 주어진 경우 (BL 없음)
"백로그에 먼저 등록할까요?" 한 번 묻기.
- 등록 → `/backlog-add` 실행 후 진행
- 즉시 작성 → 백로그 없이 PRD 작성 (related 필드 비움)

## 실행 순서

### Step 1. 컨텍스트 로드

```bash
# 페르소나
cat $HOME/.nexus8/_libs/personas/po.yaml
# 출력 가이드
cat $HOME/.nexus8/docs/output-format-guide.md
# 템플릿
cat $HOME/.nexus8/templates/outputs/prd.md.template
# 사용자 정보 (NEXUS_USER_NAME, NEXUS_VAULT)
source $HOME/.nexus8/config.sh
# 백로그 항목 (BL-ID 주어진 경우)
python3 -c "import json; d=json.load(open('$HOME/context/backlog.json')); \
  print(json.dumps([i for i in d['items'] if i['id']=='[BL-ID]'][0], ensure_ascii=False, indent=2))"
```

### Step 2. Q&A — 페인포인트 명확화

backlog 항목에 `pain_point`·`goal`·`success_criteria`가 없으면 3문항:

```
Q1. 현재 어떤 페인포인트가 있어?
Q2. 이번에 뭘 달성하고 싶어? (수치 포함)
Q3. 어떤 상태면 성공이야?
```

답변 받으면 다음 단계.

### Step 3. PRD 작성

`templates/outputs/prd.md.template` 기반으로 모든 섹션을 채워서 작성.

치환 변수:
- `{{TITLE}}` ← 백로그 제목 또는 사용자 입력 주제
- `{{TODAY}}` ← 오늘 날짜 (YYYY-MM-DD)
- `{{NEXUS_USER_NAME}}` ← `~/.nexus8/config.sh`의 NEXUS_USER_NAME
- `{{BL_ID}}` ← 백로그 ID (없으면 빈 문자열)

**페르소나 적용 (필수)**:
- po.yaml의 system_prompt 따라 작성
- 결론 먼저(BLUF) → 본문 → 다음 액션
- 수치 목표 명시 (정성 표현 금지)
- 비용·효과 또는 KPI 포함

**저장 경로**:
```
$NEXUS_VAULT/03_Projects/[도메인]/[BL-ID]-PRD.md
예: ~/obsidian-vault/03_Projects/work/BL-001-PRD.md
```

`$NEXUS_VAULT`는 `~/.nexus8/config.sh`에서 로드.

### Step 4. 자체 검수 (reviewer 페르소나)

`reviewer.yaml`의 system_prompt에 따라 방금 작성한 PRD를 검수.

판정 출력:
```
## 검수 결과: [✅ PASS | ⚠️ WARN | ❌ FAIL]

### 검수 항목
- [✅/⚠️/❌] frontmatter
- [✅/⚠️/❌] 표준 6 섹션
- [✅/⚠️/❌] 본문 표준 (PRD)
- [✅/⚠️/❌] PO 관점 품질

### 보완 필요
1. [구체 항목]: [수정 방법]
```

### Step 5. 후처리

| 판정 | 처리 |
|---|---|
| ✅ PASS | 저장 확정. 사용자에게 경로 안내. |
| ⚠️ WARN | 보완 권장 사항 표시 + 사용자에게 "이대로 저장할까요?" 확인 |
| ❌ FAIL | 자체 수정 후 재검수 (최대 2회). 3회 FAIL 시 사용자 호출. |

### Step 6. 완료 출력

```
## /prd [BL-ID] 완료

📄 PRD: $NEXUS_VAULT/03_Projects/[도메인]/[BL-ID]-PRD.md
검수: ✅ PASS

다음 단계 추천:
- /backlog-sprint activate    ← 스프린트로 묶기
- /plan [BL-ID]              ← 기술 계획 작성 (개발 단계)
```

## 사람이 해야 하는 것

- Q&A 3문항 답변 (필요시)
- WARN 판정 시 저장 여부 결정

## 주의

- `~/.nexus8/config.sh`가 없으면 NEXUS_VAULT가 정의되지 않음 → 사용자에게 setup.sh 안내
- 도메인은 백로그 항목의 `domain` 필드 사용. BL 없으면 사용자에게 묻기.
