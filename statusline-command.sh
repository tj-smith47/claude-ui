#!/bin/bash
# Dracula Pro status line for Claude Code.
# model │ git │ context(used/window ⊘compact-at) │ effort │ rate windows.
# Green pipe dividers keep Dracula green on screen regardless of the
# context segment's own green→yellow→red gradient.
input=$(cat)

IFS=$'\t' read -r cwd model used total ctxpct eff fast five seven exceeds style < <(
  jq -r '[
    .cwd,
    .model.display_name,
    .context_window.total_input_tokens,
    .context_window.context_window_size,
    (.context_window.used_percentage // 0 | round),
    .effort.level,
    .fast_mode,
    (.rate_limits.five_hour.used_percentage // 0 | round),
    (.rate_limits.seven_day.used_percentage // 0 | round),
    .exceeds_200k_tokens,
    .output_style.name
  ] | @tsv' <<<"$input"
)

# Auto-compact budget is config, not payload: `autoCompactWindow` is the token
# ceiling auto-compact watches (smaller than the model's full context window).
acwin=$(jq -r '.autoCompactWindow // 0' ~/.claude/settings.json 2>/dev/null)
compact_at=${acwin:-0}

# Dracula Pro palette (R;G;B).
CYAN='\e[38;2;128;255;234m'
GREEN='\e[38;2;138;255;128m'
ORANGE='\e[38;2;255;202;128m'
PINK='\e[38;2;255;128;191m'
PURPLE='\e[38;2;149;128;255m'
RED='\e[38;2;255;149;128m'
YELLOW='\e[38;2;255;255;128m'
B='\e[1m'; R='\e[0m'
SEP="${GREEN}❙${R}"            # major divider: always-green bracket bar
DOT='\e[38;2;125;125;160m·\e[0m'  # minor divider: muted middot (intra-segment)

hum() { # token count -> compact k / M
  local n=${1:-0}
  if   [ "$n" -ge 1000000 ] 2>/dev/null; then printf '%d.%dM' $((n/1000000)) $(((n%1000000)/100000))
  elif [ "$n" -ge 1000 ]    2>/dev/null; then printf '%dk' $((n/1000))
  else printf '%s' "$n"; fi
}

# model first; the 1M-context flag renders as a separate magenta tag, not
# stitched onto the model name.
model=${model% (1M context)}

# git
dir=$(basename "$cwd")
branch=$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null)

# context: used vs model window, annotated with the compaction wall.
# Gradient grades by proximity to compaction (the real first ceiling),
# not the distant 1M model max.
uctx=$(hum "$used"); tctx=$(hum "$total")
ctxcol=$GREEN
if [ "${compact_at:-0}" -gt 0 ] 2>/dev/null; then
  fillpct=$(( used * 100 / compact_at ))
  compact_note=" ${PURPLE}(⊘$(hum "$compact_at"))${R}"
else
  fillpct=${ctxpct:-0}
  compact_note=""
fi
[ "${fillpct:-0}" -ge 70 ] 2>/dev/null && ctxcol=$YELLOW
[ "${fillpct:-0}" -ge 90 ] 2>/dev/null && ctxcol=$RED

# effort + fast-mode flag
eff_seg="${YELLOW}◆ ${eff}${R}"
[ "$fast" = true ] && eff_seg="${eff_seg} ${RED}⚡${R}"

# rate-limit windows (100% = that window's allowance spent)
fcol=$ORANGE; [ "${five:-0}" -ge 85 ] 2>/dev/null && fcol=$RED
scol=$PINK;   [ "${seven:-0}" -ge 85 ] 2>/dev/null && scol=$RED

out="${B}${CYAN}${model}${R}"
[ "${total:-0}" -ge 1000000 ] 2>/dev/null && out="${out} ${PINK}(1M)${R}"
out="${out} ${SEP} ${B}${PURPLE}${dir}${R}"
# Solid triangle: renders at full width on every terminal (the thin ⎇ glyph
# clipped on some). One space each side — no extra left padding.
[ -n "$branch" ] && out="${out}${ORANGE} ▸ ${R}${PINK}${branch}${R}"
out="${out} ${SEP} ${ctxcol}${uctx}/${tctx}${R}${compact_note}"
out="${out} ${SEP} ${eff_seg}"
out="${out} ${SEP} ${fcol}5h ${five}%${R} ${DOT} ${scol}7d ${seven}%${R}"
[ -n "$style" ] && [ "$style" != default ] && out="${out} ${SEP} ${GREEN}${style}${R}"
printf '%b' "$out"
