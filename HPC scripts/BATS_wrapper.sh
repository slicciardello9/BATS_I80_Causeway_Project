#!/bin/bash

if [[ $# -eq 0 ]]; then
    echo "Usage:"
    echo "./BATS_wrapper.sh DATE1 DATE2 DATE3 ..."
    exit 1
fi

prev=""
for date in "$@"; do
    prev=$(./bats_input_single_date.sh "$date" "$prev" | tail -1)
    echo "Queued $date with job ID: $prev"
done

echo "All dates submitted."
