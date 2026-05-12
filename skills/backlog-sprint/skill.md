---
name: backlog-sprint
description: 현재 스프린트 확인·이력 조회·activate. /backlog-sprint [history|#N|activate].
트리거: /backlog-sprint, 스프린트 확인, 스프린트 보여줘
완료: 스프린트 정보 출력 또는 activate 시 S/M/L 분류표 제시
실행: 직접
verified_at: 2026-05-09
---

# backlog-sprint

현재 스프린트 확인, 이전 스프린트 이력 조회, 강제 실행.

## 트리거
- `/backlog-sprint` — 현재 스프린트
- `/backlog-sprint history` — 전체 이력
- `/backlog-sprint #N` — N번 스프린트 상세

## 실행

```python
import json, sys
from pathlib import Path

# ── 백엔드 선택 (BACKLOG_BACKEND=linear → Linear API, 기본=json) ──
import os
_backend = os.environ.get("BACKLOG_BACKEND", "json").lower()
_ok = False

if _backend == "linear":
    sys.path.insert(0, str(Path.home() / "projects/work/linear"))
    try:
        from linear_client import load_backlog_compat
        d = load_backlog_compat()
        _ok = True
    except Exception:
        pass

if not _ok:
    BACKLOG = Path.home() / "context/backlog.json"
    if not BACKLOG.exists():
        print("⚠️ backlog.json 없음")
        raise SystemExit
    d = json.loads(BACKLOG.read_text())

args  = "{{args}}"   # 호출 인자
items = {i["id"]: i for i in d["items"]}

def progress_bar(done, total, width=10):
    filled = int(done / max(total, 1) * width)
    return "█" * filled + "░" * (width - filled)

def show_sprint(s):
    sprint_no  = s.get("no", "?")
    sprint_ids = s.get("items", [])
    all_it     = [items.get(sid) for sid in sprint_ids if sid in items]
    done_cnt   = sum(1 for i in all_it if i and i.get("status") == "done")
    total_cnt  = len(all_it)
    bar        = progress_bar(done_cnt, total_cnt)
    status_tag = {"active":"🏃","completed":"✅","draft":"⏳"}.get(s.get("status",""),"?")

    print(f"{status_tag} 스프린트 #{sprint_no} ({s['id']})")
    print(f"   주간: {s.get('week','?')}  [{bar}] {done_cnt}/{total_cnt} 완료")
    if s.get("completed_at"):
        print(f"   완료: {s['completed_at'][:10]}")
    print()

    for sid in sprint_ids:
        i = items.get(sid)
        if not i:
            continue
        icon = {"done":"✅","in_progress":"🔄","sprint":"📌","backlog":"  "}.get(i.get("status",""),"  ")
        print(f"  {icon} [{i['domain']}] ★{i.get('rice_score',0):.0f} {i['title'][:55]}")

sprints = d.get("sprints", [])

# /backlog-sprint activate
if "activate" in args:
    active = next((s for s in sprints if s.get("status") == "active"), None)
    if active:
        print(f"이미 active 스프린트: {active['id']}")
    else:
        sprint_items = list(items.values())[:5]
        print("📋 스프린트 activate — 항목 분류")
        print()
        for i in sprint_items:
            rice = i.get("rice_score", 0)
            tier = "L" if rice >= 100 else "M" if rice >= 50 else "S"
            print(f"  [{tier}] [{i['domain']}] ★{rice:.0f} {i['title'][:50]}")
        print()
        print("→ /backlog-sprint activate [sprint-id] 로 활성화")

# /backlog-sprint history
elif "history" in args:
    total = len(sprints)
    total_done = sum(
        sum(1 for sid in s.get("items",[]) if items.get(sid,{}).get("status")=="done")
        for s in sprints if s.get("status")=="completed"
    )
    print(f"📊 스프린트 이력 — 총 {total}회 실행\n")
    for s in reversed(sprints):
        show_sprint(s)

# /backlog-sprint #N
elif args.strip().startswith("#"):
    try:
        no = int(args.strip().lstrip("#"))
        s  = next((s for s in sprints if s.get("no") == no), None)
        if s:
            show_sprint(s)
        else:
            print(f"⚠️ 스프린트 #{no} 없음")
    except ValueError:
        print("⚠️ 형식: /backlog-sprint #N")

# 기본: 현재 스프린트
else:
    active = next((s for s in sprints if s.get("status") == "active"), None)
    if active:
        show_sprint(active)
        todo = [items.get(sid) for sid in active.get("items",[])
                if items.get(sid) and items.get(sid,{}).get("status") != "done"]
        if todo:
            print(f"\n남은 항목 {len(todo)}개 — /backlog-sprint history 로 전체 이력 확인")
    else:
        last = sprints[-1] if sprints else None
        if last:
            print(f"현재 active 스프린트 없음")
            print(f"마지막: 스프린트 #{last.get('no','?')} ({last['id']}) — {last.get('status','?')}")
        else:
            print("스프린트 없음 — 목요일 09:00 자동 생성")
        total = d.get("config",{}).get("sprint_counter", 0)
        print(f"누적 스프린트: {total}회")
```
