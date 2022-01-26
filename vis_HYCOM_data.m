%created by MAZ on 1/11/22 to look at HYCOM data at depths/over time
%%%%%%make option to average closest lat-lons or just use closest?

close all
clear all
clc

%%%%%%% settings %%%%%%%%
%pick variable(s)
varname = {'water_temp'};
site = 'HZ'; %current options are 'kona','kauai','manawai1','manawai2','manawai3'
anom = 1; %set to 1 if you want to visualize anomalous values for your variables,
%0 if you want to visualize the raw variable
combineNC = 1; %set to 1 if you need to make combined NC files for your site locations,
%if already have these can set to 0 and specify infiles
infiles = 'E:\ModelingCovarData\Temperature\New folder';
timestep = 1; %set this to number of months you want timestep to be
depthrange = [0,4000]; %depth range you want to view


%%%%%%%%%%%% RUN %%%%%%%%%%%%%%%%

if combineNC
    %get lat/lon for various site options to use for determining closest point
    %location
%     if strcmp(site,'kona')
%         sitelat = 19.5824;
%         sitelon = -156.0154;
%     elseif strcmp(site,'kauai')
%         sitelat = 21.9519;
%         sitelon = -159.8883;
%     elseif strcmp(site,'manawai1')
%         sitelat = 27.7257;
%         sitelon = -176.6364;
%     elseif strcmp(site,'manawai2')
%         sitelat = 27.7418;
%         sitelon = -175.5598;
%     elseif strcmp(site,'manawai3')
%         sitelat = 27.7281;
%         sitelon = -175.5543;
%     end
    
    %         % Add site lat/lon info
    if strcmp(site,'HZ')
        sitelat = 41.06165;
        sitelon = -66.35155;
    elseif strcmp(site,'OC')
        sitelat = 40.22999;
        sitelon = -67.97798;
    elseif strcmp(site,'NC')
        sitelat = 39.83295;
        sitelon = -69.98194;
    elseif strcmp(site,'BC')
        sitelat = 39.19192;
        sitelon = -72.22735;
    elseif strcmp(site,'WC')
        sitelat = 38.37337;
        sitelon = -73.36985;
    elseif strcmp(site,'NFC')
        sitelat = 37.16452;
        sitelon = -74.46585;
    elseif strcmp(site,'HAT')
        sitelat = 35.5841;
        sitelon = -74.7499;
    elseif strcmp(site,'GS')
        sitelat = 33.66992;
        sitelon = -75.9977;
    elseif strcmp(site,'BP')
        sitelat = 32.10527;
        sitelon = -77.09067;
    elseif strcmp(site,'BS')
        sitelat = 30.58295;
        sitelon = -77.39002;
    elseif strcmp(site,'JAX')
        sitelat = 30.27818;
        sitelon = -80.22085;
    end

    
    %grab some files
    varmat = [];
    
    for iV = 1:size(varname,2)
        
        files = dir(fullfile(infiles,['*',varname{iV},'*.nc4']));
        
        %run through and combine existing files under this variable
        lats = [];
        lons = [];
        var = [];
        times = [];
        depths = [];
        
        for iF = 1:size(files,1)
            file = fullfile(files(iF).folder,files(iF).name);
            %get the depth this data is from
            depthtemp = extractAfter(files(iF).name,[varname{1} '_']);
            depth = str2num(char(extractBefore(depthtemp,'m_')));
            
            vartemp = ncread(file,varname{iV}); %each variable is only taken at one depth, so we can collapse it down
            %make it three dimensions, a bit easier to work with
            var{iF} = vartemp(:,:,1,:);
            times{iF} = ncread(file,'time');
            depths = [depths; repmat(depth,size(times{iF},1),1)];
        end
        
        
        %select the closest lat-lon to scan through data with; depends on site
        %grab lats and lons from any file- will be same for all
        lats = ncread(file,'lat');
        lons = ncread(file,'lon');
        %use average locations for sites to come up with closest data match
        %use closest four lat/lon points to the site
        [~,latind] = mink(abs(lats-sitelat),2);
        [~,lonind] = mink(abs(lons-sitelon),2);
        
        %truncate variable to this location
        varuse = [];
        for ivar = 1:size(var,2)
            vartemp2 = var{ivar};
            varsh = vartemp2(lonind,latind,:);
            %get the average
            varuse{ivar} = mean(reshape(varsh,[],size(varsh,3),1),'omitnan');
        end
        
        %get times into useable format for display- times are in hours since
        %2000-01-01
        dntimes = datenum(0,0,0,vertcat(times{:}),0,0) + datenum(2000,1,1,0,0,0);
        
        %         %convert variable into anomaly, if desired
        %         if anom
        %             varcon = horzcat(varuse{:})';
        %             %subtract all values by mean value to look for
        %             %anomalies
        %             varfinal = varcon - mean(varcon,'omitnan');
        %         else
        %             %otherwise, use the raw data
        %             varfinal = horzcat(varuse{:})';
        %         end
        
        %assign depth and time to values in varuse
        varmattemp = [dntimes,depths,horzcat(varuse{:})'];
        
        %get anomalies by calculating mean by depth
        uniqd = unique(depths);
        varmattemp(:,4) = nan(size(varmattemp,1),1);
        for id = 1:size(uniqd,1)
            vard = varmattemp(depths == uniqd(id),3);
            %find anomalous values for these variables
            varanom = vard - mean(vard,'omitnan');
            %put the anomalous values in the correct rows based on depth
            %index
            varmattemp(depths == uniqd(id),4) = varanom;
        end
        
        %store varmat for whichever variables we care about
        varmat{iV} = varmattemp;
    end
    
    savename = fullfile(files(iF).folder,[site,'_',horzcat(varname{:}),...
        '_nccomb.mat']);
    save(savename,'varmat','varname','-v7.3')
    
else
    openfile = dir(fullfile(infiles,[site,'*nccomb.mat']));
    load(fullfile(openfile.folder,openfile.name))
end

%sort out plotting functionality
%figure out how many time bins we'll have- lets plot a month at once
%query the time bins
varq = varmat{1};
dttimeInds = datetime(datevec(min(varq(:,1)))):calmonths(timestep)...
    :datetime(datevec(max(varq(:,1))));
timeInds = datenum(dttimeInds);

figure
%run through the times
for ti = 1:size(timeInds,2)-1
    %current time indices
    timest_ed = timeInds(ti:ti+1);
    %create a subplot for each variable with correct times
    for vari = 1:size(varmat,2)
        if vari ~= 2
            curvar = varmat{vari};
            %create a subplot for this variable
            subplot(size(varmat,2),1,vari)
            %truncate to desired times
            timeuse = find(curvar(:,1) >= timest_ed(1) & curvar(:,1) <=timest_ed(2));
            vartr = curvar(timeuse,:);
            fulldepths = max(vartr(:,2)):-0.5:min(vartr(:,2));
            
            %interpolate-at each time slice- between depths to get all depth ranges
            eachTime = unique(vartr(:,1));
            
            plotvarc = [];
            for ie = 1:size(eachTime,1)
                varsh2 = vartr(vartr(:,1) == eachTime(ie),:);
                
                %remove duplicates
                [~,dupdepid] = unique(varsh2(:,2));
                varsh2 = varsh2(dupdepid,:);
                
                %get full depth for this time slice
                %if using anomaly, use it
                if anom
                    varcol = 4;
                else
                    %otherwise use raw variable
                    varcol = 3;
                end
                
                interpvar = interp1(varsh2(~isnan(varsh2(:,varcol)),2),...
                    varsh2(~isnan(varsh2(:,varcol)),varcol),fulldepths,'linear','extrap');
                
                %restructure into final matrix for plotting
                plotvarc{ie} = [repmat(eachTime(ie),size(fulldepths,2),1),fulldepths',interpvar'];
            end
            
            %put back in matrix
            plotvar = vertcat(plotvarc{:});
            
            %plot using depth for y, time for x, and color as variable
            scatter(plotvar(:,1),plotvar(:,2),[],plotvar(:,3),'.')
            %set colormap based on variable type
            if strcmp(varname{vari},'salinity')
                cmocean('haline');
            elseif strcmp(varname{vari},'water_temp')
                cmocean('thermal');
            else
                cmocean('curl');
            end
            colorbar
            %set the colorbar axis to just include values we want
            lowlim = mean(plotvar(:,3)) - std(plotvar(:,3));
            highlim = mean(plotvar(:,3)) + std(plotvar(:,3));
            caxis([lowlim highlim])
            axis tight
            
            datetick
            ylabel('Depth (m)')
            if anom
                title([varname{vari},' anomaly'],'Interpreter', 'none')
            else
                title(varname{vari},'Interpreter', 'none')
            end
            set(gca, 'YDir','reverse')
            %         set(gca, 'YScale', 'log')
            ylim(depthrange)
            xlim([min(plotvar(:,1)) max(plotvar(:,1))])
            shading interp
            set(gcf, 'Units', 'Normalized', 'OuterPosition', [0.1, 0.2, 0.6, 0.8]);
        end
    end
    xlabel('Time')
    set(gcf,'Name',['Variables for site ',site])
    pause
end



%%additional functionality: look at data on a map view to see spatial
%%extent, run through times to examine change

% %make our lat/lon matrices
% ln = repmat(lons,1,length(lats));
% lt = repmat(lats,1,length(lons))';
%
% %run through the times to look at changing chlorophyll
% figure
% for iz = 1:size(sal,4)
%     sal1 = sal(:,:,1,iz);
%
%     pcolor(ln,lt,sal1)
%     shading interp
%
%     title(char(dttimes(iz)))
%     pause;
% end
