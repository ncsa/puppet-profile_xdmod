#!/bin/bash
set -euo pipefail

# Generates a report of Slurm jobs for one day in a format that xdmod can shred
# Syntax:
#   -d|--date DATE
#       Date to run the report for (if not given default to yesterdays date)
#       Multiple date formats supported including YYYY-MM-DD and YYYY/MM/DD
#   -c|--copy
#       Copy the report to the configured xdmod server, if this flag is omitted it will just run and save the report on the local host

# subs ###################################################################

# $1 = type of error
#    1 = warning : log but continue
#    2 = fatal   : log and exit
# $2 = message for error
throw_error () {
	local error_type="$1"
	local error_msg="$2"

	if [[ $error_type == "warning" ]]; then
		log "[WARNING] $error_msg"
	else
		log "[FATAL] $error_msg"
		exit 9
	fi
}

# Log message to syslog and stdout
log() {
	local msg="$1"

	logger -t "$PRG" "$msg"
	echo "$msg"
}


# sacct command that generates the report
# $1 = date to run report on in YYYY-MM-DD format, report is run for full day
slurm_report () {
	local date="$1"

	TZ=UTC sacct \
	--clusters "$CLUSTER_NAME" \
	--allusers --parsable2 --noheader --allocations --duplicates \
	--format jobid,jobidraw,cluster,partition,qos,account,group,gid,user,uid,submit,eligible,start,end,elapsed,exitcode,state,nnodes,ncpus,reqcpus,reqmem,reqtres,alloctres,timelimit,nodelist,jobname \
	--starttime ${date}T00:00:00 \
	--endtime ${date}T23:59:59 \
	>> "$OUTPUT_FILE"
}


# main ##################################################################

PRG=$( basename "$0" )

# Read in variables
source "$(dirname "$0")/slurm_xdmod_common.config" || throw_error "fatal" "Cannot source config file"

# Initialize COPY_REPORT to false
COPY_REPORT=false

# Read in CLI args
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -d|--date) CLI_DATE="$2"; shift ;;
        -c|--copy) COPY_REPORT=true ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

[ ! -d "$REPORT_STAGE_DIR" ] && throw_error "fatal" "$REPORT_STAGE_DIR does not exist"

CLUSTER_NAME=$(scontrol show config | grep ClusterName | awk '{print $3}') || throw_error "fatal" "Cannot determine ClusterName"
RUN_TIMESTAMP=$(date +%s) || throw_error "fatal" "Error setting RUN_TIMESTAMP"

INITIAL_DATE_TO_REPORT=${CLI_DATE:-yesterday}
# Convert date to YYYY-MM-DD even if they give YYYY/MM/DD on CLI
DATE_TO_REPORT=$(date -d "$INITIAL_DATE_TO_REPORT" '+%F') || throw_error "fatal" "Invalid date syntax given"

OUTPUT_FILE="${REPORT_STAGE_DIR}/${CLUSTER_NAME}_${DATE_TO_REPORT}-${RUN_TIMESTAMP}"
touch "$OUTPUT_FILE" || throw_error "fatal" "Cannot create $OUTPUT_FILE"

log "Running report for $DATE_TO_REPORT : Saving to $OUTPUT_FILE"

slurm_report "$DATE_TO_REPORT" || throw_error "fatal" "Error while running slurm_report"

if [ "$COPY_REPORT" = true ]; then
    /root/cron_scripts/slurm_xdmod_transfer_report.sh "$OUTPUT_FILE"
fi
