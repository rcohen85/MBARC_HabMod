#load libraries
library(ggplot2)
library(grid)
library(gridExtra)
library(tidyverse)

#Create our Data frames -----------------------------------------------------------------


#Temperature

#create data frames, add depth column
temp0m <- data.frame(sapply(water_temp_0m,c))
temp0m$Depth <- c(0)
temp50m <- data.frame(sapply(water_temp_50m,c))
temp50m$Depth <- c(50)
temp100m <- data.frame(sapply(water_temp_100m,c))
temp100m$Depth <- c(100)
temp200m <- data.frame(sapply(water_temp_200m,c))
temp200m$Depth <- c(200)
temp500m <- data.frame(sapply(water_temp_500m,c))
temp500m$Depth <- c(500)
temp1000m <- data.frame(sapply(water_temp_1000m,c))
temp1000m$Depth <- c(1000)
temp3000m <- data.frame(sapply(water_temp_3000m,c))
temp3000m$Depth <- c(3000)
temp4000m <- data.frame(sapply(water_temp_4000m,c))
temp4000m$Depth <- c(4000)

#create a list of data frames to be merged
temp_list <- list(temp0m, temp50m, temp100m,
                  temp200m, temp500m, temp1000m,
                  temp3000m, temp4000m)

#merge all data frames together
tempAllDepths <- temp_list %>% reduce(full_join)
tempAllDepths <- as.data.frame(tempAllDepths)

#unlist data frame
tempAllDepths <- as.data.frame(lapply(tempAllDepths, unlist))


#CREATE CONTOUR PLOTS ---------------------------------------------------------------

#TEMPERATURE
ggplot(tempAllDepths, aes(x=Time, y=Depth)) + 
  geom_contour_filled(aes(z=Covar), na.rm=TRUE) +
  scale_y_reverse() + 
  labs(x="Time", y="Depth (m)", title = "HYCOM_Temp") +
  theme(plot.title = element_text(hjust = 0.5)) +
  guides(fill = guide_legend(title = "Temperature (°C)"))

#SALINITY


#SURFACE ELEVATION


#U-VELOCITY



#V-VELOCITY


