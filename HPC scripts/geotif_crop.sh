#!/bin/bash
#SBATCH --job-name=geotiff_JOBID
#SBATCH --output=/quobyte/ckreudergrp/slicciar/out/geotiff_JOBID-%A_%a.out
#SBATCH --error=/quobyte/ckreudergrp/slicciar/err/geotiff_JOBID-%A_%a.err
#SBATCH --time=2:00:00
#SBATCH --partition=low
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G

module load conda
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate /quobyte/ckreudergrp/gjospin/envs/geotiff_crop

cd /quobyte/ckreudergrp/slicciar

python /quobyte/ckreudergrp/gjospin/bats_radar_tracker-main/crop_causeway_geotiff_v4.py \
  --input /quobyte/ckreudergrp/gjospin/bats_radar_tracker-main/data/doppler/RUNDATE/run_RUNNUM/classified \
  --out /quobyte/ckreudergrp/slicciar/data/causeway_crop_out_JOBID \
  --buffer-m 500 \
  --fps 4 \
  --delimiter "tab"
