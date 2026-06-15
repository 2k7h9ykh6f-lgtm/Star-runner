#!/usr/bin/env bash

#SYNAPSNEX OSS-Protection License (SOPL) v1.0
#Copyright (c) 2026 Dulsara Pieris

# STAR RUNNER - Challenge Run Module
# A fixed-rule time-attack mode with its own, separate leaderboard.
#
# Challenge Run never touches the career profile, crystal bank, owned ships
# or shop state. Every override it applies lives only in memory and is
# discarded when the process exits, and results are stored in a dedicated
# leaderboard file (NOT the profile).

# Separate leaderboard storage (independent from the career profile)
CHALLENGE_SCORES_FILE="$HOME/.star_runner_challenge"

# -----------------------------
# Fixed challenge rules
# Identical for every run so scores are directly comparable.
# -----------------------------
CHALLENGE_DURATION=120     # run length in seconds
CHALLENGE_SHIP=1           # Scout - fixed ship, ignores owned/equipped ship
CHALLENGE_SKIN=1           # Default skin - fixed cosmetic
CHALLENGE_SCORE_MULT=1     # no difficulty score bonus
CHALLENGE_SPAWN_FREQ=2     # fixed asteroid spawn cadence (spawn every N frames)
CHALLENGE_LIVES=3          # fixed lives; the timer is the main limiter
CHALLENGE_RAMP=30          # seconds between difficulty steps (fixed curve)

# -----------------------------
# Runtime state
# challenge_mode stays 0 for normal play; start_challenge_mode flips it to 1.
# -----------------------------
challenge_mode=0
challenge_start_epoch=0

# Seconds elapsed since the challenge clock started
challenge_elapsed() {
  local now
  now=$(date +%s)
  echo $(( now - challenge_start_epoch ))
}

# Seconds remaining in the run (never negative)
challenge_remaining() {
  local rem
  rem=$(( CHALLENGE_DURATION - $(challenge_elapsed) ))
  [ "$rem" -lt 0 ] && rem=0
  echo "$rem"
}

# Apply the fixed challenge ruleset. Called from the menu right before the
# main game loop begins. All overrides are in-memory only, so the saved
# profile, crystal bank and equipped ship/skin remain untouched.
start_challenge_mode() {
  challenge_mode=1
  difficulty_name="Challenge"
  score_multiplier=$CHALLENGE_SCORE_MULT
  spawn_floor=$CHALLENGE_SPAWN_FREQ
  player_lives=$CHALLENGE_LIVES
  current_ship=$CHALLENGE_SHIP
  current_skin=$CHALLENGE_SKIN
  challenge_start_epoch=$(date +%s)
}

# Called every frame from the main loop. Ends the run when time is up.
# Safe to call in normal mode - it returns immediately.
challenge_check_time() {
  [ "${challenge_mode:-0}" = 1 ] || return 0
  if [ "$(challenge_elapsed)" -ge "$CHALLENGE_DURATION" ]; then
    end_challenge
  fi
}

# Append one record to the challenge leaderboard.
# Record format: score|survival_seconds|asteroids|crystals|YYYY-MM-DD
save_challenge_score() {
  local c_score=$1 c_survival=$2 c_asteroids=$3 c_crystals=$4 c_date
  c_date=$(date +%Y-%m-%d)
  printf '%s|%s|%s|%s|%s\n' \
    "$c_score" "$c_survival" "$c_asteroids" "$c_crystals" "$c_date" \
    >> "$CHALLENGE_SCORES_FILE"
  chmod 600 "$CHALLENGE_SCORES_FILE" 2>/dev/null
}

# Highest challenge score on record (0 if none yet)
get_challenge_best() {
  [ -s "$CHALLENGE_SCORES_FILE" ] || { echo 0; return; }
  local best
  best=$(sort -t'|' -k1 -nr "$CHALLENGE_SCORES_FILE" 2>/dev/null | head -n1 | cut -d'|' -f1)
  echo "${best:-0}"
}

# End a challenge run: record the result to the separate leaderboard,
# restore the terminal, show a summary and exit. Never writes the profile.
end_challenge() {
  local survival
  survival=$(challenge_elapsed)
  [ "$survival" -gt "$CHALLENGE_DURATION" ] && survival=$CHALLENGE_DURATION

  save_challenge_score "$score" "$survival" "$asteroids_destroyed" "$crystals_collected"

  hide_alternate_screen
  show_cursor
  stty icanon echo 2>/dev/null

  printf "$COLOR_CYAN"
  cat << "EOF"

  ██████╗██╗  ██╗ █████╗ ██╗     ██╗     ███████╗███╗   ██╗ ██████╗ ███████╗
 ██╔════╝██║  ██║██╔══██╗██║     ██║     ██╔════╝████╗  ██║██╔════╝ ██╔════╝
 ██║     ███████║███████║██║     ██║     █████╗  ██╔██╗ ██║██║  ███╗█████╗
 ██║     ██╔══██║██╔══██║██║     ██║     ██╔══╝  ██║╚██╗██║██║   ██║██╔══╝
 ╚██████╗██║  ██║██║  ██║███████╗███████╗███████╗██║ ╚████║╚██████╔╝███████╗
  ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝╚═╝  ╚═══╝ ╚═════╝ ╚══════╝
EOF
  printf "$COLOR_NEUTRAL\n"

  printf "\n${COLOR_MAGENTA}╔═══════════════════════════════════════════════════════╗${COLOR_NEUTRAL}\n"
  printf "${COLOR_MAGENTA}║${COLOR_NEUTRAL}              CHALLENGE RUN - RESULTS                  ${COLOR_MAGENTA}║${COLOR_NEUTRAL}\n"
  printf "${COLOR_MAGENTA}╚═══════════════════════════════════════════════════════╝${COLOR_NEUTRAL}\n\n"

  printf "  ${COLOR_YELLOW}⚡ Score:${COLOR_NEUTRAL} $score\n"
  printf "  ${COLOR_GREEN}⏱ Survival Time:${COLOR_NEUTRAL} ${survival}s / ${CHALLENGE_DURATION}s\n"
  printf "  ${COLOR_RED}◆ Asteroids Destroyed:${COLOR_NEUTRAL} $asteroids_destroyed\n"
  printf "  ${COLOR_CYAN}◇ Crystals Collected:${COLOR_NEUTRAL} $crystals_collected\n"
  printf "  ${COLOR_MAGENTA}🏆 Challenge Best:${COLOR_NEUTRAL} $(get_challenge_best)\n\n"

  printf "  ${COLOR_WHITE}Career profile, crystal bank and shop were not affected.${COLOR_NEUTRAL}\n\n"
  printf "  ${COLOR_CYAN}Created by Dulsara(SYNAPSNEX)${COLOR_NEUTRAL}\n\n"
  exit 0
}

# Challenge leaderboard screen (reached from the main menu).
show_challenge_scores() {
  clear
  printf "${COLOR_MAGENTA}╔═══════════════════════════════════════════════════════╗${COLOR_NEUTRAL}\n"
  printf "${COLOR_MAGENTA}║${COLOR_NEUTRAL}                   CHALLENGE SCORES                    ${COLOR_MAGENTA}║${COLOR_NEUTRAL}\n"
  printf "${COLOR_MAGENTA}╚═══════════════════════════════════════════════════════╝${COLOR_NEUTRAL}\n\n"

  printf "  ${COLOR_WHITE}Rule: score as much as possible in ${CHALLENGE_DURATION} seconds${COLOR_NEUTRAL}\n"
  printf "  ${COLOR_WHITE}Fixed ship - fixed difficulty - no shop bonuses${COLOR_NEUTRAL}\n\n"

  if [ ! -s "$CHALLENGE_SCORES_FILE" ]; then
    printf "  ${COLOR_YELLOW}No challenge runs yet. Be the first!${COLOR_NEUTRAL}\n\n"
    printf "  Press Enter to return..."
    read -r
    return
  fi

  printf "  ${COLOR_CYAN}%-4s %-8s %-7s %-7s %-9s %s${COLOR_NEUTRAL}\n" \
    "#" "SCORE" "TIME" "KILLS" "CRYSTALS" "DATE"
  printf "  ${COLOR_CYAN}───────────────────────────────────────────────────${COLOR_NEUTRAL}\n"

  local rank=1
  while IFS='|' read -r c_score c_survival c_asteroids c_crystals c_date; do
    [ -z "$c_score" ] && continue
    printf "  ${COLOR_YELLOW}%-4s${COLOR_NEUTRAL} %-8s %-7s %-7s %-9s %s\n" \
      "$rank" "$c_score" "${c_survival}s" "$c_asteroids" "$c_crystals" "$c_date"
    rank=$((rank + 1))
    [ "$rank" -gt 10 ] && break
  done < <(sort -t'|' -k1 -nr "$CHALLENGE_SCORES_FILE" 2>/dev/null)

  printf "\n  Press Enter to return..."
  read -r
}
