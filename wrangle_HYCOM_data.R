
######## Settings ------------------

inDir = "E:/ModelingCovarData/Temperature"
var = "water_temp"
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


allFiles = list.files(path = inDir) # list all files in given directory
varFiles = allFiles[grep(var, allFiles)] # find file names containing given covar


for(k in 1:length(depth)) { # for each specified depths
  
  # find files matching this depth
  thisDepthInd = which(!is.na(str_match(varFiles,unlist(depth[k]))))
  
  # initialize data frame to hold data from all files matching this depth & covar
  masterData = list(Covar = double(),
                    Coords = double(),
                    Time = double())
  
  for (j in 1:length(thisDepthInd)){ # for each file matching this depth
    
    # assemble file name
    ncfilename = paste(inDir,'/',varFiles[thisDepthInd[j]],sep="") # file name will need to be constructed prior to this step!
    ncin = nc_open(ncfilename)
    # print(ncin)
    
    # load data
    thisCovar = ncvar_get(ncin,"water_temp") 
    lat = ncvar_get(ncin,"lat")
    lon = ncvar_get(ncin,"lon")
    time = ncvar_get(ncin,"time") 
    
    # initialize array to hold data from this file
    thisFile = list(Covar = double(),
                    Coords = double(),
                    Time = double())
    
    for (l in 1:length(time)){ # for each time stamp in this file
      
      dat = matrix(nrow=11,ncol=1)
      coord = matrix(nrow=11,ncol=1)
      timeSt = matrix(nrow=11,ncol=1)
      
      for (m in 1:nrow(HARPs)){ # for each HARP site
        
        # find data points nearest this HARP site
        sitelat = which.min(abs(HARPs[m,1]-lat))
        sitelon = which.min(abs(HARPs[m,2]-lon))
        
        # grab covar values at this HARP site
        dat[m,1] = thisCovar[sitelon,sitelat,l]
        coord[m] = list(c(lat[sitelat],lon[sitelon]))
        timeSt[m,1] = time[l]
      }
      
      # add to array for this file
      thisFile$Covar = cbind(thisFile$Covar,dat)
      thisFile$Coords = cbind(thisFile$Coords,coord)
      thisFile$Time = cbind(thisFile$Time,timeSt)
      
    }
    
    masterData$Covar = cbind(masterData$Covar,thisFile$Covar)
    masterData$Coords = cbind(masterData$Coords,thisFile$Coords)
    masterData$Time = cbind(masterData$Time,thisFile$Time)
    
  }
  
  assign(paste(var,depth[k],sep=""),masterData)
  
  
} # move onto next depth

# save all data frames for a given covar











