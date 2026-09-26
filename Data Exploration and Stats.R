####Script Description####
#Explore the data and run statistics
#must first create load all data and create dataframes in "Load and Create Dataframes" script

#####Libraries####
library(tidyverse)
library(emmeans)
library(betareg)
library(car)

####Data Exploration####

#Finding number of dates included 

#finding n= overall
num_dates <- master_df %>%
  filter(!is.na(binary_pixels)) %>%
  summarise(n_dates=n_distinct(date))
num_dates

#finding sample size for each month
num_dates_month <- master_df %>%
  filter(!is.na(binary_pixels)) %>%
  group_by(month) %>%
  summarise(total_dates=sum(n_distinct(date)))
num_dates_month

#finding sample size for each month x location
num_dates_month_loc <- master_df %>%
  group_by(month, Location) %>%
  summarise(total_dates=sum(n_distinct(date)))
num_dates_month_loc

#finding sample size for each year
num_dates_year <- master_df %>%
  filter(!is.na(binary_pixels)) %>%
  group_by(year) %>%
  summarise(total_dates=sum(n_distinct(date)))
num_dates_year

#finding sample size for each monthxlocationxyear
num_dates_all <- master_df %>%
  group_by(year, month) %>%
  summarise(total_dates=sum(n_distinct(date)))
num_dates_all

####Stats####

#create models
m1 <- betareg(prop ~ Location + factor(month) + factor(year), data=final_df) #main effects only
m2 <- betareg(prop ~ factor(month)*Location*factor(year) - factor(month):Location:factor(year) - Location:factor(year) , data = final_df) #main effects and interactions, excluding Location:year
m3 <- betareg(prop ~ factor(month)*Location*factor(year) - factor(month):Location:factor(year) , data = final_df ) #main effects and interactions

#compare models
#The AIC of m1 and m2 are very similar, proceed with m2 as it includes interactions we are interested in
AIC(m1,m2,m3)

#model summary for m2
summary(m2)

#ANOVA for m2 using the car package
car::Anova(m2)

#post-hoc analysis using emmeans package
emmeans(m2, spec = pairwise~ month) %>% #comparing the proportions of the different months
  emmeans:::cld.emm_list()
emmeans(m2, spec = ~ Location) %>% #comparing the proportions of the different sections
  emmeans:::cld.emmGrid()
emmeans(m2, spec = ~ year) %>% #comparing the proportions of the different years
  emmeans:::cld.emmGrid()
emmeans(m2, spec = ~ year | month) %>%  #comparing the proportions of the different month and year combinations
  emmeans:::cld.emmGrid()
emmeans(m2, spec = ~ month | year) %>% #different way of comparing the proportions of the different month and year combination
  emmeans:::cld.emmGrid()