#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXERCISES_DIR="$ROOT_DIR/exercises"
OUT_BASE_DEFAULT="$ROOT_DIR/tests/output"

FROM_LAB=1
TO_LAB=16
STEP_TIMEOUT=240
RUN_CLEANUP=1
OUT_DIR=""

usage() {
  cat <<USAGE
Usage: bash tests/run_all_labs.sh [options]

Options:
  --from N           Start lab number (default: 1)
  --to N             End lab number (default: 16)
  --timeout SEC      Per-script timeout in seconds (default: 240)
  --skip-cleanup     Do not run each lab cleanup.sh
  --output-dir PATH  Output directory for logs and summaries
  -h, --help         Show this help

Examples:
  bash tests/run_all_labs.sh
  bash tests/run_all_labs.sh --from 6 --to 10 --timeout 300
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --from)
      FROM_LAB="$2"; shift 2 ;;
    --to)
      TO_LAB="$2"; shift 2 ;;
    --timeout)
      STEP_TIMEOUT="$2"; shift 2 ;;
    --skip-cleanup)
      RUN_CLEANUP=0; shift ;;
    --output-dir)
      OUT_DIR="$2"; shift 2 ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 2 ;;
  esac
done

if [[ -z "$OUT_DIR" ]]; then
  TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
  OUT_DIR="$OUT_BASE_DEFAULT/$TIMESTAMP"
fi
mkdir -p "$OUT_DIR"

SUMMARY_TSV="$OUT_DIR/summary.tsv"
SUMMARY_TXT="$OUT_DIR/summary.txt"
: > "$SUMMARY_TSV"

if [[ ! -f "$EXERCISES_DIR/.env" ]]; then
  cp "$EXERCISES_DIR/.env.example" "$EXERCISES_DIR/.env"
fi

check_bin() {
  local name="$1"
  if command -v "$name" >/dev/null 2>&1; then
    echo "OK      $name ($(command -v "$name"))"
  else
    echo "MISSING $name"
  fi
}

{
  echo "Lab smoke test started at $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  echo "Range: lab-$(printf '%02d' "$FROM_LAB") to lab-$(printf '%02d' "$TO_LAB")"
  echo "Timeout per script: ${STEP_TIMEOUT}s"
  echo "Run cleanup: $RUN_CLEANUP"
  echo
  echo "Prerequisite binaries:"
  check_bin aws
  check_bin docker
  check_bin localstack
  check_bin terraform
  check_bin ansible-playbook
  check_bin kubectl
  check_bin kind
  check_bin python3
  check_bin mvn
  check_bin gradle
  echo
} | tee "$SUMMARY_TXT"

run_step() {
  local labname="$1"
  local script_path="$2"
  local script_base
  script_base="$(basename "$script_path")"
  local log_file="$OUT_DIR/${labname}__${script_base}.log"

  # Isolate step stdin so scripts that call `read` do not consume our loop input.
  if timeout "$STEP_TIMEOUT" bash "$script_path" </dev/null >"$log_file" 2>&1; then
    echo -e "${labname}\t${script_base}\t0\t${log_file}" >> "$SUMMARY_TSV"
    printf "PASS  %s/%s\n" "$labname" "$script_base" | tee -a "$SUMMARY_TXT"
  else
    local rc=$?
    echo -e "${labname}\t${script_base}\t${rc}\t${log_file}" >> "$SUMMARY_TSV"
    printf "FAIL  %s/%s (rc=%s)\n" "$labname" "$script_base" "$rc" | tee -a "$SUMMARY_TXT"
  fi
}

for lab_num in $(seq "$FROM_LAB" "$TO_LAB"); do
  labname="lab-$(printf '%02d' "$lab_num")"
  lab_dir="$(find "$EXERCISES_DIR" -maxdepth 1 -mindepth 1 -type d -name "${labname}-*" | head -n 1 || true)"

  if [[ -z "$lab_dir" ]]; then
    printf "SKIP  %s (directory not found)\n" "$labname" | tee -a "$SUMMARY_TXT"
    continue
  fi

  scripts_dir="$lab_dir/scripts"
  if [[ ! -d "$scripts_dir" ]]; then
    printf "SKIP  %s (scripts directory missing)\n" "$labname" | tee -a "$SUMMARY_TXT"
    echo -e "${labname}\tNO_SCRIPTS\t125\t-" >> "$SUMMARY_TSV"
    continue
  fi

  printf "\n=== %s ===\n" "$(basename "$lab_dir")" | tee -a "$SUMMARY_TXT"
  while IFS= read -r script_path; do
    run_step "$(basename "$lab_dir")" "$script_path"
  done < <(find "$scripts_dir" -maxdepth 1 -type f -name '[0-9][0-9]-*.sh' | sort)

  if [[ "$RUN_CLEANUP" -eq 1 && -f "$scripts_dir/cleanup.sh" ]]; then
    run_step "$(basename "$lab_dir")" "$scripts_dir/cleanup.sh"
  fi
done

{
  echo
  echo "=== Per-lab summary ==="
  awk -F'\t' '
    {count[$1]++; if($3==0) pass[$1]++; else fail[$1]++}
    END {
      for (lab in count) {
        printf "%s\tsteps=%d\tpass=%d\tfail=%d\n", lab, count[lab], pass[lab]+0, fail[lab]+0
      }
    }
  ' "$SUMMARY_TSV" | sort

  echo
  echo "=== Failed steps ==="
  awk -F'\t' '$3!=0 {printf "%s\t%s\trc=%s\t%s\n", $1, $2, $3, $4}' "$SUMMARY_TSV" | sort
} | tee -a "$SUMMARY_TXT"

FAIL_COUNT="$(awk -F'\t' '$3!=0 {n++} END {print n+0}' "$SUMMARY_TSV")"
echo
echo "Output directory: $OUT_DIR"
echo "Summary TSV:      $SUMMARY_TSV"
echo "Summary text:     $SUMMARY_TXT"

if [[ "$FAIL_COUNT" -gt 0 ]]; then
  exit 1
fi
