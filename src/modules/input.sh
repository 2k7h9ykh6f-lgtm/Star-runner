#!/usr/bin/env bash

#SYNAPSNEX OSS-Protection License (SOPL) v1.0
#Copyright (c) 2026 Dulsara Pieris

# STAR RUNNER - Input Handling Module
# Keyboard input processing

# Map a raw input key to a logical action using the configured bindings.
# Bindings are guaranteed unique (see config.sh), so order does not matter.
resolve_key_action() {
  local k="$1"
  [ -z "$k" ] && { printf 'none'; return; }
  if [ "$k" = "$KEY_UP" ]; then printf 'up'; return; fi
  if [ "$k" = "$KEY_DOWN" ]; then printf 'down'; return; fi
  if [ "$k" = "$KEY_LEFT" ]; then printf 'left'; return; fi
  if [ "$k" = "$KEY_RIGHT" ]; then printf 'right'; return; fi
  if [ "$k" = "$KEY_FIRE" ]; then printf 'fire'; return; fi
  if [ "$k" = "$KEY_SKILL" ]; then printf 'skill'; return; fi
  if [ "$k" = "$KEY_PAUSE" ]; then printf 'pause'; return; fi
  if [ "$k" = "$KEY_QUIT" ]; then printf 'quit'; return; fi
  printf 'none'
}

# Handle player input
handle_input() {
  read_chars key 1

  if [ "$key" = "$ESCAPE_CHAR" ]; then
    read_chars key 2
    key="${key##*[}"
  fi

  # Resolve the configured action for whatever key was pressed.
  local action mkey
  action=$(resolve_key_action "$key")

  # Movement is funneled through the punishment transformer using canonical
  # arrow codes (A/B/C/D). This keeps REVERSE/DIZZY punishment effects working
  # no matter which physical keys the player has bound to movement.
  mkey=""
  case "$action" in
    up) mkey="A" ;;
    down) mkey="B" ;;
    right) mkey="C" ;;
    left) mkey="D" ;;
  esac

  if [ -n "$mkey" ] && [ "$(type -t handle_input_with_punishment)" = "function" ]; then
    mkey="$(handle_input_with_punishment "$mkey")"
    case "$mkey" in
      A) action="up" ;;
      B) action="down" ;;
      C) action="right" ;;
      D) action="left" ;;
    esac
  fi

  # Get ship speed for movement - ensure it's a number
  current_ship=$((current_ship + 0))
  ship_speed=$(get_ship_speed "$current_ship")
  ship_speed=$((ship_speed + 0))

  case "$action" in
    up) # always move 1 line at a time vertically
      if [ "$ship_line" -gt 3 ]; then
        clear_ship
        ship_line=$((ship_line - 1))
      fi
      ;;
    down) # always move 1 line at a time vertically
      if [ "$ship_line" -lt $((NUM_LINES - 2)) ]; then
        clear_ship
        ship_line=$((ship_line + 1))
      fi
      ;;
    right) # use ship speed for horizontal movement
      if [ "$ship_column" -lt $((NUM_COLUMNS - 10)) ]; then
        clear_ship
        ship_column=$((ship_column + ship_speed))
      fi
      ;;
    left) # use ship speed for horizontal movement
      if [ "$ship_column" -gt 5 ]; then
        clear_ship
        ship_column=$((ship_column - ship_speed))
      fi
      ;;
    fire) # fire weapon
      fire_weapon
      ;;
    skill) # active skill
      use_active_skill
      ;;
    pause) # pause / resume
      toggle_pause
      ;;
    quit) # quit
      on_exit
      ;;
  esac
}

# Active skill: a short "super-mode" burst (brief invincibility + destroy
# asteroids on contact), reusing the existing powerup mechanic and gated by a
# frame-based cooldown so it cannot be spammed.
use_active_skill() {
  if [ "${skill_cooldown:-0}" -gt 0 ]; then
    return
  fi

  super_mode_active=1
  super_timer=0
  skill_cooldown=120

  printf "$COLOR_MAGENTA"
  skill_line=$((NUM_LINES / 2))
  skill_col=$((NUM_COLUMNS / 2 - 8))
  move_cursor $skill_line $skill_col
  printf " ◈ SKILL ACTIVE ◈ "
  printf "$COLOR_NEUTRAL"
}

# Capture a single keypress (including arrow keys) for the Controls rebind UI.
# Result is returned in the global CAPTURED_KEY. Enter or a lone ESC yields an
# empty string (treated as "cancel" by the caller).
capture_key() {
  local _ck _rest
  stty -icanon -echo min 1 time 0
  read_chars _ck 1
  if [ "$_ck" = "$ESCAPE_CHAR" ]; then
    stty min 0 time 1
    read_chars _rest 2
    if [ -n "$_rest" ]; then
      _ck="${_rest##*[}"
    else
      _ck=""
    fi
  fi
  stty icanon echo
  CAPTURED_KEY="$_ck"
}

# Toggle pause state
toggle_pause() {
  if [ "$paused" = 0 ]; then
    paused=1
    printf "$COLOR_CYAN"
    center_col=$((NUM_COLUMNS / 2 - 8))
    center_line=$((NUM_LINES / 2))
    move_cursor $center_line $center_col
    printf " ║║ PAUSED ║║ "
    printf "$COLOR_NEUTRAL"
  else
    paused=0
    center_col=$((NUM_COLUMNS / 2 - 8))
    center_line=$((NUM_LINES / 2))
    move_cursor $center_line $center_col
    printf "               "
  fi
}
