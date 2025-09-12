# Custom commands
alias gs='git status'
alias gsw='git switch'
alias gp='git push'
alias gpl='git pull'
alias gc='git commit -m'
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

commands_info() {
echo "Custom aliases: gs, gsw, gp, gpl, gc, gla"
echo "Activate Normandy environment with: activate_normandy"
}
