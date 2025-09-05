#!/bin/bash
set -euo pipefail

# Copy the xdmod slurm report (given as $1) to the xdmod server via sftp

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


# main ##################################################################

PRG=$( basename "$0" )

# Read in variables
source "$(dirname "$0")/slurm_xdmod_common.config" || throw_error "fatal" "Cannot source config file"

[[ "$#" -ne 1 ]] && throw_error "fatal" 'Incorrect # of args, $1 is the single file to copy'

FILE="$1"
[[ -e "$FILE" ]] || throw_error "fatal" "File does not exist : ${FILE}"

sftp -i "${XDMOD_SERVICE_ACCT_KEY}" -b - "${XDMOD_SERVICE_ACCT}"@"${XDMOD_HOSTNAME}":/"${XDMOD_DST_DIR}"/. <<< "put ${FILE}" || throw_error "fatal" "Error while transferring file"

