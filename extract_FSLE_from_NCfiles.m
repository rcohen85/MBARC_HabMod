%created by MAZ on 7/12/2021 to prune downloaded aviso fsle files to
%relevant times, lats, lons
clear all
close all
clc

infold = 'E:\ftp_test\2007'; %input folder of .nc fsle files downloaded from aviso using habMod_FSLE_from_AVISO.m
outfold = 'E:\ftp_test\2007\trunc';
latRange = [24,46]; %range of latitudes for truncated data
lonRange = [-63,-82]; %range of longitudes for truncated data
timeRange = [datenum(2007,1,15,0,0,0),datenum(2007,10,1,0,0,0)]; %what date range do you care about
inFSLE = dir(fullfile(infold,'*.nc'));

if ~isdir(outfold)
    mkdir(outfold)
end

%run through each file and truncate down, save modified version
%for each file
for ifile = 1:size(inFSLE,1)
    curfile = fullfile(inFSLE(ifile).folder,inFSLE(ifile).name);
    %figure out what day it's from- if day is outside of date range, skip file
    %and move on
    time = ncread(curfile,'time');
    dntime = double(datenum(1950,1,1,0,0,0) + time); %convert time from days since 1950-01-01 00:00:00 to normal MATLAB datenum
    
    if dntime >= min(timeRange) & dntime<=max(timeRange)
        %grab other relevant data to modify
        lats_temp = ncread(curfile,'lat');
        lons_temp = ncread(curfile,'lon');
        theta_max_temp = ncread(curfile,'theta_max');
        lon_bnds_temp = ncread(curfile,'lon_bnds');
        lat_bnds_temp = ncread(curfile,'lat_bnds');
        fsle_max_temp = ncread(curfile,'fsle_max');
        %also get variables without adjustments, so we can save them in output
        %file. Not res-saving global attributes; if those are needed should be
        %extracted from original nc files using ncdisp()
        crs = ncread(curfile,'crs');
        
        trunclats = find(lats_temp>=latRange(1) & lats_temp<=latRange(2));
        trunclons = find(lons_temp>=lonRange(1) & lons_temp<=lonRange(2));
        %truncate things down to match
        lats = double(lats_temp(trunclats));
        lat_bnds = lat_bnds_temp(trunclats);
        lons = double(lons_temp(trunclons));
        lon_bnds = lon_bnds_temp(trunclons);
        theta_max = theta_max_temp(trunclons,trunclats);
        fsle_max = fsle_max_temp(trunclons,trunclats);
        
        savename = strrep(inFSLE(ifile).name,'.nc','_mod.mat');
        save(fullfile(outfold,savename),'fsle_max','theta_max','lats','lons',...
            'lat_bnds','lon_bnds','crs','-v7.3')
        disp(['Done with file ',curfile])
    else
        disp(['Skipping ',curfile,'. Outside of desired time range'])
    end
end
