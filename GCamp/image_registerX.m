function [RegistrationInfoX,unique_filename] = image_registerX(mouse_name, base_date, base_session, reg_date, reg_session, manual_reg_enable, varargin)
% RegistrationInfoX = image_registerX(mouse_name, base_date, base_session, reg_date, reg_session, manual_reg_enable)
% Image Registration Function - THIS FUNCTION ONLY REGISTERS ONE IMAGE TO ANOTHER
% AND DOES NOT DEAL WITH ANY INDIVIDUAL CELLS.
% this fuction allows you to register a given
% recording session (the registered session) to a previous sesison ( the
% base session) to track neuronal activity from session to session.  It
% also outputs a combined set of ICs so that you can register a given
% session to multiple previous sessions.  
%
% INPUT VARIABLES (if none are entered, you will be prompted to enter in
% the files to register manually)
% mouse_name:   string with mouse name
%
% base_date: date of base session
%
% base_session: session number for base session
%
% reg_date: date of session to register to base.  List as 'mask' if you are
% using in conjuction with mas1k_multi_image_reg.
%
% reg_session: session number for session to register to base. List as 'mask' if you are
% using in conjuction with mask_multi_image_reg.
%
% manual_reg_enable: 0 if you want to disallow manually adjusting the
%               registration, 1 if you want to allow it (default)
%
% 'mask_reg': this optional argument MUST be followed by the pathname to
% the mask file for running Tenaspis
%
% OUTPUTS
% cell_map:     cell array with each row corresponding to a given neuron,
%               and each column corresponding to a recording session.  The value
%               corresponds to the GoodICf number from that session for that neuron.
%
% cell_map_header: contains info for each column in cell_map
%
% GoocICf_comb: combines ICs from the base file and the registered file.
%               Use this file as the base file for future registrations of
%               a file to multiple previous sessions.
%
% RegistrationInfoX : saves the location of the base file, the registered
%                file, the transform applied, and statistics about the
%                transform

% To do:

% - Try this out for images that are significantly different, e.g. rotated
% 180 degrees...
% - Automatically fill in expected neuron for base mapping

close all;

%% User inputs - if set the same the function should run without any user input during the mapping portion


%% MAGIC VARIABLES
configname = 'multimodal'; % For images taken with similar contrasts, e.g. from the same device, same gain, etc.
regtype = 'rigid'; % rigid = Translation, Rotation % Similarity = Translation, Rotation, Scale

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

%% Step 0: Get varargins

for j = 1:length(varargin)
    if strcmpi('mask_reg',varargin{j})
        mask_reg_file = varargin{j+1};
    end
end

%% Step 1: Select images to compare and import the images

if nargin == 0 % Prompt user to manually enter in files to register if no inputs are specified
    [base_filename, base_path, ~] = uigetfile('*.tif',...
        'Pick the base image file: ');
    base_file = [base_path base_filename];

    [reg_filename, reg_path, ~] = uigetfile('*.tif',...
        'Pick the image file to register with the base file: ',[base_path base_filename]);
    register_file = [reg_path reg_filename];
    [ mouse_name, reg_date, reg_session ] = get_name_date_session(reg_path);
else
    % Create strings to point to minimum projection files in each working
    % directory for registration
    currdir = cd;
    base_path = ChangeDirectory(mouse_name, base_date, base_session);
    base_file = fullfile(base_path,'ICmovie_min_proj.tif');
    if ~exist('mask_reg_file','var')
        reg_path = ChangeDirectory(mouse_name, reg_date, reg_session);
        register_file = fullfile(reg_path,'ICmovie_min_proj.tif');
    elseif exist('mask_reg_file','var')
        register_file = mask_reg_file;
        reg_date = 'neuron_mask';
    end
    cd(currdir)
end

%% Define unique filename for file you are registering to that you will
% eventually save in the base path
unique_filename = fullfile(base_path,['RegistrationInfo-' mouse_name '-' reg_date '-session' ...
        num2str(reg_session) '.mat']);

%% Step 1a: Skip out on everything if registration is already done!
try
    load(unique_filename);
    disp('REGISTRATION ALREADY RAN!! Skipping this step');
catch

%% Step 2a: Get Images and pre-process - Note that this step is vital as it helps
% correct for differences in overall illumination or contrast between
% sessions.

% Magic numbers
disk_size = 15;
pixel_thresh = 100;

base_image_gray = uint16(imread(base_file));
base_image_untouch = base_image_gray;
reg_image_gray = uint16(imread(register_file));
reg_image_untouch = reg_image_gray;

bg_base = imopen(base_image_gray,strel('disk',disk_size));
base_image_gray = base_image_gray - bg_base;
base_image_gray = imadjust(base_image_gray);
level = graythresh(base_image_gray);
base_image_bw = im2bw(base_image_gray,level);
base_image_bw = bwareaopen(base_image_bw,pixel_thresh,8);
base_image = double(base_image_bw);

bg_reg = imopen(reg_image_gray,strel('disk',disk_size));
reg_image_gray = reg_image_gray - bg_reg;
reg_image_gray = imadjust(reg_image_gray);
level = graythresh(reg_image_gray);
reg_image_bw = im2bw(reg_image_gray,level);
reg_image_bw = bwareaopen(reg_image_bw,pixel_thresh,8);
reg_image = double(reg_image_bw);


%% Step 2b: Run Registration Functions, get transform

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

% Run registration
disp('Running Registration...');
tform = imregtform(reg_image, base_image, regtype, optimizer, metric);

% Create no registration variable
tform_noreg = tform;
tform_noreg.T = eye(3);

% Apply registration to 2nd session
base_ref = imref2d(size(base_image_gray));
moving_reg = imwarp(reg_image,tform,'OutputView',imref2d(size(base_image)),...
    'InterpolationMethod','nearest');
moving_reg_gray = imwarp(reg_image_gray,tform,'OutputView',...
   base_ref,'InterpolationMethod','nearest');

% Apply NO registrtion to 2nd session for comparison
moving_noreg = imwarp(reg_image,tform_noreg,'OutputView',imref2d(size(base_image)),...
    'InterpolationMethod','nearest');
moving_gray_noreg = imwarp(reg_image_gray,tform_noreg,'OutputView',...
    base_ref,'InterpolationMethod','nearest');

% Plot it out for comparison
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

figure
subplot(1,2,1)
imagesc_gray(base_image_gray - moving_gray_noreg);
title('Base Image - Unregistered 2nd image');
subplot(1,2,2)
imagesc_gray(base_image_gray - moving_reg_gray);
title('Base Image - Registered Image');


% FigNum = FigNum + 1;

%% Step 3: Take Good ICs from registered image and overlay them onto base image


%% Step 3A: Give option to adjust manually if this doesn't work...
disp('Registration Stats:')
disp(['X translation = ' num2str(tform.T(3,1)) ' pixels.'])
disp(['Y translation = ' num2str(tform.T(3,2)) ' pixels.'])
disp(['Rotation = ' num2str(mean([asind(tform.T(2,1)) acosd(tform.T(1,1))])) ' degrees.'])

if ~exist('manual_reg_enable','var') || manual_reg_enable == 1
    manual_flag = input('Do you wish to manually adjust this registration? (y/n): ','s');
elseif manual_reg_enable == 0
    manual_flag = 'n';
end
% if strcmpi(manual_flag,'n')
%     use_manual_adjust = 0;
% end
while strcmpi(manual_flag,'y')
    manual_type = input('Do you wish to adjust by landmarks or none? (l/n): ','s');
    while ~(strcmpi(manual_type,'l') || strcmpi(manual_type,'n'))
        manual_type = input('Do you wish to adjust by landmarks or my cell masks or none? (l/n): ','s');
    end
    T_manual = [];
    while isempty(T_manual)
        if strcmpi(manual_type,'l')
            reg_type = 'landmark';
            figure(20)
            hbase = subplot(1,2,1); 
            imagesc_gray(base_image_untouch);
            hreg = subplot(1,2,2); 
            imagesc_gray(reg_image_untouch);
            
            T_manual = manual_reg(hbase, hreg, reg_type);
        elseif strcmpi(manual_type,'n')
            T_manual = eye(3);
        end
    end
    
    tform_manual = tform;
    tform_manual.T = T_manual;
    moving_reg_manual = imwarp(reg_image,tform_manual,'OutputView',imref2d(size(base_image)),'InterpolationMethod','nearest');
   
    FigNum = FigNum + 1;
    figure(FigNum)
    imagesc(abs(moving_reg_manual - base_image)); colormap(gray); colorbar
    title('Registered Image - Base Image after manual adjust')
    
    
    manual_flag = input('Do you wish to manually adjust again? (y/n)', 's');
%     use_manual_adjust = 1;
    
end

% Get index to pixels that are zeroed out as a result of registration
moving_reg_untouch = imwarp(reg_image_untouch,tform,'OutputView',...
    imref2d(size(base_image_untouch)),'InterpolationMethod','nearest');
exclude_pixels = moving_reg_untouch(:) == 0;

regstats.base_2nd_diff_noreg = sum(abs(base_image_gray(:) - moving_gray_noreg(:)));
regstats.base_2nd_diff_reg = sum(abs(base_image_gray(:) - moving_reg_gray(:)));
regstats.base_2nd_bw_diff_noreg = sum(abs(base_image(:) - moving_noreg(:)));
regstats.base_2nd_bw_diff_reg = sum(abs(base_image(:) - moving_reg(:)));


% Determine if there are previously run versions of this registration
% I think that this is no longer necessary since each registration is saved
% with a unique filename, but keeping it for now
if exist(unique_filename,'file') == 2
    load(unique_filename);
        size_info = size(RegistrationInfoX,2)+1;
else
    size_info = 1;
end
FigNum = FigNum + 1;

% Save info into RegistrationInfo data structure.
RegistrationInfoX(size_info).mouse = mouse_name;
RegistrationInfoX(size_info).base_date = base_date;
RegistrationInfoX(size_info).base_session = base_session;
RegistrationInfoX(size_info).base_file = base_file;
RegistrationInfoX(size_info).register_date = reg_date;
RegistrationInfoX(size_info).register_session = reg_session;
RegistrationInfoX(size_info).register_file = register_file;
RegistrationInfoX(size_info).tform = tform;
RegistrationInfoX(size_info).exclude_pixels = exclude_pixels;
RegistrationInfoX(size_info).regstats = regstats;
RegistrationInfoX(size_info).base_ref = base_ref;

if exist('T_manual','var')
    RegistrationInfoX(size_info).tform_manual = tform_manual;
    regstats.base_2nd_bw_diff_reg_manual = sum(abs(base_image(:) - moving_reg_manual(:)));
end
 
save (unique_filename,'RegistrationInfoX');

% keyboard;
end % End try/catch statement

end
