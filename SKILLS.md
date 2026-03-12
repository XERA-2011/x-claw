# Skills Guide

This repo contains OpenClaw skills under `skills/`. The OpenClaw runtime loads skills from `~/.openclaw/skills`, so each repo skill should be symlinked there.

## A Share Monitor

Location:
`/Users/xera/GitHub/x-claw/skills/a_share_monitor`

Copy to enable in OpenClaw (symlinks are skipped by OpenClaw):
`cp -R /Users/xera/GitHub/x-claw/skills/a_share_monitor /Users/xera/.openclaw/skills/a_share_monitor`

One-click sync (copies all skills):
`/Users/xera/GitHub/x-claw/scripts/sync_skills.sh`

Dependency:
`pip install efinance`

Test the script directly:
```bash
python3 /Users/xera/GitHub/x-claw/skills/a_share_monitor/scripts/ef_tool.py --query "宁德时代"
python3 /Users/xera/GitHub/x-claw/skills/a_share_monitor/scripts/ef_tool.py --query 300750
python3 /Users/xera/GitHub/x-claw/skills/a_share_monitor/scripts/ef_tool.py --query 300750 --lhb
```

If OpenClaw is already running, restart the gateway to reload skills:
`openclaw gateway restart`
