#created by MAZ on 7/26/2021 to extract specific lats, lons, and times from 
#downloaded AVISO FSLE data .nc files

library(stringr)
library(ncdf4)

infolder = 'F:/AVISO_FLSEdata/2019'
outfolder = file.path('E:/CovarShinyApp/Covars') #kind of a nuisance to write it this way, but different types of computers use different file separators, so in the long run it might be good?
latrange = c(24,46)
lonrange = c(-63,-82)
timerange = c(as.Date('2016/05/1'),as.Date('2019/04/30'))

####--------------------------------------------

allfiles = list.files(infolder,pattern = "*.nc",full.names = TRUE,recursive=TRUE)
lonrange = 360+lonrange

if (!dir.exists(outfolder)){
  dir.create(outfolder,recursive = TRUE)
}

for (i in seq_along(allfiles)){
  
  #open a given file
  ncdata = nc_open(allfiles[i])
  
  #get times
  # time_temp = ncvar_get(ncdata,"time")
  
  # times = as.Date('1950/1/1')
  
  # get 6-digit datestamp from file name
  fileDate = str_extract(allfiles[i],"\\d\\d\\d\\d\\d\\d\\d\\d") 
  time_temp = paste(str_sub(fileDate,start=1L,end=4L),'-',
                     str_sub(fileDate,start=5L,end=6L),'-',
                     str_sub(fileDate,start=7L,end=8L),sep="")
  
  times = as.Date(time_temp,format='%Y-%m-%d',tz="UTC")
  
  if (times>=timerange[1] & times<=timerange[2]){
    #get lats
    lats_temp = ncvar_get(ncdata,"lat")
    #get lons
    lons_temp = ncvar_get(ncdata,"lon")
    #get other variables
    # theta_max_temp = ncvar_get(ncdata,"theta_max")
    # lon_bnds_temp = ncvar_get(ncdata,'lon_bnds')
    # lat_bnds_temp = ncvar_get(ncdata,'lat_bnds')
    data_temp = ncvar_get(ncdata,'fsle_max')
    # crs = ncvar_get(ncdata,'crs')
    
    #truncate lats/lons
    latsidx = lats_temp>=latrange[1] & lats_temp<=latrange[2]
    lonsidx = lons_temp<=lonrange[1]&lons_temp>=lonrange[2]
    
    #truncate others to match
    lats = as.numeric(lats_temp[latsidx])
    lons = as.numeric(lons_temp[lonsidx])
    # lat_bnds = as.numeric(lat_bnds_temp[latsidx])
    # lon_bnds = as.numeric(lon_bnds_temp[lonsidx])
    # theta_max = as.data.frame(t(theta_max_temp[lonsidx,latsidx]))
    data = as.data.frame(t(data_temp[lonsidx,latsidx]))
    
    #save stuff
    #get just the name of the file
    # tempname = read.table(text = allfiles[i],sep = '/')
    usename = "FSLE"
    usename = paste(usename,"_0_",str_replace_all(times,"-",""),sep="")
    savename = file.path(outfolder,paste(usename,'.Rdata',sep=""))
    
    #set up data as dataframe
    # ncframe = data.frame(lats = lats,
    #                      lons = lons,
    #                      lat_bnds = lat_bnds,
    #                      lon_bnds = lon_bnds,
    #                      theta_max = theta_max,
    #                      fsle_max = fsle_max,
    #                      crs = crs)
    
    #save data frame as .csv
    # write.csv(ncframe,savename)
    save(lats,lons,data,file=savename)
    
    print(paste('Done with file ',allfiles[i]))
  }
    else {
      #if skipping file, say so 
      print(paste('Skipping file ',allfiles[i],', outside of time bounds.'))
    }}
