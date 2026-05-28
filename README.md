# Claude Code Statusline

A custom status line script for [Claude Code](https://claude.ai/code) that shows session context at a glance: cost, context remaining, session time with reset countdown, active tool, and local times for IST and PT.

**Author:** Varun Das

## What it shows

```
astra/Developer  |  Sonnet 4.6  |  Context Remaining: 74%  |  $0.2476  |  ⏱ 1h 4m (resets 16:30 IST)  |  15:25 IST  02:55 PT
```

Each segment is conditional — it only appears when data is present:

| Segment | Description |
|---|---|
| `dir` | Last two path components of current working directory |
| `⎇ branch` | Git branch or short SHA (hidden when not in a git repo) |
| `model` | Active Claude model (e.g. Sonnet 4.6) |
| `Context Remaining: N%` | Context window remaining — green above 50%, yellow 20-50%, red below 20% |
| `$0.XXXX` | Running session cost in USD |
| `⏱ Xh Ym (resets HH:MM IST)` | Time until the 5-hour rate-limit window resets, with the reset clock in IST |
| `⚙ tool` | Currently active tool (only visible while a tool is running) |
| `HH:MM IST  HH:MM PT` | Current time in India Standard Time and Pacific Time |

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

## Customising the time zones

The script shows IST and PT by default. To change them, edit the times section near the bottom of the script:

```sh
# Times: IST | PT
ist=$(TZ=Asia/Kolkata date '+%H:%M IST')
pt=$(TZ=America/Los_Angeles date '+%H:%M PT')
time_part="${SEP}\033[2m${ist}  ${pt}\033[0m"
```

Replace the `TZ=` values with any valid IANA timezone. Common ones:

| Label | TZ value |
|---|---|
| IST (India) | `Asia/Kolkata` |
| PT (US Pacific) | `America/Los_Angeles` |
| ET (US Eastern) | `America/New_York` |
| GMT | `UTC` |
| SGT (Singapore) | `Asia/Singapore` |
| AEST (Sydney) | `Australia/Sydney` |

## How the session timer works

Claude Code enforces a 5-hour rolling rate-limit window. The `⏱` segment counts down the time remaining in that window and shows the reset time in IST so you know exactly when capacity refreshes. The colour shifts: green above 60 minutes, yellow between 30-60 minutes, red below 30 minutes.

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
.rate_limits.five_hour.resets_at — Unix timestamp of rate-limit reset
```

These field paths reflect Claude Code 2.1.x. If a future version changes the schema, the affected segment will simply not render rather than breaking the whole line.

## License

MIT
