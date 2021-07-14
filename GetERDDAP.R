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
library(tidyverse)
library(lubridate)
library(dplyr)
library(oce)

#### Data exploration ####
#You can search publicaly available data from ERDDAP by variable or time frame of interest
#simple search
SSH.dataset = ed_search(query='SSH') #sea surface height anomaly data sets
SST.dataset = ed_search(query= 'SST')
#advanced search
Upwelling.dataset = ed_search_adv(query = 'upwelling', maxLat = 63, minLon = -107, maxLon = -87, minLat = 50,
                      minTime = "2010-01-01T00:00:00Z",
                      maxTime="2010-02-01T00:00:00Z")


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
p

#### Access, Download, Process and VIsualize sea surface height and geostrophic current from AVISO ####
tpos = c("2017-04-15","2020-04-15")
SSHInfo = rerddap::info('nesdisSSH1day')

#Get u_current
u = rxtracto_3D(SSHInfo,parameter="ugos",
                tcoord=tpos,
                xcoord=xpos,ycoord=ypos)
u %>% glimpse()

lon = u$longitude
lat = u$latitude
time = u$time %>%as.Date()
u.data = u$ugos 

## obtain dimension
dimension = data.frame(lon, u.data[,,1]) %>% dim()

## convert the array into data frame
u.tb = data.frame(lon, u.data[,,1]) %>% 
  as_tibble() %>% 
  gather(key = "lati", value = "u", 2:dimension[2]) %>% 
  mutate(lat = rep(lat, each = dimension[1]), time = time[1]) %>% 
  select(lon,lat, time, u)

#Get v_current
v = rxtracto_3D(SSHInfo,parameter="vgos",
                tcoord=tpos,
                xcoord=xpos,ycoord=ypos)
v %>% glimpse()

lon = v$longitude
lat = v$latitude
time = v$time %>%as.Date()
v.data = v$vgos 

## obtain dimension
dimension = data.frame(lon, v.data[,,1]) %>% dim()

## convert the array into data frame
v.tb = data.frame(lon, v.data[,,1]) %>% 
  as_tibble() %>% 
  gather(key = "lati", value = "v", 2:dimension[2]) %>% 
  mutate(lat = rep(lat, each = dimension[1]), time = time[1]) %>% 
  select(lon,lat, time, v)

#Get SSH
SSH = rxtracto_3D(SSHInfo,parameter = "sla",
                tcoord=tpos,
                xcoord=xpos,ycoord=ypos)
SSH %>% glimpse()

lon = SSH$longitude
lat = SSH$latitude
time = SSH$time %>%as.Date()
SSH.data = SSH$sla 

## obtain dimension
dimension = data.frame(lon, SSH.data[,,1]) %>% dim()

## convert the array into data frame
SSH.tb = data.frame(lon, SSH.data[,,1]) %>% 
  as_tibble() %>% 
  gather(key = "lati", value = "SSH", 2:dimension[2]) %>% 
  mutate(lat = rep(lat, each = dimension[1]), time = time[1]) %>% 
  select(lon,lat, time, SSH)

ssh.in = oce::interpBarnes(x = SSH.tb$lon, y = SSH.tb$lat, z = SSH.tb$SSH)
dimension = data.frame(lon = ssh.in$xg, ssh.in$zg) %>% dim()

ssh.in = data.frame(lon = ssh.in$xg, ssh.in$zg) %>% 
  as_tibble() %>% 
  gather(key = "lati", value = "ssh", 2:dimension[2]) %>% 
  mutate(lat = rep(ssh.in$yg, each = dimension[1]), time = time[1]) %>% 
  select(lon,lat, time, ssh)

#combine dataframes into tibble
aviso = SSH.tb %>% 
  bind_cols(u.tb %>%select(u),
            v.tb %>% select(v))

#Visualizing the data
library(metR)
library(spData)
ggplot()+
  metR::geom_contour_fill(data = ssh.in, aes(x = lon, y = lat, z = ssh))+
  metR::geom_contour2(data = ssh.in, aes(x = lon, y = lat, z = ssh))+
  metR::geom_text_contour(data = ssh.in, aes(x = lon, y = lat, z = ssh), 
                          parse = TRUE, check_overlap = TRUE, size = 3.2)+
  geom_sf(data = spData::world, fill = "grey60", col = "grey20")+
  coord_sf(xlim = c(39,49.5), ylim = c(-14.5,-8))+
  theme(legend.position = "none")+
  labs(x = NULL, y = NULL)+
  scale_fill_gradientn(name = "ssh (m)",colours = oce::oceColors9A(120), na.value = "white")+
  scale_x_continuous(breaks = seq(39.5, 49.5, length.out = 4) %>%round(1))+
  scale_y_continuous(breaks = seq(-14,-8, 2))+
  guides(fill = guide_colorbar(title = "Sea surface height (m)", 
                               title.position = "right", title.theme = element_text(angle = 90), 
                               barwidth = 1.25, barheight = 10, draw.ulim = 1.2, draw.llim = 0.6))+
  theme_bw()+
  theme(axis.text = element_text(colour = 1, size = 11))
