# BATS_I80_Causeway_Project
Code and essential data used for 1-80 causeway project

# Data Processing Pipeline
# Running BATS on the HPC
# First time only
1. Copy all the files in HPC scripts folder + sunset_times.csv into personal directory 
2. Use chmod +x BATS_wrapper.sh and chmod +x crop_input.sh to make files repeatable 

# Everytime you want to run BATS
1. Input selected dates using ./BATS_wrapper.sh yearmonth{first day..last day}
     Ex: for the dates 1/1/2026 to 1/30/2026, input as ./BATS_wrapper.sh 202601{01..30}
     Note: if one of the dates cannot run, the dates after will not be able to run. Use scancel JOBID to cancel all the dates currently in the queue and try again. 
2. Check your current queue using squeue -u username
3. Use ./crop_input first_date last_date date_run_in_HPC first_run_number last_run_number
       Ex: For the dates 1/1/2026 to 1/30/2026 run on the HPC on 5/5/2026 from runnumbers 1 to 30, input as ./crop_input.sh 20260101 20260130 20260505 1 30

# Downloading TSV files to local
1. Make sure you are still signed into HPC. Open another terminal and use cd folderpath to get to the location where you want the files to be downloaded to.
2. Copy save_to_local.sh to the local folder.
3. Use chmod +x save_to_local.sh to make file repeatable just first time.
4. Input selected dates to ./save_to_local.sh .

# Generate Videos
1. Make sure you are still signed into HPC. Open another terminal and use cd folderpath to get to the location where you want the files to be downloaded to.
2. Use scp -r username@hive.hpc.ucdavis.edu:/directorypath/dateofruninHPC/run_#/classified classified_date
    Ex: for the date 1/1/2026 run on the HPC on 5/5/2026 from runnumber 1, input as scp -r username@hive.hpc.ucdavis.edu:/directorypath/20260505/run_1/classified classified_20260101
3. First time only: use conda install -c conda-forge rasterio matplotlib imageio imageio-ffmpeg geopandas osmnx shapely pyproj rtree tqdm packaging numpy -y
4. First time only: Copy make_covell_fullframe_box_v16_newcenter.py to local computer.
5. Input selected date into python3 filepath/make_covell_fullframe_box_v16_newcenter.py --in /pathnamefordownloadedtiffiles --out /pathnameforoutputfile --mp4 videoname.mp4
       Ex: for the date 1/1/2026 run on the HPC on 5/5/2026, input python3 /filepath/make_covell_fullframe_box_v16_newcenter.py --in /filepath/classified_20260101 --out /pathnameforoutputfile --mp4 20260101.mp4

# Basic Commands
ssh: sign into HPC using ssh username@hive.hpc.ucdavis.edu
cd: call directory using cd directoryfilepath
ls: list
nano: open file
scancel: stop something currently running in sbatch
squeue -u: Check what is currently running in the queue using squeue -u username

# Selecting Moment of Emergence
1. Read the Methods section of the manuscript to determine how to select the moment of emergence (MOE)
2. Use the MOE_times.csv and input the selected MOE for those dates.
3. Download each month as its own independent CSV file

# Data Processing, Graphing, and Stats in R
1. Run every month individually in the Load and Create Dataframes script
2. Use Plots script for graphing
3. Use Data Exploration and Stats script for data analysis
