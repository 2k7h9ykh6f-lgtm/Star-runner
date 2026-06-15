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

  # Active-skill duration (Scout speed boost / Interceptor rapid fire)
  if [ "$skill_active" = 1 ]; then
    skill_timer=$((skill_timer + 1))
    if [ "$skill_timer" -ge "$SKILL_DURATION" ]; then
      skill_active=0
      skill_timer=0
      skill_speed_boost=0
      skill_rapid=0
    fi
  fi

  # Skill cooldown. This only ticks here, and update_timers runs solely while
  # the game is unpaused and in-play, so the cooldown freezes during pause and
  # never advances after Game Over.
  if [ "$skill_cooldown" -gt 0 ]; then
    skill_cooldown=$((skill_cooldown - 1))
  fi
}

# Clear every active asteroid from the screen (Cruiser - Mega Bomb)
skill_mega_bomb() {
  local i=1
  local active line col size
  while [ "$i" -le "$asteroid_count" ]; do
    eval "active=\$asteroid_${i}_active"
    if [ "$active" = 1 ]; then
      eval "line=\$asteroid_${i}_line"
      eval "col=\$asteroid_${i}_col"
      eval "size=\$asteroid_${i}_size"
      eval "asteroid_${i}_active=0"
      add_score_points 5
      move_cursor "$line" "$col"
      case $size in
        1) printf "   " ;;
        2) printf "    " ;;
        3) printf "     " ;;
      esac
      move_cursor "$line" "$col"
      printf "${COLOR_YELLOW}✶${COLOR_NEUTRAL}"
    fi
    i=$((i + 1))
  done
}

# Trigger the current ship's active skill (bound to the E key).
# Each unlocked ship has a distinct effect; locked ships never reach here
# because the player can only fly ships they own.
activate_skill() {
  # Still cooling down -> ignore the press
  [ "$skill_cooldown" -gt 0 ] && return
  # Guard: only owned/unlocked ships have a usable skill
  check_ownership "$current_ship" "$owned_ships" || return

  current_ship=$((current_ship + 0))
  skill_cooldown=$SKILL_COOLDOWN

  case "$current_ship" in
    1)  # Scout - Speed Boost: briefly move faster
      skill_speed_boost=1
      skill_active=1
      skill_timer=0
      ;;
    2)  # Interceptor - Rapid Fire: lasers travel faster, raising fire rate
      skill_rapid=1
      skill_active=1
      skill_timer=0
      ;;
    3)  # Frigate - Shield: gain a one-hit protective shield
      shield_active=1
      shield_timer=0
      ;;
    4)  # Cruiser - Mega Bomb: clear all on-screen asteroids
      skill_mega_bomb
      ;;
    5)  # Battleship - Invincible Burst: temporary invincibility
      super_mode_active=1
      super_timer=0
      ;;
  esac
}
