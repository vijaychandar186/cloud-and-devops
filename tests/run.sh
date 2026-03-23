#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNNER="$ROOT_DIR/tests/run_all_labs.sh"
LOG_FILE="$ROOT_DIR/tests/run_all_labs.log"

ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --log-file)
      LOG_FILE="$2"
      shift 2
      ;;
    *)
      ARGS+=("$1")
      shift
      ;;
  esac
done

chmod +x "$RUNNER"

echo "Runner:   $RUNNER"
echo "Log file: $LOG_FILE"

set +e
bash "$RUNNER" "${ARGS[@]}" 2>&1 | tee "$LOG_FILE"
rc=${PIPESTATUS[0]}
set -e

exit "$rc"
