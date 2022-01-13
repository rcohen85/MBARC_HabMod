
######## Settings ------------------

inDir = "I:/DataScrapingCode/Test"
var = "salinity"


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

# list all files in given directory
# find file names containing given covar
# create loop running through each file name containing given covar (1st loop)
# identify file names containing given depth 
# load files one at a time (2nd loop: for (i in c(0, 50, 100, 200, 500, 1000, 2000, 3000m 4000)){...})
# (will construct a full file path for each one, use nc_open, then grab variables)
# grab covar values at HARP locations
# organize into data frame (ll rows x lots of columns); name new data frames for each covar (assign())
# move onto next depth
# save all data frames for a given covar
# move onto next covar

ncfilename = paste(path,'/',file,'.nc4',sep="") # file name will need to be constructed prior to this step!
ncin = nc_open(ncfilename)
print(ncin)

temp = ncvar_get(ncin,"water_temp")
lat = ncvar_get(ncin,"lat")
lon = ncvar_get(ncin,"lon")
time = ncvar_get(ncin,"time") # might want to name this something generic, since the covar listed in line 5 will change


for (i in 1:length(HARPs)){
  
  HZlat = which.min(abs(HARPs[i,1]-lat))
  HZlon = which.min(abs(HARPs[i,2]-lon))
  
  temp[HZlon,HZlat]
  
}