#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Aug  5 17:05:00 2026

@author: miaemanuele
"""

########################## MODEL 1 ##########################

##-- Finding the best two-predictor linear model to predict Overall.

library(tidyverse) 
library(olsrr) 

imd = read_csv('imd2025_individual.csv')
 
model = lm(Overall~ Employment + Health + Living + Crime 
           + Education + Income + Barriers, data = imd) 

ols_step_best_subset(model, max_order = 2) 

model = lm(Overall~Living+Employment, data=imd) 
summary(model)


##-- Producing diagnostic plots for further evidence 
#    of the best predictive model.

library(ggfortify) 

model = lm(Overall~ Living + Employment, data = imd) 
autoplot(model, data = imd) 

model = lm(Overall~ Employment + Income, data = imd) 
autoplot(model, data = imd)




########################## MODEL 2 ##########################


##-- Finding the best linear model to predict Overall that uses 
#    at most four quantitative predictors.

model = lm(Overall~ Employment + Health + Living + Crime + Education +
           Income + Barrier,, data = imd)

ols_step_best_subset(model, max_order = 4)





########################## MODEL 3 ##########################

##-- Finding the best linear model to predict Overall in London only,
#    that uses at most four quantitative predictors (excluding Rank) 
#    but must include Crime.

London = read_csv('London.csv') 

model = lm(Overall~ Employment + Health + Living + Crime + Education + 
           Income + Barriers, data = London) 

ols_step_best_subset(model, include = c("Crime"), max_order = 4)



##-- Checking if the same predictors are selected for the  
#    equivalent best linear model to predict Overall in all districts 
#    NOT in London.

Not_London = read_csv('Not_London.csv') 

model = lm(Overall~ Employment + Health + Living + Crime + 
           Education + Income + Barriers, data = Not_London) 

ols_step_best_subset(model, include = c("Crime"), max_order = 4)



########################################################

##-- Using diagnostic plots to discuss whether any of the districts 
#    in the dataset need further investigation

model = lm(Overall~ Employment + Living + Education + 
           Income, data = imd) 

autoplot(model, data=imd, colour="Rank")



#######################################################

##-- Comapring the three models against each other using AIC

model = lm(Overall~Living+Employment, data=imd) 
summary(model) 

ols_step_best_subset(model, metric = "aic") 

model = lm(Overall~ Employment + Living + Education + 
           Income, data = imd) 
summary(model) 

model = lm(Overall~ Living + Crime + Education + 
           Income, data = London)
summary(model)


