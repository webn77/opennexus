---
name: user-journey
description: 서비스명과 핵심 단계 목록을 받아 단계별 행동/감정/접점/개선기회 4요소가 매핑된 사용자 여정 지도 생성. "사용자 여정", "유저 저니", "user journey", "/user-journey" 요청 시 실행.
트리거: 사용자 여정, 유저 저니, user journey, /user-journey
완료: obsidian/03_Projects/[domain]/[work]/user-journey-[date].md 저장
실행: 직접
version: 1.0
verified_at: 2026-05-09
---

# /user-journey
> 서비스 + 핵심 단계 → 행동/감정/접점/개선기회 4요소 매핑 여정 지도

## YAML 명세

```yaml
skill:
  id: user-journey
  name: 사용자 여정 지도
  domain: po/스토리보드
  trigger:
    - "사용자 여정"
    - "유저 저니"
    - "user journey"
    - "/user-journey"
  inputs:
    - "서비스명"
    - "핵심 단계 목록 (최소 3개)"
    - "페르소나 (선택)"
  outputs:
    - path: "obsidian/03_Projects/[domain]/[work]/user-journey-[date].md"
      type: md
    - path: context/events.jsonl
      type: log
  passes:
    - "단계별 행동/감정/접점/개선기회 4요소 매핑됨"
    - "최소 3개 이상의 단계 정의됨"
    - "개선 기회 도출됨"
  reviewer: passes 항목 체크 후 APPROVE/REVISE
```

## 트리거

- `/user-journey` — 직접 실행
- `사용자 여정` — 여정 지도 생성 요청
- `유저 저니` — 동의어
- `user journey` — 영어 명령어

## 실행 순서

### Step 1. 단계 목록 확인
입력된 단계 목록 정리:
- 단계명 표준화
- 단계 간 순서 확인
- 최소 3개 단계 보장

**출력:** 단계 목록

### Step 2. 4요소 매핑
각 단계별:
1. **행동(Action)**: 사용자가 하는 것
2. **감정(Emotion)**: 긍정/중립/부정 + 구체적 감정
3. **접점(Touchpoint)**: 채널/인터페이스 (앱, 웹, 이메일 등)
4. **개선기회(Opportunity)**: Pain Point → 해결 아이디어

**출력:** 4요소 테이블

### Step 3. 개선 기회 종합
전체 여정에서 핵심 개선 기회 도출:
- Pain Point 클러스터링
- 우선순위 개선 포인트 1~3개

**출력:** 개선 기회 요약

### Step 4. Reviewer — passes 조건 체크

```
Worker 산출물
  → Reviewer (passes 조건 1:1 대조)
    APPROVE → 저장 + 텔레그램 알림
    REVISE  → Worker 재실행 (최대 3회)
    REJECT  → Stuck Detector 발동
```

**Stuck Detector 텔레그램 포맷:**
```
[STUCK] user-journey | retry=[count]회
실패 조건: [failed_passes]
마지막 오류: [error]
→ 직접 개입 필요
```

### Step 5. Obsidian 저장
파일명: `user-journey-[YYYY-MM-DD].md`
저장 경로: `obsidian/03_Projects/[domain]/[work]/`

## 출력 형식

```
## /user-journey 완료

# [서비스명] 사용자 여정 지도

**페르소나**: [페르소나명]
**목표**: [최종 목표]

| 단계 | 행동 | 감정 | 접점 | 개선기회 |
|------|------|------|------|----------|
| [단계1] | [행동] | 😊/😐/😣 [감정] | [채널] | [기회] |
| [단계2] | [행동] | [감정] | [채널] | [기회] |
| [단계3] | [행동] | [감정] | [채널] | [기회] |

## 핵심 개선 기회
1. [개선기회1] — [우선순위]
2. [개선기회2] — [우선순위]

passes:
✅ 단계별 행동/감정/접점/개선기회 4요소 매핑됨
✅ 3개 이상 단계 정의됨
✅ 개선 기회 도출됨

저장: obsidian/03_Projects/[domain]/[work]/user-journey-[date].md
```

## passes 조건

| 조건 | 확인 방법 |
|------|----------|
| 4요소 매핑 | 행동/감정/접점/개선기회 열 존재 |
| 3개 이상 단계 | 테이블 행 3개 이상 |
| 개선 기회 도출 | 개선기회 열 또는 별도 섹션 존재 |

## 사용 예시

```
/user-journey
서비스: 모두충전 앱
단계: 앱 설치 → 회원가입 → 충전소 검색 → 충전 시작 → 결제 → 완료
```

## 트리거 제외

- 유저 스토리 작성 → /user-story 사용
- 화면 흐름도 → /prototype-flow 사용
