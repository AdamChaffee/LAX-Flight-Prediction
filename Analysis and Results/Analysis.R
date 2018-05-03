## LAX Arrival delay analysis
## Adam Chaffee
setwd("C:/Users/achaf/OneDrive/Documents/DS Projects/LAX")

#############################
## Packages needed
#############################
## Data observations/visualization
library(mosaic)
## SVM will come from e1071
library(e1071)
## nnet neural net, function and multinom
library(nnet)
## Random forest
library(randomForest)
## xgboost
library(xgboost)
## Data visualization package
library(mosaic)

load("cleaned data.RData")

## Histogram of flight delays
histogram(train$ARR_DELAY, width = 10, xlim = c(-60, 180))
max(train$ARR_DELAY, na.rm = T)

## significant delay is greater than 30 mins
train$delay_sig = as.numeric(1 - train$ARR_DELAY<=30)
train = train[-which(is.na(train$delay_sig)),]
str(train)

## NA checking
for(i in 1:18){
  print(c(i,sum(which(is.na(train[,i])))))
}

## Let's consider "within 30 minute window" close enough to on-time
## Google Flights only alerts if a flight is expected to be more than 30 late
train$delayed.30 = ifelse(train$ARR_DELAY > 30 | is.na(train$ARR_DELAY), 1, 0)
test$delayed.30 = ifelse(test$ARR_DELAY > 30 | is.na(test$ARR_DELAY), 1,0)

## Delay categories
delayBreaks = c((-3:6)*30,3000)
train$delay.block.30 = cut(train$ARR_DELAY, breaks = delayBreaks)

##################################
## Analysis - GLM
##################################
set.seed(1337)
flt_samp = sample(1:428469, 50000)
flights_samp = train[flt_samp,]

## Modeled all except "DIST" and "CARRIER" and "as.factor(DISTANCE_GROUP)" 
## Note that at least one factor is missing due to collinearity
#names(train)
#model.glm = glm(delayed.30 ~ FL_DATE+flight_ID+CRS_DEP_TIME+CRS_ARR_TIME+DISTANCE+
#                DOW+Month+as.factor(Quarter)+CRS_DEP_TIME_GRP+CRS_ARR_TIME_GRP+Holiday,
#                family = "binomial", data = train)
#summary(model.glm)

train$delayed = as.numeric(1 - train$ARR_DELAY<=0)
head(train$delayed)

##################################
## Analysis Random Forest
##################################
## Random Forest limitations:
## (1) cannot handle predictors with more than 53 categories (excludes CARRIER)
## (2) cannot handle the full data frame. Worked for sample of 50,000

## Predictors based on Alex's xgboost feature importance
head(train)
flights.rf.df = train[,c("DEST", "DISTANCE", "DOW", "Month", "Quarter", "CRS_DEP_TIME_GRP",
                      "CRS_ARR_TIME_GRP", "Holiday", "delay_pct", "delayed.30")]

check_ind = dim(flights.rf.df)[2]
for(i in 1:check_ind){
  print(c(i,sum(which(is.na(flights.rf.df[,i])))))
}

for(i in c(1,3:7)){
  flights.rf.df[,i] = as.factor(flights.rf.df[,i])
}

set.seed(1337)
flt_samp = sample(1:433201, 50000)
rf.sample = flights.rf.df[flt_samp,]

head(rf.sample)

## random forest run
names(rf.sample)
rf.flights = randomForest(x = rf.sample[,1:9], y = as.factor(rf.sample$delayed.30), mtry = 3)
rf.flights

conf = rf.train$confusion
acc = sum(diag(conf))/sum(conf)
sens = 1 - conf[2,3]
spec = 1-conf[1,3]

## Really bad sensitivity at 6%, overall accuracy 84%
RF = data.frame(c(acc, sens, spec), row.names = c("Accuracy", "Sensitivity", "Specificity"))
names(RF) = c("Random Forest Results")
RF

rf.train$importance

########################
## For loop
########################
flights.rf.df = flights[,c(5:14,17)]

for(i in 5:9){
  flights.rf.df[,i] = as.factor(flights.rf.df[,i])
}
set.seed(1337)
flt_samp = sample(1:433201, 50000)
rf.sample = flights.rf.df[flt_samp,]

## random forest loop run to find best sensitivity
## This loop took about 20 minutes to run on my computer
RF_loop_df = data.frame(c(rep(0,10)), c(rep(0,10)), c(rep(0,10)))
names(RF_loop_df) = c("Accuracy", "Sensitivity", "Specificity")

for(i in 1:10){
  rf.flights = randomForest(x = rf.sample[,1:10], y = as.factor(rf.sample$delayed.30), mtry = i,
                            ntree = 1000)
  conf = rf.train$confusion
  RF_loop_df[i,1] = sum(diag(conf))/sum(conf)
  RF_loop_df[i,2] = 1 - conf[2,3]
  RF_loop_df[i,3] = 1 - conf[1,3]
  print(i)
}
RF_loop_df_node1 = RF_loop_df

rf.flights = randomForest(x = rf.sample[,1:10], y = as.factor(rf.sample$delayed.30), mtry = 10,
                          ntree = 1000)