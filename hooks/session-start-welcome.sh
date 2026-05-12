#!/usr/bin/env bash
# session-start-welcome.sh — open-nexus8 신규 세션 안내

# context-sync: 세션 시작 시 최신 context pull (실패해도 세션 차단 안 함)
if git -C "$HOME/context" rev-parse --git-dir &>/dev/null 2>&1; then
    git -C "$HOME/context" pull --quiet --rebase 2>/dev/null || true
fi

NAME=""
[ -f "$HOME/.nexus8/config.sh" ] && \
  NAME=$(awk -F'"' '/^export NEXUS_USER_NAME=/{print $2}' "$HOME/.nexus8/config.sh")

MSG=$(NEXUS_USER_NAME="$NAME" python3 << 'PYEOF'
import json, os
from datetime import date, datetime
from pathlib import Path

name = os.environ.get("NEXUS_USER_NAME", "")
bl_path = Path.home() / "context" / "backlog.json"

count = 0
sprint_active = False
next_msg = "첫 백로그를 추가해보세요 — '백로그 추가해줘'"
suggestions = []

try:
    data = json.load(open(bl_path))
    items = data.get("items", [])
    backlog = [i for i in items if i.get("status") == "backlog"]
    count = len(backlog)

    sprints = data.get("sprints", [])
    sprint_active = any(s.get("status") == "active" for s in sprints)

    if backlog:
        today = date.today()
        urgent = None
        for it in backlog:
            due = it.get("due", "")
            if due:
                try:
                    d = datetime.strptime(due, "%Y-%m-%d").date()
                    if (d - today).days <= 3:
                        urgent = it
                        break
                except ValueError:
                    pass

        target = urgent or max(backlog, key=lambda x: x.get("rice_score", 0))

        if urgent:
            next_msg = f"⚠️ 마감 임박: {target['id']} {target['title']} (마감 {target['due']})"
        else:
            next_msg = f"가장 급한 작업부터 — {target['id']} {target['title']} (★{target.get('rice_score',0):.0f})"

        # 단계별 추천 분기
        if sprint_active:
            suggestions = [
                "/backlog-sprint            ← 현재 스프린트 진행 상황 확인",
                f"/prd {target['id']}         ← 항목 PRD화",
                "백로그 추가해줘              ← 새 항목 등록",
            ]
        elif count >= 3:
            suggestions = [
                "🚀 백로그가 충분히 쌓였어요. 스프린트로 묶어 실행해볼까요?",
                "/backlog-sprint activate   ← 새 스프린트 시작 (상위 항목 자동 배정)",
                "/backlog-view             ← 전체 RICE 순 확인 후 결정",
                f"/prd {target['id']}         ← 단일 항목 PRD화",
            ]
        else:
            suggestions = [
                f"/prd {target['id']}         ← PRD·기능명세서 자동 생성",
                "/backlog-view             ← 전체 백로그 RICE 순 확인",
                "백로그 추가해줘              ← 새 항목 등록 (3개 이상이면 스프린트 가능)",
            ]
    else:
        suggestions = [
            "백로그 추가해줘 [도메인] [제목]",
            "/news                    ← 오늘 도메인 뉴스 브리핑",
            "/brainstorm              ← 아이디어 탐색",
        ]
except Exception:
    pass

lines = ["=== open-nexus8 ==="]
if name:
    lines.append(f"👤 {name}")
lines.append(f"▶ 다음 액션: {next_msg}")
lines.append(f"📋 백로그: {count}개")
if suggestions:
    lines.append("")
    lines.append("💡 추천 명령어:")
    for s in suggestions:
        lines.append(f"   {s}")
lines.append("==================")

print("\n".join(lines))
PYEOF
)

if command -v jq > /dev/null 2>&1; then
  jq -nc --arg msg "$MSG" '{systemMessage: $msg}'
else
  MSG="$MSG" python3 -c "
import json, os
print(json.dumps({'systemMessage': os.environ['MSG']}, ensure_ascii=False))
"
fi
