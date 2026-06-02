#!/bin/sh
# Claude Code status line — dir | git branch | model | context | cost | tool | times
input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
model=$(echo "$input" | jq -r '.model.display_name // ""')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
tool=$(echo "$input" | jq -r '.current_tool // empty')
rate_resets=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
rate_used=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')

SEP="\033[2m  |  \033[0m"

# Directory: show last 2 path components
dir=$(echo "$cwd" | awk -F/ '{
  n=NF
  if (n==1) print "/"
  else if (n==2) print $2
  else print $(n-1) "/" $n
}')

# Git branch (skip optional lock)
branch=""
if [ -d "$cwd/.git" ] || git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
  branch=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null)
  if [ -z "$branch" ]; then
    branch=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
  fi
fi

# Context remaining with traffic-light color (inverted: 100 - used)
ctx_part=""
if [ -n "$used" ]; then
  used_int=$(printf "%.0f" "$used")
  remaining=$((100 - used_int))
  if [ "$remaining" -le 20 ]; then
    ctx_color="\033[0;31m"
  elif [ "$remaining" -le 50 ]; then
    ctx_color="\033[0;33m"
  else
    ctx_color="\033[0;32m"
  fi
  ctx_part="${SEP}${ctx_color}Context ${remaining}%\033[0m"
fi

# Session cost
cost_part=""
if [ -n "$cost" ]; then
  cost_fmt=$(printf "%.4f" "$cost")
  cost_part="${SEP}\033[0;36m\$${cost_fmt}\033[0m"
fi

# 5h window usage + reset timer (combined, no separator between them)
window_part=""
if [ -n "$rate_used" ]; then
  rate_int=$(printf "%.0f" "$rate_used")
  if [ "$rate_int" -ge 80 ]; then
    rate_color="\033[0;31m"
  elif [ "$rate_int" -ge 50 ]; then
    rate_color="\033[0;33m"
  else
    rate_color="\033[0;32m"
  fi
  window_part="${SEP}${rate_color}% Usage ${rate_int}%\033[0m"

  if [ -n "$rate_resets" ]; then
    now=$(date -u +%s)
    diff=$((rate_resets - now))
    if [ "$diff" -gt 0 ]; then
      hrs=$((diff / 3600))
      mins=$(((diff % 3600) / 60))
      if [ "$diff" -lt 1800 ]; then
        sess_color="\033[0;31m"
      elif [ "$diff" -lt 3600 ]; then
        sess_color="\033[0;33m"
      else
        sess_color="\033[0;32m"
      fi
      reset_time=$(TZ=Asia/Kolkata date -r "$rate_resets" '+%H:%M' 2>/dev/null)
      window_part="${window_part}  ${sess_color}⏱ ${hrs}h ${mins}m${reset_time:+ (resets ${reset_time})}\033[0m"
    fi
  fi
fi

# Active tool
tool_part=""
if [ -n "$tool" ]; then
  tool_part="${SEP}\033[0;33m⚙ ${tool}\033[0m"
fi

time_part=""

# Build status line
dir_seg="\033[0;34m${dir}\033[0m"
model_seg="\033[2m${model}\033[0m"

if [ -n "$branch" ]; then
  branch_seg="\033[0;35m⎇ ${branch}\033[0m"
  printf "%b" "${dir_seg}${SEP}${branch_seg}${SEP}${model_seg}${ctx_part}${window_part}${cost_part}${tool_part}${time_part}"
else
  printf "%b" "${dir_seg}${SEP}${model_seg}${ctx_part}${window_part}${cost_part}${tool_part}${time_part}"
fi
