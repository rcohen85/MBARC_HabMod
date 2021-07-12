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
library(reshape2)
library(data.table)
library(mapdata)

#### User Defined parameters ####
#Define spatial scale of interest
xpos = c(-122,-123) #longitude -- look at the data's homepage to ensure your lat/longs are in the correct format
ypos = c(36,37) #latitude -- look at the data's homepage to ensure your lat/longs are in the correct format
zpos = c(0.0,0.0) #altitude (not all data has a z variable)

#Define temporal range of interest
tpos = c("2014-04-15","2017-04-15") 

### Obtaining information about the dataset of interest from the ERDDAP server ####
require(rerddap)
require(rerddapXtracto)
  #baseURL of the ERDDAP server is https://upwell.pfeg.noaa.gov/erddap/index.html
  #datasetID of the data to be accessed
dataInfo = info('erdMBchla1day')

#### Extracting data and plotting ####
myFunc = function(x) log(x) #function for plotting in log

#Extracting data and plotting a single time period
#Using the VIIRSN data as an example - https://coastwatch.pfeg.noaa.gov/erddap/griddap/erdVH3chlamday.graph
require("rerddapXtracto")
ChlInfo = rerddap::info('erdVH3chlamday')
parameter = 'chla'
sanctchl = rxtractogon(ChlInfo, parameter = parameter, xcoord = xpos, ycoord = ypos,  tcoord = tpos) #extracts the data as a time series
str(sanctchl)
sanctchl1 = sanctchl
sanctchl1$chla = sanctchl1$chla[, , 2] #choosing the 2nd time 
sanctchl1$time = sanctchl1$time[2] #choosing the 2nd time
sanctchlPlot = plotBBox(sanctchl1, plotColor = 'algae', myFunc = myFunc)
sanctchlPlot

#Extracting and Plotting 3D data
VIIRSInfo <- rerddap::info('erdVH3chlamday')
parameter = 'chla'
VIIRS = rxtracto_3D(VIIRSInfo,parameter = parameter, xcoord = xpos, ycoord = ypos, tcoord = tpos) #returns the data as an array
str(VIIRS)
Chl3DPlot = plotBBox(VIIRS, plotColor = 'algae', myFunc = myFunc)
Chl3DPlot

#Using MODIS data as another example
dataInfo = rerddap::info('erdMH1chlamday')
parameter = dataInfo$variable$variable_name # Extract the parameter name from the metadata in dataInfo
global = dataInfo$alldata$NC_GLOBAL #Extract the start and end times of the dataset from the metadata in dataInfo
# Populate the time vector with the time_coverage_start from dataInfo
# Use the "last" option for the ending date
tt = global[ global$attribute_name %in% c('time_coverage_end','time_coverage_start'), "value", ]
tcoord = c(tt[2],"last")
# Run rxtracto_3D
chlMODIS = rxtracto_3D(dataInfo,parameter=parameter,
                      tcoord=tpos,
                      xcoord=xpos,ycoord=ypos)

#### Create timeseries of mean montly data using the MODIS data ####
## Spatially average all the data within the box for each dataset.
## The c(3) indicates the dimension to keep - in this case time 
chlMODIS$avg <- apply(chlMODIS$chlorophyll, c(3),function(x) mean(x,na.rm=TRUE))

## Temporally average all of the data into one map 
## The c(1,2) indicates the dimensions to keep - in this case latitude and longitude  
chlMODIS$avgmap <- apply(chlMODIS$chlorophyll,c(1,2),function(x) mean(x,na.rm=TRUE))

##Format Box Coordinates for cosmetics, to make a nice map title
ttext<-paste(paste(abs(xpos), collapse="-"),"W, ", paste(ypos, collapse="-"),"N")

#Plot time series
plot(as.Date(chlMODIS$time), chlMODIS$avg, 
     type='b', bg="blue", pch=21, xlab="", cex=.7,
     ylab="Chlorophyll", main=ttext)

#### Working with sparse data ####
# ESA integrates data from all these sensors into one; good for remote locations
dataInfo = rerddap::info('pmlEsaCCI31OceanColorMonthly')

# This identifies the parameter to choose - there are > 60 in this dataset1 
parameter = 'chlor_a'

global = dataInfo$alldata$NC_GLOBAL
tt = global[ global$attribute_name %in% c('time_coverage_end','time_coverage_start'), "value", ]
tcoord = c(tt[2],"last")
# if you encouter an error reading the nc file clear the rerrdap cache: 
rerddap::cache_delete_all(force = TRUE)

chlOCCCI<-rxtracto_3D(dataInfo,parameter=parameter,
                      tcoord=tpos,
                      xcoord=xpos,ycoord=ypos)

# Now spatially average the data into a timeseries
chlOCCCI$avg = apply(chlOCCCI$chlor_a, c(3),function(x) mean(x,na.rm=TRUE))

# Now temporally average the data into one map 
chlOCCCI$avgmap = apply(chlOCCCI$chlor_a,c(1,2),function(x) mean(x,na.rm=TRUE))

#Plot the ESA OCCI data
plot(as.Date(chlOCCCI$time), chlOCCCI$avg, 
     type='b', bg="blue", pch=21, xlab="", cex=.7,
     ylab="Chlorophyll", main=ttext)

#### Plot the average chlorophyll for one satellite ####
coast = map_data("worldHires", ylim = ypos, xlim = xpos)

# Put arrays into format for ggplot
melt_map = function(lon,lat,var) {
  dimnames(var) = list(Longitude=lon, Latitude=lat)
  ret = melt(var,value.name="Chl")
}

chlmap = melt_map(chlOCCCI$longitude, chlOCCCI$latitude, chlOCCCI$avgmap)

p = ggplot(
  data = chlmap, 
  aes(x = Longitude, y = Latitude, fill = log(Chl))) +
  geom_raster(interpolate = FALSE, na.rm=T) +
  geom_polygon(data = coast, aes(x=long, y = lat, group = group), fill = "grey80") +
  theme_bw(base_size = 12) + ylab("Latitude") + xlab("Longitude") +
  coord_fixed(1.3, xlim =c(min(xpos), max(xpos)), ylim = c(min(ypos), max(ypos))) +
  scale_fill_gradientn(colours = rev(rainbow(12)), na.value = NA, limits=c(-2,3)) +
  ggtitle(paste("Average Chlorophyll")
  ) 
