#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Lab 13 — Script 02: Git Workflow Demo
# Demonstrates core Git operations in a temporary repository
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ------------------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------------------
print_header() {
    echo ""
    echo "============================================================"
    echo "  $1"
    echo "============================================================"
}

print_step() {
    echo ""
    echo "--- $1 ---"
}

# Create a temp directory for all git operations; clean up on exit
DEMO_DIR=$(mktemp -d)
trap 'echo ""; echo "Cleaning up temp directory: $DEMO_DIR"; rm -rf "$DEMO_DIR"' EXIT

echo "Using temporary directory: $DEMO_DIR"

# ------------------------------------------------------------------------------
# Step 1: Check Git version
# ------------------------------------------------------------------------------
print_header "Step 1: Verify Git Installation"

print_step "Command: git --version"
echo "Git is the industry-standard distributed version control system."
git --version

# ------------------------------------------------------------------------------
# Step 2: Configure Git identity (local to the demo repo)
# ------------------------------------------------------------------------------
print_header "Step 2: Configure Git Identity"

print_step "Commands: git config user.name / git config user.email"
echo "Git requires a name and email for every commit."
echo "Using --local scopes configuration to this repository only."

# Initialize repo first so --local config works
cd "$DEMO_DIR"
git init .

git config --local user.name  "Lab13 Demo"
git config --local user.email "lab13@example.com"

echo ""
echo "Local git config applied:"
git config --local --list | grep user

# ------------------------------------------------------------------------------
# Step 3: git init
# ------------------------------------------------------------------------------
print_header "Step 3: Initialize Repository"

print_step "Result: git init created a .git directory"
echo "The .git directory holds all version history, branches, and metadata."
ls -la "$DEMO_DIR"

# ------------------------------------------------------------------------------
# Step 4: First commit
# ------------------------------------------------------------------------------
print_header "Step 4: First Commit"

print_step "Create hello.txt and commit"
echo "git add stages changes to the index (staging area)."
echo "git commit records the staged snapshot permanently."

cat > hello.txt <<'EOF'
Hello from Lab 13!
This is our first tracked file.
EOF

git add .
git commit -m "Initial commit: add hello.txt"
echo ""
echo "Committed successfully."

# ------------------------------------------------------------------------------
# Step 5: Second commit
# ------------------------------------------------------------------------------
print_header "Step 5: Second Commit"

print_step "Create notes.txt and commit"

cat > notes.txt <<'EOF'
CI/CD tool notes:
- Git:     version control
- Maven:   Java build tool (convention-based)
- Gradle:  Java build tool (script-based)
- Jenkins: automation server / CI/CD orchestration
EOF

git add .
git commit -m "Add notes.txt with CI/CD tool overview"
echo ""
echo "Second commit recorded."

# ------------------------------------------------------------------------------
# Step 6: git log --oneline
# ------------------------------------------------------------------------------
print_header "Step 6: View Commit History"

print_step "Command: git log --oneline"
echo "Each line shows: <short-hash> <commit-message>"
git log --oneline

# ------------------------------------------------------------------------------
# Step 7: Create a feature branch
# ------------------------------------------------------------------------------
print_header "Step 7: Create a Feature Branch"

print_step "Command: git branch feature/greeting"
echo "Branches let you work in isolation without affecting the main line."
git branch feature/greeting
echo ""
echo "Branches:"
git branch

# ------------------------------------------------------------------------------
# Step 8: Switch to the feature branch
# ------------------------------------------------------------------------------
print_header "Step 8: Switch to Feature Branch"

print_step "Command: git checkout feature/greeting"
git checkout feature/greeting
echo ""
echo "Current branch:"
git branch

# ------------------------------------------------------------------------------
# Step 9: Commit on the feature branch
# ------------------------------------------------------------------------------
print_header "Step 9: Commit on Feature Branch"

print_step "Add greeting.txt and commit on feature/greeting"

cat > greeting.txt <<'EOF'
Greetings from the feature branch!
This change was made independently of main.
EOF

git add .
git commit -m "Add greeting.txt on feature branch"
echo ""
echo "Feature branch history:"
git log --oneline

# ------------------------------------------------------------------------------
# Step 10: Switch back to main/master
# ------------------------------------------------------------------------------
print_header "Step 10: Switch Back to Main Branch"

# Detect whether the default branch is 'main' or 'master'
DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || true)
if [ -z "$DEFAULT_BRANCH" ]; then
    # Fall back: check locally
    if git rev-parse --verify main &>/dev/null; then
        DEFAULT_BRANCH="main"
    else
        DEFAULT_BRANCH="master"
    fi
fi

print_step "Command: git checkout $DEFAULT_BRANCH"
git checkout "$DEFAULT_BRANCH"
echo ""
echo "Back on: $(git branch --show-current)"

# ------------------------------------------------------------------------------
# Step 11: Merge the feature branch
# ------------------------------------------------------------------------------
print_header "Step 11: Merge Feature Branch"

print_step "Command: git merge feature/greeting"
echo "Merging integrates the feature branch commits into the main branch."
git merge feature/greeting --no-edit
echo ""
echo "Merge complete."

# ------------------------------------------------------------------------------
# Step 12: Show commit graph
# ------------------------------------------------------------------------------
print_header "Step 12: Commit Graph"

print_step "Command: git log --oneline --graph --all"
echo "The graph shows how branches diverged and merged over time."
git log --oneline --graph --all

# ------------------------------------------------------------------------------
# Reference table
# ------------------------------------------------------------------------------
print_header "Git Quick Reference"

echo ""
printf "  %-35s  %s\n" "COMMAND" "PURPOSE"
printf "  %-35s  %s\n" "-----------------------------------" "----------------------------------------------"
printf "  %-35s  %s\n" "git init"                        "Initialize a new local repository"
printf "  %-35s  %s\n" "git clone <url>"                 "Copy a remote repository locally"
printf "  %-35s  %s\n" "git status"                      "Show working tree and staging area status"
printf "  %-35s  %s\n" "git add <file>"                  "Stage a file for the next commit"
printf "  %-35s  %s\n" "git add ."                       "Stage all changes in the current directory"
printf "  %-35s  %s\n" "git commit -m '<msg>'"           "Record staged snapshot with a message"
printf "  %-35s  %s\n" "git log --oneline --graph"       "Compact, visual commit history"
printf "  %-35s  %s\n" "git branch <name>"               "Create a new branch"
printf "  %-35s  %s\n" "git checkout <branch>"           "Switch to a branch"
printf "  %-35s  %s\n" "git merge <branch>"              "Merge named branch into current branch"
printf "  %-35s  %s\n" "git pull"                        "Fetch and merge from tracked remote"
printf "  %-35s  %s\n" "git push"                        "Upload local commits to remote"
printf "  %-35s  %s\n" "git diff"                        "Show unstaged changes"
printf "  %-35s  %s\n" "git stash"                       "Temporarily shelve uncommitted changes"
printf "  %-35s  %s\n" "git tag <name>"                  "Mark a specific commit with a label"

echo ""
echo "Git demo complete. Temporary directory will be cleaned up now."
echo ""
