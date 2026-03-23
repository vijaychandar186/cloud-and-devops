#!/bin/bash
# Lab 05 — Script 3: Redirection and Pipes
# Covers: >, >>, 2>, 2>&1, pipes, and stdin redirection.

WORKDIR=$(mktemp -d)
echo "Working in: $WORKDIR"
echo ""

# --- stdout redirect (overwrite) ---
echo "first line" > "$WORKDIR/output.txt"
echo "==> Wrote 'first line' to output.txt"
cat "$WORKDIR/output.txt"

# --- stdout redirect (append) ---
echo "second line" >> "$WORKDIR/output.txt"
echo "==> Appended 'second line' to output.txt"
cat "$WORKDIR/output.txt"

# --- stderr redirect ---
ls /nonexistent_path 2> "$WORKDIR/errors.txt"
echo ""
echo "==> Captured stderr:"
cat "$WORKDIR/errors.txt"

# --- stdout + stderr to same file ---
{ echo "stdout message"; ls /another_bad_path; } > "$WORKDIR/all.txt" 2>&1
echo ""
echo "==> stdout + stderr combined:"
cat "$WORKDIR/all.txt"

# --- stdin redirection ---
echo -e "banana\napple\ncherry" > "$WORKDIR/fruits.txt"
echo ""
echo "==> Sorted using stdin redirect:"
sort < "$WORKDIR/fruits.txt"

# --- pipes ---
echo ""
echo "==> Users with /bin/bash (pipe example):"
cat /etc/passwd | grep "/bin/bash" | cut -d: -f1

# cleanup
rm -rf "$WORKDIR"
echo ""
echo "Done."
