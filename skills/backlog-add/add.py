#!/usr/bin/env python3
"""
backlog-add — 백로그 항목 추가
사용: python3 add.py [domain] [title] [--due YYYY-MM-DD] [--rice '{"reach":7,"impact":8,"confidence":6,"effort":4}']

RICE는 Claude가 계산해서 --rice 인자로 전달. 없으면 기본값 5,5,5,5 사용.
"""
import argparse
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

BACKLOG = Path.home() / "context" / "backlog.json"

def calc_score(rice: dict) -> int:
    effort = max(rice.get("effort", 1), 1)
    return round(rice["reach"] * rice["impact"] * rice["confidence"] / effort)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("domain")
    parser.add_argument("title", nargs="+")
    parser.add_argument("--due", default="")
    parser.add_argument("--rice", default="", help='JSON: {"reach":N,"impact":N,"confidence":N,"effort":N}')
    args = parser.parse_args()

    domain = args.domain
    title = " ".join(args.title)
    due = args.due.strip()

    if due and not re.match(r'^\d{4}-\d{2}-\d{2}$', due):
        print(f"⚠️  마감일 형식 오류: {due} (YYYY-MM-DD)")
        sys.exit(1)

    # RICE 파싱 (전달받은 경우)
    default_rice = {"reach": 5, "impact": 5, "confidence": 5, "effort": 5}
    if args.rice:
        try:
            r = json.loads(args.rice)
            rice = {k: int(r.get(k, 5)) for k in default_rice}
        except Exception:
            rice = default_rice
    else:
        rice = default_rice

    score = calc_score(rice)

    if not BACKLOG.exists():
        BACKLOG.parent.mkdir(parents=True, exist_ok=True)
        BACKLOG.write_text('{"version":"1.0","items":[],"sprints":[]}')

    data = json.loads(BACKLOG.read_text())
    items = data.setdefault("items", [])

    max_id = 0
    for it in items:
        try:
            n = int(str(it.get("id", "BL-0")).split("-")[1])
            if n > max_id:
                max_id = n
        except (IndexError, ValueError):
            pass

    now = datetime.now(timezone.utc).isoformat()
    item = {
        "id": f"BL-{max_id + 1:03d}",
        "domain": domain,
        "title": title,
        "due": due,
        "status": "backlog",
        "rice": rice,
        "rice_score": score,
        "created_at": now,
        "updated_at": now,
    }
    items.append(item)
    data["updated_at"] = now

    BACKLOG.write_text(json.dumps(data, ensure_ascii=False, indent=2))

    print(f"✅ {item['id']} 추가됨: [{domain}] {title}")
    print(f"   RICE: R{rice['reach']} I{rice['impact']} C{rice['confidence']} E{rice['effort']} → ★{score}")
    if due:
        print(f"   📅 마감: {due}")
    else:
        print(f"   💡 마감일을 정해두면 우선순위 관리에 도움됩니다 (--due 2026-12-31)")

if __name__ == "__main__":
    main()
