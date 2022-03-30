# This code will calculate the distance to the gulf stream, saving a time series
# of Gulf Stream frontal position and distance to front for each HARP site

## Settings --------------------------------------------------------------------
library(lubridate)
library(geodist)
library(stringr)

inDir = 'E:/hycom/0.08deg'
outDir = 'E:/hycom'
sites = c('HZ','OC','NC','BC','WC','NFC','HAT','GS','BP','BS','JAX')
setLon = as.numeric(-74.5)

#HARP Sites
OC_change = as_date('2018-05-01') # account for change in
HAT_change = as_date('2017-05-01') # account for change in HAT location from site A to B
HARPs = data.frame(t(data.frame(c(41.06165, -66.35155), # WAT_HZ
                                c(40.26333,-67.9861,40.26333,-67.9861, 40.22999, -67.97798),  # WAT_OC
                                c(39.83295, -69.98194),  # WAT_NC
                                c(39.19192, -72.22735),  # WAT_BC
                                c(38.37337, -73.36985),  # WAT_WC
                                c(37.16452, -74.46585),  # NFC
                                c(35.30183,-74.8789,35.5841,-74.7499, 35.5841,-74.7499),  # HAT_A & HAT_B
                                c(33.66992, -75.9977),   # WAT_GS
                                c(32.10527, -77.09067),  # WAT_BP
                                c(30.58295, -77.39002),  # WAT_BS
                                c(30.27818, -80.22085))))  # JAX_D
rownames(HARPs) = sites
colnames(HARPs) = c("Lat1", "Lon1", "Lat2", "Lon2","Lat3","Lon3")

fileList = list.files(inDir,pattern = "SSH",full.names = TRUE,recursive=TRUE)

## Action ----------------------------------------------------------------------

# initialize data frames for saving later
masterData.Frontal = double()
masterData.GeoDist = double()
masterData.Time = double()

# load in SSH files
for (i in seq_along(fileList)){   #for each file in fileList
  
  # Open a given SSH .Rdata file
  load(fileList[i])
  
  # get 6-digit datestamps from file names
  fileDate = str_extract(fileList[i],"\\d\\d\\d\\d\\d\\d\\d\\d") 
  time_temp = paste(str_sub(fileDate,start=1L,end=4L),'-',
                    str_sub(fileDate,start=5L,end=6L),'-',
                    str_sub(fileDate,start=7L,end=8L),sep="")
  
  thisFileTime = as.Date(time_temp,format='%Y-%m-%d',tz="UTC")
  
  # Find the column closest to setLon
  lons = lons-360
  colInd = which.min(abs(lons-setLon))
  closeLon = lons[colInd]
  
  # Calculate the first difference of SSH values at column matching closeLon
  maxDiffInd = which.max(diff(data[,colInd], lag = 1))
  
  # Get the corresponding latitude
  maxDiffLat = lats[maxDiffInd]
  # Add to master data frame
  masterData.Frontal = cbind(masterData.Frontal, maxDiffLat)
  
  # Calculate the geodesic distance from HARP site to lat/lon of maxDiff
  if (thisFileTime<HAT_change) {
    frontalLats = rep(maxDiffLat, times = 11)
    frontalLons = rep(closeLon, times = 11)
    frontalCoord = t(rbind(frontalLats, frontalLons))
    colnames(frontalCoord) = c("latitude", 'longitude')
    HARPcoords = cbind(HARPs$Lat1, HARPs$Lon1)
    colnames(HARPcoords) = c("latitude", "longitude")
    # calculate geodesic distance in m
    geoDist = geodist(frontalCoord, HARPcoords, paired=TRUE, measure="geodesic")
  }
  if (thisFileTime>HAT_change & thisFileTime<OC_change) {
    frontalLats = rep(maxDiffLat, times = 11)
    frontalLons = rep(closeLon, times = 11)
    frontalCoord = t(rbind(frontalLats, frontalLons))
    colnames(frontalCoord) = c("latitude", 'longitude')
    HARPcoords = cbind(HARPs$Lat2, HARPs$Lon2)
    colnames(HARPcoords) = c("latitude", "longitude")
    # calculate geodesic distance in m
    geoDist = data.frame(geodist(frontalCoord, HARPcoords, paired=TRUE, measure="geodesic"))
  }
  if (thisFileTime>HAT_change & thisFileTime>OC_change) {
    frontalLats = rep(maxDiffLat, times = 11)
    frontalLons = rep(closeLon, times = 11)
    frontalCoord = t(rbind(frontalLats, frontalLons))
    colnames(frontalCoord) = c("latitude", 'longitude')
    HARPcoords = cbind(HARPs$Lat3, HARPs$Lon3)
    colnames(HARPcoords) = c("latitude", "longitude")
    # calculate geodesic distance in m
    geoDist = data.frame(geodist(frontalCoord, HARPcoords, paired=TRUE, measure="geodesic"))
  }
  # Add geodist to master data frame
  masterData.GeoDist = cbind(masterData.GeoDist, geoDist)
  
  # Add times to master data frame
  masterData.Time = cbind(masterData.Time, thisFileTime)
  
}

# Save TS
save(masterData.GeoDist,masterData.Frontal,masterData.Time,
     file=paste(outDir,'/','GeoDist_TS.Rdata',sep=""))

