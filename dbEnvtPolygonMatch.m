% Determine which specific data points from a box of pulled remotely sensed
% data should be used for habitat modeling by comparing with detection
% range calculations for specific site
% Uses areas where 50% or more of remote-sensing block overlaps with area
% with detections
% Uses Polygons_intersection code packet developed by Guillaume JACQUENOT
% (ver 2009-06-16 and 64-bit recompiled version of Polygon Clipper code 
% originally developed by Sebastian Hölz
%
% Potential inputs: 
%   remotely sensed data file pulled with dbERDDAP
%   file with detection polygon coordinates
%   note whether detecton polygon longitude is 180-180 or 0-360
%   create plots of areas & timeseries?
%   optional ratio of area to include?
% Potential outputs:
%   averaged data value over determined area for each day with data
%   other things to include: stdev, max, min
%   some metric of area used for calculation? what fraction of overall
%   detection range is covered; how much area in detection range not
%   used...
%
% Haven't tested yet how it crashes if no overlap in areas

clear all;

site = 'N';
variable = 'sshd';

%hard-wire data you're pulling
inpath = 'E:\SOCAL HabMod Project\ERDDAP\';
infile = ['site' site variable '.mat'];
%get mat file to read environmental data pulled from ERDDAP
%[infile,inpath]=uigetfile('*.mat');
if isequal(infile,0)
    disp('Cancelled button pushed');
    return
end

cd(inpath)
load(infile);

%Remove any singleton dimensions from the data 
singletonP = data.dims == 1;
if any(singletonP)
    % Copy singletons to a constants structure and remove
    % them from the Axes structure
    for f = {'names', 'units', 'types', 'values'}
        f = f{1};
        data.Constants.(f) = data.Axes.(f)(singletonP);
        data.Axes.(f)(singletonP) = [];
    end
    for idx = 1:length(data.Data.values)
        data.Data.values{idx} = squeeze(data.Data.values{idx});
    end
    data.dims(singletonP) = [];
end

%Get all the latitude and longitude coordinates from center points of envt
%data
overallong = data.Axes.values{1,1};
overallat = data.Axes.values{2,1};

%Create matrix of coordinates that describe square-polygons of pulled
%environmental data
%figure out step of each lat/long bin
latstep = mean(diff(overallat));
latleng = length(overallat);
longstep = mean(diff(overallong));
longlen = length(overallong);
i = 1;
%Create all polygons
for j = 1:longlen
    S(i).P(j).y(1:2) = overallat(i)-latstep/2;
    S(i).P(j).y(3:4) = S(i).P(j).y(1:2)+latstep;
    S(i).P(j).y(5) = S(i).P(j).y(1);
    S(i).P(j).x(1) = overallong(j)-longstep/2;
    S(i).P(j).x(2:3) = overallong(j)+longstep/2;
    S(i).P(j).x(4:5) = overallong(j)-longstep/2;
    S(i).P(j).hole = 0;
end
for i = 2:latleng
    for j=1:longlen
        S(i).P(j).y(1:2) = overallat(i)-latstep/2;
        S(i).P(j).y(3:4) = S(i).P(j).y(1:2)+latstep;
        S(i).P(j).y(5) = S(i).P(j).y(1);
        S(i).P(j).x(1) = overallong(j)-longstep/2;
        S(i).P(j).x(2:3) = overallong(j)+longstep/2;
        S(i).P(j).x(4:5) = overallong(j)-longstep/2;
        S(i).P(j).hole = 0;
    end
end
%Calculate area (madeup units) of one data square
onebox = S(1);
[onebox S_area] = Polygons_intersection_Compute_area(onebox);

%Pull data that decsribe the polygon of the detection ranges
secondinp = 'E:\SOCAL HabMod Project\ERDDAP\Polygon analysis\Site Ranges Data\';
secondinf = ['site' site 'rangesBlue.mat'];
load([secondinp secondinf]);
%Convert longitudes to be on 360 degrees
longs = longs+360;
%Create polygon of detection range
longs(end+1) = longs(1);
lats(end+1) = lats(1);
DetectionArea = polyarea(longs,lats);

%Draw the polygons to verify this all makes sense
figure(1);
hold on;
for zz = 1:size(S,2)
    for vv = 1:size(S(zz).P,2)
        fill(S(zz).P(vv).x,S(zz).P(vv).y,'r');
    end
end
fill(longs,lats,'g')
hold off;

%Pull intersections for each general polygon with overall detection range
testpol = []; 
%Initialize variable for storing loaction of grid points that will be
%pulled and total area used
BoxToUse = []; z = 1; 
GridArea = 0; OverlapArea = 0; TooSmallArea = 0;
for k = 1:size(S,2) %S is latitude
    for l = 1:size(S(1,1).P,2)  %P is longitude
        %create polygon with one envt box and whole detection range
        testpol(1).P(1) = S(k).P(l);
        testpol(2).P(1).x = longs;
        testpol(2).P(1).y = lats;
        testpol(2).P(1).hole = 0;
        %find all intersection between these two "polygons"
        geo = Polygons_intersection(testpol);
        %test if there actually is an intersection of the two
        for cnt = 1:size(geo,2),
            if size(geo(cnt).index,2)==2,
            %there is intersection and we need to see if it's more than 50% 
            %of area to decide if using that box
                if geo(cnt).area/S_area.A(1)>=0.5,
                    BoxToUse(z,1:2) = [l k];
                    z = z+1;
                    GridArea = GridArea+S_area.A(1);
                    OverlapArea = OverlapArea+geo(cnt).area;
                else TooSmallArea = TooSmallArea+geo(cnt).area;
                end
            end
        end
        clear testpol;
    end
end

%Create new matrix using only data from areas within the detection range
%First chcek there are more than one day of data
if size(data.dims,2)>2
    for cc=1:data.dims(3)
        %create vector with day of data (1) and mean (2) value over the whole
        %area as well as st dev (3), max (4) and min (5) values
        values = [];
        for dd = 1:size(BoxToUse,1)
            values(dd) = data.Data.values{1}(BoxToUse(dd,1),BoxToUse(dd,2),cc);
        end
        DetRangeData(cc,1) = data.Axes.values{3}(cc);
        DetRangeData(cc,2) = nanmean(values);
        DetRangeData(cc,3) = nanstd(values);
        DetRangeData(cc,4) = nanmax(values);
        DetRangeData(cc,5) = nanmin(values);
    end
else values = [];
    for dd = 1:size(BoxToUse,1)
        values(dd) = data.Data.values{1}(BoxToUse(dd,1),BoxToUse(dd,2));
    end
    %only one day of data
    DetRangeData(1) = cell2mat(data.Constants.values(2)); %1 is altitude
    DetRangeData(2) = nanmean(values);
    DetRangeData(3) = nanstd(values);
    DetRangeData(4) = nanmax(values);
    DetRangeData(5) = nanmin(values);
end

PercDetArea = OverlapArea/GridArea*100;     %Percent of area used for envt data that is actually within detrange
PercMissArea = TooSmallArea/DetectionArea*100;  %Percent of area in detection range that is not used for envt data
%Save some of the calculated data
variname = ['site' site '_compr_' variable];
save(variname, 'DetRangeData', 'PercDetArea', 'PercMissArea');

figure(2)
%plot timeseries of variable for this location
%errorbar(DetRangeData(:,1),DetRangeData(:,2),DetRangeData(:,3));
plot(DetRangeData(:,1),DetRangeData(:,2));
ylabel(cellstr(data.Data.names));