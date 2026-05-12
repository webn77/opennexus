---
name: pricing-strategy
description: >
  가격 전략 심층 분석으로 요금 구조의 최적화 포인트를 찾을 때 사용합니다.
  가격 전략, 요금제 분석, 가격 구조, 프리미엄 전환, 가격 인상 관련 요청 시 자동 실행.
---

# Pricing Strategy 파이프라인

## 깊이 판단 (시작 시 먼저 결정)
```
[QUICK]  현재 요금제만 분석, 검색 없음 → 페이월 문제점 빠르게
[NORMAL] 검색 5회 이하 → 경쟁사 비교 + 개선안
```

## 토큰 원칙
- web_fetch: 요금제 페이지 1개만 (메인 생략)
- Tavily 최대 5회 (경쟁사 요금제 조사)
- 에이전트 간 전달: 요금제 구조 요약만

---

## 에이전트 A — 리서처 [NORMAL만]

수집 (검색 최대 5회):
- 경쟁사 요금제 3개 (web_fetch 1회)
- 리뷰에서 가격 언급 패턴

반환 (요약만):
```json
{
  "our_pricing": "현재 구조 3줄",
  "competitor_pricing": [{"name": "", "model": "", "price_point": ""}]
}
```

---

## 에이전트 B — 분석가

5관점 분석:

1. **모델 분류**: Freemium / 구독 / 종량제 / 번들
2. **페이월 설계**: 전환 트리거 / 너무 빠름·늦음 / 무료 티어 관대함
3. **Price Anchoring**: 앵커 요금제 존재 여부
4. **가격 탄력성**: WTP 추정 / 경쟁사 대비 포지션
5. **즉시 개선안** TOP 3 + 예상 임팩트

반환 (요약만):
```json
{
  "paywall_issues": ["2개 이내"],
  "top_improvements": ["3개"],
  "expected_impact": "1줄"
}
```

---

## 에이전트 C — 서기

1. `obsidian/03_Projects/[분석명]/insight.md` — 페이월 문제 + 개선안 TOP 3
2. `obsidian/03_Projects/[분석명]/analysis.md` — 5관점 전체 (NORMAL만)
3. 요금제 개선 → `_BACKLOG.md`
4. git push
