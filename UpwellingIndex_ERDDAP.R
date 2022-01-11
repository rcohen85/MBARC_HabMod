# Calculate daily mean upwelling index  from ERDDAP Ekman Transport
#
# Depending on the datasource you use, you may need to change variable names found in .nc file
# (latitude, longitude, ektrx, ektry)
# This code will calculate daily upwelling index, but you get higher resolution at line 87 if needed
#
#
#
#
#
# Vanessa ZoBell August 17, 2021
#
#
#
#
# First you will need to find a dataset of ekman transport in the x and y direction.
# I used data from ERRDAP but I'm sure there are other data sources out there.
# https://coastwatch.pfeg.noaa.gov/erddap/griddap/erdlasFnTran6_LonPM180.html
# Download your ERRDAP Ekman Transport data as a .nc file.
#
#
# ------------------------------------------ Load packages and functions

library(ncdf4)           # for opening .nc files
library(lubridate)       # for dates
library(dplyr)           # for data wrangling
library(tidyverse)       # "because it literally does everything" - Natalie
library(timetk)          # timeseries plots (just in case you want to see a plot of it)

upwell <- function(ektrx, ektry, coast_angle) {
  pi <- 3.1415927
  degtorad <- pi/180.
  alpha <- (360 - coast_angle) * degtorad
  s1 <- cos(alpha)
  t1 <- sin(alpha)
  s2 <- -1 * t1
  t2 <- s1
  perp <- (s1 * ektrx) + (t1 * ektry)
  para <- (s2 * ektrx) + (t2 * ektry)
  return(perp/10)
}


# to convert dates in .nc files
daysFromDate <- function(data1, data2="1970-01-01")
{
  round(as.numeric(difftime(data1,data2,units = "secs")))
}

# ------------------------------------------ Change site specific variables

# latitude and longitude bounds for your site of interest
lat_hi = 34.6
lat_lo = 33.6
long_hi = -119
long_lo = -121

# start date and end date for your site of interest
startDate = "2009-11-03"
endDate = "2014-12-31"

# working directory
wd = "G:/Shared drives/Ashley Adornato"
# filename with file extension
filename = 'UpwellingIndex2.nc'

# Coast angle, NEED TO LOOK UP FOR YOUR SITE https://oceanview.pfeg.noaa.gov/products/upwelling/bakun
# the angle the coast makes with north in the mathematical sense,
# and is defined as the angle the landward side of the coastline makes.
coastAngle = 135


# ------------------------------------------ Calculate Upwelling Index
## Loading in .nc files downloaded from ERRDAP
setwd(wd)
UIndex = nc_open(filename)

## pulling out lat, lon, and time variables for Ekman Transport from .nc file
lon = ncvar_get(UIndex, "longitude")
lat = ncvar_get(UIndex, "latitude")
time = ncvar_get(UIndex, "time")

## indexing for data within specific lat and lon bounds
lonIdx <- which( lon >= long_lo & lon <= long_hi)
latIdx <- which( lat >= lat_lo & lat <= lat_hi)

## indexing for data within specific time bounds
myTime <- c(daysFromDate(startDate), daysFromDate(endDate))
timeIdx <- which(time >= myTime[1] & time <= myTime[2])

## pulling out curl, ektrx, and ektry data from from lat, lon, and time indices
## you actually don't need curl for the Upwelling Index, but I'll leave it here just in case someone wants it
curl <- ncvar_get(UIndex, "curl")[lonIdx, latIdx, timeIdx]
ektrx = ncvar_get(UIndex, "ektrx")[lonIdx, latIdx, timeIdx]
ektry = ncvar_get(UIndex, "ektry")[lonIdx, latIdx, timeIdx]

## getting indices for lat, long, time data
indices <- expand.grid(lon[lonIdx], lat[latIdx], time[timeIdx])

## creating data frame for each variable for specific indices
curl <- data.frame(cbind(indices, as.vector(curl)))
ektrx <- data.frame(cbind(indices, as.vector(ektrx)))
ektry <- data.frame(cbind(indices, as.vector(ektry)))

## creating dataframe with Ekman Transport x and y for upwelling index calculation
ekmanALL = left_join(ektrx, ektry)

## getting rid of n/a
ekmanALL = na.omit(ekmanALL)

## converting date to usable format of date
ekmanALL$date = as.Date(format(as.POSIXct(ekmanALL$Var3, origin =   "1970-01-01",tz = "GMT"), format = '%Y-%m-%d'))

## average ekman x and y to get mean daily values
ekmanDay <- ekmanALL %>%
  group_by(date) %>%
  summarize(ektrx = mean(as.vector.ektrx.),
            ektry = mean(as.vector.ektry.))


ekmanDay$UI = upwell(ekmanDay$ektrx, ekmanDay$ektry, coast_angle = coastAngle)
ekmanDay %>%
  plot_time_series(date, UI,
                   .color_var = year(date),
                   .facet_ncol = 2,
                   .facet_scales = "free",
                   .interactive = FALSE,
                   .title = "Upwelling Index",
                   .x_lab = "Date (1 day intervals)",
                   .y_lab = "Upwelling Index",
                   .color_lab = "Year")
