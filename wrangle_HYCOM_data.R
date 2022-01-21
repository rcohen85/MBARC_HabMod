
######## Settings ------------------

inDir = c("E:/ModelingCovarData/Temperature") # directory containing nc4 files
var = c("water_temp") # must be given just as it appears in the HYCOM .nc4 files
depth = list("_0m", "_50m", "_100m", "_200m", "_500m", "_1000m", "_3000m", "_4000m")


######## Action -----------------
library(ncdf4)
library(stringr)
HARPs = t(data.frame(c(41.06165, -66.35155), # WAT_HZ
                     c(40.22999, -67.97798),  # WAT_OC
                     c(39.83295, -69.98194),  # WAT_NC
                     c(39.19192, -72.22735),  # WAT_BC
                     c(38.37337, -73.36985),  # WAT_WC
                     c(37.16452, -74.46585),  # NFC
                     c(35.30183, -74.87895),  # HAT
                     c(33.66992, -75.9977),   # WAT_GS
                     c(32.10527, -77.09067),  # WAT_BP
                     c(30.58295, -77.39002),  # WAT_BS
                     c(30.27818, -80.22085)))  # JAX_D
rownames(HARPs) = c("HZ","OC","NC","BC","WC","NFC","HAT","GS","BP","BS","JAX")
colnames(HARPs) = c("Lat","Lon")

for (i in 1:length(var)){
  
  allFiles = list.files(path=inDir[i],pattern=".nc4") # list all files in given directory
  #varFiles = allFiles[grep(var[i], allFiles)] # find file names containing given covar
  
  for(k in 1:length(depth)) { # for each specified depth
    
    # find files matching this depth
    thisDepthInd = which(!is.na(str_match(allFiles,unlist(depth[k]))))
    
    # initialize arrays to hold data from all files matching this depth & covar
    masterData.Covar = double()
    masterData.Lat = double()
    masterData.Lon = double()
    masterData.Time = double()
    
    for (j in 1:length(thisDepthInd)){ # for each file matching this depth
      
      # assemble file name
      ncfilename = paste(inDir[i],'/',allFiles[thisDepthInd[j]],sep="")
      ncin = nc_open(ncfilename)
      # print(ncin)
      
      # load data
      thisCovar = ncvar_get(ncin,var[i]) 
      lat = ncvar_get(ncin,"lat")
      lon = ncvar_get(ncin,"lon")
      time = ncvar_get(ncin,"time") 
      
      # initialize arrays to hold relevant data points from this file
      thisFile.Covar = double()
      thisFile.Lat = double()
      thisFile.Lon = double()
      thisFile.Time = double()
      
      for (l in 1:length(time)){ # for each time stamp in this file
        
        dat = matrix(nrow=11,ncol=1)
        thisDatLat = matrix(nrow=11,ncol=1)
        thisDatLon = matrix(nrow=11,ncol=1)
        timeSt = matrix(nrow=11,ncol=1)
        
        for (m in 1:nrow(HARPs)){ # for each HARP site
          
          # find data points nearest this HARP site
          sitelat = which.min(abs(HARPs[m,1]-lat))
          sitelon = which.min(abs(HARPs[m,2]-lon))
          
          # grab covar values at this HARP site
          dat[m,1] = thisCovar[sitelon,sitelat,l]
          thisDatLat[m] = lat[sitelat]
          thisDatLon[m] = lon[sitelon]
          timeSt[m,1] = time[l]
        }
        
        # add data from this time stamp to array for this file
        thisFile.Covar = cbind(thisFile.Covar,dat)
        thisFile.Lat = cbind(thisFile.Lat,thisDatLat)
        thisFile.Lon = cbind(thisFile.Lon,thisDatLon)
        thisFile.Time = cbind(thisFile.Time,timeSt)
        
      }
      
      # add data points from all time stamps in this file to master data frame
      masterData.Covar = cbind(masterData.Covar,thisFile.Covar)
      masterData.Lat = cbind(masterData.Lat,thisFile.Lat)
      masterData.Lon = cbind(masterData.Lon,thisFile.Lon)
      masterData.Time = cbind(masterData.Time,thisFile.Time)
      
      rm(thisCovar) # clear this variable to free up memory
      
    }
    
    # # rename this variable with the covariate and depth in the name
    # assign(paste(var,depth[k],'_data',sep=""),masterData.Covar)
    # assign(paste(var,depth[k],'_lat',sep=""),masterData.Lat)
    # assign(paste(var,depth[k],'_lon',sep=""),masterData.Lon)
    # assign(paste(var,depth[k],'_time',sep=""),masterData.Time)
    # 
    # # save this depth dataframe 
    # action = paste("save(",paste(var,depth[k],'_data,',sep=""),
    #                paste(var,depth[k],'_lat,',sep=""),
    #                paste(var,depth[k],'_lon,',sep=""),
    #                paste(var,depth[k],'_time',sep=""),
    #                ',file=',paste("'",inDir[i],'/',var[i],depth[k],'.Rdata',"'",sep=""),')',sep="")
    # eval(parse(text=action))
    
    save(masterData.Covar,masterData.Lat,masterData.Lon,masterData.Time,
         file=paste(inDir[i],'/',var[i],depth[k],'.Rdata',sep=""))
    
  } # move onto next depth
  
  
}








