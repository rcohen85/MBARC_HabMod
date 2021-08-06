setwd("G:/Shared drives/Ashley Adornato/")
getwd()
install.packages("ncdf4")
library(ncdf4)
install.packages("lubridate")
library(lubridate)
library(dplyr)
library(gam)
library(mgcv)
library(mgcViz)
daysFromDate <- function(data1, data2="1970-01-01")
{
  round(as.numeric(difftime(data1,data2,units = "secs")))
}

matlab2POS = function(x, timez = "UTC") {
  days = x - 719529 	# 719529 = days from 1-1-0000 to 1-1-1970
  secs = days * 86400 # 86400 seconds in a day
  # This next string of functions is a complete disaster, but it works.
  # It tries to outsmart R by converting the secs value to a POSIXct value
  # in the UTC time zone, then converts that to a time/date string that
  # should lose the time zone, and then it performs a second as.POSIXct()
  # conversion on the time/date string to get a POSIXct value in the user's
  # specified timezone. Time zones are a goddamned nightmare.
  return(as.POSIXct(strftime(as.POSIXct(secs, origin = '1970-1-1',
                                        tz = 'UTC'), format = '%Y-%m-%d %H:%M',
                             tz = 'UTC', usetz = FALSE), tz = timez))
}

sst2008_2012 <- nc_open('SSTjan2008_to_dec2012.nc')
chloa2008_2012 <- nc_open('CHLOAjan2008_to_dec2012.nc')
sss2011_2012 <- nc_open('SSSaug2011_to_dec2012.nc')
print(sst2008_2012)



# --------------------------------- SST

#pulling out lat, time, and lon variables for sst from .nc file
lon <- ncvar_get(sst2008_2012, "longitude")
lat <- ncvar_get(sst2008_2012, "latitude")
time <- ncvar_get(sst2008_2012, "time")


#filtering (indexing) for data within specific lat and lon bounds
lonIdx <- which( lon >= -121 & lon <= -117)
latIdx <- which( lat >= 31.5 & lat <= 35.5)

#filtering (indexing) for data within specific time bounds
myTime <- c(daysFromDate("2009-11-03"), daysFromDate("2012-12-31"))
timeIdx <- which(time >= myTime[1] & time <= myTime[2])

#pulling out sstdata from indexed lat,lon, and time
data <- ncvar_get(sst2008_2012, "sst")[lonIdx, latIdx, timeIdx]


#pulling out lat, long, time data from indeces
indices <- expand.grid(lon[lonIdx], lat[latIdx], time[timeIdx])
print(length(indices))
class(indices)
summary(indices)
str(indices)


#binding together sst, lat, long, and time
dfsst <- data.frame(cbind(indices, as.vector(data)))
summary(df)
str(df)


#converting date to a different format of date
dfsst$date = as.character(as.Date(format(as.POSIXct(dfsst$Var3, origin =   "1970-01-01",tz = "GMT"), format = '%Y-%m-%d')))

#getting rid of n/a
dfsst = na.omit(dfsst)


#taking the mean daily sst
sstday <- dfsst %>%
  group_by(date) %>%
  summarize(avg_sst_per_day = mean(as.vector.data.))


# ------------------------------------ CHLORA
lon <- ncvar_get(chloa2008_2012, "longitude")
lat <- ncvar_get(chloa2008_2012, "latitude")
time <- ncvar_get(chloa2008_2012, "time")



lonIdx <- which( lon >= -121 & lon <= -117)
latIdx <- which( lat >= 31.5 & lat <= 35.5)

myTime <- c(daysFromDate("2009-11-03"), daysFromDate("2012-12-31"))
timeIdx <- which(time >= myTime[1] & time <= myTime[2])

data <- ncvar_get(chloa2008_2012, "chlorophyll")[lonIdx, latIdx, timeIdx]

indices <- expand.grid(lon[lonIdx], lat[latIdx], time[timeIdx])
print(length(indices))
class(indices)
summary(indices)
str(indices)



dfchlora <- data.frame(cbind(indices, as.vector(data)))
summary(df)
str(df)
format = "%Y-%m-%d"
dfchlora$date = as.character(as.Date(format(as.POSIXct(dfchlora$Var3, origin =   "1970-01-01",tz = "GMT"), format = '%Y-%m-%d')))

#getting rid of n/a
dfchlora = na.omit(dfchlora)


#taking the mean daily chlorA
chloraday <- dfchlora %>%
  group_by(date) %>%
  summarize(avg_chlora_per_day = mean(as.vector.data.))

#latCB = 34.247568
#longCB = -120.025978
#lat_hi = latCB + ((10/6377)*(180/pi))
#lat_lo = latCB - ((10/6377)*(180/pi))
#long_hi = longCB + ((10/6378)*(180/pi))/cos(latCB*pi/180)
#long_lo = longCB - ((10/6378)*(180/pi))/cos(latCB*pi/180)
#newdf = filter(df, Var2 > lat_lo & Var2 < lat_hi)

#---------------------------------------------SSS

lon <- ncvar_get(sss2011_2012, "longitude")
lat <- ncvar_get(sss2011_2012, "latitude")
time <- ncvar_get(sss2011_2012, "time")



lonIdx <- which( lon >= -121 & lon <= -117)
latIdx <- which( lat >= 31.5 & lat <= 35.5)

myTime <- c(daysFromDate("2009-11-03"), daysFromDate("2012-12-31"))
timeIdx <- which(time >= myTime[1] & time <= myTime[2])

data <- ncvar_get(sss2011_2012, "sss")[lonIdx, latIdx, timeIdx]

indices <- expand.grid(lon[lonIdx], lat[latIdx], time[timeIdx])
print(length(indices))
class(indices)
summary(indices)
str(indices)



dfsss <- data.frame(cbind(indices, as.vector(data)))
summary(df)
str(df)

dfsss$date = as.character(as.Date(as.POSIXct(dfsss$Var3,origin = "1970-01-01",tz = "GMT")))

dfsss = na.omit(dfsss)
sssday <- dfsss %>%
  group_by(date) %>%
  summarize(avg_sss_per_day = mean(as.vector.data.))

#------------------------------------------------------------
#combine all data
humpbackdata = read.csv('G:/My Drive/Mentoring/Ashley Adornato/migration data analysis/HumpbackDetectionsHabitatModel.csv')
humpbackdata$date = as.character(as.Date(matlab2POS(humpbackdata$datenum)))

masterdf = left_join(humpbackdata, chloraday, by = 'date')
masterdf = left_join(masterdf, sstday, by = 'date')
masterdf = left_join(masterdf, sssday, by = 'date')


#--------------------------------------------------------
#gam

nullModel = gam(CallingHours~1, data = masterdf)
AIC(nullModel)

# ------------ chlora test and smooth chlora test
model1 = gam(CallingHours ~ avg_chlora_per_day, data = masterdf)
model2 = gam(CallingHours~ s(avg_chlora_per_day), data = masterdf)
AIC(model1)
AIC(model2)
summary(model2)

b = getViz(model2)
print(plot(b, allTerms = T), pages = 1)


#--------------------sst test and smooth sst test
model1 = gam(CallingHours ~ avg_sst_per_day, data = masterdf)
model2 = gam(CallingHours~ s(avg_sst_per_day), data = masterdf)
AIC(model1)
AIC(model2)
summary(model2)


#--------------------------------sss test and smooth sss test
model1 = gam(CallingHours ~ avg_sss_per_day, data = masterdf)
model2 = gam(CallingHours~ s(avg_sss_per_day), data = masterdf)
AIC(model1)
AIC(model2)
summary(model2)
test

#---------------------------------full ADDITIVE model
modelfull = gam(CallingHours ~ s(avg_chlora_per_day) + s(avg_sst_per_day), data = masterdf)
AIC(modelfull)
summary(modelfull)

b = getViz(modelfull)
print(plot(b, allTerms = T), pages = 1)


