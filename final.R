rm(list=ls())
wd<-getwd()
setwd(wd)

event<-read.csv("event.csv")

event<-na.omit(event)

newdata <- event[which(event$ebt_snap=='1'),]


event1<-aggregate(newdata[, 2:4], list(newdata$hhnum), sum)
names(event1)[1]<-"hhnum"

# Household data set
hh<-read.csv("household.csv")
hh<-na.omit(hh)


hh1 <- hh[ which(hh$snapnowhh=='1' & hh$snapnowreport ==1),]


#joining two data set by hhnum
#finaldata<-hh1[hh1$hhnum%in%event1$Group.1,]

#event1[!event1$Group.1%in%hh1$hhnum,]

final.data<-merge(hh1, event1)

# remove duplicate household if any.. 
final.data<-final.data[!duplicated(final.data$hhnum), ]

#recoding region variable
final.data$region[final.data$region==1]="Northeast"
final.data$region[final.data$region==2]="Midwest"
final.data$region[final.data$region==3]="South"
final.data$region[final.data$region==4]="West"

#recoding rural variable
final.data$rural[final.data$rural==1]="Rural"
final.data$rural[final.data$rural==0]="Urban"

# recoding adjtfscat variable 
final.data$adltfscat[final.data$adltfscat==1]="High"
final.data$adltfscat[final.data$adltfscat==2]="Marginal"
final.data$adltfscat[final.data$adltfscat==3]="Low"
final.data$adltfscat[final.data$adltfscat==4]="very low"

summary(final.data)
# I categorized total weekly food expenditure on food at home based on Official USDA Food Plans,
# based on  weekly food expenditure for a family of 4 (which is average household size in our data) is $129.5.
# I am interested to examine the proportion of hosehold that have met the food expenditure requirement on the basis of Thrifty Food Plan and Dietary Guidelines of america. 

final.data$total.paid <- ifelse(final.data$totalpaid > 129, 
                        c("1"), c("0")) 

# converting numeric variable into factor 
final.data$total.paid<-as.factor(final.data$total.paid)

final.data$region<-as.factor(final.data$region)
final.data$hhsize<-as.factor(final.data$hhsize)
final.data$rural <-as.factor(final.data$rural)
final.data$targetgroup<-as.factor(final.data$targetgroup)
final.data$selfemployhh<-as.factor(final.data$selfemployhh)
final.data$housingown<-as.factor(final.data$housingown)

final.data$liqassets<-as.factor(final.data$liqassets)
final.data$anyvehicle<-as.factor(final.data$anyvehicle)
final.data$foodsufficient<-as.ordered(final.data$foodsufficient)
final.data$grocerylistfreq<-as.factor(final.data$grocerylistfreq)
final.data$anyvegetarian<-as.factor(final.data$anyvegetarian)
final.data$nutritioneduc<-as.factor(final.data$nutritioneduc)
final.data$eathealthyhh<-as.factor(final.data$eathealthyhh)
final.data$adltfscat<-as.ordered(final.data$adltfscat)
final.data$dietstatuspr<-as.factor(final.data$dietstatuspr)

# structure of data
str(final.data)

#Exploratory data analysis
#install.packages("DataExplorer")
library(DataExplorer)
basic_eda <- function(data)
{
  head(data)
  df_status(data)
  freq(data) 
  profiling_num(data)
  plot_num(data)
  describe(data)
}

basic_eda(final.data)


library(ggplot2)

g2<-ggplot(final.data) + 
  geom_bar(aes(primstoresnaptype,totalpaid, fill =primstoresnaptype), stat = "summary", fun.y = "mean")
g2 + labs(title = "Total expenditure by store types", xlab="Store type", ylab="Weekly food expenditure $")


g3<-ggplot(data =final.data) +
  geom_bar(aes(region,ebt_snapamt, fill=region), stat = "summary", fun.y = "mean")
g3 + labs(x="Region ", y="Weekly food expenditure",title = "Food expenditure by regions")


g4<-ggplot(data =final.data) +
  geom_bar(aes(rural,totalpaid, fill=rural), stat = "summary", fun.y = "mean")
g4 + labs(x="Rural ", y="Weekly food expenditure",title = "Food expenditure by rural and urban region")

  g5<-ggplot(final.data, aes(x=adltfscat, y=totalpaid, group=rural)) +
  geom_line(aes(color=rural))+
  geom_point(aes(color=rural))
g5+labs(x="Food security ", y="Weekly food expenditure",title = "Food expenditure  with food security levels")


g6<-ggplot(data =final.data) +
  geom_bar(aes(hhsize,totalpaid, fill=hhsize), stat = "summary", fun.y = "mean")
g6 + labs(x="HH size ", y="Weekly food expenditure",title = "Food expenditure by HH size")

#predicting model using mechine learning 
library(tidyverse)

library(caret)
library(randomForest)
require(e1071)
library(DataExplorer)
set.seed(1337)

# tainControl function
train_control<-trainControl(method = "cv", number=10)

# create an index to partition data
index <- createDataPartition(final.data$total.paid, p=0.75, list=FALSE)

# spliting data in to training and testing groups
trainSet <- final.data[ index,]
testSet <- final.data[-index,]

#Feature selection using rfe in caret
#control <- rfeControl(functions = rfFuncs,method = "repeatedcv",repeats = 3,verbose = FALSE)

outcomeName<-'total.paid'
control <- rfeControl(functions = rfFuncs,
                      method = "repeatedcv",
                      repeats = 3,
                      verbose = FALSE)

predictors<-names(trainSet)[!names(trainSet) %in% outcomeName]
spend_Pred_Profile <- rfe(trainSet[,predictors], trainSet[,outcomeName],
                         rfeControl = control)
spend_Pred_Profile

# Total potential predictors

#predictors<-c("hhsize", "region", "rural", "itemstot", "anyvegetarian","inchhavg_r", "liqassets", "selfemployhh", "anyvehicle", "largeexp","adltfscat", "foodsufficient", "dietstatuspr", "grocerylistfreq", "primstoresnaptype", "primstoredist_d", "nutritioneduc")

# Using several combinations of explatory variabls here I finalize following variables in the final model. 

predictors<-c("hhsize", "itemstot", "inchhavg_r", "grocerylistfreq", "primstoredist_d")

names(getModelInfo())

#random forest
model_rf<-train(total.paid~hhsize+itemstot +inchhavg_r+grocerylistfreq+primstoredist_d,method="rf", data=trainSet, trControl=train_control, na.action = na.omit)
model_rf
save(model_rf, file="RandomF.rda")


model_rf<-train(trainSet[,predictors],trainSet[,outcomeName],method='rf')
save(model_rf, file="RandomForest.rda")
print(model_rf)
confusionMatrix(model_rf)
#Creating grid

#Checking variable importance for GLM
varImp(object=model_rf)

#rf variable importance
plot(model_rf)
plot(varImp(object=model_rf),main="Random forest - Variable Importance")

#Predictions
predictions_rf<-predict.train(object=model_rf,testSet[,predictors],type="raw")
table(predictions_rf)
# Confusion matrix
confusionMatrix(predictions_rf,testSet[,outcomeName])


#Using gbm method

model_gbm<-train(trainSet[,predictors],trainSet[,outcomeName],method='gbm')
print(model_gbm)


#Checking variable importance for GBM

#Variable Importance
varImp(object=model_gbm)
plot(varImp(object=model_gbm),main="GBM - Variable Importance")

#Prediction with GBM
predictions_gbm<-predict.train(object=model_gbm,testSet[,predictors],type="raw")
table(predictions_gbm)

confusionMatrix(predictions_gbm,testSet[,outcomeName])

# Now Using nnet method

model_nnet<-train(trainSet[,predictors],trainSet[,outcomeName],method='nnet')
print(model_nnet)
plot(model_nnet)
# prediction with nnet
predictions_nnet<-predict.train(object=model_nnet,testSet[,predictors],type="raw")
table(predictions_nnet)

#Confusion Matrix and Statistics

confusionMatrix(predictions_nnet,testSet[,outcomeName])

confusionMatrix(predictions_gbm,testSet[,outcomeName])

confusionMatrix(predictions_rf,testSet[,outcomeName])


table(final.data$total.paid)
