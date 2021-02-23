clear all;

% initialize database access 
triton; 
close all;
dbJavaPaths;
query_h=dbInit();

project = 'SOCAL';
site = 'N';     %use I for A2 and F for G2; other currently available: A,B,C,E,G,J,K,H,M,N,P,Q,R,S
datastr = 'ssh';    %options here: sst, ssh, chl, ppro, wind

%create names for appropriate data to pull and variables to save (dataname
%is dataset ID from ERDDAP and ?____ is 'grid variable' from ERDDAP)
switch datastr
    case 'sst',
        %data streams to pull
        dataname = 'erdATssta8day?sst';
        savename = ['site' site 'sst'];
    case 'ssh',
        dataname = 'erdTAssh1day?sshd';
        savename = ['site' site 'sshd'];
    case 'chl',
        dataname = 'erdMBchla8day?chlorophyll';
        savename = ['site' site 'chl'];
    case 'ppro'
        dataname = 'erdPPbfp28day?productivity';
        savename = ['site' site 'ppr'];
    case 'wind'
        dataname = 'cwwcNDBCMet?station,longitude,latitude,time,wd,wspd,wvht,mwd,wtmp,tide';
        %wd = wind direction (deg_true); wspd = wind speed (m/s); wvht =
        %wave height (m); mwd = wave direction (deg_true)l wtmp = SST (C);
        %tide = water level (m)
        savename = ['site' site 'win'];        
end

%pulls appropriate time period for each site (sometimes you have to pull
%smaller chunks and combine afterwards)
switch site
    case 'A',
        %set start and end times for pulled data
        startdate = dbSerialDateToISO8601(datenum([2006 7 3]));
        enddate = dbSerialDateToISO8601(datenum([2007 12 31]));
        %no good buoy station
    case 'I',   %really A2
        %set start and end times for pulled data
        startdate = dbSerialDateToISO8601(datenum([2008 2 2]));
        enddate = dbSerialDateToISO8601(datenum([2009 6 16]));
        %no good buoy station
    case 'B',  
        %set start and end times for pulled data
        startdate = dbSerialDateToISO8601(datenum([2006 11 11]));
        enddate = dbSerialDateToISO8601(datenum([2012 12 10]));
        statnum = 46053;    %same as J
    case 'C',
        %set start and end times for pulled data
        startdate = dbSerialDateToISO8601(datenum([2006 8 26]));
        %enddate = dbSerialDateToISO8601(datenum([2012 12 24]));
        %edited end date - ERDDAP dataset ends
        enddate = dbSerialDateToISO8601(datenum([2012 12 12]));
        statnum = 46218;
    case 'E',
        %set start and end times for pulled data
        startdate = dbSerialDateToISO8601(datenum([2006 8 27]));
        enddate = dbSerialDateToISO8601(datenum([2009 9 13]));
        statnum = 46047;    %same as H
    case 'G',
        %set start and end times for pulled data
        startdate = dbSerialDateToISO8601(datenum([2007 1 11]));
        enddate = dbSerialDateToISO8601(datenum([2008 8 5]));
        %no good buoy station
    case 'F',   %really G2
        %set start and end times for pulled data
        startdate = dbSerialDateToISO8601(datenum([2006 1 6]));
        enddate = dbSerialDateToISO8601(datenum([2009 11 23]));
        %no good buoy station
    case 'J',
        %set start and end times for pulled data
        startdate = dbSerialDateToISO8601(datenum([2008 5 28]));
        enddate = dbSerialDateToISO8601(datenum([2009 10 30]));
        statnum = 46053;
    case 'K',
        %set start and end times for pulled data
        startdate = dbSerialDateToISO8601(datenum([2008 7 17]));
        enddate = dbSerialDateToISO8601(datenum([2009 3 2]));
        statnum = 46069;    %also site R?
    case 'H',
        %set start and end times for pulled data
        startdate = dbSerialDateToISO8601(datenum([2007 7 17]));
        %enddate = dbSerialDateToISO8601(datenum([2012 12 27]));
        %edited end date - ERDDAP dataset ends
        enddate = dbSerialDateToISO8601(datenum([2012 12 12]));
        statnum = 46047;
    case 'M',
        %set start and end times for pulled data
        startdate = dbSerialDateToISO8601(datenum([2009 1 6]));
        %enddate = dbSerialDateToISO8601(datenum([2012 12 26]));
        %edited end date - ERDDAP dataset ends
        enddate = dbSerialDateToISO8601(datenum([2012 12 12]));
        statnum = 46025;
    case 'N',
        %set start and end times for pulled data
        startdate = dbSerialDateToISO8601(datenum([2009 1 7]));
        %enddate = dbSerialDateToISO8601(datenum([2012 12 13]));
        %edited end date - ERDDAP dataset ends
        enddate = dbSerialDateToISO8601(datenum([2012 12 12]));
        statnum = 46086;
    case 'P',
        %set start and end times for pulled data
        startdate = dbSerialDateToISO8601(datenum([2009 9 17]));
        enddate = dbSerialDateToISO8601(datenum([2010 5 4]));
        statnum = 46225;
    case 'Q',
        %set start and end times for pulled data
        startdate = dbSerialDateToISO8601(datenum([2009 9 17]));
        enddate = dbSerialDateToISO8601(datenum([2010 7 28]));
        statnum = 46221;
    case 'R',
        %set start and end times for pulled data
        startdate = dbSerialDateToISO8601(datenum([2009 9 18]));
        enddate = dbSerialDateToISO8601(datenum([2011 3 31]));
        statnum = 46069; % ? Others are further away
    case 'S',
        %set start and end times for pulled data
        startdate = dbSerialDateToISO8601(datenum([2009 9 19]));
        enddate = dbSerialDateToISO8601(datenum([2011 5 8]));
        statnum = 46086;
end

%determine location around which to pull data
[num,txt,raw]=xlsread('E:\SOCAL HabMod Project\ERDDAP\Noise level calculations\Noise measures.xlsx');
%[num,txt,raw]=xlsread('C:\Users\Ana\Desktop\Work\Noise measures.xlsx');
index = find(char(txt{:,1})==site);
%index = 17;    %hardcode for site S

%define the box around which we're pulling data
%latitudinal bounds
a = num(index-1,7);     %need to remove header line
b = num(index-1,8);
%longitudinal bounds
x = num(index-1,9);
y = num(index-1,10);

%create query string with appropriate parameters

switch datastr
    case 'wind'
        querystring = [dataname '&station=%22' num2str(statnum) '%22&time>='... 
            startdate '&time<=' enddate];
    otherwise 
        querystring = [dataname '[(' startdate '):1:(' enddate ')][(0.0):1:(0.0)][(' ...
        num2str(a) '):1:(' num2str(b) ')][(' num2str(360+x) '):1:(' num2str(360+y) ')]'];
end
%pull data from ERDDAP
data = dbERDDAP(query_h,querystring);

%save data as Matlab file to be used later
save(savename, 'data');