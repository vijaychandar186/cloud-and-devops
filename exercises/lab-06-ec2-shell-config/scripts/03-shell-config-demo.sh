#!/bin/bash
# Lab 06 — Script 3: Shell configuration best practices demo
# Runs locally to demonstrate .bashrc, aliases, PS1, and PATH customisation.

echo "=========================================="
echo " Lab 06 — Shell Configuration Demo"
echo "=========================================="

DEMO_HOME=$(mktemp -d)
DEMO_BASHRC="$DEMO_HOME/.bashrc"

# -----------------------------------------------------------
echo ""
echo "==> Writing a sample .bashrc to $DEMO_BASHRC ..."
cat > "$DEMO_BASHRC" <<'EOF'
# -----------------------------------------------
# Sample .bashrc — applied to every interactive shell
# -----------------------------------------------

# Aliases
alias ll='ls -lah'
alias grep='grep --color=auto'
alias ..='cd ..'
alias df='df -h'
alias free='free -h'
alias ports='ss -tulnp'

# Custom prompt: green user@host, blue path
export PS1='\[\e[32m\]\u@\h\[\e[0m\]:\[\e[34m\]\w\[\e[0m\]\$ '

# History settings
export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTCONTROL=ignoredups:erasedups

# Default editor
export EDITOR=nano

# Extend PATH (e.g. for user-installed binaries)
export PATH="$HOME/.local/bin:$PATH"
EOF

echo ""
echo "--- Contents of .bashrc ---"
cat "$DEMO_BASHRC"

# -----------------------------------------------------------
echo ""
echo "==> Loading config and checking active aliases..."
# Source into a subshell so we don't pollute the current environment
bash --rcfile "$DEMO_BASHRC" -i <<'SUBSHELL' 2>/dev/null
echo ""
echo "--- Active aliases (from sourced .bashrc) ---"
alias
echo ""
echo "--- PS1 value ---"
echo "$PS1"
echo ""
echo "--- EDITOR ---"
echo "$EDITOR"
echo ""
echo "--- HISTSIZE ---"
echo "$HISTSIZE"
SUBSHELL

# -----------------------------------------------------------
echo ""
echo "==> Key shell config files and when they run:"
echo ""
printf "  %-22s  %s\n" "File" "When it runs"
printf "  %-22s  %s\n" "----" "------------"
printf "  %-22s  %s\n" "~/.bashrc"        "Every interactive non-login shell (new terminal tabs)"
printf "  %-22s  %s\n" "~/.bash_profile"  "Login shell only (SSH sessions, console login)"
printf "  %-22s  %s\n" "~/.bash_logout"   "On logout"
printf "  %-22s  %s\n" "/etc/bash.bashrc" "System-wide, all users"
printf "  %-22s  %s\n" "/etc/profile"     "System-wide login shells"

rm -rf "$DEMO_HOME"

echo ""
echo "==> Done."
echo ""
echo "    To apply changes to your current shell after editing .bashrc:"
echo "    source ~/.bashrc"
