#!/usr/bin/env bash
set -euo pipefail

# context-sync.sh — ~/context/ 를 GitHub private repo에 연동
# 사용법: bash context-sync.sh <github-private-repo-url>
# 환경변수: CONTEXT_DIR (기본값: ~/context)

CONTEXT_DIR="${CONTEXT_DIR:-$HOME/context}"
REPO_URL="${1:-}"

if [[ -z "$REPO_URL" ]]; then
    echo "사용법: bash context-sync.sh <github-private-repo-url>"
    echo "예시:   bash context-sync.sh https://github.com/yourname/nexus-context.git"
    exit 1
fi

if [[ ! -d "$CONTEXT_DIR" ]]; then
    mkdir -p "$CONTEXT_DIR"
fi

cd "$CONTEXT_DIR"

if git rev-parse --git-dir &>/dev/null 2>&1; then
    echo "  OK: $CONTEXT_DIR 이미 git repo — remote 업데이트만"
    git remote set-url origin "$REPO_URL" 2>/dev/null || git remote add origin "$REPO_URL"
    echo "  OK: remote origin → $REPO_URL"
else
    echo "  git init: $CONTEXT_DIR"
    git init -b main

    cat > .gitignore << 'EOF'
events.jsonl
search.db
*.pyc
__pycache__/
sessions.db
*.log
save_daemon.log
EOF

    # 핵심 파일만 커밋 (존재하는 것만)
    for f in checkpoint.json backlog.json work-index.jsonl projects-index.jsonl .gitignore; do
        [[ -f "$f" ]] && git add "$f" || true
    done

    if git diff --cached --quiet; then
        # 스테이지된 파일 없으면 빈 커밋
        git commit --allow-empty -m "init: context-sync 초기화"
    else
        git commit -m "init: context-sync 초기화"
    fi

    git remote add origin "$REPO_URL"
fi

echo "  push: origin main..."
git push -u origin main
echo "  OK: context-sync 완료. /save 시 자동 push됩니다."
