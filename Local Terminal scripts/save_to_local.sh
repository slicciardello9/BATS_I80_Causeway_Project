#!/bin/bash

read -p "Start date (YYYYMMDD): " start
read -p "End date (YYYYMMDD): " end
read -p "Number of parallel downloads (e.g. 5): " maxjobs

# Convert to YYYY-MM-DD
start_fmt=$(date -j -f "%Y%m%d" "$start" +"%Y-%m-%d")
end_fmt=$(date -j -f "%Y%m%d" "$end" +"%Y-%m-%d")

current="$start_fmt"

count=0

while [[ "$current" < "$end_fmt" || "$current" == "$end_fmt" ]]
do

    # Convert back to YYYYMMDD
    filedate=$(date -j -f "%Y-%m-%d" "$current" +"%Y%m%d")

    echo "Queueing $filedate"

    scp slicciar@hive.hpc.ucdavis.edu:/quobyte/ckreudergrp/slicciar/data/causeway_crop_out_${filedate}/causeway_timeseries.tsv ./${filedate}.tsv &

    ((count++))

    # Limit parallel jobs
    if (( count % maxjobs == 0 ))
    then
        wait
    fi

    # Move forward one day
	current=$(date -j -v+1d -f "%Y-%m-%d" "$current" +"%Y-%m-%d")
done

wait

echo "All downloads complete"
