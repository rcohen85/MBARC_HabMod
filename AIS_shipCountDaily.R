
# This code gets daily ship presence from Marine Cadastre Data located on MBARC_MarineCadastre Google Drive
# Original marine cadastre data can be found on https://marinecadastre.gov/ais/
#
#
#
#
# Vanessa ZoBell July 8 2021
# (Currently working with 2015, will need to change for years with different formats)
#
# Variables to change: year, month, zone, site, radius, dir
#
# year = year of interest
# month = month of interest
# zone = AIS zone of that your site is in, which can be found here https://marinecadastre.gov/AIS/AIS%20Documents/UTMZoneMap2014.png
# site = latitude and longitude of HARP site
# radius = radius (in km) around the site
# dir = directory of Google Drive MBARC_MarineCadastre

#--------------------------------------------
install.packages('swfscMisc')
library('swfscMisc')
library(dplyr)
install.packages('geosphere')
library('geosphere')


# Specify the year you want to analyze
year = '2015'

# Specify the month you want to analyze
month = '01'

# Specify the zone you want to analyze with TWO digits (example: 01, 12)
zone = '11'

# Specify the latitude and longitude of your site in decimal degrees
site = c(34.247568, -120.025978)

# Specify the radius you would like to filter in
radius = 10

#Specify Directory of MBARC_MarineCadastre (include backslash at end)
dir = 'F:/Shared drives/MBARC_MarineCadastre/'

#--------------------------------------------


# Setting up directory with year to be analyzed
data_dir = paste(dir,year, sep = "")

# Pulling all .csv files from zone and month of interest (THIS WILL TAKE SOME TIME)
filePaths <- list.files(data_dir,
                        pattern  = paste(month, '_Zone', zone, '.csv', sep = ""),
                        all.files = TRUE,
                        recursive = TRUE,
                        full.names = TRUE)

# Reading csv file (THIS WILL TAKE SOME TIME)
df = data.frame(lapply(filePaths, read.csv))


circleSite = data.frame(circle.polygon(site[1], site[2], radius))

colnames(circleSite) = c("Lat", "Lon")

circleSite$Lon = as.numeric(circleSite$Lon)

circleSite$Lat = as.numeric(circleSite$Lat)

n<-dim(circleSite)[1]

circleSite = circleSite[1:(n-1), ]


dfCoord = cbind("longitude" = df$LON,
                "latitude"= df$LAT)
df = data.frame(df,
                   within_Rad = geosphere::distHaversine(
                     dfCoord,
                     c(site[2], site[1])
                   ) / 1000 < radius)    # convert m to km, check < 5

dfRad = filter(df, within_Rad == "TRUE")

dfRad$DayDate = as.POSIXct(dfRad$BaseDateTime)

uVesselDay = distinct(dfRad, MMSI, DayDate, .keep_all = TRUE)


