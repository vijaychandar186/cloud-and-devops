#!/bin/bash
# Lab 05 — Script 5: Palindrome checker
# Covers: conditionals, string manipulation.

read -p "Enter a string: " string

reverse=$(echo "$string" | rev)

if [ "$string" = "$reverse" ]; then
  echo "The string is a palindrome"
else
  echo "The string is not a palindrome"
fi
