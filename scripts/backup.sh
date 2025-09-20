#!/bin/bash

# --- Defaults ---
DO_DRY=1            # default is dry-run
OP="copy"           # default is copy
PASS_THRU=()
SRC=""
DST=""
LOG_DIR="/volume3/vol3/backupjobs/logs"

usage() {
  cat <<'USAGE'
Usage: backup.sh --src <source_path> --dest <destination_path> [--dry | --do] [--copy | --move] [--] [extra rclone flags]

Options:
  --src   Source path (required)
  --dest  Destination path (required)
  --dry   Use rclone dry-run (default)
  --do    Perform actual transfers (disables dry-run)
  --copy  Use rclone copy (default)
  --move  Use rclone move
  -h, --help  Show this help

Anything after '--' is passed directly to rclone.
USAGE
}

# --- Parse arguments ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --src)  SRC="$2"; shift 2 ;;
    --dest) DST="$2"; shift 2 ;;
    --dry)  DO_DRY=1; shift ;;
    --do)   DO_DRY=0; shift ;;
    --copy) OP="copy"; shift ;;
    --move) OP="move"; shift ;;
    -h|--help) usage; exit 0 ;;
    --) shift; PASS_THRU+=("$@"); break ;;
    *) PASS_THRU+=("$1"); shift ;;
  esac
done

# --- Validate ---
if [[ -z "$SRC" || -z "$DST" ]]; then
  echo "ERROR: Both --src and --dest must be specified." >&2
  usage
  exit 1
fi

mkdir -p "$LOG_DIR"

# Timestamp for filename: YYYY-MM-DD_HH-MM-SS
TS="$(date '+%Y-%m-%d_%H-%M-%S')"
LOG_FILE="$LOG_DIR/rclone_${OP}_$( ((DO_DRY)) && echo dryrun_ ).${TS}.log"
LOG_FILE="${LOG_FILE//.. /.}"   # safety: collapse accidental double dots/spaces

# --- Log header ---
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Backup started (op=${OP}, dryrun=$((DO_DRY)), src='$SRC', dst='$DST')" >"$LOG_FILE"

# Dry-run flag
DRY_FLAG=()
if (( DO_DRY )); then
  DRY_FLAG+=(--dry-run)
fi

# --- Build command ---
RCLONE_CMD=(rclone "$OP" "$SRC" "$DST"
  "${DRY_FLAG[@]}"
  --stats=30s
  --stats-log-level NOTICE
  --log-level INFO
  --log-file "$LOG_FILE"
  "${PASS_THRU[@]}"
)

# --- Print command ---
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Running command: ${RCLONE_CMD[*]}" | tee -a "$LOG_FILE"

# --- Run ---
"${RCLONE_CMD[@]}" >>"$LOG_FILE" 2>&1
RC=$?

# --- Footer ---
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Backup ended with exit code $RC" | tee -a "$LOG_FILE"
exit "$RC"