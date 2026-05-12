#!/usr/bin/env python3
"""backlog-view — RICE 순 백로그 출력 + 마감일 표시"""
import json
import os
import sys
from datetime import date, datetime
from pathlib import Path

BACKLOG = Path.home() / "context" / "backlog.json"

def load_data():
    backend = os.environ.get("BACKLOG_BACKEND", "json").lower()
    if backend == "linear":
        linear_path = Path.home() / ".nexus8" / "linear"
        if linear_path.exists():
            sys.path.insert(0, str(linear_path))
            try:
                from linear_client import load_backlog_compat
                return load_backlog_compat()
            except Exception as e:
                print(f"⚠️  Linear 연동 실패 — JSON으로 fallback: {e}")
        else:
            print("⚠️  Linear 백엔드 미설정 — JSON 사용")

    if not BACKLOG.exists():
        print("⚠️  backlog.json 없음 — /backlog-add 로 첫 항목을 추가하세요")
        sys.exit(0)
    return json.loads(BACKLOG.read_text())

def fmt_due(due: str) -> str:
    """마감일 → D-day 형태로 변환"""
    if not due:
        return "        "
    try:
        d = datetime.strptime(due, "%Y-%m-%d").date()
        diff = (d - date.today()).days
        if diff < 0:
            return f"❗D+{-diff:<3}"
        elif diff == 0:
            return "🔥오늘  "
        elif diff <= 3:
            return f"⚠️ D-{diff:<3}"
        else:
            return f"📅 D-{diff:<3}"
    except ValueError:
        return due[:8]

def print_item(idx, item, prefix=""):
    pin = "📌" if item.get("pinned") else prefix
    score = item.get("rice_score", 0)
    domain = item.get("domain", "?")
    due = fmt_due(item.get("due", ""))
    title = item.get("title", "")[:50]
    if idx is not None:
        print(f"{pin}{idx:2}. [{domain:7}] ★{score:>4.0f} {due} {title}")
    else:
        status_icon = {"done":"✅","in_progress":"🔄","sprint":"📌"}.get(item.get("status",""), "  ")
        print(f"  {status_icon} [{domain:7}] ★{score:>4.0f} {due} {title}")

def main():
    d = load_data()
    items = sorted(d.get("items", []), key=lambda x: x.get("rice_score", 0), reverse=True)

    if not items:
        print("📋 백로그가 비어있습니다.")
        print("   /backlog-add 또는 '백로그 추가해줘'로 첫 항목을 추가해보세요.")
        return

    # 활성 스프린트
    active_sprint = next((s for s in d.get("sprints", []) if s.get("status") == "active"), None)
    sprint_ids = set(active_sprint.get("items", [])) if active_sprint else set()

    sprint_items = [i for i in items if i["id"] in sprint_ids]
    backlog_items = [i for i in items if i.get("status") == "backlog" and i["id"] not in sprint_ids]
    blocked_items = [i for i in items if i.get("status") == "blocked"]

    if active_sprint:
        print(f"🏃 스프린트 {active_sprint['id']}")
        for i in sprint_items:
            print_item(None, i)
        print()

    print(f"📋 백로그 ({len(backlog_items)}개, RICE 순)")
    print(f"   {'':3}{'':9}{'★점수':>6} {'마감':<8} 제목")
    for idx, i in enumerate(backlog_items[:15], 1):
        print_item(idx, i, prefix="  ")

    if len(backlog_items) > 15:
        print(f"   ... 외 {len(backlog_items) - 15}개")

    if blocked_items:
        print(f"\n⛔ blocked ({len(blocked_items)}개)")
        for i in blocked_items[:5]:
            print_item(None, i)

if __name__ == "__main__":
    main()
