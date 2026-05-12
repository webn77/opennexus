#!/usr/bin/env bash
# session-start-context.sh — openNexus SessionStart
# checkpoint.json → systemMessage + additionalContext 주입

set -euo pipefail

# events.jsonl 2000줄 유지
_EVENTS="$HOME/context/events.jsonl"
[ -f "$_EVENTS" ] && tail -n 2000 "$_EVENTS" > "${_EVENTS}.tmp" && mv "${_EVENTS}.tmp" "$_EVENTS"

# context-sync: 최신 context pull
if git -C "$HOME/context" rev-parse --git-dir &>/dev/null 2>&1; then
    git -C "$HOME/context" pull --quiet --rebase 2>/dev/null || true
fi

python3 - <<'PYEOF'
import json, pathlib, os

home = pathlib.Path.home()
checkpoint_path = home / "context/checkpoint.json"
backlog_path    = home / "context/backlog.json"

# HARNESS_MODE (config.sh 있으면 읽기)
harness = "off"
config_path = home / "projects/config.sh"
if config_path.exists():
    for line in config_path.read_text().splitlines():
        if line.startswith("export HARNESS_MODE="):
            harness = line.split("=", 1)[1].split("#")[0].strip().strip('"').strip("'")
            break

# checkpoint 없으면 신규 세션
if not checkpoint_path.exists():
    ctx = f"=== openNexus 세션 시작 ===\n신규 세션 — checkpoint.json 없음\nHARNESS_MODE={harness}"
    print(json.dumps({
        "systemMessage": ctx,
        "hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": ctx}
    }, ensure_ascii=False))
    exit()

cp = json.load(open(checkpoint_path))
when = cp.get("when", "")[:10]

lines = [f"=== 세션 컨텍스트  HARNESS:{harness} | {when} ==="]

nxt = cp.get("next", "")
if nxt:
    lines.append("\n[다음 액션]")
    lines.append(f"  ▶ {nxt}")

blocked = cp.get("blocked", [])
todo    = cp.get("todo", [])
counts  = []
if blocked: counts.append(f"블로커 {len(blocked)}개")
if todo:    counts.append(f"미결 {len(todo)}개")
if counts:
    lines.append(f"  {'  ·  '.join(counts)}  (상세: '블로커 보여줘' / '미결 보여줘')")

lines.append("=" * 40)

# backlog 요약
if backlog_path.exists():
    try:
        bl = json.load(open(backlog_path))
        items  = bl.get("items", [])
        sprints = bl.get("sprints", [])
        active = next((s for s in sprints if s.get("status") == "active"), None)
        item_map = {i["id"]: i for i in items}

        lines.append("\n=== 오늘 할 것 (backlog-os) ===")
        if active:
            sprint_no  = active.get("no", "?")
            sprint_ids = active.get("items", [])
            all_it     = [item_map.get(sid) for sid in sprint_ids if sid in item_map]
            done_cnt   = sum(1 for i in all_it if i and i.get("status") == "done")
            total_cnt  = len(all_it)
            bar_filled = int(done_cnt / max(total_cnt, 1) * 10)
            bar        = "█" * bar_filled + "░" * (10 - bar_filled)
            lines.append(f"🏃 스프린트 #{sprint_no} ({active['id']})  [{bar}] {done_cnt}/{total_cnt}")
            lines.append(f"   주간: {active.get('week','?')} | 누적 스프린트: {len(sprints)}회")
            todo_it = [i for i in all_it if i and i.get("status") != "done"]
            for i in sorted(todo_it, key=lambda x: x.get("rice_score", 0), reverse=True)[:3]:
                icon = {"in_progress": "🔄", "sprint": "📌"}.get(i.get("status",""), "  ")
                lines.append(f"  {icon}[{i['domain']}] ★{i.get('rice_score',0):.0f} {i['title'][:48]}")
        else:
            top3 = sorted([i for i in items if i.get("status") == "backlog"],
                          key=lambda x: x.get("rice_score", 0), reverse=True)[:3]
            lines.append(f"📋 백로그 추천 (스프린트 없음 | 누적 {len(sprints)}회)")
            for i in top3:
                lines.append(f"  ★{i.get('rice_score',0):.0f} [{i['domain']}] {i['title'][:50]}")
    except Exception:
        pass

ctx_text = "\n".join(lines)
print(json.dumps({
    "systemMessage": ctx_text,
    "hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": ctx_text}
}, ensure_ascii=False))
PYEOF
