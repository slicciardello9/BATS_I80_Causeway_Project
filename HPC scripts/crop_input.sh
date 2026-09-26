#!/bin/bash

set -e

########################################
# Input Arguments (HPC Safe)
########################################

start="$1" #First date of doppler run
end="$2" #Last date of doppler run
rundate="$3" #Date of HPC run
runnumstart="$4" #First run_num of date (typically 1)
runnumend="$5" #last run_num of date

if [[ -z "$1" || -z "$2" || -z "$3" || -z "$4" || -z "$5" ]]; then
    echo "Usage: ./script.sh STARTDATE ENDDATE RUNDATE RUNNUMSTART RUNNUMEND"
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

rundate_fmt=$(date -d "$rundate" +"%Y%m%d")
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

if [[ -z "$rundate_fmt" ]]; then
    echo "Error: Invalid run date"
    exit 1
fi

if ! [[ "$runnumstart" =~ ^[0-9]+$ && "$runnumend" =~ ^[0-9]+$ ]]; then
    echo "Error: runnum must be integers"
    exit 1
fi

if [[ ! -f geotif_crop.sh ]]; then
    echo "Error: Template not found"
    exit 1
fi

########################################
# Loop
########################################

current="$start_fmt"
runnum="$runnumstart"

while (( $(date -d "$current" +%s) <= $(date -d "$end_fmt" +%s) ))
do

    if (( runnum > runnumend )); then
        echo "Reached max run numbers"
        break
    fi

    jobdate=$(date -d "$current" +"%Y%m%d")

    echo "Submitting $jobdate run $runnum"

    ####################################
    # Create Job
    ####################################

    sed \
        -e "s/JOBID/$jobdate/g" \
        -e "s/RUNDATE/$rundate_fmt/g" \
        -e "s/RUNNUM/$runnum/g" \
        geotif_crop.sh \
        > "geotif_crop_${jobdate}_${runnum}.sh"

    ####################################
    # Submit
    ####################################

    sbatch "geotif_crop_${jobdate}_${runnum}.sh"

    ####################################
    # Next
    ####################################

    runnum=$((runnum+1))

    current=$(date -d "$current +1 day" +"%Y-%m-%d")

done


echo "All jobs submitted."
