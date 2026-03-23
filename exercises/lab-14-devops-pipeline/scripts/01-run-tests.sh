#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$SCRIPT_DIR/../app"

echo "=== Stage: Test ==="
echo ""
echo "Running unit tests for the Lab 14 server application..."
echo ""

cd "$APP_DIR"

python3 -m unittest test_server -v

echo ""
echo "---------------------------------------"
echo "Test stage complete. All tests passed."
echo "---------------------------------------"
echo ""
echo "In a real CI system (e.g. Jenkins, GitHub Actions, GitLab CI) this"
echo "stage runs automatically on every push to the repository. If any test"
echo "fails the pipeline is aborted immediately, preventing broken code from"
echo "being built or deployed."
