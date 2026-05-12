---
name: backlog-ingest
description: URL을 받아 backlog.json에 gap 분석 결과를 자동 저장. /backlog-ingest [URL] 또는 "백로그에 추가 [URL]" 요청 시 실행.
type: skill
verified_at: 2026-05-09
---

# backlog-ingest

URL 내용을 분석해 기존 백로그와 비교 → 새 항목(gap)을 자동 저장합니다.

## 트리거
`/backlog-ingest [URL]`, `백로그에 추가 [URL]`, `이 URL 백로그로`

## 사용법
```
/backlog-ingest https://example.com/article
/backlog-ingest --dry-run https://example.com/article
```

## 실행

```bash
INGESTOR="$HOME/projects/work/nexus/backlog-os/agents/url_ingestor.py"

# URL 인자 파싱 (호출 시 치환)
URL="{{url}}"
DRY_RUN="{{dry_run}}"  # --dry-run 또는 빈 문자열

if [[ -z "$URL" ]]; then
  echo "⚠️ URL을 입력하세요: /backlog-ingest [URL]"
  exit 1
fi

if [[ ! -f "$INGESTOR" ]]; then
  echo "⚠️ url_ingestor.py 없음: $INGESTOR"
  exit 1
fi

# url_ingestor 실행
# BACKLOG_BACKEND=linear → url_ingestor가 Linear에 직접 저장
# BACKLOG_BACKEND=json   → backlog.json에 저장 (기존 동작)
python3 "$INGESTOR" $DRY_RUN "$URL"
```

## 동작 흐름

1. URL fetch (timeout 30s, HTML만 허용)
2. Claude Sonnet으로 기존 백로그 vs URL 내용 비교 → gap 추출
3. confidence 분기:
   - ≥ 0.7 → `backlog.json items[]` 저장 (rice-scorer가 다음 실행 시 RICE 재계산)
   - 0.5~0.7 → `candidate_pool` + ambiguous 사유 기록
   - < 0.5 → skip
4. gap 5개 초과 → 텔레그램 알림 후 PO 확인 대기 (자동 저장 차단)

## 완료 출력 예시
```
✅ backlog 2개 저장
💡 candidate_pool 1개
⏭️ skip 1개
출처: https://example.com/article
```
