#!/bin/bash
# Lab 05 — Script 2: Variables
# Covers: assignment, referencing, command substitution, environment variables, user input.

# --- Static variables ---
NAME="Alice"
AGE=30
echo "Hello, $NAME. You are $AGE years old."

# --- Command substitution ---
TODAY=$(date +%Y-%m-%d)
HOSTNAME_VAL=$(hostname)
echo "Today's date : $TODAY"
echo "Running on   : $HOSTNAME_VAL"

# --- Environment variable ---
export MY_ENV_VAR="I am exported"
echo "MY_ENV_VAR   : $MY_ENV_VAR"

# --- User input ---
echo ""
read -p "Enter your name: " USER_NAME
echo "Welcome, $USER_NAME!"
