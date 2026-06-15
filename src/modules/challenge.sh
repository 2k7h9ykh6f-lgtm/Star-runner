#!/usr/bin/env bash

#SYNAPSNEX OSS-Protection License (SOPL) v1.0
#Copyright (c) 2026 Dulsara Pieris

# STAR RUNNER - Challenge Run Module
# Timed challenge mode with fixed rules and separate leaderboard

# ------------------------------
# Constants
# ------------------------------
CHALLENGE_SCORES_FILE="$HOME/.star_runner_challenge_scores"
CHALLENGE_DURATION=120   # seconds
CHALLENGE_SEED=42

# ------------------------------
# State
# ------------------------------
challenge_mode=0
challenge_time_left=0
challenge_start_frame=0
_challenge_rng_state=0

# ------------------------------
# Seeded RNG (deterministic for challenge mode)
# Uses a linear congruential generator so every
# challenge run produces the same spawn sequence.
# ------------------------------
challenge_seeded_random() {
  local min=$1
  local max=$2
  local range=$((max - min + 1))
  _challenge_rng_state=$(( (_challenge_rng_state * 1103515245 + 12345) % 2147483648 ))
  local val=$(( _challenge_rng_state % range ))
  [ "$val" -lt 0 ] && val=$(( -val ))
  echo $(( min + val ))
}

# Override get_random_number when in challenge mode
get_random_number() {
  if [ "$challenge_mode" -eq 1 ]; then
    challenge_seeded_random "$1" "$2"
    return
  fi
  local min=$1
  local max=$2
  local range=$((max - min + 1))
  local num
  num=$(od -An -N2 -tu2 /dev/urandom 2>/dev/null | tr -d ' ')
  printf "%d" $((min + num % range))
}

# ------------------------------
# Initialize challenge mode state
# ------------------------------
init_challenge() {
  challenge_mode=1
  challenge_start_frame=$frame

  # Fixed ship: Scout (ship 1)
  current_ship=1
  current_skin=1

  # Fixed difficulty: Classic rules
  difficulty_name="Challenge"
  player_lives=1
  spawn_floor=1
  score_multiplier=1

  # Starting ammo from Scout
  ammo=$(get_ship_ammo 1)
  ammo=$((ammo + 0))

  # Reset all gameplay state
  score=0
  level=1
  speed_multiplier=0
  crystals_collected=0
  asteroids_destroyed=0
  combo_streak=0
  combo_timer=0
  asteroid_count=0
  crystal_active=0
  powerup_active=0
  laser_active=0
  laser2_active=0
  laser3_active=0
  shield_active=0
  shield_timer=0
  grace_timer=0
  super_mode_active=0
  super_timer=0
  weapon_type=1
  weapon_timer=0

  # Seed the deterministic RNG
  _challenge_rng_state=$CHALLENGE_SEED
}

# ------------------------------
# Challenge menu (shown from main menu)
# ------------------------------
show_challenge_menu() {
  clear
  printf "${COLOR_YELLOW}"
  cat << "EOF"
     ██████╗██╗  ██╗ █████╗ ██╗     ███████╗███████╗
    ██╔════╝██║  ██║██╔══██╗██║     ██╔════╝██╔════╝
    ██║     ███████║███████║██║     █████╗  █████╗
    ██║     ██╔══██║██╔══██║██║     ██╔══╝  ██╔══╝
    ╚██████╗██║  ██║██║  ██║███████╗███████╗███████╗
     ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝
    ██████╗ ██╗   ██╗███╗   ██╗
    ██╔══██╗██║   ██║████╗  ██║
    ██████╔╝██║   ██║██╔██╗ ██║
    ██╔══██╗██║   ██║██║╚██╗██║
    ██║  ██║╚██████╔╝██║ ╚████║
    ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝
EOF
  printf "${COLOR_NEUTRAL}\n"

  printf "  ${COLOR_CYAN}═══ CHALLENGE RUN RULES ═══${COLOR_NEUTRAL}\n\n"
  printf "  ${COLOR_WHITE}▸ Fixed ship: Scout (no shop upgrades)${COLOR_NEUTRAL}\n"
  printf "  ${COLOR_WHITE}▸ Duration: ${CHALLENGE_DURATION} seconds${COLOR_NEUTRAL}\n"
  printf "  ${COLOR_WHITE}▸ Lives: 1 (one hit = game over)${COLOR_NEUTRAL}\n"
  printf "  ${COLOR_WHITE}▸ Difficulty curve: fixed & escalating${COLOR_NEUTRAL}\n"
  printf "  ${COLOR_WHITE}▸ No store bonuses or power-ups${COLOR_NEUTRAL}\n"
  printf "  ${COLOR_WHITE}▸ Deterministic spawns (same every run)${COLOR_NEUTRAL}\n"
  printf "  ${COLOR_WHITE}▸ Goal: Score as high as possible!${COLOR_NEUTRAL}\n\n"

  printf "  ${COLOR_GREEN}[1]${COLOR_NEUTRAL} Start Challenge Run\n"
  printf "  ${COLOR_YELLOW}[2]${COLOR_NEUTRAL} View Challenge Scores\n"
  printf "  ${COLOR_RED}[3]${COLOR_NEUTRAL} Back to Main Menu\n\n"
  printf "  Select option: "

  read -r challenge_choice
  case $challenge_choice in
    1)
      return 0
      ;;
    2)
      show_challenge_scores
      show_challenge_menu
      ;;
    *)
      return 1
      ;;
  esac
}

# ------------------------------
# Challenge leaderboard display
# ------------------------------
show_challenge_scores() {
  clear
  printf "${COLOR_YELLOW}╔═══════════════════════════════════════════════════════╗${COLOR_NEUTRAL}\n"
  printf "${COLOR_YELLOW}║${COLOR_NEUTRAL}              CHALLENGE RUN LEADERBOARD                ${COLOR_YELLOW}║${COLOR_NEUTRAL}\n"
  printf "${COLOR_YELLOW}╚═══════════════════════════════════════════════════════╝${COLOR_NEUTRAL}\n\n"

  if [ ! -f "$CHALLENGE_SCORES_FILE" ]; then
    printf "  ${COLOR_CYAN}No challenge runs recorded yet!${COLOR_NEUTRAL}\n"
    printf "  ${COLOR_WHITE}Complete a Challenge Run to appear here.${COLOR_NEUTRAL}\n\n"
    printf "  Press Enter to return..."
    read -r
    return
  fi

  printf "  ${COLOR_CYAN}%-4s %-8s %-6s %-6s %-8s %-12s${COLOR_NEUTRAL}\n" "RANK" "SCORE" "TIME" "KILLS" "CRYSTALS" "DATE"
  printf "  ${COLOR_WHITE}────────────────────────────────────────────────────${COLOR_NEUTRAL}\n"

  local rank=0
  sort -t'|' -k1 -rn "$CHALLENGE_SCORES_FILE" | head -10 | while IFS='|' read -r s_score s_time s_kills s_crystals s_date; do
    rank=$((rank + 1))
    case $rank in
      1) printf "  ${COLOR_YELLOW}" ;;
      2) printf "  ${COLOR_WHITE}" ;;
      3) printf "  ${COLOR_YELLOW}" ;;
      *) printf "  ${COLOR_NEUTRAL}" ;;
    esac
    printf "#%-3s %-8s %-6s %-6s %-8s %-12s${COLOR_NEUTRAL}\n" \
      "$rank" "$s_score" "${s_time}s" "$s_kills" "$s_crystals" "$s_date"
  done

  printf "\n  Press Enter to return..."
  read -r
}

# ------------------------------
# Save challenge result to leaderboard
# ------------------------------
save_challenge_score() {
  local s_score=$1
  local s_time=$2
  local s_kills=$3
  local s_crystals=$4
  local s_date
  s_date=$(date '+%Y-%m-%d')
  echo "${s_score}|${s_time}|${s_kills}|${s_crystals}|${s_date}" >> "$CHALLENGE_SCORES_FILE"
  chmod 600 "$CHALLENGE_SCORES_FILE" 2>/dev/null
}

# ------------------------------
# Fixed difficulty curve for challenge mode
# Speed increases at 30s, 60s, 90s marks
# ------------------------------
update_challenge_difficulty() {
  local elapsed=$(( (frame - challenge_start_frame) * TURN_DURATION / 10 ))
  challenge_time_left=$(( CHALLENGE_DURATION - elapsed ))
  [ "$challenge_time_left" -lt 0 ] && challenge_time_left=0

  if [ "$elapsed" -ge 90 ]; then
    speed_multiplier=3
  elif [ "$elapsed" -ge 60 ]; then
    speed_multiplier=2
  elif [ "$elapsed" -ge 30 ]; then
    speed_multiplier=1
  else
    speed_multiplier=0
  fi

  # Time's up — end the challenge
  if [ "$challenge_time_left" -le 0 ]; then
    on_challenge_game_over
  fi
}

# ------------------------------
# Challenge game over (time expired)
# ------------------------------
on_challenge_game_over() {
  local elapsed=$(( (frame - challenge_start_frame) * TURN_DURATION / 10 ))
  [ "$elapsed" -gt "$CHALLENGE_DURATION" ] && elapsed=$CHALLENGE_DURATION

  # Save to leaderboard
  save_challenge_score "$score" "$elapsed" "$asteroids_destroyed" "$crystals_collected"

  # Restore terminal
  hide_alternate_screen
  show_cursor
  stty icanon echo

  # Display results
  clear
  printf "${COLOR_YELLOW}"
  cat << "EOF"

 ██████╗  █████╗ ███╗   ███╗███████╗     ██████╗ ██╗   ██╗███████╗██████╗
██╔════╝ ██╔══██╗████╗ ████║██╔════╝    ██╔═══██╗██║   ██║██╔════╝██╔══██╗
██║  ███╗███████║██╔████╔██║█████╗      ██║   ██║██║   ██║█████╗  ██████╔╝
██║   ██║██╔══██║██║╚██╔╝██║██╔══╝      ██║   ██║██║   ██║██╔══╝  ██╔══██╗
╚██████╔╝██║  ██║██║ ╚═╝ ██║███████╗    ╚██████╔╝╚██████╔╝███████╗██║  ██║
 ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝╚══════╝     ╚═════╝  ╚═════╝ ╚══════╝╚═╝  ╚═╝

EOF
  printf "${COLOR_NEUTRAL}"

  printf "${COLOR_MAGENTA}╔═══════════════════════════════════════════════════════╗${COLOR_NEUTRAL}\n"
  printf "${COLOR_MAGENTA}║${COLOR_NEUTRAL}          CHALLENGE RUN COMPLETE                       ${COLOR_MAGENTA}║${COLOR_NEUTRAL}\n"
  printf "${COLOR_MAGENTA}╚═══════════════════════════════════════════════════════╝${COLOR_NEUTRAL}\n\n"

  printf "  ${COLOR_YELLOW}Score:${COLOR_NEUTRAL}              $score\n"
  printf "  ${COLOR_CYAN}Survival Time:${COLOR_NEUTRAL}      ${elapsed}s / ${CHALLENGE_DURATION}s\n"
  printf "  ${COLOR_RED}Asteroids Destroyed:${COLOR_NEUTRAL} $asteroids_destroyed\n"
  printf "  ${COLOR_CYAN}Crystals Collected:${COLOR_NEUTRAL}  $crystals_collected\n"
  printf "  ${COLOR_WHITE}Date:${COLOR_NEUTRAL}               $(date '+%Y-%m-%d %H:%M')\n\n"

  # Compute rank
  printf "  ${COLOR_GREEN}Challenge Rank:${COLOR_NEUTRAL} "
  if [ "$score" -lt 50 ]; then
    printf "${COLOR_WHITE}Rookie Pilot${COLOR_NEUTRAL}\n"
  elif [ "$score" -lt 150 ]; then
    printf "${COLOR_GREEN}Challenger${COLOR_NEUTRAL}\n"
  elif [ "$score" -lt 300 ]; then
    printf "${COLOR_CYAN}Contender${COLOR_NEUTRAL}\n"
  elif [ "$score" -lt 500 ]; then
    printf "${COLOR_BLUE}Elite Runner${COLOR_NEUTRAL}\n"
  elif [ "$score" -lt 800 ]; then
    printf "${COLOR_MAGENTA}Champion${COLOR_NEUTRAL}\n"
  elif [ "$score" -lt 1200 ]; then
    printf "${COLOR_YELLOW}Master Pilot${COLOR_NEUTRAL}\n"
  else
    printf "${COLOR_RED}NEXUS LEGEND${COLOR_NEUTRAL}\n"
  fi

  # Show top-3 from leaderboard
  printf "\n  ${COLOR_YELLOW}── Top 3 Challenge Scores ──${COLOR_NEUTRAL}\n"
  if [ -f "$CHALLENGE_SCORES_FILE" ]; then
    local r=0
    sort -t'|' -k1 -rn "$CHALLENGE_SCORES_FILE" | head -3 | while IFS='|' read -r ls lt lk lc ld; do
      r=$((r + 1))
      printf "  ${COLOR_CYAN}#${r}${COLOR_NEUTRAL}  Score: ${COLOR_YELLOW}${ls}${COLOR_NEUTRAL}  Time: ${lt}s  Kills: ${lk}  Date: ${ld}\n"
    done
  fi

  printf "\n  ${COLOR_CYAN}Created by Dulsara(SYNAPSNEX)${COLOR_NEUTRAL}\n"
  printf "  ${COLOR_YELLOW}dulsara.synapsnex@gmail.com${COLOR_NEUTRAL}\n\n"
  exit
}

# ------------------------------
# Challenge ship destruction (lives ran out)
# ------------------------------
on_challenge_destroyed() {
  printf "$COLOR_RED"
  center_col=$((NUM_COLUMNS / 2 - 10))
  center_line=$((NUM_LINES / 2))
  move_cursor $center_line $center_col
  printf " SHIP DESTROYED "
  printf "$COLOR_NEUTRAL"
  sleep 3
  on_challenge_game_over
}
