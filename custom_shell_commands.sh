# Custom Shell Commands for jplwunder
# ----------------------------------

### STARTUP CONFIGURATION ###

load_env() {
    if [ -f .env ]; then
        set -a
        source .env
        set +a
    fi
}
load_env

### ALIASES AND FUNCTIONS ###

# Git Aliases
alias gs='git status'
alias gsh='git stash'
alias gsw='git switch'
alias gps='git push'
alias gpl='git pull'
alias gcm='git commit -m'
alias gco='git checkout'
alias ga='git add'
alias gb='git branch'
alias gd='git diff'
alias gwt='git worktree'

# Other aliases
alias add_commit='ga . && commit'
alias commit='python3 ~/Documents/Coding/jplwunder/ai_commit.py'

# Fancy greetings with colors
greeting_time() {
    local hour
    hour=$(date +%H)
    if (( hour < 12 )); then
        echo "morning"
    elif (( hour < 18 )); then
        echo "afternoon"
    else
        echo "evening"
    fi
}
greeting_emoji() {
    local hour
    hour=$(date +%H)
    if (( hour < 12 )); then
        echo "🌤️"
    elif (( hour < 18 )); then
        echo "☀️"
    else
        echo "🌙"
    fi
}
greetings() {
    local COLOR_GREEN="\033[0;32m"
    local COLOR_BLUE="\033[0;34m"
    local COLOR_RESET="\033[0m"
    echo -e "${COLOR_BLUE}Good $(greeting_time), jplwunder! $(greeting_emoji)${COLOR_RESET}"
}

# Normandy Repo Section
NORMANDY_DIR="$HOME/Commure/repos/normandy"
VENV_DIR="$PWD/.venv"
SHORTCUTS_FILE="$PWD/shortcuts.sh"

activate_normandy() {
    if [ -d "$VENV_DIR" ] && [ -f "$SHORTCUTS_FILE" ]; then
        source "$VENV_DIR/bin/activate"
        source "$SHORTCUTS_FILE"
        echo "Normandy environment activated."
        echo ""
        normandy_commands
    else
        echo "Normandy environment or shortcuts not found."
        echo ""
    fi
}

copy_code_config() {
    local SOURCE_DIR="$NORMANDY_DIR/code-config"
    local TARGET_BASE="$NORMANDY_DIR/code"
    
    if [ ! -d "$SOURCE_DIR" ]; then
        echo "Error: code-config directory not found at $SOURCE_DIR"
        return 1
    fi
    
    if [ ! -d "$TARGET_BASE" ]; then
        echo "Error: code directory not found at $TARGET_BASE"
        return 1
    fi
    
    echo "Copying contents of code-config to all directories in $TARGET_BASE..."
    echo ""
    
    local total_copies=0
    local target_dirs=()
    
    # First, collect all target directories
    for dir in "$TARGET_BASE"/*; do
        if [ -d "$dir" ]; then
            target_dirs+=("$dir")
        fi
    done
    
    if [ ${#target_dirs[@]} -eq 0 ]; then
        echo "No directories found in $TARGET_BASE"
        return 1
    fi
    
    # Then, iterate through SOURCE_DIR contents and copy to each target
    # Use find to safely handle empty directories and hidden files
    while IFS= read -r item; do
        # Skip . and .. entries
        if [ "$(basename "$item")" = "." ] || [ "$(basename "$item")" = ".." ]; then
            continue
        fi
        
        local itemname=$(basename "$item")
        echo "Copying: $itemname"
        
        for dir in "${target_dirs[@]}"; do
            local dirname=$(basename "$dir")
            cp -r "$item" "$dir/"
            if [ $? -eq 0 ]; then
                ((total_copies++))
                echo "  ✓ Copied to $dirname"
            else
                echo "  ✗ Failed to copy to $dirname"
            fi
        done
        echo ""
    done < <(find "$SOURCE_DIR" -mindepth 1 -maxdepth 1)
    
    echo "Completed: Copied contents to ${#target_dirs[@]} directory(ies) ($total_copies total copies)"
}

normandy_commands() {
    alias gla='git_lint_add'
    alias add_commit='gla . && commit'
    echo "Normandy Repo Commands:"
    echo "  activate_normandy : Activate Normandy virtual environment and shortcuts"
    echo "  gla : git_lint_add"
    echo "  copy_code_config : Copy code-config folder to all directories in code/"
    echo ""
}

### COMMAND LIST / HELP SECTION ###

# Command list/help
personal_commands() {
    local short_mode=0
    for arg in "$@"; do
        case "$arg" in
            --short) short_mode=1 ;;
        esac
    done

    if [[ $short_mode -eq 1 ]]; then
        echo "Custom aliases: gs, gsh, gsw, gps, gpl, gcm, gco, ga, gb, gd, gwt"
        return
    else 
        echo "Custom Aliases:"
        echo "  gs   : git status"
        echo "  gsh  : git stash"
        echo "  gsw  : git switch"
        echo "  gps  : git push"
        echo "  gpl  : git pull"
        echo "  gcm  : git commit -m"
        echo "  gco  : git checkout"
        echo "  ga   : git add"
        echo "  gb   : git branch"
        echo "  gd   : git diff"
        echo "  gwt  : git worktree"
        echo ""
    fi

    # Only show Normandy commands if PWD begins with NORMANDY_DIR
    if [[ "$PWD" == "${NORMANDY_DIR}"* ]]; then
        activate_normandy;
        normandy_commands
    fi
}

### STARTUP SEQUENCE ###

# Startup greetings and command list
echo "" >&2
greetings >&2
echo "" >&2
personal_commands --short >&2
echo "" >&2

# Auto-activate Normandy if in project directory
if [[ "$PWD" == "${NORMANDY_DIR}"* ]]; then
    activate_normandy >&2;
fi