# Data wrangling script for downloaded ERDAP data
# Start with downloaded .nc files, end with time series at each site
# Also save a file for lat, lon, chlorophyll, for each date
# Final data format is .Rdata

library(stringr)
library(lubridate)
library(ncdf4)

## SETTINGS --------------------------------------------------------------------

inDir = c("E:/ModelingCovarData/Chl") # directory containing .nc files
outfolder = c("E:/CovarShinyApp/Covars")
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

fileList = list.files(inDir,pattern = "*.nc",full.names = TRUE,recursive=TRUE)

## ACTION ----------------------------------------------------------------------

# initialize arrays to hold data from all points matching sites
masterData.Data = double()
masterData.Lat = double()
masterData.Lon = double()
masterData.Time = double()

for (i in seq_along(fileList)){   #for each file in fileList
  
  # Open a given .nc file
  ncdata = nc_open(fileList[i])
  
  # get 6-digit datestamps from file names
  fileDate = str_extract(fileList[i],"\\d\\d\\d\\d\\d\\d\\d\\d") 
  time_temp = paste(str_sub(fileDate,start=1L,end=4L),'-',
                    str_sub(fileDate,start=5L,end=6L),'-',
                    str_sub(fileDate,start=7L,end=8L),sep="")
  
  thisFileTime = as.Date(time_temp,format='%Y-%m-%d',tz="UTC")
  
  # get latitude values from file
  lats = ncvar_get(ncdata,"latitude")
  
  # get longitude values from file
  lons = ncvar_get(ncdata, "longitude")
  lons[lons<0] = lons[lons<0]+360
  
  # get chlorophyll values from file
  data = t(ncvar_get(ncdata, "chlor_a"))
  
  saveName = paste(outfolder,'/',"Chlorophyll_0_",fileDate,'.Rdata',sep="")
  save(data,lats,lons,file=saveName)
  
  # # initialize arrays to hold relevant data points from this file
  # thisFile.Fsle = double()
  # thisFile.Lat = double()
  # thisFile.Lon = double()
  # thisFile.Time = double()
  

  thisFileData = matrix(nrow=11,ncol=1)
  thisFileLat = matrix(nrow=11,ncol=1)
  thisFileLon = matrix(nrow=11,ncol=1)
  
  for (m in 1:nrow(HARPs)){ # for each HARP site
    
    # find data points nearest this HARP site
    if (m==7){ # at HAT, pull points first from site A, then from site B
      if (thisFileTime<HAT_change){
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
    thisFileData[m,1] = data[sitelon,sitelat]
    thisFileLat[m] = lats[sitelat]
    thisFileLon[m] = lons[sitelon]
    
  }
  
  # # add data from each HARP site to array for this file
  # thisFile.Fsle = cbind(thisFile.Fsle,fsle)
  # thisFile.Lat = cbind(thisFile.Lat,thisFsleLat)
  # thisFile.Lon = cbind(thisFile.Lon,thisFsleLon)
  # thisFile.Time = times
  
  # add HARP site data points from each file to master data frame
  masterData.Data = cbind(masterData.Data, thisFileData)
  masterData.Lat = cbind(masterData.Lat,thisFileLat)
  masterData.Lon = cbind(masterData.Lon,thisFileLon)
  masterData.Time = cbind(masterData.Time,thisFileTime)
  
}



save(masterData.Data,masterData.Lat,masterData.Lon,masterData.Time,
     file=paste(inDir,'/','Chl_TS.Rdata',sep=""))
