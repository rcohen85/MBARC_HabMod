#load libraries
library(ggplot2)
library(grid)
library(gridExtra)
library(tidyverse)
library(stringr)

## Settings -------------------------------------------------------
inDir = c('E:/ModelingCovarData/Temperature')
covar = 'water_temp'
depths = c(0,50,100,200,500,1000,2000, 3000,4000) # order to organize depth layers for plotting
sites = c('HZ','OC','NC','BC','WC','NFC','HAT','GS','BP','BS','JAX') 
# NOTE: site order should match order of coordinates below

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
rownames(HARPs) = sites
colnames(HARPs) = c("Lat","Lon")

# Load and organize data by site -----------------------------------------------------------------

# initialize data frames for each site
action = paste(sites,rep('=',length(sites)),rep('double()',
                                                length(sites)),collapse=";")
eval(parse(text=action))

action = paste(paste(sites,rep('_time',length(sites)),sep=""),rep('=',length(sites)),
               rep('double()',length(sites)),collapse=";")
eval(parse(text=action))

fileList = dir(inDir,".Rdata")

for (i in 1:length(fileList)){
  
  # Load data from this depth
  load(paste(inDir,'/',fileList[i],sep=""))
  
  # Get depth level from file
  thisFile = fileList[i]
  thisDepth = str_replace(thisFile,paste(covar,'_',sep=""),"")
  thisDepth = as.numeric(str_replace(thisDepth,"m.Rdata",""))
  depthInd = which(depths==thisDepth)
  
  # loop through HARP sites
  for (j in 1:length(sites)){
    
    # for each site, find observations which have Lat & Lon values closest to this site
    sitelat = which.min(abs(HARPs[j,1]-masterData.Lat))
    # sitelon = which.min(abs(HARPs[j,2]-masterData.Lon))
    
    # Pull obs to the appropriate site's data frame, with depth given by row
    action = paste(sites[j],' = rbind(',sites[j],',masterData.Covar[sitelat,])',sep="")
    eval(parse(text=action))
    action = paste(sites[j],'_time = rbind(',sites[j],'_time,masterData.Time[sitelat,])',sep="")
    eval(parse(text=action))
  }
  
  
  #Temperature
  
  # #create data frames, add depth column
  # temp0m <- data.frame(sapply(water_temp_0m,c))
  # temp0m$Depth <- c(0)
  # temp50m <- data.frame(sapply(water_temp_50m,c))
  # temp50m$Depth <- c(50)
  # temp100m <- data.frame(sapply(water_temp_100m,c))
  # temp100m$Depth <- c(100)
  # temp200m <- data.frame(sapply(water_temp_200m,c))
  # temp200m$Depth <- c(200)
  # temp500m <- data.frame(sapply(water_temp_500m,c))
  # temp500m$Depth <- c(500)
  # temp1000m <- data.frame(sapply(water_temp_1000m,c))
  # temp1000m$Depth <- c(1000)
  # temp3000m <- data.frame(sapply(water_temp_3000m,c))
  # temp3000m$Depth <- c(3000)
  # temp4000m <- data.frame(sapply(water_temp_4000m,c))
  # temp4000m$Depth <- c(4000)
  # 
  # #create a list of data frames to be merged
  # temp_list <- list(temp0m, temp50m, temp100m,
  #                   temp200m, temp500m, temp1000m,
  #                   temp3000m, temp4000m)
  
  
  # #merge all data frames together
  # tempAllDepths <- temp_list %>% reduce(full_join)
  # tempAllDepths <- as.data.frame(tempAllDepths)
  
}


#unlist data frame
# tempAllDepths <- as.data.frame(lapply(tempAllDepths, unlist))


#CREATE CONTOUR PLOTS ---------------------------------------------------------------
# x = unlist(lapply(HZ,c));y= unlist(lapply(HZ_time,c))
# HZ_plot=as.data.frame(cbind(x,y))
# HZ_plot=as.data.frame(cbind(HZ_plot,c(depths)))
# colnames(HZ_plot) = c("Data","Time","Depth")

x = as.vector(t(HZ))
y= as.vector(t(HZ_time))
depthVar = rep(depths,each=dim(HZ)[2])
HZ_plot=as.data.frame(cbind(x,y,depthVar))
colnames(HZ_plot) = c("Data","Time","Depth")

#TEMPERATURE
ggplot(HZ_plot_clean, aes(x=Time, y=Depth, z=Data)) + 
  geom_contour_filled() +
  scale_y_reverse() + 
  labs(x="Time", y="Depth (m)", title = "HYCOM_Temp") +
  theme(plot.title = element_text(hjust = 0.5)) +
  guides(fill = guide_legend(title = "Temperature (°C)"))

#SALINITY


#SURFACE ELEVATION


#U-VELOCITY



#V-VELOCITY


