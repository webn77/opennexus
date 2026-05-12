---
name: md-to-pdf
description: 마크다운 파일을 PDF로 변환. /md-to-pdf [파일경로] 또는 "PDF 만들어줘", "PDF로 변환해줘" 요청 시 실행.
트리거: /md-to-pdf [파일경로], PDF 만들어줘, PDF로 변환해줘, PDF 출력해줘
완료: [원본파일명].pdf (원본과 같은 폴더에 저장)
실행: 직접
---

# /md-to-pdf

> 마크다운 → PDF 변환 스킬 | md-to-pdf + CSS 스타일 적용

## 트리거

- `/md-to-pdf [파일경로]`
- "PDF 만들어줘", "PDF로 변환해줘", "PDF 출력해줘"
- 파일 경로가 없으면 현재 대화에서 작업 중인 md 파일 자동 감지

## 고정 설정

- **바이너리:** `md-to-pdf` (PATH에서 탐색 — `npm install -g md-to-pdf`로 설치)
- **CSS:** 대상 폴더의 `pdf-style.css` 우선 → 없으면 스타일 없이 진행
- **출력 파일명:** `[원본파일명].pdf` (원본과 같은 폴더)
- **PDF 옵션:** A4, 여백 18mm, printBackground true

## 실행 순서

### Step 1. 파일 경로 확인

- 인자로 받은 경로 사용
- 없으면 대화 컨텍스트에서 최근 작업한 `.md` 파일 경로 추출
- `~` 포함이면 절대 경로로 변환

### Step 2. md-to-pdf 설치 확인

```bash
command -v md-to-pdf || echo "미설치 — npm install -g md-to-pdf 실행 필요"
```

### Step 3. CSS 준비

- 대상 폴더에 `pdf-style.css` 있는지 확인
- 없으면 스타일 없이 진행 (사용자에게 알림)

### Step 4. PDF 변환

```bash
BASENAME=$(basename "[파일경로]" .md)
DIR=$(dirname "[파일경로]")
OUTPUT="$DIR/${BASENAME}.pdf"

md-to-pdf \
  --stylesheet "$DIR/pdf-style.css" \
  --pdf-options '{"format":"A4","margin":{"top":"18mm","bottom":"18mm","left":"18mm","right":"18mm"},"printBackground":true}' \
  "[파일경로]"
```

### Step 5. 결과 확인

- `ls -lh $OUTPUT` 으로 파일 크기 확인
- `open $OUTPUT` 으로 PDF 열기

## 완료 메시지 형식

```
PDF 생성 완료
파일: [파일명].pdf
크기: [크기]
경로: [전체경로]
```

## 오류 처리

- md-to-pdf 미설치 시: `npm install -g md-to-pdf` 안내 후 중단
- CSS 없을 시: 스타일 없이 진행 (사용자에게 알림)
- 파일 경로 못 찾을 시: 경로 직접 입력 요청
