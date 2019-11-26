%% Collect image from webcam
clear('usbcam'); % clears existing usbcam connections
webcam_name = 'c922 Pro Stream Webcam' ; % or: 'USB2.0 Camera'
usbcam = webcam(find(ismember(webcamlist,webcam_name))); % pick the USB camera
if exist('usbcam') == 0
    error('No USB camera is found') % throw error if camera is absent
end
usbcam.AvailableResolutions % check possible resolutions
usbcam.Resolution =  '1280x720'; %'800x600'; % % set highest res
usbcam.ExposureMode = 'manual'; % fix the exposure
usbcam.Exposure  = -8 ; % Specify exposure, in log base 2 seconds (1/2^n seconds)
                         % more negative values are shorter
usbcam.Sharpness = 4  ;  % not sure what this does exactly
usbcam.Contrast  = 63 ;

white_bg = ones(1080,1920);
f = figure();
movegui(f,[2500,0]); % push figure into the right display
fullscreen_fun(white_bg,f);
pause(1);

% average some images
im_reps = 100;
sumImage = double(snapshot(usbcam)); % Inialize to first image.
for i=2:im_reps % Read in remaining images.
  rgbImage = snapshot(usbcam);
  sumImage = sumImage + double(rgbImage);
  %pause(0.007); % pause to stop interference - doesn't seem to matter
end
usb_img = uint8(sumImage / im_reps);

clear('usbcam');
close(f);
figure();
imshowpair(rgbImage,usb_img,'montage')  %or image(img) % get image, which is already a structure

%% Extract color channels

% this turns the structure into 3 matrices of 256 colour values
redChannel = usb_img(:,:,1); % Red channel
greenChannel = usb_img(:,:,2); % Green channel
blueChannel = usb_img(:,:,3); % Blue channel
meanChannel = rgb2gray(usb_img) ; % greyscale average

% Plot them (high values are bright)
figure(15);
histogram(blueChannel , 'FaceColor','b', 'EdgeAlpha',0, 'FaceAlpha',0.33);
hold on; 
histogram(redChannel  , 'FaceColor','r', 'EdgeAlpha',0, 'FaceAlpha',0.33);
%hold on 
histogram(greenChannel, 'FaceColor','g', 'EdgeAlpha',0, 'FaceAlpha',0.33);
histogram(meanChannel, 'FaceColor',[0.25,0.25,0.25], 'EdgeAlpha',0, 'FaceAlpha',0.33);
hold off;

%% Make thresholded matrix from one channel
usedChannel = blueChannel; % which channel is used from here on in
TXT = strcat('Lowest value is_', string(min(usedChannel,[],'all'))); % find the lowest vlaue of this channel
disp(TXT)

% turns everything below threshold to black and everything else to white
threshold = 170 ;% 256 *0.75;
threshed = usedChannel ; % seems to work the best
threshed(threshed < threshold) = 0;
threshed(threshed >= threshold) = 1;
threshed = logical(threshed);
imshow(threshed)

%% Now, pick out the blobs

% Extract objects from binary image by size - makes another image
blob_mat = bwareafilt(threshed,1,'largest'); % keeps the n largest objects from the inverted thresholded img.
inv_blob = ~blob_mat; % get inverse
% figure(35);
% imshowpair(blob_mat,rev_blob_mat,'montage')

inv_blob_2 = bwareafilt(inv_blob,1,'largest'); % keeps the n largest objects from the inverted thresholded img
blob_mat2 = ~inv_blob_2 ;
figure(45);
imshowpair(usedChannel,blob_mat2,'montage')

% can also use bwareaopen to remove small points

%% Object stat and erode stuff

%se = strel('line',11,90);
%eroded = imerode(inv_blob_2,se);
%imshowpair(inv_blob_2,eroded,'montage')

stats = regionprops('table',inv_blob_2,'Area','Centroid',...
    'MajorAxisLength','MinorAxisLength','Orientation','Circularity');
% stats{1,1}(1) start of centroid
% J = regionfill(I,mask)
%figure(65);
%p = calculateEllipse(stats{1,2}(1),stats{1,2}(1),stats{1,3},stats{1,4},-stats{1,5});
%plot(p(:,1), p(:,2), '.-'), axis equal

%% Reduce blob size
% erode image until area reduced two thirds
eroded_area = stats{1,1};
valve_proportion = 0.7 ;
valve_area = eroded_area * valve_proportion;
SE = strel('disk',2); % structure used to erode the blob
inv_valve_stimulus = inv_blob_2;

while eroded_area > valve_area
    inv_valve_stimulus = imerode(inv_valve_stimulus,SE);  % or BW2 = imdilate(BW, SE);
    temp = regionprops('table',inv_valve_stimulus,'Area');
    eroded_area = temp{1,1};
end

figure(55);
imshowpair(inv_blob_2,inv_valve_stimulus,'montage')

%% Now check the stats of the newly eroded version

stats2 = regionprops('table',inv_valve_stimulus,'Area','Centroid',...
    'MajorAxisLength','MinorAxisLength','Orientation','Circularity');

diff_stats = stats{1,:} - stats2{1,:}; % see diffs
disp(diff_stats(1)*100 / stats{1,1}) % percentage diff area between old and new blob
valve_stimulus = ~ inv_valve_stimulus; % invert the new blob

%% Cover the girdle
% COULD MAKE A WHILE LOOP WHICH EXPANDS BW2 UNTIL IT DEFINITELY DOESN'T
% OVERLAP THE VALVE BEFORE SUBTRACTING THAT AREA FROM THE GIRDLE STIMULUS
inv_girdle_stimulus = inv_blob_2 - inv_valve_stimulus ; % take the silhouette of the animal and increase the values
girdle_stimulus = ~ inv_girdle_stimulus; % the girdle covering stimulus

figure(65);
imshowpair(valve_stimulus,girdle_stimulus,'montage')  % Display the valve image and the girdle one side-by-side.


