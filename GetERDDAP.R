#This script queries the ERDDAP database for data
#Learn more about the database here: https://coastwatch.pfeg.noaa.gov/erddap/index.html
#NP 07/09/2021

#Load packages
library(rerddap)
library(rerddapXtracto)
library(ncdf4)
library(parsedate)
library(sp)
library(gganimate)
library(ggplot2)
library(plotdap)

#Define spatial scale of interest
xpos = c(125,130) #longitude
ypos = c(30,36) #latitude
zpos = c(0.0,0.0) #altitude

#Define temporal scale of interest
tpos = c("2017-04-15","2019-04-15") 

myFunc <- function(x) log(x) #function for plotting in log

#Obtain information about the dataset of interest from the ERDDAP server
require(rerddap)
require(rerddapXtracto)
  #baseURL of the ERDDAP server is https://upwell.pfeg.noaa.gov/erddap/index.html
  #datasetID of the data to be accessed
dataInfo = info('erdMBchla1day')

#Extracting a time-series and Plotting a single time period
EnvData_ts = rxtractogon(dataInfo, parameter = dataInfo$variables[[1]], xcoord = xpos, ycoord = ypos, tcoord = tpos, zcoord = zpos)
#plotting a single time period
EnvData_ts$chla <- EnvData_ts$chla[, , 2]
EnvData_ts$time <- EnvData_ts$time[2]
ChlPlot <- plotBBox(ChlPlot, plotColor = 'algae', myFunc = myFunc)
ChlPlot

#Extracting and Plotting 3D data
EnvData = rxtracto_3D(dataInfo,parameter = dataInfo$variables[[1]], xcoord = xpos, ycoord = ypos, tcoord = tpos, zcoord = zpos)
Chl3DPlot <- plotBBox(EnvData, plotColor = 'algae', myFunc = myFunc)
Chl3DPlot
