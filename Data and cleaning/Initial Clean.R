## Adam Chaffee
## Cleaning LAX flight data

## Set working directory
setwd("C:/Users/achaf/OneDrive/Documents/DS Projects/LAX")


#############################
## Packages needed
#############################
## Data observations/visualization
library(mosaic)

## Cleaning
library(lubridate)
library(dplyr) ## NEEDED
library(plyr)

####################################
## Previewing data
####################################
load(file = "flights.RData")
str(flights)
flight_preview = head(flights)
View(flight_preview)

###############
### CLEAN   ###
###############

## Combine carrier and flight number into unique ID
flights$FL_NUM = as.character(flights$FL_NUM)
flights$flight_ID = paste(flights$CARRIER, flights$FL_NUM)

# restrict columns to only those we want:
names(flights)
keepers <- c("FL_DATE","flight_ID","DEST","CRS_DEP_TIME","CRS_ARR_TIME","DISTANCE","DISTANCE_GROUP", "ARR_DELAY")

flights<-flights[,keepers]

## Alternative method using select() function
#flight_preview = select(flight_preview, -c(ORIGIN_CITY_NAME, ORIGIN_AIRPORT_ID, ORIGIN_STATE_NM))
#flights = select(flights, -c(ORIGIN_CITY_NAME, TAIL_NUM, ORIGIN_AIRPORT_ID, ORIGIN_AIRPORT_SEQ_ID,
#                             ORIGIN_STATE_NM, DEST_CITY_NAME, DEST_STATE_NM, DEST_AIRPORT_ID,
#                             DEST_AIRPORT_SEQ_ID, DEP_TIME, DEP_DELAY_GROUP))


## Convert date to R's Date format
flights$FL_DATE = as.Date(flights$FL_DATE,format = "%Y-%m-%d")


## First set of feature engineering: add day of week, month, quarter
flights$DOW = weekdays(flights$FL_DATE)
flights$Month = as.character(month(flights$FL_DATE))
flights$Quarter = as.character(quarter(flights$FL_DATE))


## Re-categorizing scheduled departure and arrival times into categories
flights$CRS_DEP_TIME_GRP = ifelse(flights$CRS_DEP_TIME > 2200 | flights$CRS_DEP_TIME <= 400, "Red Eye",
                                   ifelse(flights$CRS_DEP_TIME>400 & flights$CRS_DEP_TIME <=1000,"Early AM",
                                          ifelse(flights$CRS_DEP_TIME > 1000 & flights$CRS_DEP_TIME<=1600,"Mid Day","Evening")))

flights$CRS_ARR_TIME_GRP = ifelse(flights$CRS_ARR_TIME > 2359 | flights$CRS_ARR_TIME <= 600, "Early AM",
                                   ifelse(flights$CRS_ARR_TIME>600 & flights$CRS_ARR_TIME <=1200,"Morning",
                                          ifelse(flights$CRS_ARR_TIME > 1200 & flights$CRS_ARR_TIME<=1800,"Afternoon","Evening")))

## Establish flight days near major US holidays
## Christmas/ New Year (12/21-1/4), Thanksgiving (need to get specifics!!), 4th of July (1st-7th)
xmas = as.Date(c("2014-12-25","2015-12-25","2016-12-25"), format = "%Y-%m-%d")
xmasev = as.Date(c("2014-12-24","2015-12-24","2016-12-24"), format = "%Y-%m-%d")
ny =   as.Date(c("2014-01-01","2015-01-01","2016-01-01"), format = "%Y-%m-%d")
frth = as.Date(c("2014-07-04","2015-07-04","2016-07-04"), format = "%Y-%m-%d")
thx = as.Date(c("2014-11-27","2015-11-26","2016-11-24"), format = "%Y-%m-%d")

## Create a new variable within major US holidays
holidays = c(xmas,xmasev,ny,frth,thx)
holiday_within_3 = c()
for(i in 1:length(holidays)){
  pm = holidays[i]+c(-3:3)
  holiday_within_3 = c(holiday_within_3, pm)
}
holiday_within_3 = as.Date(holiday_within_3)

## Binary identifier for flights near major US holidays
flights$Holiday = 0
flights$Holiday[which(flights$FL_DATE %in% holiday_within_3)] = 1

## Create outcome major delay label: 1 if delayed by 30+ or canceled, 0 otherwise
flights$maj_delay = 0
flights$maj_delay[which(flights$ARR_DELAY >= 30)] = 1
flights$maj_delay[which(is.na(flights$ARR_DELAY))] = 1

## Create index of major delay percentage
cutoff = "2016-01-01"
fl_14_15 = flights[flights$FL_DATE < as.Date(cutoff),]
ID_count = as.data.frame(tally(fl_14_15$flight_ID))
maj_delay_count = aggregate(maj_delay ~ flight_ID, data = fl_14_15, FUN = sum)

ID_delay_rate_lookup = cbind(maj_delay_count$flight_ID, round(maj_delay_count$maj_delay/ID_count$Freq,3), ID_count$Freq)
colnames(ID_delay_rate_lookup) = c("flight_ID", "delay_pct", "n_ID")

## Append to the flights data frame
flights = merge(flights, ID_delay_rate_lookup, by = "flight_ID", 
                sort = FALSE, all.x = TRUE)
flights = flights[order(flights$FL_DATE),]
flights$delay_pct = as.numeric(levels(flights$delay_pct))[flights$delay_pct]

## Impute values for the 2016 NA's as the mean from 2014-2015. Summary function can
## provide the mean excluding the NA's
flights$delay_pct[which(is.na(flights$delay_pct))] = summary(flights$delay_pct)[4]

train = flights[flights$FL_DATE < as.Date(cutoff),]
test = flights[flights$FL_DATE >= as.Date(cutoff),]
