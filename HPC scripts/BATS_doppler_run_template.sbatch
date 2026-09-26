#!/bin/bash
#SBATCH --job-name=Bat_Doppler__JOBID_
#SBATCH --output=/quobyte/ckreudergrp/slicciar/out/_JOBID_-%A_%a.out
#SBATCH --error=/quobyte/ckreudergrp/slicciar/err/_JOBID_-%A_%a.err
#SBATCH --time=24:00:00
#SBATCH --partition=low
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=96G

module load conda
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate /quobyte/ckreudergrp/gjospin/envs/bats_dopler2

cd /quobyte/ckreudergrp/slicciar

#python /quobyte/ckreudergrp/gjospin/bats_radar_tracker-main/scripts/main.py day of run next day station start time (in local time) hours of run
python /quobyte/ckreudergrp/gjospin/bats_radar_tracker-main/scripts/main.py _STARTDATE_ _NEXTDATE_ KDAX --start_time SUNSET --hours 1


