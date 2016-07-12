function FixFrames(filename)
%FixFrames(filename)
%
%   The camera occasionally produces bad frames that are characterized by
%   massive static. This function uses the mean pixel value of the entire
%   frame to determine whether it is a bad frame or not. If it is,
%   FixFrames will replace that frame with the frame before it. Note that
%   your tif file will be overwritten with the new tif after corrections. 
%
%   INPUT:
%       filename: Filename of the brain imaging tif movie. 
%

%% Parameters and preallocation. 
    imgdata = imfinfo(filename); 
    nFrames = size(imgdata,1); 
    TifLink = Tiff(filename); 
    
    meanframes = nan(1,nFrames); 
    badframes = [];
    
%% Get the mean pixel value for every frame. 
    p = ProgressBar(nFrames);
    for thisframe = 1:nFrames
        TifLink.setDirectory(thisframe); 
        frame = TifLink.read();
        meanframes(thisframe) = mean(frame(:));
        
        if any(sum(frame,2) == 0)
           	badframes = [badframes, thisframe];
        end
        
        p.progress;
    end
    p.stop;
    
%% Get bad frames. 
    SD = std(meanframes); 
    toohigh = median(meanframes) + 4*SD; 
    toolow = median(meanframes) - 4*SD;
    
    badframes = [badframes, find(meanframes > toohigh | meanframes < toolow)]; 
    numbadframes = length(badframes); 
    
    %Display them. 
    for i=1:numbadframes
        figure;
        TifLink.setDirectory(badframes(i)); 
        frame = TifLink.read(); 
        imshow(frame,[]);
        title(['Frame #', num2str(badframes(i))]); 
    end
        
    %List the bad frames. 
    if isempty(badframes)
        disp('All frames in this recording are good!');
    elseif ~isempty(badframes)
        disp('Bad frames detected:');
        for i=1:numbadframes
            disp(badframes(i));
        end
    end
    
    %Manual check. 
    if ~isempty(badframes)
        disp('Are these all bad frames? If not, enter good frame numbers or type ''all'' if all frames are good')
        goodframes = input('If all frames are bad, leave empty. ', 's');
        if strcmpi(goodframes,'all')
            goodframes = badframes;
        else
            goodframes = str2num(goodframes);
        end
        if ~isempty(goodframes)
            badframes(ismember(badframes,goodframes)) = []; 
        end
    end
    
    close all;
    
%% Replace bad frames. 
    %Replace bad frames with the previous and save. 
    outputname = [filename(1:end-4), 'fixed.tif']; 
    
    if ~isempty(badframes)
        disp('Replacing frames...');
        for i=1:nFrames
            TifLink.setDirectory(i); 
            frame = TifLink.read(); 
            if ismember(i,badframes);
                j = i; %Initial frame. 
                stillbad = 1; 
                
                %While still in badframes, subtract one from frame number. 
                while stillbad
                    j = j-1;    
                    stillbad = ismember(j,badframes);
                end
                
                %Replace frame. 
                TifLink.setDirectory(j);
                frame = TifLink.read(); 
            end
            try
                imwrite(frame,outputname,'WriteMode','append','Compression','none'); 
            catch
                pause(1);
                imwrite(frame,outputname,'WriteMode','append','Compression','none');
                return;
            end
        end
        
        TifLink.close();
        %Replace old movie with fixed movie. 
        delete(filename); 
        FileRename(outputname,filename,'forced');
    end
    
    save([filename(1:end-4), 'fixed.mat'],'badframes'); 
end