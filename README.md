# openNexus v8

> AI-native productivity OS for Claude Code — skills, hooks, and session memory in one install.

[![version](https://img.shields.io/badge/version-v8.1-blue)](https://github.com/webn77/opennexus)
[![Claude Code](https://img.shields.io/badge/Claude-Code-orange)](https://claude.ai/code)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

## What is openNexus?

openNexus turns Claude Code into a persistent AI operating system.

- **50+ skills** — PO workflows, sprint execution, brainstorm, diagrams, and more
- **Hook system** — session context injection, post-edit validation, Telegram notifications
- **Session memory** — checkpoint across sessions via GitHub private repo sync
- **One-command install** — up and running in under 10 minutes

## Quick Install

```bash
git clone https://github.com/webn77/opennexus
cd opennexus
bash install.sh
```

During install you'll be prompted for an optional GitHub private repo URL for session memory sync.

## Requirements

- [Claude Code CLI](https://claude.ai/code)
- Python 3.10+
- bash / zsh
- jq (`brew install jq`)
- git

## Core Structure

```
~/.claude/skills/    ← skill definitions (SKILL.md)
~/.claude/hooks/     ← automation hooks
~/context/           ← session data (checkpoint, backlog, memory)
```

## Skills

| Category | Skills |
|----------|--------|
| PO | /prd, /spec-define, /spec-build, /spec-up, /spec-action |
| Analysis | /data-insight, /service-analysis, /brainstorm, /growth-loop |
| Sprint | /sprint-exec, /backlog-sprint, /backlog-view, /backlog-add |
| Docs | /diagram-gen, /flow-design, /prototype-flow, /user-journey |
| Session | /save, /current-context, /checkpoint |

## Session Memory Sync

Keep your AI memory in sync across multiple machines:

```bash
# Initial setup (run once)
bash scripts/context-sync.sh https://github.com/yourname/your-private-repo.git

# After that, /save automatically pushes — new machines pull on session start
```

## License

MIT
