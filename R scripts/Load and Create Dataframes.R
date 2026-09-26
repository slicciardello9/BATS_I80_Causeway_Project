####Script Description####
#Load tsv files from local computer
#Clean and process files 
#Create dataframes for each month
#Create an overall master dataframe containing all the months
#Create a final dataframe that contains the proportions for each section for each month and year combination
#Note: This is the overall script for creating the final dataframe, will need to manually change the month and year for each new month you upload
    #Will mark any code that needs to be adjusted each time as "CHANGE PER MONTH"
#Run before other R-scripts

####Libraries####
library(tidyverse)
library(janitor)
library(data.table)
library(dplyr)
library(tidyr)
library(stringr)
library(lubridate)
library(gtools)

#####Upload files#####

#Selected Coordinates
#long,lat coordinates surrounding causeway
#Includes: lon, lat, and Location (Location is the Section name)
#only need to upload first time
coords= read.csv("/Users/savannahlicc/Desktop/Bat_Doppler_Project/Datasheets/coords.csv")

#Input Directory
#select where in your computer for the files are stored 
#use exact pathname for folder
#CHANGE PER MONTH
input_dir = "/Users/savannahlicc/Desktop/Bat_Doppler_Project/Data/2023/August_2023" 

#Moment of Emergence (MOE) times 
#manually selected moment of emergence times for each month
#Includes: date and MOE (MOE=Moment of Emergence for that night, criteria for selecting MOE is located in manuscript)
#CHANGE PER MONTH
MOE_times=read.csv("/Users/savannahlicc/Desktop/Bat_Doppler_Project/Datasheets/MOE_times_August_2023.csv")

#creates function to read files quickly
#function Nicole created
read_all_files = function(file){read_all_files = 
  suppressMessages(data.table::fread(file, stringsAsFactors = F))}


# make an index of all .tsv the files you have in the input directory
# save your file index as needed to prevent reading in files you've already processed,
# then you can read in and filter the new file index to exclude the old file index
# this will be based off of what I named files
file_index = mixedsort(list.files(input_dir, pattern = "*.tsv", full.names = T, recursive = T))
print(file_index)

# read in all the files
#file_index is all the files being read in
#read_all_files is the function
file_list = lapply(file_index, read_all_files)

#####Clean files#####

#filter data files for only coordinates that match selected coordinates in "coords"
#filtering for only rows that match the lon, lat on coords.csv
#file_manipulate is temporary df used for all data processing steps
file_manipulate <- lapply(file_list, function(df) { #use lapply to apply to all files in "file_list", creates temporary function to apply to temporary df
  df%>%
    mutate(lon = round(lon, 6), #round to 6 sigfigs as different files have different number of sigfigs
           lat = round(lat, 6)) %>%
    inner_join(coords %>% #"coords" is reference
                mutate(lon = round(lon, 6),
                       lat = round(lat, 6)) %>% 
                 select(lon, lat, Location),  
              by = c("lon", "lat")) #joining by "lon" and "lat"
})

#transform from UTC to PST
#Output from BATS is in UTC, convert to PST as KDAX is in PST timezone
#Will need to change if doppler tower is in another timezone
file_manipulate <- lapply(file_manipulate, function(df) {
  names(df)[3:ncol(df)] <- names(df)[3:ncol(df)] %>% #use the column names from the third column to the last column (skip first two columns, which are lon and lat)
    sub(" PDT| PST", "", .) %>% #remove the PDT/PST labels from the column names
    as.POSIXct(format = "%Y-%m-%d %H:%M", tz = "America/Los_Angeles") %>% #select the new timezone
    `-`(hours(7)) %>% #subtract 7 hours from UTC
    format("%Y-%m-%d %H:%M") #format as year-month-day hour:minute
  df
})


#add date column for reference later
#finds the date in column name row, creates a new column containing that date, relocates column to first position
file_manipulate <- lapply(file_manipulate, function(df) {
  df%>%
    mutate(date = as.Date(str_extract(colnames(df)[5], "\\d{4}-\\d{2}-\\d{2}"))) %>% #extract date from column name #create column containing that date
    rename_with(~ str_remove(.x, "\\d{4}-\\d{2}-\\d{2} ")) %>% #remove date from column name, leaving only the time
    relocate(date, .before = 1) #move date column to first position
})

#Make values binary
#Takes all light up values and makes them either 0 or 1
#0.9 is cutoff value used in Lee et al. 2024
file_manipulate = lapply(file_manipulate, function(df) {
  df%>%
    mutate(across(-c(date, lon, lat, Location), ~ ifelse(. > 0.9, 1, 0))) #excluding the date, lon, lat, and Location columns, make everything creater than 0.9 =1, otherwise make it 0
})

#select only the time point that matches the MOE
  #add MOE (moment of emergence column)
# Find the MOE letter for this date
# Use the MOE letter as the column name to pull the value
file_manipulate <- lapply(file_manipulate, function(df) {
  df <- as.data.frame(df)
  df %>%
    select(date, lon, lat, everything()) %>% #select the columns from the dataframes
    rowwise() %>% #group input by row for the MOE_times csv
    mutate(MOE = {moe_col <- MOE_times$MOE[MOE_times$date == date] #filters where date from MOE_times matches date in dataframe, pulls cooresponding MOE value
    if (length(moe_col) == 1) moe_col else NA_character_}) %>% #if exactly a single value found, use that, otherwise assign an NA value
    ungroup() %>% #stop using rowwise
    mutate(binary_pixels = {if (!is.na(MOE[1]) && MOE[1] %in% names(df)) { #creates binary_pixel column that contain 0 or 1 values
        df[[MOE[1]]]} 
      else {rep(NA, nrow(df))}
    }) %>%
    select(date, lon, lat, Location, MOE, binary_pixels) #Proceed with only these columns
})


#####Combine into single df#####

#Monthly Dataframes
# merge files into one data frame for each month
#CHANGE PER MONTH
df_August_2023 = bind_rows(file_manipulate)

#Master Dataframe
#dataframe containing all the months
#create master df from all montly df
master_df <- bind_rows(df_June_2013, df_August_2013, df_June_2019, df_August_2019, df_June_2020, 
                       df_August_2020, df_June_2021, df_August_2021, df_June_2022, df_August_2022,
                       df_June_2023, df_August_2023)

#make month, year columns
master_df <- master_df %>%
  mutate(month=lubridate::month(date, label= TRUE), year=year(date)) #extract month and year from date column, create seperate month and year columns

#Final dataframe
#Proportions of positive pixels for each month, year, section
#Includes: year, month, Location, total_ones, prop
  #total_ones is a count of how many times a pixel lights up for that month, calculated by summing up binary_pixels for that month in that section
  #prop is the proportion of pixels lit up for that section and month divided by the theoretical sum if all the pixels lit up all the nights
final_df <- master_df %>%
  group_by(year, month, Location) %>%
  summarise(total_ones = sum(binary_pixels, na.rm = TRUE), prop=total_ones/n(), .groups = "drop")
final_df


