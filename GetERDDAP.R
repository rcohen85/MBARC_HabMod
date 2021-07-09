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