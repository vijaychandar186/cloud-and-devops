#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$SCRIPT_DIR/../app"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Track stage timing and status
declare -a STAGE_NAMES=()
declare -a STAGE_STATUSES=()
declare -a STAGE_TIMES=()

stage_banner() {
    local name="$1"
    echo ""
    echo "┌─────────────────────────────────────────────┐"
    printf  "│  STAGE: %-36s│\n" "$name"
    echo "└─────────────────────────────────────────────┘"
    echo ""
}

run_stage() {
    local name="$1"
    shift
    stage_banner "$name"
    local start
    start=$(date +%s)
    local status="PASSED"
    "$@" || status="FAILED"
    local end
    end=$(date +%s)
    local elapsed=$(( end - start ))
    STAGE_NAMES+=("$name")
    STAGE_STATUSES+=("$status")
    STAGE_TIMES+=("${elapsed}s")
    if [[ "$status" == "FAILED" ]]; then
        echo ""
        echo "ERROR: Stage '$name' failed. Aborting pipeline." >&2
        print_summary
        exit 1
    fi
}

print_summary() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║                  Pipeline Summary                        ║"
    echo "╠══════════════════════════╦══════════╦════════════════════╣"
    printf "║ %-24s ║ %-8s ║ %-18s ║\n" "STAGE" "STATUS" "TIME"
    echo "╠══════════════════════════╬══════════╬════════════════════╣"
    for i in "${!STAGE_NAMES[@]}"; do
        printf "║ %-24s ║ %-8s ║ %-18s ║\n" \
            "${STAGE_NAMES[$i]}" "${STAGE_STATUSES[$i]}" "${STAGE_TIMES[$i]}"
    done
    echo "╚══════════════════════════╩══════════╩════════════════════╝"
    echo ""
}

# ---------------------------------------------------------------------------
# Main banner
# ---------------------------------------------------------------------------

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║  Lab 14 — DevOps Pipeline                ║"
echo "║  Stages: Test → Build → Smoke → Deploy   ║"
echo "╚══════════════════════════════════════════╝"
echo ""
echo "Working directory : $SCRIPT_DIR"
echo "App directory     : $APP_DIR"
echo ""

# ---------------------------------------------------------------------------
# Stage 1: Checkout
# ---------------------------------------------------------------------------

run_stage "Checkout" bash -c '
    echo "Source code already in working directory (simulating git checkout)."
    echo ""
    echo "In a real Jenkins pipeline the '"'"'checkout scm'"'"' step would clone"
    echo "or update the repository from the configured SCM URL before any"
    echo "other stage runs."
'

# ---------------------------------------------------------------------------
# Stage 2: Test
# ---------------------------------------------------------------------------

run_stage "Test" bash -c "
    cd \"$APP_DIR\"
    python3 -m unittest test_server -v
"

# ---------------------------------------------------------------------------
# Stage 3: Build
# ---------------------------------------------------------------------------

run_stage "Build" bash -c "
    docker build -t lab14-server:latest \"$APP_DIR\"
    echo ''
    echo 'Image built successfully:'
    docker images lab14-server --format 'table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}'
"

# ---------------------------------------------------------------------------
# Stage 4: Smoke Test
# ---------------------------------------------------------------------------

run_stage "Smoke Test" bash -c '
    # Clean up any leftover container from a previous run
    docker stop lab14-smoke 2>/dev/null || true
    docker rm   lab14-smoke 2>/dev/null || true

    echo "Starting smoke-test container on port 18888..."
    docker run -d --name lab14-smoke -p 18888:8888 lab14-server:latest

    echo "Waiting for server to be ready..."
    sleep 2

    echo "Probing /health endpoint..."
    RESPONSE=$(curl -sf http://localhost:18888/health)
    echo "Response: $RESPONSE"

    docker stop lab14-smoke && docker rm lab14-smoke
    echo "Smoke test container removed."
'

# ---------------------------------------------------------------------------
# Stage 5: Deploy
# ---------------------------------------------------------------------------

run_stage "Deploy" bash -c '
    echo "Stopping any existing lab14-server container..."
    docker stop lab14-server 2>/dev/null || true
    docker rm   lab14-server 2>/dev/null || true

    echo "Starting new lab14-server container on port 8888..."
    docker run -d --name lab14-server -p 8888:8888 lab14-server:latest

    echo ""
    echo "Application deployed and running at http://localhost:8888"
    echo "Health endpoint : http://localhost:8888/health"
'

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

print_summary
echo "Pipeline complete. Run scripts/04-verify.sh to confirm the deployment."
