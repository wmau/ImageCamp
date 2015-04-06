function [cell_map_reg cell_map_header_reg ] = image_register3(base_file, register_file, rotation) % , cell_map, cell_map_header)
% Image Registration Function - this fuction allows you to register a given
% recording session (the registered session) to a previous sesison ( the
% base session) to track neuronal activity from session to session.  It
% also outputs a combined set of ICs so that you can register a given
% session to multiple previous sessions.  Note that you must enter an
% approximate rotation if you used a different focuse for the registered
% file, or else the in-house MATLAB image registration functions won't
% work...
%
% INPUT VARIABLES
% base_file:    .tif file for the minimimum projection of the motion
%               corrected ICmovie for the base image.  Needs to be in the
%               same directory as SignalTrace.mat (or CellRegisterBase.mat
%               for multiple sessions) to work
% register_file:.tif file (min projection of the motion corrected ICmovie)
%               for the image/recording you wish to register to the base
%               image. Needs to be in the same directory as SignalTrace.mat
%               to work.  Enter the same file as the base_file if you want
%               to do a base mapping.
% rotation:     Degrees (+ = CW). If a different focus level was used for the registered
%               file, enter it here - this will rotate the registered image
%               before doing the registration (will not work otherwise).
% OUTPUTS
% cell_map:     cell array with each row corresponding to a given neuron,
%               and each column corresponding to a recording session.  The value
%               corresponds to the GoodICf number from that session for that neuron.
% cell_map_header: contains info for each column in cell_map
% GoocICf_comb: combines ICs from the base file and the registered file.
%               Use this file as the base file for future registrations of
%               a file to multiple previous sessions.

% To do:

% Try this out for images that are significantly different, e.g. rotated
% 180 degrees...
% Run this for G19 for all sessions!
% Automatically fill in expected neuron for base mapping

close all;
 
%% MAGIC VARIABLES
configname = 'multimodal'; % For images taken with similar contrasts, e.g. from the same device, same gain, etc.
regtype = 'similarity'; % Similarity = Translation, Rotation, Scale

% Adjust registration algorithm values:
% MONOMODAL
mono_max_iterations = 1000; % optimizer.MaximumIterations = 100 default
mono_max_step = 1e-3;% optimizer.MaximumStepLength = 0.0625 default
mono_min_step = 1e-5; % optimizer.MinimumStepLength = 1e-5 default
mono_relax = 0.5; %optimizer.RelaxationFactor = 0.5 default
mono_gradient_tol = 1e-6; % optimizer.GradientMagnitudeTolerance = 1e-4 default
% MULTIMODAL
multi_max_iterations = 10000; % optimizer.MaximumIterations = 100 default
multi_growth = 1.05; % optimizer.GrowthFactor = 1.05 default
multi_epsilon = 1.05e-6; % optimizer.Epsilon = 1.05e-6 default
multi_init_rad = 6.25e-4; % optimizer.InitialRadius = 6.25e-3 default

FigNum = 1; % Start off figures at this number

%% Step 1: Select images to compare and import the images

if nargin == 0
[base_filename, base_path, filterindexbase] = uigetfile('*.tif',...
    'Pick the base image file: ');
base_file = [base_path base_filename];

[reg_filename, reg_path, filterindexbase] = uigetfile('*.tif',...
    'Pick the image file to register with the base file: ',[base_path base_filename]);
register_file = [reg_path reg_filename];
elseif nargin == 1
    error('Please input both a base image and image to register to base file')
elseif nargin >= 2
   
    base_filename = base_file(max(regexp(base_file,'\','end'))+1:end);
    base_path = base_file(1:max(regexp(base_file,'\','end')));
    reg_filename = register_file(max(regexp(register_file,'\','end'))+1:end);
    reg_path = register_file(1:max(regexp(register_file,'\','end')));
    
end

% Check if this is a base cell mapping or not
base_check = [base_path 'CellRegisterBase.mat'];

% Set flag if this is the base cell registration
if exist(base_check,'file') == 0
    base_map = 1;
elseif exist(base_check,'file') == 2
    base_map = 0;
end

% Check if this is the base mapping run in case no registered file was
% entered.
if reg_filename == 0
   temp1 = input('You have not entered a file to register.  Is this the base mapping run? (y/n):' ,'s');
   if strcmp(temp1,'n')
       disp('Please re-run register function and enter file to register');
       return
   elseif strcmp(temp1,'y') %  Set up base mapping!
      reg_filename = base_filename;
      reg_path = base_path;
      register_file = base_file;
   end
end

base_image = im2double(imread(base_file));
reg_image = im2double(imread(register_file));

%% Step 2: Run Registration Functions, get transform

if nargin >= 3
    manual_tform = affine2d([cosd(rotation) -sind(rotation) 0 ; ...
        sind(rotation) cosd(rotation) 0; 0 0 1]);    
else
    
end

[optimizer, metric] = imregconfig(configname);
if strcmp(configname,'monomodal') % Adjust defaults if desired.
    optimizer.MaximumIterations = mono_max_iterations;
    optimizer.MaximumStepLength = mono_max_step;
    optimizer.MinimumStepLength = mono_min_step;
    optimizer.RelaxationFactor = mono_relax;
    optimizer.GradientMagnitudeTolerance = mono_gradient_tol;
    
elseif strcmp(configname,'multimodal')
    optimizer.MaximumIterations = multi_max_iterations;
    optimizer.GrowthFactor = multi_growth;
    optimizer.Epsilon = multi_epsilon;
    optimizer.InitialRadius = multi_init_rad;
    
end
% [moving_reg r_reg] = imregister(reg_image, base_image, regtype, optimizer, metric
tform = imregtform(reg_image, base_image, regtype, optimizer, metric);
moving_reg = imwarp(reg_image,tform,'OutputView',imref2d(size(base_image)));

% This makes sure that no transform is applied to the base image, just in
% case.
if base_map == 1
   tform.T = [1 0 0 ; 0 1 0 ; 0 0 1]; 
else
end


% Quality Control Plot: Plot original images, registered image, and 
% base-registered image

figure(1)
h_base_landmark = subplot(2,2,1);
imagesc(base_image); colormap(gray); colorbar
title('Base Image');
h_reg_landmark = subplot(2,2,2);
imagesc(reg_image); colormap(gray); colorbar
title('Image to Register');
subplot(2,2,3)
imagesc(moving_reg); colormap(gray); colorbar
title('Registered Image')
subplot(2,2,4)
imagesc(abs(moving_reg - base_image)); colormap(gray); colorbar
title('Registered Image - Base Image')

% FigNum = FigNum + 1;

%% Step 3: Take Good ICs from registered image and overlay them onto base image

% Load data for ICs: Here I assume that the data files lie in the same directories as the
% reference images

if base_map == 1
    base_data = importdata([base_path 'FinalTraces.mat']);
    reg_data = importdata([base_path 'FinalTraces.mat']);
    
%     base_data = importdata([base_path 'SignalTrace.mat']);
%     reg_data = importdata([reg_path 'SignalTrace.mat']);
    
    base_IC = base_data.ThreshIC; % Use ThreshICs for base image if base mapping condition

elseif base_map == 0
    base_data = importdata([base_path 'CellRegisterBase.mat']);
    reg_data = importdata([reg_path 'SignalTrace.mat']);
    
    base_IC = base_data.GoodICf_comb; % Set GoodICf to combined otherwise
    % GoodICf from all previous sessions
    
    % Archive CellRegisterBase, since it will get overwritten later
    save([base_path 'CellRegisterBase' num2str(size(base_data.cell_map,2)) '.mat'],...
        'base_data');
end

% Create a map of All ICs for both the base file and the registered file.

base_data.AllIC = create_AllICmask(base_IC);
AllIC_base = base_data.AllIC;
% AllIC = zeros(size(base_IC{1}));
% for j = 1:size(base_IC,2)
%     AllIC = AllIC + base_IC{j};
% end
% base_data.AllIC = AllIC;

% if base_map == 1 % Use ThreshICs for AllIC map if this is the base mapping condition
%     AllIC = zeros(size(base_data.ThreshIC{1}));
%     for j = 1:size(base_data.ThreshIC,2)
%         AllIC = AllIC + base_data.ThreshIC{j};
%     end
%     base_data.AllIC = AllIC;
%     
%     
% elseif base_map == 0 % Use GoodICf_comb for AllIC map if this is not the base condition
%     AllIC = zeros(size(base_data.GoodICf{1}));
%     for j = 1:size(base_data.GoodICf,2)
%         AllIC = AllIC + base_data.GoodICf{j};
%     end
%     base_data.AllIC = AllIC;
% 
% end

reg_data.AllIC = create_AllICmask(reg_data.GoodICf);
% AllIC2 = zeros(size(reg_data.GoodICf{1}));
% for j = 1:size(reg_data.GoodICf,2)
%    AllIC2 = AllIC2 + reg_data.GoodICf{j};
% end
% reg_data.AllIC = AllIC2;


% Register AllIC_reg to AllIC_base
AllIC_reg = imwarp(reg_data.AllIC,tform,'OutputView',imref2d(size(base_image)));



% Plot out both...

figure(2)
h_base_mask = subplot(1,2,1);
imagesc(base_data.AllIC); title('Base Image Cells')
h_reg_mask = subplot(1,2,2);
imagesc(AllIC_reg*2); title('Registered Image Cells')
figure(3)
imagesc(base_data.AllIC+ AllIC_reg*2); title('Combined Image Cells'); colormap(jet)
h = colorbar('YTick',[0 1 2 3],'YTickLabel', {'','Base Image Cells','Reg Image Cells','Overlapping Cells'});

% FigNum = FigNum + 1;

%% Step 3A: Give option to adjust manually if this doesn't work...

FigNum = 5;
manual_flag = input('Do you wish to manually adjust this registration? (y/n): ','s');
while strcmpi(manual_flag,'y')
    manual_type = input('Do you wish to adjust by landmarks or my cell masks? (l/m): ','s');
    T_manual = [];
    while isempty(T_manual)
        if strcmpi(manual_type,'l')
            reg_type = 'landmark';
            figure(1)
            T_manual = manual_reg(h_base_landmark, h_reg_landmark, reg_type);
            
        elseif strcmpi(manual_type,'m')
            reg_type = 'mask';
            figure(4)
            h_base_mask = subplot(1,2,1);
            imagesc(base_data.AllIC); title('Base Image Cells')
            h_reg_mask = subplot(1,2,2);
            imagesc(reg_data.AllIC); title('Registered Image Cells')
            T_manual = manual_reg( h_base_mask, h_reg_mask, reg_type, base_data, reg_data);
        end
    end
    
    tform_manual = tform;
    tform_manual.T = T_manual;
    AllIC_reg_manual = imwarp(reg_data.AllIC,tform_manual,'OutputView',imref2d(size(base_image)));
    moving_reg_manual = imwarp(reg_image,tform_manual,'OutputView',imref2d(size(base_image)));
    
    figure(FigNum)
    imagesc(base_data.AllIC+ AllIC_reg_manual*2);  colormap(jet)
    title(['Combined Image Cells - Manual Adjust, rot = ' num2str( asind(tform_manual.T(1,2)),'%1.2f') ' degrees']);
    h = colorbar('YTick',[0 1 2 3],'YTickLabel', {'','Base Image Cells','Reg Image Cells','Overlapping Cells'});
    xlabel(['X shifted by ' num2str(tform_manual.T(3,1),'%1.1f') ' pixels']);
    ylabel(['Y shifted by ' num2str(tform_manual.T(3,2),'%1.1f') ' pixels']);
    
    FigNum = FigNum + 1;
    
    figure(FigNum)
    imagesc(abs(moving_reg_manual - base_image)); colormap(gray); colorbar
    title('Registered Image - Base Image')
    
    
    manual_flag = input('Do you wish to manually adjust again? (y/n)', 's');


    
end
FigNum = FigNum + 1;

if exist('T_manual','var')
    save ([ base_path 'RegistrationInfo.mat'], 'tform', 'tform_manual','AllIC_base',...
        'AllIC_reg','AllIC_reg_manual','base_file','register_file')
else
    save ([ base_path 'RegistrationInfo.mat'], 'tform','AllIC_base',...
    'AllIC_reg','base_file','register_file')
end


%% Step 4: Visually scroll through registered cells and map them onto base image cells

figure(FigNum)

reg_GoodICf = cellfun(@(a) imwarp(a,tform,'OutputView',imref2d(size(base_image))), ...
    reg_data.GoodICf,'UniformOutput',0); % Register each IC to the base image

% Create cell map cell variable if one doesn't already exist
if base_map == 1
    cell_map = cell(size(base_IC,2),2);
    for j = 1:size(cell_map,1)
        cell_map{j,1} = j;
    end
    reg_col = 2;
elseif base_map == 0
    cell_map = base_data.cell_map;
    cell_map_header = base_data.cell_map_header;
    reg_col = size(cell_map,2) + 1;
end


% Step through each cell in registered image and match to base image cells.
% Note that if this is the base mapping, you are registering the GoodICfs
% to all the ICs from the base session.
overlap = cell(1,size(reg_data.GoodICf,2));
overlap_ratio = cell(1,size(reg_data.GoodICf,2));

base_map_error_cells = [];
for j = 1:size(reg_data.GoodICf,2)
    num_cells_total = size(cell_map,1); % Get total number of cells
    
    % Get union of each IC from the base image with the given registered IC
    temp = cellfun(@(a) a & reg_GoodICf{j},base_IC, ...
         'UniformOutput',0); 
    overlap{j} = find(cellfun(@(a) sum(sum(a)) > 0,temp));
    
    figure(FigNum)
    imagesc(base_data.AllIC + 2*reg_GoodICf{j})
    
    if ~isempty(overlap{j})
        for k = 1:size(overlap{j},2)
            overlap_ratio{j}(k) = sum(sum(temp{overlap{j}(k)}))/...
                sum(sum(base_IC{overlap{j}(k)})); % Get ratio of mask that overlaps with each cell in base image
            disp(['This cell overlaps with base image cell #' ...
                num2str(overlap{j}(k)) ' by ' num2str(100*overlap_ratio{j}(k),'%10.f') '%.'])
        end
        figure(FigNum) % For some reason figure 3 gets hidden occassionally when I get to this point, manually overriding. Doesn't work!
        
        if base_map == 1
            temp2 = overlap{j}(k); % THIS ISN'T IN A FOR LOOP, NEEDS TO BE CORRECTED/CHECKED
            temp3 = input('Hit enter to confirm.  Enter cell number to log error in mapping this cell: ');
            base_map_error_cells = [base_map_error_cells temp3];
        elseif base_map ~= 1 % NRK - make this simpler.  Automatically fill in cell with most overlap, and have user overwrite if not ok...?
            temp2 = input('Enter base image cell number to register with this neuron (enter nothing for new neuron):');
            % Check to make sure you didn't make an obvious error
            if isempty(temp2) || sum(overlap{j} == temp2) == 0 && sum(overlap_ratio{j} >= 0.5) == 1
                % Check if you entered a cell number that doesn't overlap, or
                % new neuron was entered even though there is more than 50%
                % overlap with a cell
                temp2 = input('Possible error detected.  Confirm previous cell number entry: ');
            elseif sum(overlap{j} == temp2) == 1 && overlap_ratio{j}(overlap{j} == temp2) < 0.5
                % Check if you entered the neuron with lesser overlap by
                % accident
                temp2 = input('Possible error detected.  Confirm previous cell number entry: ');
            end
            
        end
        
        if ~isempty(temp2)
            cell_map{temp2,reg_col} = j; % Assign registered image good IC number to appropriate base image IC
        elseif isempty(temp2)
            cell_map{num_cells_total+1,reg_col} = j;
        end
        

    elseif isempty(overlap{j})
        disp(['Registered image cell # ' num2str(j) ' does not overlap with any cells from base image. Hit enter to proceed.'])
        cell_map{num_cells_total+1,reg_col} = j;
        pause
    end
     
    
end
FigNum = FigNum + 1;

figure(FigNum) % Plot out combined cells after registration
subplot(2,1,1)
imagesc(base_data.AllIC+ AllIC_reg*2); title('Combined Image Cells'); colormap(jet)
h = colorbar('YTick',[0 1 2 3],'YTickLabel', {'','Base Image Cells','Reg Image Cells','Overlapping Cells'});


%% Step 5: Plot out updated masks that combines all the ICs from the two sessions and plot out which
% cells overlap, which cells are new, and which are active only in the base
% session
% Right now I will assume that we always want to reference back to the very
% first session for our reference picture...

GoodICf_comb = cell(1,size(cell_map,1)); % Overwrite previous GoodICf_comb
for j = 1:size(GoodICf_comb,2)
    
   if ~isempty(cell_map{j,reg_col}) && isempty(cell_map{j,reg_col-1}) 
       % New neuron (neuron only active in registered session, not any previous sessions)
       GoodICf_comb{j} = reg_GoodICf{cell_map{j,reg_col}};
   elseif ~isempty(cell_map{j,reg_col}) && ~isempty(cell_map{j,reg_col-1}) 
       % Neuron active in both sessions
       GoodICf_comb{j} = reg_GoodICf{cell_map{j,reg_col}} | base_IC{j} ;
   elseif isempty(cell_map{j,reg_col}) 
       % Previously active neuron becomes silent in registered session (or noisy??)
       GoodICf_comb{j} = base_IC{j};
   end
   
end

% Combine all the ICs together and plot versus individual masks to check
AllIC_comb = zeros(size(GoodICf_comb{1}));
for j = 1:size(GoodICf_comb,2)
   AllIC_comb = AllIC_comb + GoodICf_comb{j}; % NRK start here - matrix dimensions don't agree
end

figure(FigNum)
subplot(2,1,2)
imagesc(AllIC_comb); title('Combined Session Cells after registration'); colormap(jet)
h = colorbar('YTick',[0 1 2],'YTickLabel', {'','Individual Cells','Overlapping Portions'});

colorbar

FigNum = FigNum + 1;

%% Step 6: Save the cell map and header for reference

% Prompt to save session info for header file

if base_map == 1
    base_session = input('Enter base session name (arena_location): ','s');
    base_date = input('Enter base session date (mm_dd_yyyy): ','s');
else
    base_session = input('Enter base session name (arena_location): ','s');
    base_date = input('Enter base session date (mm_dd_yyyy): ','s');
    reg_session = input('Enter registered session name (arena_location): ','s');
    reg_date = input('Enter registered session date (mm_dd_yyyy): ','s');
end

if base_map == 1
    
    cell_map_header{1,1} = base_date;
    cell_map_header{2,1} = base_session;
    cell_map_header{3,1} = 'All ICs';
    
    cell_map_header{1,2} = base_date;
    cell_map_header{2,2} = base_session;
    cell_map_header{3,2} = 'Good ICs';

elseif base_map == 0
    
    cell_map_header{1,reg_col} = reg_date;
    cell_map_header{2,reg_col} = reg_session;
    cell_map_header{3,reg_col} = 'Good ICs';
    
end

save([base_path 'CellRegisterBase.mat'], 'cell_map_header', 'cell_map', 'GoodICf_comb')

keyboard;