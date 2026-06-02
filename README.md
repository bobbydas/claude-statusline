# Claude Code Statusline

A custom status line script for [Claude Code](https://claude.ai/code) that shows session context at a glance: cost, context remaining, session time with reset countdown, active tool, and local times for IST and PT.

**Author:** Varun Das

## What it shows

```
astra/Developer  |  Sonnet 4.6  |  Context 74%  |  % Usage 23%  ⏱ 1h 4m (resets 16:30)  |  $0.2476
```

Each segment is conditional — it only appears when data is present:

| Segment | Description |
|---|---|
| `dir` | Last two path components of current working directory |
| `⎇ branch` | Git branch or short SHA (hidden when not in a git repo) |
| `model` | Active Claude model (e.g. Sonnet 4.6) |
| `Context N%` | Context window remaining — green above 50%, yellow 20-50%, red below 20% |
| `% Usage N%  ⏱ Xh Ym (resets HH:MM)` | 5-hour window used + countdown to reset (green/yellow/red on both) |
| `$0.XXXX` | Running session cost in USD |
| `⚙ tool` | Currently active tool (only visible while a tool is running) |

## Installation

**1. Copy the script**

```sh
cp statusline-command.sh ~/.claude/statusline-command.sh
chmod +x ~/.claude/statusline-command.sh
```

**2. Add to `~/.claude/settings.json`**

```json
{
  "statusLine": {
    "type": "command",
    "command": "sh /Users/YOUR_USERNAME/.claude/statusline-command.sh"
  }
}
```

Replace `YOUR_USERNAME` with your macOS username, or use `$HOME`:

```json
"command": "sh $HOME/.claude/statusline-command.sh"
```

**3. Restart Claude Code**

The status line appears at the bottom of the Claude Code terminal UI.

## How the rate limit segment works

`% Usage` shows what share of your 5-hour rolling rate-limit window has been consumed. The adjacent `⏱` countdown shows time remaining until the window resets, with the reset clock in IST. Both shift green → yellow → red as limits approach.

## Requirements

- macOS (uses BSD `date -r` for Unix timestamp conversion)
- `jq` installed (`brew install jq`)
- Claude Code 2.x or later

## JSON fields used

The script reads the following fields from Claude Code's statusline JSON payload:

```
.workspace.current_dir          — current directory
.model.display_name             — model name
.context_window.used_percentage — context usage (0–100)
.cost.total_cost_usd            — session cost
.current_tool                   — active tool name (when present)
.rate_limits.five_hour.resets_at      — Unix timestamp of rate-limit reset
.rate_limits.five_hour.used_percentage — % of 5-hour window capacity consumed
```

These field paths reflect Claude Code 2.1.x. If a future version changes the schema, the affected segment will simply not render rather than breaking the whole line.

## License

MIT
