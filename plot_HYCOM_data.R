#load libraries
library(ggplot2)
library(grid)
library(gridExtra)
library(tidyverse)
library(stringr)
library(interp)

## Settings -------------------------------------------------------
inDir = c('J:/ModelingCovarData/Temperature')
covar = 'water_temp'
depths = c(0,50,100,200,500,1000,2000,3000,4000) # order to organize depth layers for plotting
sites = c('HZ','OC','NC','BC','WC','NFC','HAT','GS','BP','BS','JAX') 
# NOTE: site order should match order of coordinates below

HARPs = t(data.frame(c(41.06165, -66.35155), # WAT_HZ
                     c(40.22999, -67.97798),  # WAT_OC
                     c(39.83295, -69.98194),  # WAT_NC
                     c(39.19192, -72.22735),  # WAT_BC
                     c(38.37337, -73.36985),  # WAT_WC
                     c(37.16452, -74.46585),  # NFC
                     c(35.5841, -74.7499),  # HAT
                     c(33.66992, -75.9977),   # WAT_GS
                     c(32.10527, -77.09067),  # WAT_BP
                     c(30.58295, -77.39002),  # WAT_BS
                     c(30.27818, -80.22085)))  # JAX_D
rownames(HARPs) = sites
colnames(HARPs) = c("Lat","Lon")

# Load and organize data by site -----------------------------------------------------------------

fileList = dir(inDir,".Rdata")

# # will need to interpolate depths by repeating depth layers
# depInt = diff(depths)
# depRep = c(depInt/50,1)

for (i in 1:length(fileList)){
  
  # Load data from this depth
  load(paste(inDir,'/',fileList[i],sep=""))
  
  if (i==1){ # on first pass, initialize data frames for each site; assumes each depth layer has same timestamps
    action = paste(sites,rep('=',length(sites)),rep('matrix(nrow=length(depths),ncol=dim(masterData.Covar)[2])',
                                                    length(sites)),collapse=";")
    eval(parse(text=action))
    
    action = paste(paste(sites,rep('_time',length(sites)),sep=""),rep('=',length(sites)),
                   rep('matrix(nrow=length(depths),ncol=dim(masterData.Covar)[2])',length(sites)),collapse=";")
    eval(parse(text=action))
  }
  
  # Get depth level from file
  thisFile = fileList[i]
  thisDepth = str_replace(thisFile,paste(covar,'_',sep=""),"")
  thisDepth = as.numeric(str_replace(thisDepth,"m.Rdata",""))
  depthInd = which(depths==thisDepth)
  
  # loop through HARP sites
  for (j in 1:length(sites)){
    
    # find row containing observations at lat closest to this site
    sitelat = which.min(abs(HARPs[j,1]-masterData.Lat))
    
    # Pull obs to the appropriate site's data frame, with depth given by row
    action = paste(sites[j],'[',depthInd,', ] = masterData.Covar[sitelat,]',sep="")
    eval(parse(text=action))
    action = paste(sites[j],'_time[',depthInd,', ] = masterData.Time[sitelat,]',sep="")
    eval(parse(text=action))
  }
  
}




#CREATE CONTOUR PLOTS ---------------------------------------------------------------

z = as.vector(t(HZ[,1:2500]))
x= as.vector(t(HZ_time[,1:2500]))
y = rep(depths,each=2500)
HZ_plot=as.data.frame(cbind(z,x,y))
colnames(HZ_plot) = c("Data","Time","Depth")


# Interpolate between vertical layers
interpVar = interp(x=HZ_plot$Time,y=HZ_plot$Depth,z=HZ_plot$Data,
                   xo=seq(min(HZ_plot$Time),max(HZ_plot$Time),by=3),
                   yo=seq(min(depths),max(depths),by=50),
                   input="points",
                   output="grid")

z = as.vector(interpVar$z)
x = rep(interpVar$x,times=81)
y = rep(interpVar$y,each=2546)
smoothDat = as.data.frame(cbind(z,x,y))
colnames(smoothDat) = c("Data","Time","Depth")


# Plot
ggplot(smoothDat,aes(x=Time,y=Depth))+
  geom_tile(aes(fill=Data))+
  scale_y_reverse()



x = unlist(lapply(HZ[,1:2500],c));y= unlist(lapply(HZ_time[,1:2500],c))
HZ_plot=as.data.frame(cbind(x,y))
HZ_plot=as.data.frame(cbind(HZ_plot,c(depths)))
colnames(HZ_plot) = c("Data","Time","Depth")

ggplot(HZ_plot, aes(x=Time, y=Depth, z=Data)) +
  geom_contour_filled() +
  scale_y_reverse() +
  labs(x="Time", y="Depth (m)", title = "HYCOM_Temp") +
  theme(plot.title = element_text(hjust = 0.5)) +
  guides(fill = guide_legend(title = "Temperature (?C)"))




