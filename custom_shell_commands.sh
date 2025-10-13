# Custom Shell Commands for jplwunder
# ----------------------------------

### STARTUP CONFIGURATION ###

if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

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
    local COLOR_RESET="\033[0m"
    echo -e "${COLOR_GREEN}Good $(greeting_time), jplwunder! $(greeting_emoji)${COLOR_RESET}"
}

# Normandy Repo Section
NORMANDY_DIR="$HOME/Commure/normandy"
NORMANDY_VENV="$NORMANDY_DIR/.venv"
NORMANDY_SHORTCUTS="$NORMANDY_DIR/shortcuts.sh"

activate_normandy() {
    if [ -d "$NORMANDY_VENV" ] && [ -f "$NORMANDY_SHORTCUTS" ]; then
        source "$NORMANDY_VENV/bin/activate"
        source "$NORMANDY_SHORTCUTS"
        echo "Normandy environment activated."
        echo ""
        normandy_commands
    else
        echo "Normandy environment or shortcuts not found."
        echo ""
    fi
}

normandy_commands() {
    echo "Normandy Repo Commands:"
    echo "  activate_normandy : Activate Normandy virtual environment and shortcuts"
    echo "  gla : git_lint_add"
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
        echo "Custom aliases: gs, gsh, gsw, gps, gpl, gcm, gco, ga, gb, gd"
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
        echo ""
    fi
    return

    # Only show Normandy commands if in Normandy dir
    if [[ "$PWD" == "$NORMANDY_DIR" ]]; then
        normandy_commands
    fi
}

### STARTUP SEQUENCE ###

# Startup greetings and command list
echo ""
greetings
echo ""
personal_commands --short
echo ""

# Auto-activate Normandy if in project directory
if [[ "$PWD" == "$NORMANDY_DIR" ]]; then
    alias gla='git_lint_add'
    activate_normandy
fi