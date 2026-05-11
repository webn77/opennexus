# openNexus v8

> 개인 AI OS — Claude Code 기반 자동화 시스템

[![version](https://img.shields.io/badge/version-v8.0-blue)](https://github.com/webn77/opennexus)
[![Claude Code](https://img.shields.io/badge/Claude-Code-orange)](https://claude.ai/code)

## 소개

openNexus v8은 Claude Code를 기반으로 한 개인 AI 운영 체제입니다.  
스킬(skill) 시스템, 백로그 자동화, 파이프라인 오케스트레이션을 포함합니다.

## 빠른 설치

```bash
git clone https://github.com/webn77/opennexus
cd opennexus
bash install.sh
```

10분 이내 설치 완료.

## 핵심 구조

```
~/.claude/skills/    ← 스킬 정의 (SKILL.md)
~/context/           ← 세션 데이터 (checkpoint, backlog)
~/projects/          ← 소스코드
```

## 스킬 시스템

| 카테고리 | 스킬 |
|----------|------|
| PO | /prd, /spec-define, /spec-build, /spec-up |
| 분석 | /data-insight, /service-analysis, /brainstorm |
| 자동화 | /sprint-exec, /backlog-sprint, /save |
| 문서 | /diagram-gen, /flow-design, /prototype-flow |

## 요구사항

- Claude Code CLI
- Python 3.10+
- bash / zsh

## 라이선스

MIT
