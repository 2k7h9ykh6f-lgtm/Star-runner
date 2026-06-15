#!/usr/bin/env bash

#SYNAPSNEX OSS-Protection License (SOPL) v1.0
#Copyright (c) 2026 Dulsara Pieris

# STAR RUNNER - Achievements & Daily Missions Module

# =============================
# Achievement Definitions (10)
# =============================
# 1:  First Flight       - Buy your first ship
# 2:  Fashion Statement  - Buy your first skin
# 3:  Crystal Hoarder    - Collect 100 lifetime crystals
# 4:  Asteroid Annihilator - Destroy 200 lifetime asteroids
# 5:  Combo Master       - Achieve a 5x combo streak
# 6:  Neon Pilot         - Reach Neon Pilot rank (high score >= 280)
# 7:  Cyber Ace          - Reach Cyber Ace rank (high score >= 550)
# 8:  Void Admiral       - Reach Void Admiral rank (high score >= 1750)
# 9:  Daily Grinder      - Complete 5 daily missions total
# 10: Marathon Runner    - Play 20 games

# =============================
# Daily Mission Definitions (5)
# =============================
# 1: Collect 20 crystals in one session
# 2: Destroy 30 asteroids in one session
# 3: Achieve a 5x combo streak
# 4: Score 500 points in one game
# 5: Survive 60 seconds in Chaos mode (~300 frames)

DAILY_CRYSTAL_TARGET=20
DAILY_ASTEROID_TARGET=30
DAILY_COMBO_TARGET=5
DAILY_SCORE_TARGET=500
DAILY_CHAOS_TARGET=300

# -----------------------------
# Initialization
# -----------------------------
init_achievements() {
    reset_daily_if_needed
    chaos_frames=0
}

# -----------------------------
# Daily Reset
# -----------------------------
reset_daily_if_needed() {
    local today
    today=$(date +%Y-%m-%d 2>/dev/null)
    if [ -n "$today" ] && [ "$daily_date" != "$today" ]; then
        daily_date="$today"
        daily_crystals_done=0
        daily_asteroids_done=0
        daily_combo_done=0
        daily_score_done=0
        daily_chaos_done=0
    fi
}

# -----------------------------
# Achievement Helpers
# -----------------------------
has_achievement() {
    local id=$1
    [[ ",$achievements_unlocked," == *",$id,"* ]] && return 0
    return 1
}

unlock_achievement() {
    local id=$1
    local name=$2
    if has_achievement "$id"; then
        return
    fi
    if [ -z "$achievements_unlocked" ]; then
        achievements_unlocked="$id"
    else
        achievements_unlocked="${achievements_unlocked},${id}"
    fi
    printf "\n  ${COLOR_YELLOW}★ Achievement Unlocked: ${name}! ★${COLOR_NEUTRAL}\n"
    save_profile
}

# -----------------------------
# Check All Achievements
# -----------------------------
check_all_achievements() {
    # 1: First Flight - bought first ship
    if [ "$first_purchase_made" -eq 1 ] && ! has_achievement 1; then
        unlock_achievement 1 "First Flight"
    fi

    # 2: Fashion Statement - bought a skin (owned_skins has more than just "1")
    if [[ ",$owned_skins," == *",2,"* ]] || [[ ",$owned_skins," == *",3,"* ]] || \
       [[ ",$owned_skins," == *",4,"* ]] || [[ ",$owned_skins," == *",5,"* ]]; then
        if ! has_achievement 2; then
            unlock_achievement 2 "Fashion Statement"
        fi
    fi

    # 3: Crystal Hoarder - 100 lifetime crystals
    if [ "$total_crystals" -ge 100 ] && ! has_achievement 3; then
        unlock_achievement 3 "Crystal Hoarder"
    fi

    # 4: Asteroid Annihilator - 200 lifetime asteroids
    if [ "$total_asteroids" -ge 200 ] && ! has_achievement 4; then
        unlock_achievement 4 "Asteroid Annihilator"
    fi

    # 5: Combo Master - 5x combo
    if [ "$max_combo_ever" -ge 5 ] && ! has_achievement 5; then
        unlock_achievement 5 "Combo Master"
    fi

    # 6: Neon Pilot - high score >= 280
    if [ "$high_score" -ge 280 ] && ! has_achievement 6; then
        unlock_achievement 6 "Neon Pilot"
    fi

    # 7: Cyber Ace - high score >= 550
    if [ "$high_score" -ge 550 ] && ! has_achievement 7; then
        unlock_achievement 7 "Cyber Ace"
    fi

    # 8: Void Admiral - high score >= 1750
    if [ "$high_score" -ge 1750 ] && ! has_achievement 8; then
        unlock_achievement 8 "Void Admiral"
    fi

    # 9: Daily Grinder - 5 total daily completions
    if [ "$daily_completed_count" -ge 5 ] && ! has_achievement 9; then
        unlock_achievement 9 "Daily Grinder"
    fi

    # 10: Marathon Runner - 20 games played
    if [ "$games_played" -ge 20 ] && ! has_achievement 10; then
        unlock_achievement 10 "Marathon Runner"
    fi
}

# -----------------------------
# Check Daily Mission Completion
# -----------------------------
check_daily_mission_progress() {
    reset_daily_if_needed
    local any_completed=0

    # Mission 1: Collect 20 crystals
    if [ "$daily_crystals_done" -eq 0 ] && [ "$crystals_collected" -ge "$DAILY_CRYSTAL_TARGET" ]; then
        daily_crystals_done=1
        daily_completed_count=$((daily_completed_count + 1))
        any_completed=1
        printf "  ${COLOR_GREEN}✓ Daily Mission Complete: Collect 20 crystals!${COLOR_NEUTRAL}\n"
    fi

    # Mission 2: Destroy 30 asteroids
    if [ "$daily_asteroids_done" -eq 0 ] && [ "$asteroids_destroyed" -ge "$DAILY_ASTEROID_TARGET" ]; then
        daily_asteroids_done=1
        daily_completed_count=$((daily_completed_count + 1))
        any_completed=1
        printf "  ${COLOR_GREEN}✓ Daily Mission Complete: Destroy 30 asteroids!${COLOR_NEUTRAL}\n"
    fi

    # Mission 3: Achieve 5x combo
    if [ "$daily_combo_done" -eq 0 ] && [ "$max_combo_ever" -ge "$DAILY_COMBO_TARGET" ]; then
        daily_combo_done=1
        daily_completed_count=$((daily_completed_count + 1))
        any_completed=1
        printf "  ${COLOR_GREEN}✓ Daily Mission Complete: Achieve 5x combo!${COLOR_NEUTRAL}\n"
    fi

    # Mission 4: Score 500 in one game
    if [ "$daily_score_done" -eq 0 ] && [ "$score" -ge "$DAILY_SCORE_TARGET" ]; then
        daily_score_done=1
        daily_completed_count=$((daily_completed_count + 1))
        any_completed=1
        printf "  ${COLOR_GREEN}✓ Daily Mission Complete: Score 500 points!${COLOR_NEUTRAL}\n"
    fi

    # Mission 5: Survive 60s in Chaos
    if [ "$daily_chaos_done" -eq 0 ] && [ "$chaos_frames" -ge "$DAILY_CHAOS_TARGET" ]; then
        daily_chaos_done=1
        daily_completed_count=$((daily_completed_count + 1))
        any_completed=1
        printf "  ${COLOR_GREEN}✓ Daily Mission Complete: Survive 60s in Chaos!${COLOR_NEUTRAL}\n"
    fi

    if [ "$any_completed" -eq 1 ]; then
        save_profile
    fi
}

# -----------------------------
# Achievements Page UI
# -----------------------------
show_achievements_page() {
    clear
    printf "${COLOR_YELLOW}╔═══════════════════════════════════════════════════════╗${COLOR_NEUTRAL}\n"
    printf "${COLOR_YELLOW}║${COLOR_NEUTRAL}                    ACHIEVEMENTS                       ${COLOR_YELLOW}║${COLOR_NEUTRAL}\n"
    printf "${COLOR_YELLOW}╚═══════════════════════════════════════════════════════╝${COLOR_NEUTRAL}\n\n"

    local unlocked_count=0
    local i=1
    while [ $i -le 10 ]; do
        if has_achievement "$i"; then
            unlocked_count=$((unlocked_count + 1))
        fi
        i=$((i + 1))
    done
    printf "  ${COLOR_CYAN}Progress: ${unlocked_count}/10 unlocked${COLOR_NEUTRAL}\n\n"

    # 1: First Flight
    if has_achievement 1; then
        printf "  ${COLOR_GREEN}★ [UNLOCKED]${COLOR_NEUTRAL} First Flight - Buy your first ship\n"
    else
        printf "  ${COLOR_WHITE}☆ [LOCKED]${COLOR_NEUTRAL}   First Flight - Buy your first ship\n"
    fi

    # 2: Fashion Statement
    if has_achievement 2; then
        printf "  ${COLOR_GREEN}★ [UNLOCKED]${COLOR_NEUTRAL} Fashion Statement - Buy your first skin\n"
    else
        printf "  ${COLOR_WHITE}☆ [LOCKED]${COLOR_NEUTRAL}   Fashion Statement - Buy your first skin\n"
    fi

    # 3: Crystal Hoarder
    if has_achievement 3; then
        printf "  ${COLOR_GREEN}★ [UNLOCKED]${COLOR_NEUTRAL} Crystal Hoarder - Collect 100 lifetime crystals\n"
    else
        printf "  ${COLOR_WHITE}☆ [LOCKED]${COLOR_NEUTRAL}   Crystal Hoarder - Collect 100 lifetime crystals ${COLOR_CYAN}(${total_crystals}/100)${COLOR_NEUTRAL}\n"
    fi

    # 4: Asteroid Annihilator
    if has_achievement 4; then
        printf "  ${COLOR_GREEN}★ [UNLOCKED]${COLOR_NEUTRAL} Asteroid Annihilator - Destroy 200 lifetime asteroids\n"
    else
        printf "  ${COLOR_WHITE}☆ [LOCKED]${COLOR_NEUTRAL}   Asteroid Annihilator - Destroy 200 lifetime asteroids ${COLOR_CYAN}(${total_asteroids}/200)${COLOR_NEUTRAL}\n"
    fi

    # 5: Combo Master
    if has_achievement 5; then
        printf "  ${COLOR_GREEN}★ [UNLOCKED]${COLOR_NEUTRAL} Combo Master - Achieve a 5x combo streak\n"
    else
        printf "  ${COLOR_WHITE}☆ [LOCKED]${COLOR_NEUTRAL}   Combo Master - Achieve a 5x combo ${COLOR_CYAN}(Best: x${max_combo_ever})${COLOR_NEUTRAL}\n"
    fi

    # 6: Neon Pilot
    if has_achievement 6; then
        printf "  ${COLOR_GREEN}★ [UNLOCKED]${COLOR_NEUTRAL} Neon Pilot - Reach Neon Pilot rank (score >= 280)\n"
    else
        printf "  ${COLOR_WHITE}☆ [LOCKED]${COLOR_NEUTRAL}   Neon Pilot - Reach Neon Pilot rank ${COLOR_CYAN}(Best: ${high_score}/280)${COLOR_NEUTRAL}\n"
    fi

    # 7: Cyber Ace
    if has_achievement 7; then
        printf "  ${COLOR_GREEN}★ [UNLOCKED]${COLOR_NEUTRAL} Cyber Ace - Reach Cyber Ace rank (score >= 550)\n"
    else
        printf "  ${COLOR_WHITE}☆ [LOCKED]${COLOR_NEUTRAL}   Cyber Ace - Reach Cyber Ace rank ${COLOR_CYAN}(Best: ${high_score}/550)${COLOR_NEUTRAL}\n"
    fi

    # 8: Void Admiral
    if has_achievement 8; then
        printf "  ${COLOR_GREEN}★ [UNLOCKED]${COLOR_NEUTRAL} Void Admiral - Reach Void Admiral rank (score >= 1750)\n"
    else
        printf "  ${COLOR_WHITE}☆ [LOCKED]${COLOR_NEUTRAL}   Void Admiral - Reach Void Admiral rank ${COLOR_CYAN}(Best: ${high_score}/1750)${COLOR_NEUTRAL}\n"
    fi

    # 9: Daily Grinder
    if has_achievement 9; then
        printf "  ${COLOR_GREEN}★ [UNLOCKED]${COLOR_NEUTRAL} Daily Grinder - Complete 5 daily missions total\n"
    else
        printf "  ${COLOR_WHITE}☆ [LOCKED]${COLOR_NEUTRAL}   Daily Grinder - Complete 5 daily missions ${COLOR_CYAN}(${daily_completed_count}/5)${COLOR_NEUTRAL}\n"
    fi

    # 10: Marathon Runner
    if has_achievement 10; then
        printf "  ${COLOR_GREEN}★ [UNLOCKED]${COLOR_NEUTRAL} Marathon Runner - Play 20 games\n"
    else
        printf "  ${COLOR_WHITE}☆ [LOCKED]${COLOR_NEUTRAL}   Marathon Runner - Play 20 games ${COLOR_CYAN}(${games_played}/20)${COLOR_NEUTRAL}\n"
    fi

    printf "\n  Press Enter to return..."
    read -r
}

# -----------------------------
# Daily Missions Page UI
# -----------------------------
show_daily_missions_page() {
    clear
    reset_daily_if_needed

    printf "${COLOR_CYAN}╔═══════════════════════════════════════════════════════╗${COLOR_NEUTRAL}\n"
    printf "${COLOR_CYAN}║${COLOR_NEUTRAL}                   DAILY MISSIONS                      ${COLOR_CYAN}║${COLOR_NEUTRAL}\n"
    printf "${COLOR_CYAN}╚═══════════════════════════════════════════════════════╝${COLOR_NEUTRAL}\n\n"

    printf "  ${COLOR_YELLOW}Date: ${daily_date:-Not set}${COLOR_NEUTRAL}\n"
    printf "  ${COLOR_GREEN}Total missions completed: ${daily_completed_count}${COLOR_NEUTRAL}\n\n"

    local bar_width=20
    local filled pct bar

    # Mission 1: Collect 20 crystals (progress from career total as proxy)
    if [ "$daily_crystals_done" -eq 1 ]; then
        printf "  ${COLOR_GREEN}✓${COLOR_NEUTRAL} Collect 20 crystals ${COLOR_GREEN}[COMPLETED]${COLOR_NEUTRAL}\n"
    else
        printf "  ${COLOR_WHITE}○${COLOR_NEUTRAL} Collect 20 crystals - play to track progress!\n"
    fi

    # Mission 2: Destroy 30 asteroids
    if [ "$daily_asteroids_done" -eq 1 ]; then
        printf "  ${COLOR_GREEN}✓${COLOR_NEUTRAL} Destroy 30 asteroids ${COLOR_GREEN}[COMPLETED]${COLOR_NEUTRAL}\n"
    else
        printf "  ${COLOR_WHITE}○${COLOR_NEUTRAL} Destroy 30 asteroids - play to track progress!\n"
    fi

    # Mission 3: 5x combo
    if [ "$daily_combo_done" -eq 1 ]; then
        printf "  ${COLOR_GREEN}✓${COLOR_NEUTRAL} Achieve a 5x combo streak ${COLOR_GREEN}[COMPLETED]${COLOR_NEUTRAL}\n"
    else
        printf "  ${COLOR_WHITE}○${COLOR_NEUTRAL} Achieve a 5x combo streak - play to track progress!\n"
    fi

    # Mission 4: Score 500
    if [ "$daily_score_done" -eq 1 ]; then
        printf "  ${COLOR_GREEN}✓${COLOR_NEUTRAL} Score 500 points in one game ${COLOR_GREEN}[COMPLETED]${COLOR_NEUTRAL}\n"
    else
        printf "  ${COLOR_WHITE}○${COLOR_NEUTRAL} Score 500 points in one game - play to track progress!\n"
    fi

    # Mission 5: Survive 60s in Chaos
    if [ "$daily_chaos_done" -eq 1 ]; then
        printf "  ${COLOR_GREEN}✓${COLOR_NEUTRAL} Survive 60s in Chaos mode ${COLOR_GREEN}[COMPLETED]${COLOR_NEUTRAL}\n"
    else
        printf "  ${COLOR_WHITE}○${COLOR_NEUTRAL} Survive 60s in Chaos mode - play to track progress!\n"
    fi

    printf "\n  ${COLOR_CYAN}Missions reset daily. Progress is tracked per game session.${COLOR_NEUTRAL}\n"
    printf "\n  Press Enter to return..."
    read -r
}

# -----------------------------
# Game Over Mission Progress
# -----------------------------
show_mission_progress() {
    printf "\n${COLOR_CYAN}╔═══════════════════════════════════════════════════════╗${COLOR_NEUTRAL}\n"
    printf "${COLOR_CYAN}║${COLOR_NEUTRAL}              DAILY MISSION PROGRESS                   ${COLOR_CYAN}║${COLOR_NEUTRAL}\n"
    printf "${COLOR_CYAN}╚═══════════════════════════════════════════════════════╝${COLOR_NEUTRAL}\n\n"

    local bar_width=20

    # Mission 1: Crystals
    if [ "$daily_crystals_done" -eq 1 ]; then
        printf "  ${COLOR_GREEN}✓ Collect 20 crystals: DONE${COLOR_NEUTRAL}\n"
    else
        local c_progress=$crystals_collected
        [ "$c_progress" -gt "$DAILY_CRYSTAL_TARGET" ] && c_progress=$DAILY_CRYSTAL_TARGET
        printf "  ${COLOR_WHITE}○ Collect 20 crystals: ${c_progress}/${DAILY_CRYSTAL_TARGET}${COLOR_NEUTRAL}\n"
    fi

    # Mission 2: Asteroids
    if [ "$daily_asteroids_done" -eq 1 ]; then
        printf "  ${COLOR_GREEN}✓ Destroy 30 asteroids: DONE${COLOR_NEUTRAL}\n"
    else
        local a_progress=$asteroids_destroyed
        [ "$a_progress" -gt "$DAILY_ASTEROID_TARGET" ] && a_progress=$DAILY_ASTEROID_TARGET
        printf "  ${COLOR_WHITE}○ Destroy 30 asteroids: ${a_progress}/${DAILY_ASTEROID_TARGET}${COLOR_NEUTRAL}\n"
    fi

    # Mission 3: Combo
    if [ "$daily_combo_done" -eq 1 ]; then
        printf "  ${COLOR_GREEN}✓ 5x combo streak: DONE${COLOR_NEUTRAL}\n"
    else
        local combo_progress=$max_combo_ever
        [ "$combo_progress" -gt "$DAILY_COMBO_TARGET" ] && combo_progress=$DAILY_COMBO_TARGET
        printf "  ${COLOR_WHITE}○ 5x combo streak: x${combo_progress}/${DAILY_COMBO_TARGET}${COLOR_NEUTRAL}\n"
    fi

    # Mission 4: Score
    if [ "$daily_score_done" -eq 1 ]; then
        printf "  ${COLOR_GREEN}✓ Score 500 points: DONE${COLOR_NEUTRAL}\n"
    else
        local s_progress=$score
        [ "$s_progress" -gt "$DAILY_SCORE_TARGET" ] && s_progress=$DAILY_SCORE_TARGET
        printf "  ${COLOR_WHITE}○ Score 500 points: ${s_progress}/${DAILY_SCORE_TARGET}${COLOR_NEUTRAL}\n"
    fi

    # Mission 5: Chaos
    if [ "$daily_chaos_done" -eq 1 ]; then
        printf "  ${COLOR_GREEN}✓ Survive 60s in Chaos: DONE${COLOR_NEUTRAL}\n"
    else
        local ch_progress=$chaos_frames
        [ "$ch_progress" -gt "$DAILY_CHAOS_TARGET" ] && ch_progress=$DAILY_CHAOS_TARGET
        printf "  ${COLOR_WHITE}○ Survive 60s in Chaos: ${ch_progress}/${DAILY_CHAOS_TARGET} frames${COLOR_NEUTRAL}\n"
    fi
}
