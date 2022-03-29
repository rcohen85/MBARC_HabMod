# Quick and dirty script for downloading chlorophyll-a data from ERDAPP
# The source is this ESA ocean color data set: https://coastwatch.pfeg.noaa.gov/erddap/griddap/pmlEsaCCI50OceanColorDaily.html
# The url specified here is only downloading the chl_a variable, from the region bounded by latitudes (24,46) and longitudes
# (-82,-63)

library(stringr)
library(curl)

url1 = 'https://coastwatch.pfeg.noaa.gov/erddap/griddap/pmlEsaCCI50OceanColorDaily.nc?chlor_a%5B('
url2 = 'T00:00:00Z):1:('
url3 = 'T00:00:00Z)%5D%5B(46):1:(24)%5D%5B(-82):1:(-63)%5D'

dateS = as.Date('2016-02-01')
dateE = as.Date('2019-04-30')

allDates = seq.Date(dateS,dateE,by=1)

for (i in 1:length(allDates)){
  fullURL = paste(url1,strftime(allDates[i]),url2,strftime(allDates[i]),url3,sep="")
  saveName = paste('E:/ModelingCovarData/Chl',str_replace_all(strftime(allDates[i]),'-',''),'.nc',sep="")
  
  curl_download(fullURL,saveName,quiet=FALSE,mode="wb")
}
