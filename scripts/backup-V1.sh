#!/usr/bin/env bash

# --- Config ---
SRC="/volume1/vol1/share"
DST="/mnt/@usb/sde1"
LOG_DIR="/volume3/vol3/backupjobs/logs"

usage() {
  cat <<'USAGE'
Usage: backup.sh [--dry | --do] [--copy | --move] [--] [extra rclone flags]

Options:
  --dry    Use rclone dry-run (default)
  --do     Perform actual transfers (disables dry-run)
  --copy   Use rclone copy (default)
  --move   Use rclone move
  -h, --help  Show this help

Anything after '--' is passed directly to rclone.
USAGE
}

# Defaults
DO_DRY=1
OP="copy"
PASS_THRU=()

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry)  DO_DRY=1; shift ;;
    --do)   DO_DRY=0; shift ;;
    --copy) OP="copy"; shift ;;
    --move) OP="move"; shift ;;
    -h|--help) usage; exit 0 ;;
    --) shift; PASS_THRU+=("$@"); break ;;
    *) PASS_THRU+=("$1"); shift ;;
  esac
done

mkdir -p "$LOG_DIR"

# Timestamp for filename: YYYY-MM-DD_HH-MM-SS
TS="$(date '+%Y-%m-%d_%H-%M-%S')"
LOG_FILE="$LOG_DIR/rclone_${OP}_$( ((DO_DRY)) && echo dryrun_ ).${TS}.log"
LOG_FILE="${LOG_FILE//.. /.}"   # safety: collapse accidental double dots/spaces

# Header
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Backup started (op=${OP}, dryrun=$((DO_DRY)), src='$SRC', dst='$DST')" >"$LOG_FILE"

# Compose dry-run flag
DRY_FLAG=()
if (( DO_DRY )); then
  DRY_FLAG+=(--dry-run)
fi

# Run rclone; capture all output into the log
rclone "$OP" "$SRC" "$DST" \
  "${DRY_FLAG[@]}" \
  --stats=30s \
  --stats-log-level NOTICE \
  --log-level INFO \
  --log-file "$LOG_FILE" \
  "${PASS_THRU[@]}" >>"$LOG_FILE" 2>&1

RC=$?

# Footer
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Backup ended with exit code $RC" >>"$LOG_FILE"
exit "$RC"