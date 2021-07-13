%created by MAZ on 7/12/2021 in order to download fsle data from MATLAB
%using ftp server
clear all
close all
clc

ftppath = 'ftp-access.aviso.altimetry.fr';%base path in URL from ftp from AVISO
ftpfolder = 'value-added/lyapunov/delayed-time/global'; %path to specific folder within AVISO ftp that has FSLE data
outfolder = 'H:\AVISO_FLSEdata'; %will change current directory to this folder so that downloaded files are saved here
years = {'2005','2006','2007','2008','2009','2010','2011','2012','2013',...
    '2014','2015','2016','2017','2018','2019','2020'};

username = ''; %username and password below used to authenticate connection to ftp
pw = '';

%use mget to download files into your folder
for iy = 1:size(years,2)
    
%get ftp object
ftob = ftp(ftppath,username,pw);

    %get your output folder set up
    outfolderfull = fullfile(outfolder,years{iy});
    %if output folder doesn't exist, make it
    if ~isdir(outfolderfull)
        mkdir(outfolderfull)
    end
    
    %make your output folder the current folder so things save correctly there
    cd(outfolderfull)
    disp(['Saving extracted files to ',outfolderfull])
    
    %add the year to your filepath
    ftpfolderfull = [ftpfolder,'/',years{iy},'/'];
    %set current directory for ftp to point to specific folder
    cd(ftob,ftpfolderfull);
    %extract files for that year into the correct folder
    mget(ftob,'*.nc');
end

disp(['Done extracting files from ',ftppath,ftpfolder])

