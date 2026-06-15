#!/usr/bin/env bash

#SYNAPSNEX OSS-Protection License (SOPL) v1.0
#Copyright (c) 2026 Dulsara Pieris


# STAR RUNNER - Configuration Module
# All constants, colors, and terminal setup

# Color definitions
COLOR_BLUE='\e[1;34m'
COLOR_GREEN='\e[1;32m'
COLOR_MAGENTA='\e[1;35m'
COLOR_NEUTRAL='\e[0m'
COLOR_RED='\e[1;31m'
COLOR_YELLOW='\e[1;33m'
COLOR_CYAN='\e[1;36m'
COLOR_WHITE='\e[1;37m'

# Special characters
ESCAPE_CHAR=$(printf '\033')

# Terminal size requirements
MIN_NUM_COLUMNS=40
MIN_NUM_LINES=20

# Game timing
TURN_DURATION=2

# Get current terminal size
TERMINAL_SIZE=$(stty size)
NUM_COLUMNS="${TERMINAL_SIZE##* }"
NUM_LINES="${TERMINAL_SIZE%% *}"

# Validate terminal size
if [ "$NUM_LINES" -lt "$MIN_NUM_LINES" ] || [ "$NUM_COLUMNS" -lt "$MIN_NUM_COLUMNS" ]; then
  printf 'Error: Your terminal size is too small. Need at least 40x20.\n' >&2
  exit 1
fi

# Validate required commands
if ! type stty > /dev/null 2>&1; then
  printf 'Error: stty is required\n' >&2
  exit 1
fi

# ------------------------------------------------------------
# Configurable Key Bindings
# ------------------------------------------------------------
# Key bindings live in their OWN file, separate from the player profile, so
# editing them never trips the profile's tamper checksum (which would reset
# the player's stats). The file is PARSED with a strict whitelist (not
# sourced), so a corrupt or hand-crafted file cannot run arbitrary code. If
# the file is missing or invalid we silently fall back to the defaults.
CONTROLS_FILE="$HOME/.star_runner_controls"

# Default bindings expressed as internal "dispatch codes": arrow keys arrive
# from the escape-sequence reader as A/B/C/D, and Space is a literal space.
DEFAULT_KEY_UP="A"
DEFAULT_KEY_DOWN="B"
DEFAULT_KEY_LEFT="D"
DEFAULT_KEY_RIGHT="C"
DEFAULT_KEY_FIRE=" "
DEFAULT_KEY_SKILL="e"
DEFAULT_KEY_PAUSE="p"
DEFAULT_KEY_QUIT="q"

# Logical actions, in display order (drives the Controls menu and help).
CONTROL_ACTIONS="up down left right fire skill pause quit"

# Human-readable action names.
control_action_name() {
  case "$1" in
    up) printf 'Move Up' ;;
    down) printf 'Move Down' ;;
    left) printf 'Move Left' ;;
    right) printf 'Move Right' ;;
    fire) printf 'Fire Weapon' ;;
    skill) printf 'Active Skill' ;;
    pause) printf 'Pause / Resume' ;;
    quit) printf 'Quit Mission' ;;
  esac
}

# Read / write the dispatch code currently bound to an action.
get_key_for_action() {
  case "$1" in
    up) printf '%s' "$KEY_UP" ;;
    down) printf '%s' "$KEY_DOWN" ;;
    left) printf '%s' "$KEY_LEFT" ;;
    right) printf '%s' "$KEY_RIGHT" ;;
    fire) printf '%s' "$KEY_FIRE" ;;
    skill) printf '%s' "$KEY_SKILL" ;;
    pause) printf '%s' "$KEY_PAUSE" ;;
    quit) printf '%s' "$KEY_QUIT" ;;
  esac
}

set_key_for_action() {
  case "$1" in
    up) KEY_UP="$2" ;;
    down) KEY_DOWN="$2" ;;
    left) KEY_LEFT="$2" ;;
    right) KEY_RIGHT="$2" ;;
    fire) KEY_FIRE="$2" ;;
    skill) KEY_SKILL="$2" ;;
    pause) KEY_PAUSE="$2" ;;
    quit) KEY_QUIT="$2" ;;
  esac
}

# Convert between on-disk TOKENS (human-readable) and dispatch CODES.
controls_token_to_code() {
  case "$1" in
    UP) printf 'A' ;;
    DOWN) printf 'B' ;;
    RIGHT) printf 'C' ;;
    LEFT) printf 'D' ;;
    SPACE) printf ' ' ;;
    *) printf '%s' "$1" ;;
  esac
}

controls_code_to_token() {
  case "$1" in
    A) printf 'UP' ;;
    B) printf 'DOWN' ;;
    C) printf 'RIGHT' ;;
    D) printf 'LEFT' ;;
    ' ') printf 'SPACE' ;;
    *) printf '%s' "$1" ;;
  esac
}

# Friendly label for a dispatch code (used by the menu and the help screen).
controls_code_label() {
  case "$1" in
    A) printf 'Up Arrow' ;;
    B) printf 'Down Arrow' ;;
    C) printf 'Right Arrow' ;;
    D) printf 'Left Arrow' ;;
    ' ') printf 'Space' ;;
    '') printf '(unset)' ;;
    *) printf '%s' "$1" | tr '[:lower:]' '[:upper:]' ;;
  esac
}

# A token is valid if it is an arrow, Space, or a single alphanumeric char.
controls_token_valid() {
  case "$1" in
    UP|DOWN|LEFT|RIGHT|SPACE) return 0 ;;
    [A-Za-z0-9]) return 0 ;;
    *) return 1 ;;
  esac
}

set_default_controls() {
  KEY_UP="$DEFAULT_KEY_UP"
  KEY_DOWN="$DEFAULT_KEY_DOWN"
  KEY_LEFT="$DEFAULT_KEY_LEFT"
  KEY_RIGHT="$DEFAULT_KEY_RIGHT"
  KEY_FIRE="$DEFAULT_KEY_FIRE"
  KEY_SKILL="$DEFAULT_KEY_SKILL"
  KEY_PAUSE="$DEFAULT_KEY_PAUSE"
  KEY_QUIT="$DEFAULT_KEY_QUIT"
}

# True only when all 8 dispatch codes are distinct (no unreachable action).
controls_has_no_duplicates() {
  if printf '%s\n' "$KEY_UP" "$KEY_DOWN" "$KEY_LEFT" "$KEY_RIGHT" \
       "$KEY_FIRE" "$KEY_SKILL" "$KEY_PAUSE" "$KEY_QUIT" \
       | sort | uniq -d | grep -q .; then
    return 1
  fi
  return 0
}

save_controls() {
  {
    printf 'KEY_UP=%s\n'    "$(controls_code_to_token "$KEY_UP")"
    printf 'KEY_DOWN=%s\n'  "$(controls_code_to_token "$KEY_DOWN")"
    printf 'KEY_LEFT=%s\n'  "$(controls_code_to_token "$KEY_LEFT")"
    printf 'KEY_RIGHT=%s\n' "$(controls_code_to_token "$KEY_RIGHT")"
    printf 'KEY_FIRE=%s\n'  "$(controls_code_to_token "$KEY_FIRE")"
    printf 'KEY_SKILL=%s\n' "$(controls_code_to_token "$KEY_SKILL")"
    printf 'KEY_PAUSE=%s\n' "$(controls_code_to_token "$KEY_PAUSE")"
    printf 'KEY_QUIT=%s\n'  "$(controls_code_to_token "$KEY_QUIT")"
  } > "$CONTROLS_FILE"
  chmod 600 "$CONTROLS_FILE" 2>/dev/null
}

reset_controls() {
  set_default_controls
  save_controls
}

# Extract one token value from the file, stripping whitespace and CR.
_controls_read_token() {
  grep -E "^$1=" "$CONTROLS_FILE" 2>/dev/null | head -1 \
    | cut -d= -f2 | tr -d '[:space:]'
}

load_controls() {
  set_default_controls

  if [ ! -f "$CONTROLS_FILE" ]; then
    save_controls
    return
  fi

  local t_up t_down t_left t_right t_fire t_skill t_pause t_quit tok
  t_up=$(_controls_read_token KEY_UP)
  t_down=$(_controls_read_token KEY_DOWN)
  t_left=$(_controls_read_token KEY_LEFT)
  t_right=$(_controls_read_token KEY_RIGHT)
  t_fire=$(_controls_read_token KEY_FIRE)
  t_skill=$(_controls_read_token KEY_SKILL)
  t_pause=$(_controls_read_token KEY_PAUSE)
  t_quit=$(_controls_read_token KEY_QUIT)

  # Every key must be present and a valid token, else reset everything.
  for tok in "$t_up" "$t_down" "$t_left" "$t_right" \
             "$t_fire" "$t_skill" "$t_pause" "$t_quit"; do
    if [ -z "$tok" ] || ! controls_token_valid "$tok"; then
      reset_controls
      return
    fi
  done

  KEY_UP=$(controls_token_to_code "$t_up")
  KEY_DOWN=$(controls_token_to_code "$t_down")
  KEY_LEFT=$(controls_token_to_code "$t_left")
  KEY_RIGHT=$(controls_token_to_code "$t_right")
  KEY_FIRE=$(controls_token_to_code "$t_fire")
  KEY_SKILL=$(controls_token_to_code "$t_skill")
  KEY_PAUSE=$(controls_token_to_code "$t_pause")
  KEY_QUIT=$(controls_token_to_code "$t_quit")

  # Reject duplicate bindings (would make an action unreachable).
  controls_has_no_duplicates || reset_controls
}

# Load bindings now so KEY_* are available to every other module.
load_controls