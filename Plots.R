####Script Description####
#code for creating heatmaps and graphs seen in manuscript
#must first create load all data and create dataframes in "Load and Create Dataframes" script

####Libraries####

library(dplyr)
library(ggplot2)
library(patchwork)
library(tidyverse)

#rename reference dataframe, drop the 2


####Heatmaps####

##dataframes for heatmaps##

June_2013_plot <- df_June_2013 %>% #use individual dataframes for each month
  group_by(lon, lat) %>% #group by coordinate location (lon, lat)
  summarise(total_ones = sum(binary_pixels, na.rm = TRUE), .groups = "drop") #total_ones is a count of how many times a pixel lit up during that month

August_2013_plot <- df_August_2013 %>%
  group_by(lon, lat) %>%
  summarise(total_ones = sum(binary_pixels, na.rm = TRUE), .groups = "drop")

June_2019_plot <- df_June_2019 %>%
  group_by(lon, lat) %>%
  summarise(total_ones = sum(binary_pixels, na.rm = TRUE), .groups = "drop")

August_2019_plot <- df_August_2019 %>%
  group_by(lon, lat) %>%
  summarise(total_ones = sum(binary_pixels, na.rm = TRUE), .groups = "drop")

June_2020_plot <- df_June_2020 %>%
  group_by(lon, lat) %>%
  summarise(total_ones = sum(binary_pixels, na.rm = TRUE), .groups = "drop")

August_2020_plot <- df_August_2020 %>%
  group_by(lon, lat) %>%
  summarise(total_ones = sum(binary_pixels, na.rm = TRUE), .groups = "drop")

June_2021_plot <- df_June_2021 %>%
  group_by(lon, lat) %>%
  summarise(total_ones = sum(binary_pixels, na.rm = TRUE), .groups = "drop")

August_2021_plot <- df_August_2021 %>%
  group_by(lon, lat) %>%
  summarise(total_ones = sum(binary_pixels, na.rm = TRUE), .groups = "drop")

June_2022_plot <- df_June_2022 %>%
  group_by(lon, lat) %>%
  summarise(total_ones = sum(binary_pixels, na.rm = TRUE), .groups = "drop")

August_2022_plot <- df_August_2022 %>%
  group_by(lon, lat) %>%
  summarise(total_ones = sum(binary_pixels, na.rm = TRUE), .groups = "drop")

June_2023_plot <- df_June_2023 %>%
  group_by(lon, lat) %>%
  summarise(total_ones = sum(binary_pixels, na.rm = TRUE), .groups = "drop")

August_2023_plot <- df_August_2023 %>%
  group_by(lon, lat) %>%
  summarise(total_ones = sum(binary_pixels, na.rm = TRUE), .groups = "drop")


##individual month heatmaps##

p1 <- ggplot(data=June_2013_plot, aes(x=lon, y=lat)) + #coordinates as the x,y axis to setup the bridge
  geom_point(aes(color = total_ones), size = 2) + #use the total_ones created in dataframes to color the points
  scale_color_gradient(low = "yellow", high = "red", limits=c(0,31), name="Positive Pixels") + #yellow to red gradient for total_ones values 
         #manually set the possible gradient from 0-31, otherwise there will be different gradient for each heatmap #Positive pixels is the name for total_ones used in paper
  labs(title="June 2013") +
  geom_vline(xintercept=c(-121.628333,-121.612420)) #coordinates that mark division between West, Center, East sections of causeway
  theme_minimal()
  
 p2 <- ggplot(data=August_2013_plot, aes(x=lon, y=lat)) +
   geom_point(aes(color = total_ones), size = 2) +
   scale_color_gradient(low = "yellow", high = "red", limits=c(0,31), name="Positive Pixels") +
   labs(title="August 2013") +
   geom_vline(xintercept=c(-121.628333,-121.612420))
  theme_minimal()
  
 p3 <- ggplot(data=June_2019_plot, aes(x=lon, y=lat)) +
    geom_point(aes(color = total_ones), size = 2) +
    scale_color_gradient(low = "yellow", high = "red", limits=c(0,31), name="Positive Pixels") +
    labs(title="June 2019") +
   geom_vline(xintercept=c(-121.628333,-121.612420))
  theme_minimal() 
  
 p4 <- ggplot(data=August_2019_plot, aes(x=lon, y=lat)) +
    geom_point(aes(color = total_ones), size = 2) +
    scale_color_gradient(low = "yellow", high = "red", limits=c(0,31), name="Positive Pixels") +
    labs(title="August 2019") +
   geom_vline(xintercept=c(-121.628333,-121.612420))
  theme_minimal() 
  
  p5 <- ggplot(data=June_2020_plot, aes(x=lon, y=lat)) +
    geom_point(aes(color = total_ones), size = 2) +
    scale_color_gradient(low = "yellow", high = "red", limits=c(0,31), name="Positive Pixels") +
    labs(title="June 2020") +
    geom_vline(xintercept=c(-121.628333,-121.612420))
  theme_minimal() 
  
 p6 <- ggplot(data=August_2020_plot, aes(x=lon, y=lat)) +
    geom_point(aes(color = total_ones), size = 2) +
    scale_color_gradient(low = "yellow", high = "red", limits=c(0,31), name="Positive Pixels") +
    labs(title="August 2020") +
   geom_vline(xintercept=c(-121.628333,-121.612420))
  theme_minimal() 
  
p7 <- ggplot(data=June_2021_plot, aes(x=lon, y=lat)) +
    geom_point(aes(color = total_ones), size = 2) +
    scale_color_gradient(low = "yellow", high = "red", limits=c(0,31), name="Positive Pixels") +
    labs(title="June 2021") +
  geom_vline(xintercept=c(-121.628333,-121.612420))
  theme_minimal() 
  
 p8 <- ggplot(data=August_2021_plot, aes(x=lon, y=lat)) +
    geom_point(aes(color = total_ones), size = 2) +
    scale_color_gradient(low = "yellow", high = "red", limits=c(0,31), name="Positive Pixels") +
    labs(title="August 2021") +
   geom_vline(xintercept=c(-121.628333,-121.612420))
  theme_minimal() 
  
 p9 <- ggplot(data=June_2022_plot, aes(x=lon, y=lat)) +
    geom_point(aes(color = total_ones), size = 2) +
    scale_color_gradient(low = "yellow", high = "red", limits=c(0,31), name="Positive Pixels") +
    labs(title="June 2022") +
   geom_vline(xintercept=c(-121.628333,-121.612420))
  theme_minimal() 
  
 p10 <- ggplot(data=August_2022_plot, aes(x=lon, y=lat)) +
    geom_point(aes(color = total_ones), size = 2) +
    scale_color_gradient(low = "yellow", high = "red", limits=c(0,31), name="Positive Pixels") +
    labs(title="August 2022") +
   geom_vline(xintercept=c(-121.628333,-121.612420))
  theme_minimal() 
  
 p11 <- ggplot(data=June_2023_plot, aes(x=lon, y=lat)) +
    geom_point(aes(color = total_ones), size = 2) +
    scale_color_gradient(low = "yellow", high = "red", limits=c(0,31), name="Positive Pixels") +
    labs(title="June 2023") +
   geom_vline(xintercept=c(-121.628333,-121.612420))
  theme_minimal() 
  
 p12 <- ggplot(data=August_2023_plot, aes(x=lon, y=lat)) +
    geom_point(aes(color = total_ones), size = 2) +
    scale_color_gradient(low = "yellow", high = "red" , limits=c(0,31), name="Positive Pixels") +
    labs(title="August 2023") +
   geom_vline(xintercept=c(-121.628333,-121.612420))
  theme_minimal() 
  
##final heatmaps##

#Broke into two plots because does not show up well as one plot
  
#2013, 2019-2020
combined_plot_1 <- (p1 + p2 + p3 + p4 + p5 + p6) + #plots to be included
    plot_layout(nrow = 3, ncol=2) #3 rows with 2 columns
  
print(combined_plot_1)

#2021-2023
combined_plot_2<- (p7 +p8 + p9 + p10 + p11 + p12) + 
    plot_layout(nrow = 3, ncol=2)
  
print(combined_plot_2)

####Graphs from manuscript####

#June vs August plot
#does prop vary by month

month_df <- final_df %>% #create dataframe to compare June vs August
  group_by(month) %>% #group by June vs August
  summarise(prop) #overall proportion for each month
month_df

#create label for sample size for each month (number of dates included for June and August)
n_labels_m <- data.frame(
  Location = c("Jun", "Aug"),
  x=c("Jun", "Aug"), #where on the x-axis should labels be (Jun is above June boxplot, Aug is above August boxplot)
  y = c(0.50, 0.55), # where on the y-axis should labels be (adjust depending on how high above the boxplot you want number to appear)
  label = c("n = 170", "n = 167") #exact label you want to appear on plot #manually calculated in "Data Exploration and Stats" script
)

month_plot <- ggplot(month_df, aes(x = month, y = prop)) + #month on x-axis, proportion (prop) on y-axis
  geom_boxplot() + #boxplots for each month
  labs(x="Month", y="Proportion") + #manually relabel x and y axis
  geom_text(data = n_labels_m, aes(x = x, y = y, label = label, size=12)) + #add in sample size labels from n_labels_m
  #x=where on x-axis you want labels, y=where on y-axis you want labels, label=actual text you want, size=font size
  theme(axis.title=element_text(size=12), axis.text=element_text(size=12)) #resize axis labels and text elements for readability
  
month_plot
  
#Year Plot
#does prop vary by year

year_overall_df <- final_df %>% #create dataframe to compare the years
  mutate(year=as.character(year)) %>% #make year a character value so each year shows up as its own category rather than a trendline
  group_by(year) %>% #group by each year
  summarise(prop) #proportion for each year
year_overall_df

#create label for sample size for each year (number of dates included for each year)
n_labels_y <- data.frame(
  x=c("2013", "2019", "2020", "2021", "2022", "2023"), #where on the y-axis you want each label
  y = c(0.5, 0.50, 0.55, 0.5, 0.55, 0.55), #where on the x-axis you want each label 
  label = c("n = 59", "n = 56", "n = 50", "n = 56", "n = 57", "n = 59") #exact labels you want in plot #manually calculated in "Data Exploration and Stats" script
)

year_overall_plot <- ggplot(year_overall_df, aes(x = year, y = prop)) + #year as a category on x-axis, proportion on y-axis
  geom_boxplot() + #boxplots for each year
  geom_text(data = n_labels_y, aes(x = x, y = y, label = label, size=12)) + #add in sample size labels from n_labels_y
  #x=where on x-axis you want labels, y=where on y-axis you want labels, label=actual text you want, size=font size
  labs(x="Year", y="Proportion") + #manually relabel x and y axis
  theme(axis.title=element_text(size=12), axis.text=element_text(size=12)) #resize axis labels and text elements for readability

year_overall_plot

#Section Plot 
#does prop vary by section

section_df <- final_df %>%  #create dataframe to compare the years
  group_by(Location) %>% #Group by each section ("Location" is the variable name for section)
  summarise(prop) #Proportion for each section
section_df

section_plot <- ggplot(section_df, aes(x = Location, y = prop)) + 
  geom_boxplot() + #boxplot for each section
  scale_x_discrete(limits=c("W", "C", "E")) + #used to reorder the x-axis to match causeway labels (Center is automatically first)
  labs(x="Section", y="Proportion") + #manually label axis
  theme(axis.title=element_text(size=12), axis.text=element_text(size=12)) #manually set size of axis and text elements

section_plot

#Overall Plot
#does prop vary by section, year, and month

overall_plot_df <- final_df %>%
  group_by(Location, year, month) %>% #group by all three variables
  summarise(prop) #proportions for each grouping of variables
overall_plot_df

overall_plot <- ggplot(overall_plot_df, aes(x = factor(year), y = prop)) + #year as x-axis for each panel #factor year to treat it as categorical
  geom_bar(stat = "identity", fill="steelblue") + #barplot for each grouping of variables
  labs(x="Year", y="Proportion") + #Manual axis titles
  theme(axis.title=element_text(size=12), axis.text=element_text(size=12)) #set the size of axis titles and elements

overall_plot + facet_grid(month~Location) #create new panels for each month and each location