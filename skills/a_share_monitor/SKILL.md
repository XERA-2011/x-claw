---
name: a_share_monitor
description: Use when users ask for A-share realtime quotes, pct change, turnover, or LHB data; fetch via efinance using scripts/ef_tool.py.
---

# A-Share Monitor (efinance)

## Overview

Use this skill to fetch A-share realtime quotes and (optionally) LHB data via the `efinance` Python library.

For any stock-related questions, prefer the local `ef_tool.py` script first. Only use browser or web_search if explicitly requested by the user or if the local script fails.

## Hard Rules

- For stock price/行情/涨跌幅/成交额/龙虎榜 requests, DO NOT use browser or web_search. Always call the local script.
- If the script fails, ask the user for a 6-digit code and retry locally.
- If you are responding in chat, explicitly invoke `$a_share_monitor` when a stock-related request is detected.

## Quick Start

Ensure dependency:
`pip install efinance`

Run the script:

```bash
python3 scripts/ef_tool.py --query "宁德时代"
python3 scripts/ef_tool.py --query 300750
python3 scripts/ef_tool.py --query market --market
```

## Workflow

1. For overall market requests (e.g., "当前A股行情"), run the script with `--market` to return a snapshot of major indices.
2. For specific stocks, accept a name or 6-digit code and fetch via `get_latest_quote`.
   - latest price
   - pct change
   - turnover amount
3. If the user requests LHB data, call the LHB helper and return the latest rows.

## Output Format

Return a concise summary:
```
代码: 300750
名称: 宁德时代
最新价: 123.45
涨跌幅: 1.23%
成交额: 12.34亿
```

## Notes

- If `efinance` is missing, instruct to install it.
- If name lookup fails, ask the user to provide the stock code.
