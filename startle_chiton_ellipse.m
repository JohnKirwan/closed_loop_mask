%% Do manual registration
% This part opens a window to compare the projected and recorded images
% which you manual mark in pairs. Then it makes a tform object, which
% relates the pixels in these images.
close all;
clear 'usbcam'; % clears existing usbcam connections

%% Prepare the webcam
webcam_name = 'USB2.0 Camera' ; % or: 'USB2.0 Camera'
usbcam = webcam(find(ismember(webcamlist,webcam_name))); % pick the USB camera
if exist('usbcam') == 0
    error('No USB camera is found') % throw error if camera is absent
end
usbcam.AvailableResolutions % check possible resolutions
usbcam.Resolution =  '800x600'; %'800x600'; %; % set highest res
usbcam.ExposureMode = 'manual'; % fix the exposure
usbcam.Exposure  = -12 ; % Specify exposure, in log base 2 seconds (1/2^n seconds)
                         % more negative values are shorter
usbcam.Sharpness = 4  ;  % not sure what this does exactly
usbcam.Contrast  = 63 ;

%% Produce image matrices
% 1920 * 1080 pixel res on projector
%figure('units','normalized','outerposition',[0 0 1 1]) % to make a figure fullscreen
projector_pixels = [1080,1920];  % was [1080,1920]
white_bg = ones(projector_pixels);
black_bg = zeros(projector_pixels);
red_bg   = zeros([projector_pixels,3]); %initialize
red_bg(:,:,1)=0.5;   %Red (dark red)

%% Get coords of the arena
f = figure();
movegui(f,[2500,0]); % push figure into the right display
fullscreen_fun(white_bg,f);
pause(0.9);
disp('Double click inside a box to crop')
figure;
[J,cam_crop] = imcrop(snapshot(usbcam));
cam_crop = round(cam_crop) ;
close all;

%%
original = imread('Letterz.png'); % 'Letters2.png'); 
original = rgb2gray(original);
original = imresize(original, [1080,1920]);
f = figure();
movegui(f,[2500,0]); % push figure into the right display
[recorded] = im_reg_fun(original,f,3,usbcam); % opens a GUI to register the new image. 
recorded = imcrop(recorded,cam_crop) ; % crops according to a rectangle specified

%% Get the fit
% Use this transformation when the scene appears tilted. 
% Straight lines remain straight, but parallel lines converge 
% toward a vanishing point.
%invtform = fitgeotrans(fixedPoints,movingPoints, 'affine'); % 'lwm', size(movingPoints,1)); % needs 6-12 pts % 'projective');
%invtform = fitgeotrans(fixedPoints, movingPoints,'affine'); % 'projective');
% 'Manually' register the image to transform the arena shape with GUI
[movingPoints,fixedPoints] = cpselect(original,recorded, 'Wait',true ); % try doing it manually
tform = fitgeotrans(movingPoints,fixedPoints,'affine');
invtform = invert(tform);
%tform = fitgeotrans(movingPoints,fixedPoints, 'lwm', size(movingPoints,1)); % needs 6-12 pts %

% registrationEstimator(original,recorded);

%% Recover the original image by transforming the recorded image
outputView = imref2d(size(original));
recovered  = imwarp(recorded,invtform,'OutputView',outputView, 'FillValues',255);
figure(105), imshowpair(original,recovered,'montage'); 

%% Set the color value threshold and other parameters
threshold = 170;
valve_proportion = 0.7;    % amount of animal area given by the valve
girdle_proportion = 0.10 ; % amount of animal area given by the girdle
im_reps = 50 ;             % number of images to average
num_repeats = 2; % number of repeats for each condition
randz = repmat(1:5,num_repeats); % random array of 20 numbers between 1 and 4
randz=randz(randperm(length(randz)));

%% Have a look at the webcam
f = figure(33);
movegui(f,[2500,0]); % push figure into the right display
fullscreen_fun(white_bg,f);
pause(6);

sumImage = double(snapshot(usbcam)); % Inialize to first image.
for i=2:im_reps % Read in remaining images.
  rgbImage = snapshot(usbcam);
  sumImage = sumImage + double(rgbImage);
end
close 33;
figure;
usb_img = uint8(sumImage / im_reps);
imshowpair(imcrop(rgb2gray(usb_img),cam_crop), imcrop(rgb2gray(usb_img),cam_crop) > threshold,'montage');
pause();

%% Test girdle accuracy

f = figure(69);
movegui(f,[2500,0]); % push figure into the right display
fullscreen_fun(white_bg,f);
pause(3);
girdle_proportion = 0.30;

usb_img = blackout_ellipse(threshold,invtform,girdle_proportion,valve_proportion,...
                usbcam,cam_crop,outputView,f,im_reps,"girdle"); % RUN THE GIRDLE BLACKOUT SCRIPT
        pause(8);
        sumImage = double(snapshot(usbcam)); %inialise the first image
        for j=2:im_reps %read in remaining images
            rgbImage = snapshot(usbcam);
            sumImage = sumImage + double(rgbImage);
        end
        cam_img = uint8(sumImage/im_reps);
        filename = strcat('girdle_trial', strrep(datestr(datetime('now')),':',''), '.png') ;
        imwrite(cam_img,filename);

f = figure();
movegui(f,[2500,0]); % push figure into the right display
fullscreen_fun(white_bg,f);
close 69;


%% Display the various stimuli

close all;
f = figure();
movegui(f,[2500,0]); % push figure into the right display
fullscreen_fun(white_bg,f);
disp('Press any key to start trials') 
pause();

info_mat = strings(length(randz),3); % collect trial details
i = 1; % initialize for while loop

while i <= length(randz)
%for i = randz
    if randz(i) == 1   % if positive control
        disp('White control');
        pause(3);
        info_mat(i,3) = 'White';
    elseif randz(i) == 2
        disp('Red control');
        fullscreen_fun(red_bg,f) % red 'control'
        pause(3);
        info_mat(i,3) = 'Red';
    elseif randz(i) == 3
        disp('Valve blacked out');
        %usb_img = valve_blackout(threshold,invtform,valve_proportion,...
        %    usbcam,cam_crop,outputView,f,im_reps); % RUN THE VALVE BLACKOUT SCRIPT
        usb_img = blackout_ellipse(threshold,invtform,girdle_proportion,valve_proportion,...
                usbcam,cam_crop,outputView,f,im_reps,"valve"); % RUN THE GIRDLE BLACKOUT SCRIPT
        pause(3);
        info_mat(i,3) = 'Valve';
    elseif randz(i) == 4
        disp('Girdle blacked out');
        %usb_img = girdle_blackout(threshold,invtform,girdle_proportion,...
        %        usbcam,cam_crop,outputView,f,im_reps); % RUN THE GIRDLE BLACKOUT SCRIPT
        usb_img = blackout_ellipse(threshold,invtform,girdle_proportion,valve_proportion,...
                usbcam,cam_crop,outputView,f,im_reps,"girdle"); % RUN THE GIRDLE BLACKOUT SCRIPT
        pause(3);
        info_mat(i,3) = 'Girdle';
    else
        disp('Whole chiton blacked out');
        %usb_img = chiton_blackout(threshold,invtform,...
        %        usbcam,cam_crop,outputView,f,im_reps); % RUN THE ANIMAL BLACKOUT SCRIPT
        usb_img = blackout_ellipse(threshold,invtform,girdle_proportion,valve_proportion,...
                usbcam,cam_crop,outputView,f,im_reps,"whole"); % RUN THE GIRDLE BLACKOUT SCRIPT
        pause(3);
        info_mat(i,3) = 'Whole';
    end
 
    imshow(usb_img);
    fullscreen_fun(white_bg,f);    % Back to the white background:

    info_mat(i,1) = i; % include the trial number
    info_mat(i,2) = datetime('now'); % include a datestamp for the trial
    
    beep;
    disp('Press for next trial')
    pause; % wait until key for next trial - no time specified
    i = i + 1; % iterate while loop
end

disp(strcat('End of_',num2str(length(randz)),' trials'));
writematrix(info_mat,strcat( strrep(datestr(datetime('now')),':','') ,'.xlsx'),...
    'FileType','spreadsheet');
close all;
