# Custom commands
alias gs='git status'
alias gsh='git stash'
alias gsw='git switch'
alias gps='git push'
alias gpl='git pull'
alias gcm='git commit -m'
alias gla='git_lint_add'
alias activate_normandy='source /Users/jplwunder/Commure/normandy/.venv/bin/activate && source /Users/jplwunder/Commure/normandy/shortcuts.sh'

# Custom Greetings
greeting_time() {
    local hour=$(date +%H)
    if (( hour < 12 )); then
        echo "morning"
    elif (( hour < 18 )); then
        echo "afternoon"
    else
        echo "evening"
    fi
}
greeting_emoji() {
    local hour=$(date +%H)
    if (( hour < 12 )); then
        echo "🌤️"
    elif (( hour < 18 )); then
        echo "☀️"
    else
        echo "🌙"
    fi
}

greetings() {
echo "Good $(greeting_time), jplwunder! $(greeting_emoji)"
}

# Custom commands
personal_commands() {
    local short_mode=0
    for arg in "$@"; do
        case "$arg" in
            --short)
                short_mode=1
                ;;
        esac
    done

    if [[ $short_mode -eq 1 ]]; then
        echo "Custom aliases: gs, gsh, gsw, gps, gpl, gcm, gla"
        echo "Custom commands: activate_normandy"
        return
    else 
        echo ""
        echo "Custom Aliases:"
        echo "  gs   : git status"
        echo "  gsh   : git stash"
        echo "  gsw  : git switch"
        echo "  gps  : git push"
        echo "  gpl  : git pull"
        echo "  gcm  : git commit -m"
        echo "  gla  : git_lint_add"
        echo ""
        echo "Custom Commands:"
        echo "  activate_normandy : Activate Normandy virtual environment and shortcuts"
        echo ""
    fi
    return
}

# Commure Normandy auto-activate
if [[ "$PWD" == "/Users/jplwunder/Commure/normandy" ]]; then
    activate_normandy
fi

# Startup greetings and command list
echo ""
greetings
echo ""
personal_commands --short
echo ""