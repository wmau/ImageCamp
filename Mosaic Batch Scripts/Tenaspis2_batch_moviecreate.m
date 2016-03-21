% Script to take any number of movies you select and create all the imaging
% files necessary to run Tenaspis V2: DFMovie.h5 and SLPDF.h5

%% Filter Specifications
filter_type = 'circular';
filter_pixel_radius = 3;
LPfilter_pixel_radius = 20;

curr_dir = cd;

%% Step 0: Initialize
mosaic.terminate(); % terminate any previous sessions
mosaic.initialize();

%% Step 1: Select Files to load
MotCorrFiles = file_select_batch('*.mat');

%Number of files and preallocate vector for movies that are already
%smoothed. 
nFiles = length(MotCorrFiles);
alreadysmoothed3 = zeros(nFiles,1); 
alreadysmoothed20 = zeros(nFiles,1); 
for i=1:nFiles
    %Folder containing session data. 
    MotCorrFiles(i).sessionFolder = fileparts(fileparts(MotCorrFiles(i).folder)); 
    
    %3 pixel smooth already done. 
    alreadysmoothed3(i) = exist(fullfile(MotCorrFiles(i).sessionFolder,'ICmovie_smoothed-Objects'),'dir') | ...
        exist(fullfile(MotCorrFiles(i).sessionFolder,'ICmovie_smooth_circular_3-Objects'),'dir');
    
    %20 pixel smooth already done. 
    alreadysmoothed20(i) = exist(fullfile(MotCorrFiles(i).sessionFolder,'LPmovie_circular_20-Objects'),'dir');
end

%% Step 2: Load files, mean filter, save them, and run TS_Lowpass_Divide on them
for j = 1:nFiles
    % Load motion-corrected, cropped, but un-smoothed movie.
    inputMovie = mosaic.loadObjects(MotCorrFiles(j).path);
    cd(MotCorrFiles(j).sessionFolder);
    
%% Do minimum projection and save.
    if ~exist(fullfile(MotCorrFiles(j).sessionFolder,'ICmovie_min_proj.tif'),'file')
        ICmovie_min_proj = mosaic.projectMovie(inputMovie,'projectionType','Minimum');
        mosaic.saveImageTiff(ICmovie_min_proj,'ICmovie_min_proj.tif'); 
    else
        disp('Minimum projection already done! Delete ICmovie_min_proj.tif to rerun.'); 
        ICmovie_min_proj = mosaic.loadImage(fullfile(pwd,'ICmovie_min_proj.tif'));
    end
    
%% Perform 3-pixel radius disc filter and save
    if ~alreadysmoothed3(j)
        disp(['Performing ' num2str(filter_pixel_radius) ' pixel disc smoothing of input movie']);
        
        %Perform filter.
        threePixSmoothMovie = mosaic.filterMovie(inputMovie,'filterType', filter_type,...
            'filterSize',filter_pixel_radius*2); 
        
        %Save. 
        cd(MotCorrFiles(j).sessionFolder);
        threePixSmoothMovie_saveName = ['ICmovie_smooth_' filter_type '_' num2str(filter_pixel_radius)];  
        mosaic.saveOneObject(threePixSmoothMovie,threePixSmoothMovie_saveName);       
        
    else %If already smoothed, just get the save name. 
        disp([num2str(filter_pixel_radius),' pixel smooth already done.']); 
        threePixSmoothMovie_saveName = ['ICmovie_smooth_' filter_type '_' num2str(filter_pixel_radius)];
    
        threePixSmoothMovie = mosaic.loadObjects(fullfile(MotCorrFiles(j).sessionFolder,[threePixSmoothMovie_saveName,'.mat']));
    end
   
    %Folder containing the .h5 file.
    threePixSmoothMovieFolder = fullfile(MotCorrFiles(j).sessionFolder,[threePixSmoothMovie_saveName '-Objects']); 
    cd(threePixSmoothMovieFolder); 
    
    %.mat pointing to Objects folder. 
    threePixSmoothMovie_matFile = [threePixSmoothMovieFolder(1:end-8) '.mat']; 
    %Full name to h5 file.
    threePixSmoothMovie_h5FullPath = fullfile(MotCorrFiles(j).sessionFolder,[threePixSmoothMovie_saveName '-Objects'],ls('*.h5')); 
    %.mat in Objects folder.
    threePixSmoothMovie_fullPathMat = [threePixSmoothMovie_h5FullPath(1:end-3) '.mat']; 
 
%% Get DF movie from 3-pixel movie
    disp('Creating DFmovie');
    DFMovie = mosaic.normalizeMovie(threePixSmoothMovie, 'method', '(f-f0)/f0','f0Image',ICmovie_min_proj);
    cd(MotCorrFiles(j).sessionFolder);
    mosaic.saveOneObject(DFMovie,'DFmovie');
    clear DFmovie threePixSmoothMovie
    
%% Perform 20-pixel radius disc filter and save
    if ~alreadysmoothed20(j)
        disp(['Performing ' num2str(LPfilter_pixel_radius) ' pixel disc smoothing of input movie for LPmovie']);
        
        %Perform filter.
        LPMovie = mosaic.filterMovie(inputMovie,'filterType', filter_type,...
            'filterSize',LPfilter_pixel_radius*2); 
        
        %Save.
        cd(MotCorrFiles(j).sessionFolder);
        LPMovie_savename = ['LPmovie_' filter_type '_' num2str(LPfilter_pixel_radius)];    
        mosaic.saveOneObject(LPMovie,LPMovie_savename);
    else
        disp([num2str(LPfilter_pixel_radius), ' pixel smooth already done.']); 
        LPMovie_savename = ['LPmovie_' filter_type '_' num2str(LPfilter_pixel_radius)]; 
    end
    
    LPMovie_folder = fullfile(MotCorrFiles(j).sessionFolder,[LPMovie_savename '-Objects']); % Folder containing the .h5 file
    cd(LPMovie_folder);
    %.mat pointing to Objects folder.
    LPMovie_matfile = [LPMovie_folder(1:end-8) '.mat']; 
    %Full name to h5 file
    LPMovie_h5FullPath = fullfile(MotCorrFiles(j).folder,[LPMovie_savename '-Objects'],ls('*.h5')); 
    %.mat in Objects folder.
    LPMovie_fullpath_mat = [LPMovie_h5FullPath(1:end-3) '.mat']; 
    clear LPMovie inputMovie


    
    %% Run TS_Lowpass_Divide
    disp('Creating TS Lowpass Divide movie')
    TS_Lowpass_Divide(threePixSmoothMovie_h5FullPath,LPMovie_h5FullPath);
    
    % Cleanup everything
    disp(['Deleting smoothed movie 1: ' threePixSmoothMovie_h5FullPath]);
    delete(threePixSmoothMovie_h5FullPath);
    delete(threePixSmoothMovie_fullPathMat);
%     rmdir(filterMovie_folder); % Not deleting yet because LowPass movie
%     ends up here from TS_Lowpass_Divide...
    delete(threePixSmoothMovie_matFile);
    
    disp(['Deleting smoothed movie 2: ' LPMovie_h5FullPath]);
    delete(LPMovie_h5FullPath);
    delete(LPMovie_fullpath_mat);
%     rmdir(LPMovie_folder); % Not deleting yet - need to clean up manually
    delete(LPMovie_matfile);
    
end

%% Terminate

mosaic.terminate();