#!/usr/bin/env bash

#SYNAPSNEX OSS-Protection License (SOPL) v1.0
#Copyright (c) 2026 Dulsara Pieris

# STAR RUNNER - Keybinds Configuration Module
# Configurable keyboard controls with persistence and conflict detection

KEYBINDS_FILE="$HOME/.star_runner_keybinds"
KEYBINDS_CHECKSUM_FILE="$HOME/.star_runner_keybinds_checksum"

# -------------------------------
# Default keybindings
# Arrow keys: A=Up B=Down C=Right D=Left (terminal escape codes)
# -------------------------------
DEFAULT_KEY_UP="A"
DEFAULT_KEY_DOWN="B"
DEFAULT_KEY_LEFT="D"
DEFAULT_KEY_RIGHT="C"
DEFAULT_KEY_FIRE=" "
DEFAULT_KEY_PAUSE="p"
DEFAULT_KEY_QUIT="q"

# Active keybind variables (set on load)
KEY_UP=""
KEY_DOWN=""
KEY_LEFT=""
KEY_RIGHT=""
KEY_FIRE=""
KEY_PAUSE=""
KEY_QUIT=""

# -------------------------------
# Key display name helpers
# -------------------------------
key_display_name() {
    local k="$1"
    case "$k" in
        A) echo "Up Arrow" ;;
        B) echo "Down Arrow" ;;
        C) echo "Right Arrow" ;;
        D) echo "Left Arrow" ;;
        " ") echo "Space" ;;
        "") echo "(none)" ;;
        *) echo "$k" ;;
    esac
}

# -------------------------------
# Checksum / integrity
# -------------------------------
generate_keybinds_checksum() {
    if [[ -f "$KEYBINDS_FILE" ]]; then
        if command -v sha256sum >/dev/null 2>&1; then
            sha256sum "$KEYBINDS_FILE" | awk '{print $1}'
        elif command -v shasum >/dev/null 2>&1; then
            shasum -a 256 "$KEYBINDS_FILE" | awk '{print $1}'
        else
            md5sum "$KEYBINDS_FILE" | awk '{print $1}'
        fi
    fi
}

verify_keybinds_integrity() {
    [[ ! -f "$KEYBINDS_CHECKSUM_FILE" || ! -f "$KEYBINDS_FILE" ]] && return 1
    [[ "$(generate_keybinds_checksum)" == "$(cat "$KEYBINDS_CHECKSUM_FILE")" ]]
}

# -------------------------------
# Save / Reset
# -------------------------------
save_keybinds() {
    cat > "$KEYBINDS_FILE" << EOF
KEY_UP="$KEY_UP"
KEY_DOWN="$KEY_DOWN"
KEY_LEFT="$KEY_LEFT"
KEY_RIGHT="$KEY_RIGHT"
KEY_FIRE="$KEY_FIRE"
KEY_PAUSE="$KEY_PAUSE"
KEY_QUIT="$KEY_QUIT"
EOF
    echo "$(generate_keybinds_checksum)" > "$KEYBINDS_CHECKSUM_FILE"
    chmod 600 "$KEYBINDS_FILE" "$KEYBINDS_CHECKSUM_FILE" 2>/dev/null
    chown "$USER":"$USER" "$KEYBINDS_FILE" "$KEYBINDS_CHECKSUM_FILE" 2>/dev/null
}

create_new_keybinds() {
    KEY_UP="$DEFAULT_KEY_UP"
    KEY_DOWN="$DEFAULT_KEY_DOWN"
    KEY_LEFT="$DEFAULT_KEY_LEFT"
    KEY_RIGHT="$DEFAULT_KEY_RIGHT"
    KEY_FIRE="$DEFAULT_KEY_FIRE"
    KEY_PAUSE="$DEFAULT_KEY_PAUSE"
    KEY_QUIT="$DEFAULT_KEY_QUIT"
    save_keybinds
}

handle_tampered_keybinds() {
    clear
    printf "${COLOR_RED}+-------------------------------------------------------+${COLOR_NEUTRAL}\n"
    printf "${COLOR_RED}|${COLOR_NEUTRAL}            KEYBINDS INTEGRITY ALERT                    ${COLOR_RED}|${COLOR_NEUTRAL}\n"
    printf "${COLOR_RED}+-------------------------------------------------------+${COLOR_NEUTRAL}\n\n"
    printf "  ${COLOR_YELLOW}Keybinds file was modified externally!${COLOR_NEUTRAL}\n"
    printf "  ${COLOR_CYAN}Resetting to default keybinds...${COLOR_NEUTRAL}\n"
    sleep 3
    create_new_keybinds
    printf "  ${COLOR_GREEN}Keybinds restored to defaults.${COLOR_NEUTRAL}\n"
    sleep 2
}

# -------------------------------
# Load & init
# -------------------------------
load_keybinds() {
    [[ -f "$KEYBINDS_FILE" ]] && . "$KEYBINDS_FILE"

    # Validate: fall back to default for any empty / unset value
    [[ -z "$KEY_UP" ]]    && KEY_UP="$DEFAULT_KEY_UP"
    [[ -z "$KEY_DOWN" ]]  && KEY_DOWN="$DEFAULT_KEY_DOWN"
    [[ -z "$KEY_LEFT" ]]  && KEY_LEFT="$DEFAULT_KEY_LEFT"
    [[ -z "$KEY_RIGHT" ]] && KEY_RIGHT="$DEFAULT_KEY_RIGHT"
    [[ -z "$KEY_FIRE" ]]  && KEY_FIRE="$DEFAULT_KEY_FIRE"
    [[ -z "$KEY_PAUSE" ]] && KEY_PAUSE="$DEFAULT_KEY_PAUSE"
    [[ -z "$KEY_QUIT" ]]  && KEY_QUIT="$DEFAULT_KEY_QUIT"

    # Conflict check: if any two actions share a key, reset all
    local seen=""
    local conflict=0
    local k
    for k in "$KEY_UP" "$KEY_DOWN" "$KEY_LEFT" "$KEY_RIGHT" "$KEY_FIRE" "$KEY_PAUSE" "$KEY_QUIT"; do
        if echo "$seen" | grep -q "|${k}|"; then
            conflict=1
            break
        fi
        seen="${seen}|${k}|"
    done

    if [[ "$conflict" -eq 1 ]]; then
        create_new_keybinds
        load_keybinds
    fi
}

init_keybinds() {
    [[ ! -f "$KEYBINDS_FILE" ]] && create_new_keybinds
    [[ ! -f "$KEYBINDS_CHECKSUM_FILE" ]] && echo "$(generate_keybinds_checksum)" > "$KEYBINDS_CHECKSUM_FILE"

    chmod 600 "$KEYBINDS_FILE" "$KEYBINDS_CHECKSUM_FILE" 2>/dev/null
    chown "$USER":"$USER" "$KEYBINDS_FILE" "$KEYBINDS_CHECKSUM_FILE" 2>/dev/null

    verify_keybinds_integrity || handle_tampered_keybinds
    load_keybinds
}

# -------------------------------
# Controls settings UI
# -------------------------------
show_controls_menu() {
    while true; do
        clear
        printf "${COLOR_CYAN}+-------------------------------------------------------+${COLOR_NEUTRAL}\n"
        printf "${COLOR_CYAN}|${COLOR_NEUTRAL}                 CONTROLS CONFIGURATION                 ${COLOR_CYAN}|${COLOR_NEUTRAL}\n"
        printf "${COLOR_CYAN}+-------------------------------------------------------+${COLOR_NEUTRAL}\n\n"

        printf "  ${COLOR_YELLOW}Current Keybindings:${COLOR_NEUTRAL}\n\n"
        printf "  ${COLOR_GREEN}[1]${COLOR_NEUTRAL} Move Up       : ${COLOR_CYAN}$(key_display_name "$KEY_UP")${COLOR_NEUTRAL}\n"
        printf "  ${COLOR_GREEN}[2]${COLOR_NEUTRAL} Move Down     : ${COLOR_CYAN}$(key_display_name "$KEY_DOWN")${COLOR_NEUTRAL}\n"
        printf "  ${COLOR_GREEN}[3]${COLOR_NEUTRAL} Move Left     : ${COLOR_CYAN}$(key_display_name "$KEY_LEFT")${COLOR_NEUTRAL}\n"
        printf "  ${COLOR_GREEN}[4]${COLOR_NEUTRAL} Move Right    : ${COLOR_CYAN}$(key_display_name "$KEY_RIGHT")${COLOR_NEUTRAL}\n"
        printf "  ${COLOR_GREEN}[5]${COLOR_NEUTRAL} Fire Weapon   : ${COLOR_CYAN}$(key_display_name "$KEY_FIRE")${COLOR_NEUTRAL}\n"
        printf "  ${COLOR_GREEN}[6]${COLOR_NEUTRAL} Pause         : ${COLOR_CYAN}$(key_display_name "$KEY_PAUSE")${COLOR_NEUTRAL}\n"
        printf "  ${COLOR_GREEN}[7]${COLOR_NEUTRAL} Quit Mission  : ${COLOR_CYAN}$(key_display_name "$KEY_QUIT")${COLOR_NEUTRAL}\n\n"
        printf "  ${COLOR_GREEN}[8]${COLOR_NEUTRAL} Reset to Defaults\n"
        printf "  ${COLOR_RED}[9]${COLOR_NEUTRAL} Back\n\n"
        printf "  Select action to rebind: "

        read -r bind_choice

        case "$bind_choice" in
            8)
                create_new_keybinds
                load_keybinds
                printf "\n  ${COLOR_GREEN}All keybinds reset to defaults!${COLOR_NEUTRAL}\n"
                sleep 2
                continue
                ;;
            9)
                return
                ;;
            [1-7])
                # Valid selection — proceed to capture
                ;;
            *)
                continue
                ;;
        esac

        # Map numeric choice to action variable name + label
        local action_var="" action_label=""
        case "$bind_choice" in
            1) action_var="KEY_UP";    action_label="Move Up" ;;
            2) action_var="KEY_DOWN";  action_label="Move Down" ;;
            3) action_var="KEY_LEFT";  action_label="Move Left" ;;
            4) action_var="KEY_RIGHT"; action_label="Move Right" ;;
            5) action_var="KEY_FIRE";  action_label="Fire Weapon" ;;
            6) action_var="KEY_PAUSE"; action_label="Pause" ;;
            7) action_var="KEY_QUIT";  action_label="Quit Mission" ;;
        esac

        clear
        printf "${COLOR_CYAN}+-------------------------------------------------------+${COLOR_NEUTRAL}\n"
        printf "${COLOR_CYAN}|${COLOR_NEUTRAL}               REBIND: ${action_label}${COLOR_NEUTRAL}\n"
        printf "${COLOR_CYAN}+-------------------------------------------------------+${COLOR_NEUTRAL}\n\n"
        printf "  Current key: ${COLOR_YELLOW}$(key_display_name "${!action_var}")${COLOR_NEUTRAL}\n\n"
        printf "  Press the new key for ${COLOR_GREEN}${action_label}${COLOR_NEUTRAL}...\n"
        printf "  ${COLOR_YELLOW}(ESC to cancel)${COLOR_NEUTRAL}\n"

        # Temporarily switch terminal to raw mode for single-keystroke capture
        local saved_stty
        saved_stty=$(stty -g 2>/dev/null)
        stty -icanon -echo min 1 time 0 2>/dev/null

        local new_key=""
        read_chars new_key 1
        if [ "$new_key" = "$ESCAPE_CHAR" ]; then
            read_chars new_key 2
            new_key="${new_key##*[}"
        fi

        # Restore terminal
        if [[ -n "$saved_stty" ]]; then
            stty "$saved_stty" 2>/dev/null
        else
            stty icanon echo 2>/dev/null
        fi

        # ESC with no continuation means user cancelled
        if [[ -z "$new_key" ]]; then
            printf "\n  ${COLOR_YELLOW}Cancelled.${COLOR_NEUTRAL}\n"
            sleep 1
            continue
        fi

        # Same key — no change
        if [[ "$new_key" == "${!action_var}" ]]; then
            printf "\n  ${COLOR_YELLOW}Key unchanged.${COLOR_NEUTRAL}\n"
            sleep 1
            continue
        fi

        # Conflict detection: is this key already bound to another action?
        local conflict_action=""
        local check_var check_label
        for check_var in KEY_UP KEY_DOWN KEY_LEFT KEY_RIGHT KEY_FIRE KEY_PAUSE KEY_QUIT; do
            [[ "$check_var" == "$action_var" ]] && continue
            if [[ "${!check_var}" == "$new_key" ]]; then
                case "$check_var" in
                    KEY_UP)    conflict_action="Move Up" ;;
                    KEY_DOWN)  conflict_action="Move Down" ;;
                    KEY_LEFT)  conflict_action="Move Left" ;;
                    KEY_RIGHT) conflict_action="Move Right" ;;
                    KEY_FIRE)  conflict_action="Fire Weapon" ;;
                    KEY_PAUSE) conflict_action="Pause" ;;
                    KEY_QUIT)  conflict_action="Quit Mission" ;;
                esac
                break
            fi
        done

        if [[ -n "$conflict_action" ]]; then
            printf "\n  ${COLOR_RED}CONFLICT: '$(key_display_name "$new_key")' is already bound to '${conflict_action}'!${COLOR_NEUTRAL}\n"
            printf "  ${COLOR_YELLOW}Swap bindings? (y/n): ${COLOR_NEUTRAL}"
            read -r swap_confirm
            if [[ "$swap_confirm" == "y" || "$swap_confirm" == "Y" ]]; then
                # Swap: the conflicting action gets the old key of the action being rebound
                local old_key="${!action_var}"
                eval "${check_var}=\"${old_key}\""
            else
                printf "  ${COLOR_YELLOW}Binding cancelled.${COLOR_NEUTRAL}\n"
                sleep 1
                continue
            fi
        fi

        # Apply the new binding
        eval "${action_var}=\"\${new_key}\""
        save_keybinds

        printf "\n  ${COLOR_GREEN}$(printf '%s' "$action_label") is now bound to: $(key_display_name "$new_key")${COLOR_NEUTRAL}\n"
        sleep 2
    done
}

# -------------------------------
# Auto-initialize on source
# -------------------------------
init_keybinds
