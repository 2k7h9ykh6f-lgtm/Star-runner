#!/usr/bin/env bash

#SYNAPSNEX OSS-Protection License (SOPL) v1.0
#Copyright (c) 2026 Dulsara Pieris

# STAR RUNNER - Entities Module
# Asteroids, crystals, and powerups

# Spawn a new asteroid
spawn_asteroid() {
  asteroid_count=$((asteroid_count + 1))
  i=$asteroid_count

  line=$(get_random_number 10 $((NUM_LINES - 10)))
  column=$((NUM_COLUMNS - 1))
  size=$(get_random_number 1 3)
  
  # UFO asteroids appear at level 3+
  if [ "$level" -ge 3 ]; then
    type_chance=$(get_random_number 1 10)
    if [ "$type_chance" -le 3 ]; then
      asteroid_type=2  # UFO type (tracks player)
    else
      asteroid_type=1  # Normal asteroid
    fi
  else
    asteroid_type=1
  fi

  eval "asteroid_${i}_line=$line"
  eval "asteroid_${i}_col=$column"
  eval "asteroid_${i}_size=$size"
  eval "asteroid_${i}_type=$asteroid_type"
  eval "asteroid_${i}_active=1"
}

# Move all active asteroids
move_asteroids() {
  i=1
  while [ $i -le "$asteroid_count" ]; do
    eval "active=\$asteroid_${i}_active"
    
    if [ "$active" = 1 ]; then
      eval "line=\$asteroid_${i}_line"
      eval "col=\$asteroid_${i}_col"
      eval "size=\$asteroid_${i}_size"
      eval "type=\$asteroid_${i}_type"
      
      # Clear old position
      move_cursor "$line" "$col"
      case $size in
        1) printf "   " ;;
        2) printf "    " ;;
        3) printf "     " ;;
      esac
      
      # Move based on type
      if [ "$type" = 2 ]; then
        # UFO type - tracks player vertically
        col=$((col - 1))
        if [ "$line" -lt "$ship_line" ]; then
          line=$((line + 1))
        elif [ "$line" -gt "$ship_line" ]; then
          line=$((line - 1))
        fi
      else
        # Normal asteroid - moves left with speed multiplier
        move_speed=$((1 + speed_multiplier / 2))
        col=$((col - move_speed))
      fi
      
      # Deactivate if off screen
      if [ "$col" -lt 1 ]; then
        eval "asteroid_${i}_active=0"
      else
        # Update position
        eval "asteroid_${i}_col=$col"
        eval "asteroid_${i}_line=$line"
        
        # Draw at new position
        move_cursor "$line" "$col"
        
        if [ "$type" = 2 ]; then
          # UFO appearance (magenta)
          printf "$COLOR_MAGENTA"
          case $size in
            1) printf "⊕" ;;
            2) printf "◉◉" ;;
            3) printf "◉⊕◉" ;;
          esac
        else
          # Normal asteroid appearance (red)
          printf "$COLOR_RED"
          case $size in
            1) printf "◆" ;;
            2) printf "◈◈" ;;
            3) printf "◈◆◈" ;;
          esac
        fi
        printf "$COLOR_NEUTRAL"
      fi
    fi
    i=$((i + 1))
  done
}

# Spawn a crystal collectible
spawn_crystal() {
  if [ "$crystal_active" = 0 ]; then
    line=$(get_random_number 3 $((NUM_LINES - 2)))
    column=$((NUM_COLUMNS - 2))
    crystal_line=$line
    crystal_col=$column
    crystal_active=1
  fi
}

# Move crystal across screen
move_crystal() {
  if [ "$crystal_active" = 1 ]; then
    # Clear old position
    move_cursor "$crystal_line" "$crystal_col"
    printf " "
    
    crystal_col=$((crystal_col - 1))
    
    if [ "$crystal_col" -lt 1 ]; then
      crystal_active=0
    else
      # Draw at new position
      move_cursor "$crystal_line" "$crystal_col"
      printf "${COLOR_CYAN}◇${COLOR_NEUTRAL}"
    fi
  fi
}

# Spawn a powerup
spawn_powerup() {
  if [ "$powerup_active" = 0 ]; then
    chance=$(get_random_number 1 8)
    if [ "$chance" = 1 ]; then
      line=$(get_random_number 3 $((NUM_LINES - 2)))
      column=$((NUM_COLUMNS - 2))
      
      # Advanced powerups at level 4+
      if [ "$level" -ge 4 ]; then
        powerup_type=$(get_random_number 1 5)
      else
        powerup_type=$(get_random_number 1 3)
      fi
      
      powerup_line=$line
      powerup_col=$column
      powerup_active=1
    fi
  fi
}

# Move powerup across screen
move_powerup() {
  if [ "$powerup_active" = 1 ]; then
    # Clear old position
    move_cursor "$powerup_line" "$powerup_col"
    printf "  "
    
    powerup_col=$((powerup_col - 1))
    
    if [ "$powerup_col" -lt 1 ]; then
      powerup_active=0
    else
      # Draw at new position with type-specific icon
      move_cursor "$powerup_line" "$powerup_col"
      case $powerup_type in
        1) printf "${COLOR_YELLOW}☢${COLOR_NEUTRAL}" ;;  # Shield
        2) printf "${COLOR_MAGENTA}◈${COLOR_NEUTRAL}" ;; # Super mode
        3) printf "${COLOR_GREEN}⊕${COLOR_NEUTRAL}" ;;   # Ammo pack
        4) printf "${COLOR_CYAN}⚡${COLOR_NEUTRAL}" ;;   # Spread shot
        5) printf "${COLOR_WHITE}◇${COLOR_NEUTRAL}" ;;  # Rapid fire
      esac
    fi
  fi
}

# -----------------------------
# BOSS ASTEROID EVENT
# -----------------------------
# The boss is a single, self-contained entity (its own globals, NOT part of the
# asteroid_${i}_* array). This keeps the normal asteroid / crystal / powerup
# spawn cadence completely untouched.

# Spawn the boss at the right edge, centred vertically. HP scales with level.
spawn_boss() {
  boss_active=1
  boss_max_hp=$((BOSS_BASE_HP + level))
  boss_hp=$boss_max_hp
  boss_line=$((NUM_LINES / 2))
  boss_col=$((NUM_COLUMNS - BOSS_WIDTH - 1))

  # Battle hold position (~60% across the screen), then drift around it
  boss_hold_col=$(((NUM_COLUMNS * 3) / 5))
  [ "$boss_hold_col" -lt 6 ] && boss_hold_col=6
  boss_drift_left=$((boss_hold_col - 4))
  boss_drift_right=$((boss_hold_col + 4))
  [ "$boss_drift_left" -lt 4 ] && boss_drift_left=4
  [ "$boss_drift_right" -gt $((NUM_COLUMNS - BOSS_WIDTH - 1)) ] && boss_drift_right=$((NUM_COLUMNS - BOSS_WIDTH - 1))
  [ "$boss_drift_right" -lt "$boss_drift_left" ] && boss_drift_right=$boss_drift_left

  boss_phase=0   # 0 = entering from the right, 1 = drifting left-right
  boss_dir=-1    # drift direction: -1 = left, +1 = right
  last_boss_level=$level

  # Warning banner
  printf "$COLOR_RED"
  center_col=$((NUM_COLUMNS / 2 - 13))
  center_line=$((NUM_LINES / 2))
  move_cursor "$center_line" "$center_col"
  printf " ⚠ WARNING: BOSS INCOMING ⚠ "
  printf "$COLOR_NEUTRAL"
  sleep 1
  move_cursor "$center_line" "$center_col"
  printf "                            "
}

# Erase the boss sprite at its current position
clear_boss() {
  move_cursor "$boss_line" "$boss_col"
  printf "%*s" "$BOSS_WIDTH" ""
}

# Draw the boss sprite; colour and glyphs reflect remaining HP (7 cells wide)
draw_boss() {
  move_cursor "$boss_line" "$boss_col"
  if [ $((boss_hp * 3)) -gt $((boss_max_hp * 2)) ]; then
    printf "${COLOR_MAGENTA}«◈◆◈◆◈»${COLOR_NEUTRAL}"   # healthy
  elif [ $((boss_hp * 3)) -gt "$boss_max_hp" ]; then
    printf "${COLOR_YELLOW}«◈◆◇◆◈»${COLOR_NEUTRAL}"    # damaged
  else
    printf "${COLOR_RED}«◆◇◆◇◆»${COLOR_NEUTRAL}"       # critical
  fi
}

# Advance and redraw the boss each frame. It enters from the right, then drifts
# left-right within a band and never exits the left edge (persists until killed).
move_boss() {
  [ "$boss_active" = 1 ] || return

  # Repair any overdraw every frame; only change position on cadence frames
  clear_boss

  if [ $((frame % BOSS_MOVE_EVERY)) -eq 0 ]; then
    if [ "$boss_phase" = 0 ]; then
      # Entering: advance left toward the hold column
      boss_col=$((boss_col - 1))
      if [ "$boss_col" -le "$boss_hold_col" ]; then
        boss_col=$boss_hold_col
        boss_phase=1
      fi
    else
      # Drifting: oscillate horizontally between the drift bounds
      boss_col=$((boss_col + boss_dir))
      if [ "$boss_col" -le "$boss_drift_left" ]; then
        boss_col=$boss_drift_left
        boss_dir=1
      elif [ "$boss_col" -ge "$boss_drift_right" ]; then
        boss_col=$boss_drift_right
        boss_dir=-1
      fi
    fi
  fi

  draw_boss
}

# Brief "area clear" shockwave: wipe every asteroid currently on screen.
# This only deactivates live asteroids; it never touches asteroid_count, frame,
# or the spawn cadence, so normal spawning resumes unchanged on the next frame.
boss_area_clear() {
  i=1
  while [ $i -le "$asteroid_count" ]; do
    eval "active=\$asteroid_${i}_active"
    if [ "$active" = 1 ]; then
      eval "line=\$asteroid_${i}_line"
      eval "col=\$asteroid_${i}_col"
      eval "size=\$asteroid_${i}_size"
      eval "asteroid_${i}_active=0"
      move_cursor "$line" "$col"
      case $size in
        1) printf "   " ;;
        2) printf "    " ;;
        3) printf "     " ;;
      esac
    fi
    i=$((i + 1))
  done

  # Shockwave flash across the boss row
  flash_line=$((NUM_LINES / 2))
  move_cursor "$flash_line" 2
  printf "$COLOR_CYAN"
  j=2
  while [ "$j" -lt "$NUM_COLUMNS" ]; do
    printf "✶"
    j=$((j + 1))
  done
  printf "$COLOR_NEUTRAL"

  center_col=$((NUM_COLUMNS / 2 - 8))
  move_cursor "$flash_line" "$center_col"
  printf "${COLOR_WHITE} ✦ AREA CLEAR ✦ ${COLOR_NEUTRAL}"
  sleep 1

  # Erase the flash row (entities redraw themselves on subsequent frames)
  move_cursor "$flash_line" 2
  j=2
  while [ "$j" -lt "$NUM_COLUMNS" ]; do
    printf " "
    j=$((j + 1))
  done
}

# Handle boss death: award score + crystals, then run the area-clear effect.
boss_defeat() {
  clear_boss
  boss_active=0
  boss_hp=0

  add_score_points "$BOSS_REWARD_SCORE"
  crystals_collected=$((crystals_collected + BOSS_REWARD_CRYSTALS))

  printf "$COLOR_YELLOW"
  center_col=$((NUM_COLUMNS / 2 - 10))
  center_line=$((NUM_LINES / 2 - 1))
  move_cursor "$center_line" "$center_col"
  printf " ★ BOSS DEFEATED! +${BOSS_REWARD_CRYSTALS}◇ ★ "
  printf "$COLOR_NEUTRAL"
  sleep 1
  move_cursor "$center_line" "$center_col"
  printf "                          "

  boss_area_clear
}