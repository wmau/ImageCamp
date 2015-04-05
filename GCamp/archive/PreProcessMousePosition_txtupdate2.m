function [xpos_interp,ypos_interp,start_time,MoMtime] = PreProcessMousePosition(filepath)

close all;

try
    load Pos.mat
    return
catch 

    

    
% Script to take position data at given timestamps and output and interpolate 
% to any given timestamps.

PosSR = 30; % native sampling rate in Hz of position data (used only in smoothing)
aviSR = 30.0003; % the framerate that the .avi thinks it's at

% IMPORT data position from DVT file
pos_data = importdata(filepath);
%f_s = max(regexp(filepath,'\'))+1;
%mouse_name = filepath(f_s:f_s+2);
%date = [filepath(f_s+3:f_s+4) '-' filepath(f_s+5:f_s+6) '-' filepath(f_s+7:f_s+10)];

% Parse out into invididual variables
frame = pos_data(:,1);
time = pos_data(:,2); % time in seconds
Xpix = pos_data(:,3); % x position in pixels (can be adjusted to cm)
Ypix = pos_data(:,4); % y position in pixels (can be adjusted to cm)
start_time = time(1); % NRK
offset = round((time(1) - start_time)*PosSR,0);
% offset = 0; % NRK edit

disp('Here is your chance to start an interrupted session by loading Pos_temp.mat')
keyboard

% Attempt to update with TXT file if present
if ~exist('MoMtime','var') % Run only if Pos_temp.mat not loaded
    try
        %     keyboard
        % Video.txt is there instead of Video.DVT
        txt_data = importdata('Video.txt');
        cols = input('Enter [time x y] columns from text file: ');
        txt_Xpix = txt_data(:,cols(1));
        txt_Ypix = txt_data(:,cols(2));
        txt_time = txt_data(:,cols(3));
        start_time = input('Enter first time stamp from DVT file: '); % NRK
        offset = round((time(1) - start_time)*PosSR,0);
        
        % Replace values in Xpix with updated values
        disp('Updating DVT file with TXT/Cineplex editor coordinates/')
        for j = 1:length(txt_time)
            iDVT = findclosest(txt_time(j),time);
            Xpix(iDVT) = txt_Xpix(j);
            Ypix(iDVT) = txt_Ypix(j);
        end
        
        % NRK Edit startpos
        try
            h1 = implay('Raw.AVI');
        catch
            avi_filepath = ls('*.avi');
            h1 = implay(avi_filepath);
            disp(['Using ' avi_filepath ])
        end
        % NRK edit end
        
        close(h1); % Close Video Player
        
    catch
        
    end
    
    MouseOnMazeFrame = input('on what frame number does Mr. Mouse arrive on the maze??? --->');
    % MoMtime = (MouseOnMazeFrame)*(time(2)-time(1))+time(1)
    MoMtime = (MouseOnMazeFrame)*(time(2)-time(1))+ start_time
    
elseif exist('MoMtime','var')
    
    MoMtime
    MouseOnMazeFrame = (MoMtime - start_time)/(time(2)-time(1)); % Back calculate this
    
end


xAVI = Xpix*.6246;
yAVI = Ypix*.6246;

figure(777);plot(Xpix,Ypix);title('pre-corrected data')


figure(555);
subplot(4,3,1:3);plot(time,Xpix);xlabel('time (sec)');ylabel('x position (cm)');yl = get(gca,'YLim');line([MoMtime MoMtime], [yl(1) yl(2)],'Color','r');axis tight;
subplot(4,3,4:6);plot(time,Ypix);xlabel('time (sec)');ylabel('y position (cm)');yl = get(gca,'YLim');line([MoMtime MoMtime], [yl(1) yl(2)],'Color','r');axis tight;

try
    obj = VideoReader('Raw.AVI');
catch
    obj = VideoReader(avi_filepath);
end

v0 = readFrame(obj);
MorePoints = 'y';
length(time)

while (strcmp(MorePoints,'y'))
  subplot(4,3,1:3);plot(time,Xpix);xlabel('time (sec)');ylabel('x position (cm)');...
      hold on; yl = get(gca,'YLim');line([MoMtime MoMtime], [yl(1) yl(2)],'Color','r');...
      hold off;axis tight;
  subplot(4,3,4:6);plot(time,Ypix);xlabel('time (sec)');ylabel('y position (cm)');...
      hold on;yl = get(gca,'YLim');line([MoMtime MoMtime], [yl(1) yl(2)],'Color','r');...
      hold off;axis tight;
  MorePoints = input('Is there a flaw that needs to be corrected?  [y/n] -->','s');

  
  if (strcmp(MorePoints,'n') ~= 1 && strcmp(MorePoints,'g') ~= 1)
    FrameSelOK = 0;
    while (FrameSelOK == 0)
        display('click on the good points around the flaw then hit enter');
        [DVTsec,~] = ginput(2); % DVTsec is start and end time in DVT seconds
        sFrame = findclosest(time,DVTsec(1)); % index of start frame - NRK need an offset in here somehow
        eFrame = findclosest(time,DVTsec(2)); % index of end frame
        aviSR*sFrame;

        if (sFrame/aviSR > obj.Duration || eFrame/aviSR > obj.Duration) % NRK 
            
            continue;
        end
        obj.currentTime = (sFrame)/aviSR; % NRK sFrame is the correct frame #, but .avi reads are done according to time
        v = readFrame(obj);
        FrameSelOK = 1;
    end
    figure(555);
    subplot(4,3,11);imagesc(flipud(v));hold on; % plot Video
    plot(xAVI(sFrame:eFrame),yAVI(sFrame:eFrame),'LineWidth',1.5);hold off; % plot the selected trajectory
    framesToCorrect = sFrame:eFrame;  %NRK
    
    for i = 1:floor(length(framesToCorrect)/2);
        % plot x and y values for the selected frames
        figure(555);
        subplot(4,3,1:3);plot(time,Xpix);xlabel('time (sec)');ylabel('x position (cm)');...
            hold on;yl = get(gca,'YLim');line([MoMtime MoMtime], [yl(1) yl(2)],'Color','r');...
            hold off;axis tight;set(gca,'XLim',[sFrame/aviSR eFrame/aviSR]);
        subplot(4,3,4:6);plot(time,Ypix);xlabel('time (sec)');ylabel('y position (cm)');...
            hold on;;yl = get(gca,'YLim');line([MoMtime MoMtime], [yl(1) yl(2)],'Color','r');...
            hold off;axis tight;set(gca,'XLim',[sFrame/aviSR eFrame/aviSR]);
        
        % plot the velocity
        subplot(4,3,7:9);
        vel = sqrt(diff(Xpix).^2+diff(Ypix).^2)*(time(2)-time(1));
        plot(time(MouseOnMazeFrame:end-1),vel(MouseOnMazeFrame:end));hold off;axis tight;xlabel('time (sec)');ylabel('velocity (units/sec)');
        
        % plot the current sub-trajectory
        subplot(4,3,11);
        imagesc(flipud(v));hold on;
        plot(xAVI(sFrame:eFrame),yAVI(sFrame:eFrame),'LineWidth',1.5);hold off;title('chosen segment');
        
        % plot the current total trajectory
        subplot(4,3,10);
        imagesc(flipud(v));hold on;
        plot(xAVI(MouseOnMazeFrame:end),yAVI(MouseOnMazeFrame:end),'LineWidth',1.5);hold off;title('overall trajectory (post mouse arrival)');
        
        % plot the current video frame
        figure(1702);pause(0.1);
        gcf;
        obj.currentTime = framesToCorrect(i*2)/aviSR;
        framesToCorrect(i*2)/aviSR
        v = readFrame(obj);
        imagesc(flipud(v));title('click here');
        
        % plot the existing position marker on top
        hold on;plot(xAVI(sFrame + i*2),yAVI(sFrame + i*2),'ro','MarkerSize',4);
        display('click the mouses back');
        [xm,ym] = ginput(1);
        
        % apply corrected position to current frame
        xAVI(sFrame+i*2) = xm;
        yAVI(sFrame+i*2) = ym;
        Xpix(sFrame+i*2) = ceil(xm/0.6246);
        Ypix(sFrame+i*2) = ceil(ym/0.6246);
        
        % interpolate and apply correct position for previous frame
        xAVI(sFrame+i*2-1) = xAVI(sFrame+i*2-2)+(xm-xAVI(sFrame+i*2-2))/2;
        yAVI(sFrame+i*2-1) = yAVI(sFrame+i*2-2)+(ym-yAVI(sFrame+i*2-2))/2;
        Xpix(sFrame+i*2-1) = ceil(xAVI(sFrame+i*2-1)/0.6246);
        Ypix(sFrame+i*2-1) = ceil(yAVI(sFrame+i*2-1)/0.6246);
        
        
        % plot marker
        plot(xm,ym,'or','MarkerSize',4,'MarkerFaceColor','r');hold off;

        
    end
    close(1702);
    save Pos_temp.mat Xpix Ypix xAVI yAVI MoMtime
  continue
  end
  
  keyboard
  if (strcmp(MorePoints,'g'))
      % generate a movie and show it
      for i = 1:length(time)
        obj.currentTime = i/aviSR; % sFrame is the correct frame #, but .avi reads are done according to time
        v = readFrame(obj);
        figure(6156);
        imagesc(flipud(v));hold on;
        plot(xAVI(i),yAVI(i),'or','MarkerSize',5,'MarkerFaceColor','r');hold off;
        F(i) = getframe(gcf);
      end
      save F.mat F; implay(F);pause;
  end
        
end

XpixPF = Xpix;
YpixPF = Ypix;

Xpix = NP_QuickFilt(Xpix,0.0000001,1,PosSR);
Ypix = NP_QuickFilt(Ypix,0.0000001,1,PosSR);

if size(pos_data,2) == 5
    motion = pos_data(:,5);
end

frame_rate_emp = round(1/mean(diff(time))); % empirical frame rate (frames/sec)

% Conjure up set of times to test script
fps_test = 20; % frames/sec for dummy timestamps

start_time = min(time);
max_time = max(time);
time_test = start_time:1/fps_test:max_time;

if (max(time_test) >= max_time)
    time_test = time_test(1:end-1);
end

%% Do Linear Interpolation

% Get appropriate time points to interpolate for each timestamp
time_index = arrayfun(@(a) [max(find(a >= time)) min(find(a < time))],...
    time_test,'UniformOutput',0);
time_test_cell = arrayfun(@(a) a,time_test,'UniformOutput',0);

xpos_interp = cellfun(@(a,b) lin_interp(time(a), Xpix(a),...
    b),time_index,time_test_cell);

ypos_interp = cellfun(@(a,b) lin_interp(time(a), Ypix(a),...
    b),time_index,time_test_cell);

save Pos.mat xpos_interp ypos_interp start_time MoMtime

end





