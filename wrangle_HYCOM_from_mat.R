library(stringr)
library(R.matlab)
library(lubridate)

infolder = 'E:/HYCOM/'
outfolder = file.path('E:/CovarShinyApp/Covars')
latrange = c(24,46)
lonrange = c(-63,-82)
timerange = c(as.Date('2016/02/01'),as.Date('2019/04/30'))

####--------------------------------------------

allfiles = list.files(infolder,pattern = "*.mat",full.names = TRUE,
                      include.dirs=FALSE,recursive=FALSE)
lonrange = 360+lonrange

# for (i in seq_along(allfiles)){
for (i in 1109:length(allfiles)){
  
  #open a given file as a data frame
  matdata = data.frame(readMat(allfiles[i]))
  
  # get file date from file
  fileDate = matdata$X1.1$Date
  # convert from matlab time to UTC
  times = as.POSIXct((fileDate-719529)*86400,format='%Y-%m-%d',origin='1970-01-01',tz="UTC")
  
  if (month(times)<10){
    monthVal = paste(0,month(times),sep="")
  } else {
    monthVal = month(times)
  }
  if (day(times)<10){
    dayVal = paste(0,day(times),sep="")
  } else {
    dayVal = day(times)
  }
  timeString = paste(year(times),monthVal,dayVal,sep="")
  
  #if (times>=timerange[1] & times<=timerange[2]){
    #get lats
    lats = matdata$X1.1$Latitude
    #get lons
    lons = matdata$X1.1$Longitude
    # get depths
    allDepths = abs(matdata$X1.1$Depth)
    #get other variables
    data = t(matdata$X1.1$ssh) # SSH
    U_Velocity = matdata$X1.1$u
    V_Velocity = matdata$X1.1$v
    Temperature = matdata$X1.1$temperature
    Salinity = matdata$X1.1$salinity
    
    # Save SSH, lats, lons
    saveName = paste(outfolder,'/',"SSH",'_0_',timeString,'.Rdata',sep="")
    save(data,lats,lons,file=saveName)
    
    # define where our specific depth layers are
    depths = c(1,23,28,33)
    # which covars have multiple depths
    deepCovars = list("U_Velocity", "V_Velocity", "Temperature", "Salinity")
    # deepCovars = list("U_Velocity","Temperature","V_Velocity")
    
    # for each covar
    for (j in 1:length(deepCovars)){
      thisCovar = deepCovars[j]
      for (k in depths){
        data = t(eval(parse(text=paste(thisCovar,'[,,k]',sep=""))))
        saveName = paste(outfolder,'/',thisCovar,'_',allDepths[k],'_',timeString,'.Rdata',sep="")
          save(data,lats,lons,file=saveName)
      }
    }
    
    # pull only layers for our depths of interest
    # # water u
    # water_u_0m = water_u[,,1]
    # water_u_200m = water_u[,,23]
    # water_u_500m = water_u[,,28]
    # water_u_1000m = water_u[,,33]
    # 
    # # water v
    # water_v_0m = water_v[,,1]
    # water_v_200m = water_v[,,23]
    # water_v_500m = water_v[,,28]
    # water_v_1000m = water_v[,,33]
    # 
    # # temp
    # temp_0m = temp[,,1]
    # temp_200m = temp[,,23]
    # temp_500m = temp[,,28]
    # temp_1000m = temp[,,33]
    # 
    # # salinity
    # salinity_0m = salinity[,,1]
    # salinity_200m = salinity[,,23]
    # salinity_500m = salinity[,,28]
    # salinity_1000m = salinity[,,33]
    # 
    # 
    # #save stuff
    # save(lats,lons,times,salinity_0m,salinity_200m,salinity_500m,salinity_1000m,
    #      file=outfolder(""))
    # 
    # #get just the name of the file
    # tempname = read.table(text = allfiles[i],sep = '/')
    # usename = tempname[4]
    # usename = str_remove(usename,"_\\d\\d\\d\\d\\d\\d\\d\\d.nc")
    # savename = file.path(outfolder,paste(usename,'.Rdata',sep=""))
  
    
    # #save data frame as .csv
    # # write.csv(ncframe,savename)
    # save(lats,lons,theta_max,fsle_max,file=savename)
    # 
    # print(paste('Done with file ',allfiles[i]))
  }
  # else {
  #   #if skipping file, say so 
  #   print(paste('Skipping file ',allfiles[i],', outside of time bounds.'))
  # }}
