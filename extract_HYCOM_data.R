# INFO --------------------------------------------------------------------
# Pull ocean state estimate data from HYCOM for study area(s) and period(s) of interest.
# Script will loop through every combination of input area(s) and period(s). Requested 
# variables are downloaded individually, with separate files for each vertical layer. 
# Must have pracma, curl, and stringr packages installed.

# Global data are available from 1994-01-01 through 2020-02-18; resolution is 1/12 degree;
# covariates available are: surf_el, salinity, water_temp, water_u, water_v, salinity_bottom, 
# water_temp_bottom, water_u_bottom, water_v_bottom

# GoM data are available from 1993-01-01 though 2021-07-15; resolution is 1/25 degree; 
# covariates available are: surf_el, salinity, water_temp, water_u, water_v

# salinity, water_temp, water_u, water_v are all available at 40 depths (vertical levels)
# Available depths are: 0.0 2.0 4.0 6.0 8.0 10.0 12.0 15.0 20.0 25.0 30.0
# 35.0 40.0 45.0 50.0 60.0 70.0 80.0 90.0 100.0 125.0 150.0 200.0 250.0 300.0 350.0
# 400.0 500.0 600.0 700.0 800.0 900.0 1000.0 1250.0 1500.0 2000.0 2500.0 3000.0 4000.0 5000.0 m

# Script is set to download data as netCDF4 with associated lat/lon coordinates

# WARNING: When requesting all depth layers (vertStride=1) the data requests get real big! 
# Attempting to download too much data returns an error ("HTTP error 400")
# Try specifying a few depth layers to limit data size.
# Also, when a specified date range spans more than one experiment, a separate file
# will be downloaded with the data from each experiment falling within the date range.

# NOTE: SCALING AND OFFSET FACTORS MUST BE APPLIED TO THE DATA VALUES; these can be
# found in each .nc4 file, in the Attributes of each Variable. Data should be multiplied
# by the scaling factor, and the the offset should be added.

# SETTINGS ----------------------------------------------------------------

# Enter covariate(s) of interest 
covars = c("water_temp")

# Enter regions of interest; "global" (1/12degree) OR "GoM" (1/25degree)
region <- c("global")

# Enter date range(s) of interest in pairs of start/end dates
dateS <- as.Date(c('2016-02-01')) # start date(s)
dateE <- as.Date(c('2016-09-30')) # end date(s)

# Enter study area boundaries in decimal degree lat/long limits
latS <- c(24) # southern bound(s)
latN <- c(46) # northern bound(s)
lonE <- c(-63) # eastern bound(s); use "-" for west of Prime Meridian
lonW <- c(-82) # western bound(s); use "-" for west of Prime Meridian

# SET AT LEAST ONE OF THESE TO NaN
vertCoord = c(150) # Enter  depth of vertical layer(s) to grab (see available depths above) OR
vertStride = NaN # Enter vertical stride (1 for all depth layers, 2 for every other, etc.)

# Directory to save data; be sure to use forward slashes!
saveDir = "J:/DataScrapingCode/Test"


# Action ------------------------------------------------------------------

library(pracma)
library(curl)
library(stringr)

# Check if save directory exists; if not, then create it
dir.create(file.path(saveDir), recursive = TRUE, showWarnings = FALSE)
# setwd(saveDir)

# Base urls and data dates for each experiment; note these dates do not reflect the true start/end
# dates of the experiments, but are adjusted to eradicate temporal overlap between experiments
global_expts = data.frame(
  url=c('http://ncss.hycom.org/thredds/ncss/GLBv0.08/expt_53.X/data/1994',
        'http://ncss.hycom.org/thredds/ncss/GLBv0.08/expt_53.X/data/1995',
        'http://ncss.hycom.org/thredds/ncss/GLBv0.08/expt_53.X/data/1996',
        'http://ncss.hycom.org/thredds/ncss/GLBv0.08/expt_53.X/data/1997',
        'http://ncss.hycom.org/thredds/ncss/GLBv0.08/expt_53.X/data/1998',
        'http://ncss.hycom.org/thredds/ncss/GLBv0.08/expt_53.X/data/1999',
        'http://ncss.hycom.org/thredds/ncss/GLBv0.08/expt_53.X/data/2000',
        'http://ncss.hycom.org/thredds/ncss/GLBv0.08/expt_53.X/data/2001',
        'http://ncss.hycom.org/thredds/ncss/GLBv0.08/expt_53.X/data/2002',
        'http://ncss.hycom.org/thredds/ncss/GLBv0.08/expt_53.X/data/2003',
        'http://ncss.hycom.org/thredds/ncss/GLBv0.08/expt_53.X/data/2004',
        'http://ncss.hycom.org/thredds/ncss/GLBv0.08/expt_53.X/data/2005',
        'http://ncss.hycom.org/thredds/ncss/GLBv0.08/expt_53.X/data/2006',
        'http://ncss.hycom.org/thredds/ncss/GLBv0.08/expt_53.X/data/2007',
        'http://ncss.hycom.org/thredds/ncss/GLBv0.08/expt_53.X/data/2008',
        'http://ncss.hycom.org/thredds/ncss/GLBv0.08/expt_53.X/data/2009',
        'http://ncss.hycom.org/thredds/ncss/GLBv0.08/expt_53.X/data/2010',
        'http://ncss.hycom.org/thredds/ncss/GLBv0.08/expt_53.X/data/2011',
        'http://ncss.hycom.org/thredds/ncss/GLBv0.08/expt_53.X/data/2012',
        'http://ncss.hycom.org/thredds/ncss/GLBv0.08/expt_53.X/data/2013',
        'http://ncss.hycom.org/thredds/ncss/GLBv0.08/expt_53.X/data/2014',
        'http://ncss.hycom.org/thredds/ncss/GLBv0.08/expt_56.3',
        'http://ncss.hycom.org/thredds/ncss/GLBv0.08/expt_57.2',
        'http://ncss.hycom.org/thredds/ncss/GLBv0.08/expt_92.8',
        'http://ncss.hycom.org/thredds/ncss/GLBv0.08/expt_57.7',
        'http://ncss.hycom.org/thredds/ncss/GLBv0.08/expt_92.9',
        'http://ncss.hycom.org/thredds/ncss/GLBv0.08/expt_93.0',
        'http://ncss.hycom.org/thredds/ncss/GLBy0.08/expt_93.0'), 
  start=c(as.Date('1994-01-01'), as.Date('1995-01-01'), as.Date('1996-01-01'),
          as.Date('1997-01-01'), as.Date('1998-01-01'), as.Date('1999-01-01'),
          as.Date('2000-01-01'), as.Date('2001-01-01'), as.Date('2002-01-01'),
          as.Date('2003-01-01'), as.Date('2004-01-01'), as.Date('2005-01-01'),
          as.Date('2006-01-01'), as.Date('2007-01-01'), as.Date('2008-01-01'),
          as.Date('2009-01-01'), as.Date('2010-01-01'), as.Date('2011-01-01'),
          as.Date('2012-01-01'), as.Date('2013-01-01'), as.Date('2014-01-01'),
          as.Date('2014-07-01'), as.Date('2016-10-01'), as.Date('2017-02-01'), 
          as.Date('2017-06-01'), as.Date('2017-10-01'), as.Date('2018-01-01'), 
          as.Date('2020-02-19')),
  end=c(as.Date('1994-12-31'), as.Date('1995-12-31'), as.Date('1996-12-31'),
        as.Date('1997-12-31'), as.Date('1998-12-31'), as.Date('1999-12-31'),
        as.Date('2000-12-31'), as.Date('2001-12-31'), as.Date('2002-12-31'),
        as.Date('2003-12-31'), as.Date('2004-12-31'), as.Date('2005-12-31'),
        as.Date('2006-12-31'), as.Date('2007-12-31'), as.Date('2008-12-31'),
        as.Date('2009-12-31'), as.Date('2010-12-31'), as.Date('2011-12-31'),
        as.Date('2012-12-31'), as.Date('2013-12-31'), as.Date('2014-06-30'),
        as.Date('2016-09-30'), as.Date('2017-01-31'), as.Date('2017-05-31'), 
        as.Date('2017-09-30'), as.Date('2017-12-31'), as.Date('2020-02-18'), 
        Sys.Date() - 2))

gom_expts = data.frame(
  url=c('http://ncss.hycom.org/thredds/ncss/GOMu0.04/expt_50.1',
        'http://ncss.hycom.org/thredds/ncss/GOMl0.04/expt_31.0',
        'http://ncss.hycom.org/thredds/ncss/GOMl0.04/expt_32.5',
        'http://ncss.hycom.org/thredds/ncss/GOMu0.04/expt_90.1m000'),
  start=c(as.Date('1993-01-01'), as.Date('2013-01-01'), as.Date('2014-09-01'), as.Date('2019-01-01')),
  end=c(as.Date('2012-12-31'), as.Date('2014-08-30'), as.Date('2018-12-31'), as.Date('2021-07-15')))

# vertLayers = c(0.0, 2.0, 4.0, 6.0, 8.0, 10.0, 12.0, 15.0, 20.0, 25.0, 30.0,
#                35.0, 40.0, 45.0, 50.0, 60.0, 70.0, 80.0, 90.0, 100.0, 125.0, 150.0, 200.0, 250.0, 300.0, 350.0,
#                400.0, 500.0, 600.0, 700.0, 800.0, 900.0, 1000.0, 1250.0, 1500.0, 2000.0, 2500.0, 3000.0, 4000.0, 5000.0)

for (i in 1:length(dateS)){ # for each set of dates
  
  for (k in 1:length(latS)){ # for each study area
    
    for (l in 1:length(covars)){ # for each covariate
      
      # Determine which experiment(s) to pull data from based on desired region & date range
      if (strcmp(region,"global")){
        q <- which(dateS[i] >= global_expts$start)
        r <- which(dateE[i] <= global_expts$end)
        idxRange <- c(tail(q,1):r[1])
        # url <- global_expts$url[idxRange]
        dateSubsetStarts <- global_expts$start[idxRange] # subset date ranges by experiment
        dateSubsetEnds <- global_expts$end[idxRange]
        dateSubsetStarts[1] <- dateS[i]
        dateSubsetEnds[length(dateSubsetEnds)] <- dateE[i]
      }else if (strcmp(region,"GoM")) {
        q <- which(dateS[i] >= gom_expts$start)
        r <- which(dateE[i] <= gom_expts$end)
        idxRange <- c(tail(q,1):r[1])
        # url <- gom_expts$url[idxRange]
        dateSubsetStarts <- gom_expts$start[idxRange]
        dateSubsetEnds <- gom_expts$ends[idxRange]
        dateSubsetStarts[1] <- dateS[i]
        dateSubsetEnds[length(dateSubsetEnds)] <- dateE[i]
      }
      
      
      # Construct string containing relevant info on vars, region, period, etc.
      dlSpecs <- '?'
      # Add the variable
      dlSpecs = sprintf('%svar=%s&', dlSpecs, covars[l])
      # Add the spatial bounds
      dlSpecs = sprintf('%snorth=%.4f&west=%.4f&east=%.4f&south=%.4f&disableProjSubset=on&horizStride=1&',
                        dlSpecs, latN[k], lonW[k], lonE[k], latS[k] )
      if (!is.na(vertStride)){ # Specify vertical stride (if using)
        dlSpecs = sprintf('%svertStride=%s&', dlSpecs, vertStride)
        vertlb = sprintf('vertStride_%s',vertStride)}
      # Download associated lat-lon points
      dlSpecs = sprintf('%saddLatLon=true&', dlSpecs)
      # Get data in netcdf4 format
      dlSpecs = sprintf('%saccept=netcdf4&', dlSpecs)
      
      
      for (j in 1:length(idxRange)){ # For each temporal subset of data
        
        if (any(!is.na(vertCoord))){ # If vertical layer(s) have been specified
          for (m in 1:length(vertCoord)){ # For each vertical layer
            
            # Grab appropriate url(s)
            url <- global_expts$url[idxRange]
            
            # Specify vertical layer
            # layerID = which(vertLayers==vertCoord[m])
            dlSpecs2 = sprintf('%svertCoord=%s&', dlSpecs, vertCoord[m])
            vertlb = sprintf('%sm',vertCoord[m]) 
            
            # Add the time range(s) and construct download url(s)
            url[j] <- paste(url[j],sprintf('%stime_start=%s%%3A00%%3A00Z&time_end=%s%%3A00%%3A00Z&timeStride=1',
                                           dlSpecs2, strftime(dateSubsetStarts[j], '%Y-%m-%dT00'),
                                           strftime(dateSubsetEnds[j], '%Y-%m-%dT00')),sep='')
            
            # Create file name to save data
            saveDateS = str_remove_all(dateSubsetStarts[j],'-')
            saveDateE = str_remove_all(dateSubsetEnds[j],'-')
            fileName = sprintf('%s/HYCOM_%s_%s_%s_%s.nc4',saveDir,
                                 covars[l],vertlb,saveDateS,saveDateE)
            
            # Download the data
            curl_download(url[j], fileName, quiet=FALSE, mode="wb")
          }
        } else { # If vertical stride was specified
          
          # Grab appropriate url(s)
          url <- global_expts$url[idxRange]
          
          # Add the time range(s) and construct download url(s)
          url[j] <- paste(url[j],sprintf('%stime_start=%s%%3A00%%3A00Z&time_end=%s%%3A00%%3A00Z&timeStride=1',
                                         dlSpecs, strftime(dateSubsetStarts[j], '%Y-%m-%dT00'),
                                         strftime(dateSubsetEnds[j], '%Y-%m-%dT00')),sep='')
          
          # Create file name to save data
          saveDateS = str_remove_all(dateSubsetStarts[j],'-')
          saveDateE = str_remove_all(dateSubsetEnds[j],'-')
          fileName = sprintf('%s/HYCOM_%s_%s_%s_%s.nc4',saveDir,
                             covars[l],vertlb,saveDateS,saveDateE)
          
          # Download the data
          curl_download(url[j], fileName, quiet=FALSE, mode="wb")
          
        }
        
      }
    }
  }
}
