#!/usr/bin/env bash

#SYNAPSNEX OSS-Protection License (SOPL) v1.0
#Copyright (c) 2026 Dulsara Pieris


# STAR RUNNER - Effects Module
# Powerup timers and temporary effects management

# Update all active timers
update_timers() {
  # Shield timer
  if [ "$shield_active" = 1 ]; then
    shield_timer=$((shield_timer + 1))
    if [ "$shield_timer" -ge 30 ]; then
      shield_active=0
      shield_timer=0
    fi
  fi
  
  # Super mode timer
  if [ "$super_mode_active" = 1 ]; then
    super_timer=$((super_timer + 1))
    if [ "$super_timer" -ge 25 ]; then
      super_mode_active=0
      super_timer=0
    fi
  fi
  
  # Weapon timer (for spread shot and rapid fire)
  if [ "$weapon_type" -ne 1 ]; then
    weapon_timer=$((weapon_timer + 1))
    if [ "$weapon_timer" -ge 40 ]; then
      weapon_type=1
      weapon_timer=0
    fi
  fi

  # Post-hit grace window
  if [ "$grace_timer" -gt 0 ]; then
    grace_timer=$((grace_timer - 1))
  fi
}

# -----------------------------
# Ship Ability System
# -----------------------------

# Trigger the active ship's special ability
trigger_ability() {
  # Cannot trigger if on cooldown or already active
  if [ "$ability_cd" -gt 0 ] || [ "$ability_active" = 1 ]; then
    return
  fi

  current_ship=$((current_ship + 0))
  ability_name=$(get_ship_ability "$current_ship")

  case "$ability_name" in
    "Speed Boost")
      # Scout: temporarily double movement speed
      saved_ship_speed=$(get_ship_speed "$current_ship")
      saved_ship_speed=$((saved_ship_speed + 0))
      speed_boost_active=1
      ability_active=1
      ability_timer=0
      ;;
    "Double Shot")
      # Interceptor: temporarily enable rapid fire
      weapon_type=3
      ability_active=1
      ability_timer=0
      ;;
    "Shield")
      # Frigate: grant a protective shield
      shield_active=1
      shield_timer=0
      ability_active=1
      ability_timer=0
      ;;
    "Mega Bomb")
      # Cruiser: destroy all asteroids on screen
      local bomb_i=1
      while [ $bomb_i -le "$asteroid_count" ]; do
        eval "local bomb_active=\$asteroid_${bomb_i}_active"
        if [ "$bomb_active" = 1 ]; then
          eval "local bomb_line=\$asteroid_${bomb_i}_line"
          eval "local bomb_col=\$asteroid_${bomb_i}_col"
          eval "local bomb_size=\$asteroid_${bomb_i}_size"
          eval "asteroid_${bomb_i}_active=0"
          move_cursor "$bomb_line" "$bomb_col"
          case $bomb_size in
            1) printf "   " ;;
            2) printf "    " ;;
            3) printf "     " ;;
          esac
          move_cursor "$bomb_line" "$bomb_col"
          printf "${COLOR_YELLOW}✶${COLOR_NEUTRAL}"
          register_asteroid_destroy 1
        fi
        bomb_i=$((bomb_i + 1))
      done
      ability_active=1
      ability_timer=0
      ;;
    "Invincible Burst")
      # Battleship: temporary invincibility
      super_mode_active=1
      super_timer=0
      ability_active=1
      ability_timer=0
      ;;
  esac
}

# Update ability duration and cooldown timers (called each frame)
update_ability_timers() {
  # Ability duration tracking
  if [ "$ability_active" = 1 ]; then
    ability_timer=$((ability_timer + 1))

    # Check if ability duration has expired
    local max_duration=0
    case "$current_ship" in
      1) max_duration=20 ;;  # Scout Speed Boost: ~4 seconds
      2) max_duration=30 ;;  # Interceptor Double Shot: ~6 seconds
      3) max_duration=30 ;;  # Frigate Shield: ~6 seconds
      4) max_duration=1  ;;  # Cruiser Mega Bomb: instant
      5) max_duration=25 ;;  # Battleship Invincible Burst: ~5 seconds
    esac

    if [ "$ability_timer" -ge "$max_duration" ]; then
      # End ability effects
      case "$current_ship" in
        1) speed_boost_active=0 ;;
        2) if [ "$weapon_type" = 3 ]; then weapon_type=1; fi ;;
        # Ship 3 (Shield) and 5 (Invincible) are managed by their own timers
        # Ship 4 (Mega Bomb) is instant, no cleanup needed
      esac
      ability_active=0
      ability_timer=0

      # Set cooldown after ability ends
      case "$current_ship" in
        1) ability_cd=50 ;;  # ~10 seconds
        2) ability_cd=60 ;;  # ~12 seconds
        3) ability_cd=60 ;;  # ~12 seconds
        4) ability_cd=80 ;;  # ~16 seconds
        5) ability_cd=75 ;;  # ~15 seconds
      esac
    fi
  fi

  # Cooldown countdown
  if [ "$ability_cd" -gt 0 ]; then
    ability_cd=$((ability_cd - 1))
  fi
}

# Get ability description text for a given ship
get_ability_description() {
  local ability="$1"
  case "$ability" in
    "Speed Boost")      printf "Temporarily doubles movement speed" ;;
    "Double Shot")      printf "Temporarily enables rapid fire" ;;
    "Shield")           printf "Grants a protective shield" ;;
    "Mega Bomb")        printf "Destroys all asteroids on screen" ;;
    "Invincible Burst") printf "Temporary invincibility" ;;
    *)                  printf "No ability" ;;
  esac
}
