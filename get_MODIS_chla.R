#Started by RC on 18.01.22 to pull data from
# https://oceandata.sci.gsfc.nasa.gov/ob/getfile/A2016001.L3m_DAY_CHL_chlor_a_4km.nc

base = 'https://oceandata.sci.gsfc.nasa.gov/ob/getfile/A2016'
suffix = '.L3m_DAY_CHL_chlor_a_4km.nc'

for (i in 1:366){
  
  JD = 000
  if (i<10){
    JD[3] = i
  } else if (i>=10 & i<100){
    JD[2:3] = i
  } else if (i>=100){
    JD = i
  }
  
  fileName = paste()
  
  
  fullUrl = paste(base,JD,suffix,sep="")
  curl_download(url[j], fileName, quiet=FALSE, mode="wb")
  
}