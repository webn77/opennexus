---
name: growth-loop
description: >
  성장 루프(Growth Loop) 분석으로 서비스가 어떻게 자체 성장하는지 파악할 때 사용합니다.
  성장 루프 분석, 바이럴 전략, 유입 경로 분석, 어떻게 성장하나, 성장 전략 관련 요청 시 자동 실행.
---

# Growth Loop 분석 파이프라인

## 깊이 판단 (시작 시 먼저 결정)
```
[QUICK]  공개 정보만, 검색 3회 이하 → 지배적 루프 1개 파악
[NORMAL] 검색 5회 이하 → 3가지 루프 전체 분석
```

## 토큰 원칙
- 에이전트 간 전달: 핵심 신호 목록만 (원문 금지)
- Tavily 최대 5회
- 내부 데이터 있으면 검색 생략

---

## 에이전트 A — 리서처 [QUICK: 검색 3회 / NORMAL: 검색 5회]

수집:
- 공식 블로그 성장 사례 (검색 1~2회)
- 앱스토어 "어떻게 알게 됐나" 리뷰 패턴 (검색 1회)
- 내부 유입 채널 데이터 (있으면 검색 생략)

반환 (요약만):
```json
{"growth_signals": ["신호 5개 이내"], "dominant_channel": "추정값"}
```

---

## 에이전트 B — 분석가

루프 유형 분석:

**Viral**: K-factor 추정 / 공유 트리거 / 마찰 지점
**Paid**: CAC추정 / 효율 채널 / LTV:CAC 비율
**Content**: UGC 여부 / SEO 유입 / 콘텐츠→신규 경로

QUICK: 지배적 루프 1개만 깊게
NORMAL: 3가지 루프 전체

반환 (요약만):
```json
{
  "dominant_loop": "viral/paid/content",
  "missing_loops": ["목록"],
  "top_action": "즉시 할 수 있는 강화 포인트 1줄"
}
```

---

## 에이전트 C — 서기

1. `obsidian/03_Projects/[분석명]/insight.md` — 지배적 루프 + 강화 포인트
2. `obsidian/03_Projects/[분석명]/analysis.md` — 루프별 상세 (NORMAL만)
3. 루프 강화 실험 → `_BACKLOG.md`
4. git push
