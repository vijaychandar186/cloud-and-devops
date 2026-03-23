#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Lab 13 — Script 01: Install CI/CD Tools
# Installs Java 17, Maven, and Gradle if not already present
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
    echo ">>> $1"
}

# ------------------------------------------------------------------------------
# Java 17
# ------------------------------------------------------------------------------
print_header "Step 1: Java 17"

if command -v java &>/dev/null; then
    echo "Java is already installed:"
    java -version
else
    print_step "Java not found — installing openjdk-17-jdk via apt"
    sudo apt-get update -q
    sudo apt-get install -y openjdk-17-jdk
    echo "Java installed:"
    java -version
fi

JAVA_VERSION=$(java -version 2>&1 | head -1)
echo "  => $JAVA_VERSION"

# ------------------------------------------------------------------------------
# Maven
# ------------------------------------------------------------------------------
print_header "Step 2: Maven"

if command -v mvn &>/dev/null; then
    echo "Maven is already installed:"
    mvn --version
else
    print_step "Maven not found — installing via apt"
    sudo apt-get update -q
    sudo apt-get install -y maven
    echo "Maven installed:"
    mvn --version
fi

MVN_VERSION=$(mvn --version 2>&1 | head -1)
echo "  => $MVN_VERSION"

# ------------------------------------------------------------------------------
# Gradle
# ------------------------------------------------------------------------------
print_header "Step 3: Gradle"

if command -v gradle &>/dev/null; then
    echo "Gradle is already installed:"
    gradle --version
else
    print_step "Gradle not found — attempting apt install"
    sudo apt-get update -q
    sudo apt-get install -y gradle || {
        echo "apt install failed or unavailable — falling back to direct binary download (Gradle 8.5)"
        curl -sL https://services.gradle.org/distributions/gradle-8.5-bin.zip -o /tmp/gradle.zip
        sudo unzip -q /tmp/gradle.zip -d /opt
        sudo ln -sf /opt/gradle-8.5/bin/gradle /usr/local/bin/gradle
        rm /tmp/gradle.zip
        echo "Gradle 8.5 installed to /usr/local/bin/gradle"
    }
    echo "Gradle installed:"
    gradle --version
fi

GRADLE_VERSION=$(gradle --version 2>&1 | grep "^Gradle" | head -1)
echo "  => $GRADLE_VERSION"

# ------------------------------------------------------------------------------
# Git (usually pre-installed; included for completeness)
# ------------------------------------------------------------------------------
print_header "Step 4: Git"

if command -v git &>/dev/null; then
    echo "Git is already installed:"
    git --version
else
    print_step "Git not found — installing via apt"
    sudo apt-get update -q
    sudo apt-get install -y git
    echo "Git installed:"
    git --version
fi

GIT_VERSION=$(git --version)
echo "  => $GIT_VERSION"

# ------------------------------------------------------------------------------
# Summary table
# ------------------------------------------------------------------------------
print_header "Installation Summary"

printf "  %-12s  %-50s\n" "TOOL" "VERSION"
printf "  %-12s  %-50s\n" "------------" "--------------------------------------------------"
printf "  %-12s  %-50s\n" "git"    "$GIT_VERSION"
printf "  %-12s  %-50s\n" "java"   "$JAVA_VERSION"
printf "  %-12s  %-50s\n" "maven"  "$MVN_VERSION"
printf "  %-12s  %-50s\n" "gradle" "$GRADLE_VERSION"

echo ""
echo "All required CI/CD tools are installed and ready."
echo ""
