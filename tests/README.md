# Lab Smoke Tests

Run all lab scripts (Labs 01-16) and store logs/results in this repo.

## Quick Start

```bash
chmod +x tests/run.sh
bash tests/run.sh
```

The command writes output to:

- `tests/output/<timestamp>/summary.txt`
- `tests/output/<timestamp>/summary.tsv`
- `tests/output/<timestamp>/*.log`
- `tests/run_all_labs.log` (single combined console log)

## Useful Options

```bash
# Run a subset
bash tests/run.sh --from 6 --to 10

# Increase per-step timeout
bash tests/run.sh --timeout 300

# Reuse a stable output directory
bash tests/run.sh --output-dir tests/output/latest

# Skip cleanup if you want to inspect resources after run
bash tests/run.sh --skip-cleanup

# Write combined log to a custom file in tests/
bash tests/run.sh --log-file tests/all-labs.log
```

## Direct Commands

```bash
# If you want to run the base runner directly
chmod +x tests/run_all_labs.sh
bash tests/run_all_labs.sh

# Capture all output to one log file inside tests/
bash tests/run_all_labs.sh 2>&1 | tee tests/all-labs.log
```

## Exit Code

- `0` = all executed steps passed
- `1` = one or more steps failed
- `2` = invalid script arguments

## Notes

- The runner auto-creates `exercises/.env` from `exercises/.env.example` if missing.
- Labs that require missing tools (for example Terraform, Docker daemon access, or Kubernetes prerequisites) will fail and be listed under **Failed steps** in `summary.txt`.
