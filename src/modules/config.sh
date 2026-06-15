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

# Boss event tuning
BOSS_LEVEL_INTERVAL=3      # Spawn a boss every N levels (3, 6, 9, ...)
BOSS_BASE_HP=8             # Base boss hit points (scales up with level)
BOSS_WIDTH=7               # Boss sprite width in columns (wider than asteroids)
BOSS_MOVE_EVERY=2          # Advance/drift the boss once every N frames
BOSS_REWARD_SCORE=100      # Base score awarded for defeating a boss
BOSS_REWARD_CRYSTALS=5     # Crystals awarded for defeating a boss

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