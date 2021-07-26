#created by MAZ on 7/26/2021 to extract specific lats, lons, and times from 
#downloaded AVISO FSLE data .nc files
rm()


infolder = 'H:/AVISO_FLSEdata/2007/'
outfolder = file.path('E:','fsle','2007','trunc') #kind of a nuisance to write it this way, but different types of computers use different file separators, so in the long run it might be good?
latrange = c(10,40)
lonrange = c(180,250)
timerange = c(as.Date('2007/07/1'),as.Date('2007/10/1'))

allfiles = list.files(infolder,pattern = "*.nc",full.names = TRUE)

if (!dir.exists(outfolder)){
  dir.create(outfolder,recursive = TRUE)
}

for (i in seq_along(allfiles)){
  
  #open a given file
  ncdata = nc_open(allfiles[i])
  
  #get times
  time_temp = ncvar_get(ncdata,"time")
  times = as.Date('1950/1/1') + time_temp
  
  if (times>=timerange[1] & times<=timerange[2]){
    #get lats
    lats_temp = ncvar_get(ncdata,"lat")
    #get lons
    lons_temp = ncvar_get(ncdata,"lon")
    #get other variables
    theta_max_temp = ncvar_get(ncdata,"theta_max")
    lon_bnds_temp = ncvar_get(ncdata,'lon_bnds')
    lat_bnds_temp = ncvar_get(ncdata,'lat_bnds')
    fsle_max_temp = ncvar_get(ncdata,'fsle_max')
    crs = ncvar_get(ncdata,'crs')
    
    #truncate lats/lons
    latsidx = lats_temp>=latrange[1] & lats_temp<=latrange[2]
    lonsidx = lons_temp>=lonrange[1]&lons_temp<=lonrange[2]
    
    #truncate others to match
    lats = as.numeric(lats_temp[latsidx])
    lons = as.numeric(lons_temp[lonsidx])
    lat_bnds = as.numeric(lat_bnds_temp[latsidx])
    lon_bnds = as.numeric(lon_bnds_temp[lonsidx])
    theta_max = as.numeric(theta_max_temp[lonsidx,latsidx])
    fsle_max = as.numeric(fsle_max_temp[lonsidx,latsidx])
    
    #save stuff
    #get just the name of the file
    tempname = read.table(text = allfiles[i],sep = '/')
    usename = tempname[4]
    savename = file.path(outfolder,sub('.nc','.csv',usename))
    
    #set up data as dataframe
    ncframe = data.frame(lats = lats,
                         lons = lons,
                         lat_bnds = lat_bnds,
                         lon_bnds = lon_bnds,
                         theta_max = theta_max,
                         fsle_max = fsle_max,
                         crs = crs)
    
    #save data frame as .csv
    write.csv(ncframe,savename)
    
    print(paste('Done with file ',allfiles[i]))
  }
    else {
      #if skipping file, say so 
      print(paste('skipping',allfiles[i],'. Outside of time bounds.'))
    }}
