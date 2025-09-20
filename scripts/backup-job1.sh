
#!/bin/bash

LOG_DIR="/volume3/vol3/backupjobs/logs"
TS="$(date '+%Y-%m-%d_%H-%M-%S')"
LOG_FILE="$LOG_DIR/joblog.${TS}.log"

echo $LOG_FILE

# --- Defaults ---
cat <<'USAGE'
backup-job-1
nohup  ./backup.sh --src /volume1/vol1 --dest '/volume2/vol2/vol1backups' --do &> $LOG_FILE
USAGE

nohup ./backup.sh --src /volume1/vol1 --dest '/volume2/vol2/vol1backups' --do  &> $LOG_FILE 
