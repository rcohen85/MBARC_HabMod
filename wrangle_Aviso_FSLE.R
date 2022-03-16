library(stringr)
library(lubridate)
library(ncdf4)

######## Settings ------------------

inDir = c("E:/fsle/trunc") # directory containing .RData files
sites = c('HZ','OC','NC','BC','WC','NFC','HAT','GS','BP','BS','JAX')

# Only change these if using different sites
HAT_change = as_date('2017-05-01') # account for change in HAT location from site A to B
HARPs = t(data.frame(c(41.06165, -66.35155), # WAT_HZ
                     c(40.22999, -67.97798),  # WAT_OC
                     c(39.83295, -69.98194),  # WAT_NC
                     c(39.19192, -72.22735),  # WAT_BC
                     c(38.37337, -73.36985),  # WAT_WC
                     c(37.16452, -74.46585),  # NFC
                     c(35.30183,-74.8789,35.5841,-74.7499),  # HAT_A & HAT_B
                     c(33.66992, -75.9977),   # WAT_GS
                     c(32.10527, -77.09067),  # WAT_BP
                     c(30.58295, -77.39002),  # WAT_BS
                     c(30.27818, -80.22085)))  # JAX_D
rownames(HARPs) = sites
colnames(HARPs) = c("Lat1", "Lon1", "Lat2", "Lon2")

######## Action -----------------

fileList = dir(inDir,".Rdata")

# initialize arrays to hold fsle data from all files matching sites
masterData.Fsle = double()
masterData.Lat = double()
masterData.Lon = double()
masterData.Time = double()

for (i in 1:length(fileList)){
  
  # Load extracted RData files
  load(paste(inDir,'/',fileList[i],sep=""))
  
  lons = lons-360
  
  # get 6-digit datestamps from file names
  fileDate = str_extract(fileList[i],"\\d\\d\\d\\d\\d\\d\\d\\d") 
  time_temp = paste(str_sub(fileDate,start=1L,end=4L),'-',
                    str_sub(fileDate,start=5L,end=6L),'-',
                    str_sub(fileDate,start=7L,end=8L),sep="")
  
  time = as.Date(time_temp,format='%Y-%m-%d',tz="UTC")
  
  # # initialize arrays to hold relevant data points from this file
  # thisFile.Fsle = double()
  # thisFile.Lat = double()
  # thisFile.Lon = double()
  # thisFile.Time = double()
 
  #for each file in fileList
  fsle = matrix(nrow=11,ncol=1)
  thisFsleLat = matrix(nrow=11,ncol=1)
  thisFsleLon = matrix(nrow=11,ncol=1)
  
  for (m in 1:nrow(HARPs)){ # for each HARP site
    
    # find data points nearest this HARP site
    if (m==7){ # at HAT, pull points first from site A, then from site B
      if (time<HAT_change){
        sitelat = which.min(abs(HARPs[m,1]-lats))
        sitelon = which.min(abs(HARPs[m,2]-lons))
      } else {
        sitelat = which.min(abs(HARPs[m,3]-lats))
        sitelon = which.min(abs(HARPs[m,4]-lons))
      }
    } else {
      sitelat = which.min(abs(HARPs[m,1]-lats))
      sitelon = which.min(abs(HARPs[m,2]-lons))
    }
    
    # grab fsle values at this HARP site
    fsle[m,1] = fsle_max[sitelon,sitelat]
    thisFsleLat[m] = lats[sitelat]
    thisFsleLon[m] = lons[sitelon]
    
  }
  
  # # add data from each HARP site to array for this file
  # thisFile.Fsle = cbind(thisFile.Fsle,fsle)
  # thisFile.Lat = cbind(thisFile.Lat,thisFsleLat)
  # thisFile.Lon = cbind(thisFile.Lon,thisFsleLon)
  # thisFile.Time = times
  
  # add data points from all files to master data frame
  masterData.Fsle = cbind(masterData.Fsle, fsle)
  masterData.Lat = cbind(masterData.Lat,thisFsleLat)
  masterData.Lon = cbind(masterData.Lon,thisFsleLon)
  masterData.Time = cbind(masterData.Time,time)
  
}



save(masterData.Fsle,masterData.Lat,masterData.Lon,masterData.Time,
   file=paste(inDir,'/','FSLE_TS.Rdata',sep=""))









