#!/bin/bash

set -e

########################################
# Input Arguments (HPC Safe)
########################################

start=$1
end=$2

if [[ -z "$start" || -z "$end" ]]; then
    echo "Usage:"
    echo "./script.sh STARTDATE ENDDATE"
    exit 1
fi

########################################
# Convert Dates
########################################

format_date() {

    input="$1"

    if [[ "$input" =~ ^[0-9]{8}$ ]]; then
        date -d "${input:0:4}-${input:4:2}-${input:6:2}" +"%Y-%m-%d"
        return
    fi

    if [[ "$input" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        date -d "$input" +"%Y-%m-%d"
        return
    fi

    echo ""
}

start_fmt=$(format_date "$start")
end_fmt=$(format_date "$end")

########################################
# Checks
########################################

if [[ -z "$start_fmt" || -z "$end_fmt" ]]; then
    echo "Error: Invalid date format"
    exit 1
fi

if [[ "$start_fmt" > "$end_fmt" ]]; then
    echo "Error: Start date must be before end date"
    exit 1
fi

if [[ ! -f sunset_times.csv ]]; then
    echo "Error: sunset_times.csv not found"
    exit 1
fi

if [[ ! -f BATS_doppler_run_template.sbatch ]]; then
    echo "Error: Template not found"
    exit 1
fi

########################################
# Loop
########################################
prev_jobid=""

current="$start_fmt"

while (( $(date -d "$current" +%s) <= $(date -d "$end_fmt" +%s) ))
do

    jobdate=$(date -d "$current" +"%Y%m%d")

    startdate=$(date -d "$current" +"%Y-%m-%d")

    nextdate=$(date -d "$current +1 day" +"%Y-%m-%d")


    ####################################
    # Sunset
    ####################################

    LINE=$(grep "^$current," sunset_times.csv || true)

    if [[ -z "$LINE" ]]; then

        echo "Warning: No sunset time for $current"

        current=$(date -d "$current +1 day" +"%Y-%m-%d")

        continue
    fi


    IFS=',' read DATE SunsetLST <<< "$LINE"

SunsetMinus15=$(date -d "$DATE $SunsetLST -15 minutes" +"%H%M")


    ####################################
    # Output
    ####################################

    echo "Submitting $jobdate"


    ####################################
    # Create Job
    ####################################
    sed \
        -e "s/_JOBID_/$jobdate/g" \
        -e "s/_STARTDATE_/$startdate/g" \
        -e "s/_NEXTDATE_/$nextdate/g" \
        -e "s/SUNSET/$SunsetMinus15/g" \
        BATS_doppler_run_template.sbatch \
        > "Bat_Doppler_$jobdate.sbatch"

    ####################################
    # Submit
    ####################################

    sbatch "Bat_Doppler_$jobdate.sbatch"


    ####################################
    # Next Day
    ####################################

    current=$(date -d "$current +1 day" +"%Y-%m-%d")

done


echo "All jobs submitted."
if [[ -n "$prev_jobid" ]]; then
    jobid=$(sbatch --parsable --dependency=afterok:$prev_jobid "Bat_Doppler_$jobdate.sbatch")
else
    jobid=$(sbatch --parsable "Bat_Doppler_$jobdate.sbatch")
fi

prev_jobid="$jobid"
