function [usb_img] = girdle_blackout(threshold,invtform,girdle_proportion,usbcam,cam_crop,outputView,figure_h,im_reps)
% Ablates the light over the chiton and not elsewhere

valve_proportion = 1 - girdle_proportion ; % within this script, the valve prop is 1 - girdle

sumImage = double(snapshot(usbcam)); % Inialize to first image.
for i=2:im_reps % Read in remaining images.
  rgbImage = snapshot(usbcam);
  sumImage = sumImage + double(rgbImage);
  %pause(0.007); % pause to stop interference - doesn't seem to matter
end
usb_img = uint8(sumImage / im_reps);
usb_img = imcrop(usb_img,cam_crop) ;
% imshow(usb_img)  % show the averaged image

%% Extract color channels
%redChannel = usb_img(:,:,1); % Red channel
%greenChannel = usb_img(:,:,2); % Green channel
%blueChannel = usb_img(:,:,3); % Blue channel
grayChannel = rgb2gray(usb_img);

%% Make thresholded matrix from one channel
threshed = grayChannel ; % seems to work the best
threshed(threshed < threshold) = 0;
threshed(threshed >= threshold) = 1;
threshed = logical(threshed);

%% Now, pick out the blobs
% Extract objects from binary image by size - makes another image
blob_mat = bwareafilt(threshed,1,'largest'); % keeps the n largest objects from the inverted thresholded img.
inv_blob = ~blob_mat; % get inverse
inv_blob_2 = bwareafilt(inv_blob,1,'largest'); % keeps the n largest objects from the inverted thresholded img
blob_mat2 = ~inv_blob_2 ;

%% Object stat and erode stuff
stats = regionprops('table',inv_blob_2,'Area','Centroid',...
    'MajorAxisLength','MinorAxisLength','Orientation','Circularity');

%% Reduce blob size
template_blob = resizeEllipse(inv_blob_2,1);
inv_valve_stimulus = resizeEllipse(inv_blob_2,valve_proportion);
%imshowpair(inv_blob_2,inv_valve_stimulus)

%% Now check the stats of the newly eroded version
stats2 = regionprops('table',inv_valve_stimulus,'Area','Centroid',...
    'MajorAxisLength','MinorAxisLength','Orientation','Circularity');

if(exist('stats2','var')==0)
    warning('No blob found')
end

diff_stats = stats{1,:} - stats2{1,:}; % see diffs
disp(diff_stats(1)*100 / stats{1,1}) % percentage diff area between old and new blob
valve_stimulus = ~ inv_valve_stimulus; % invert the new blob

%% Cover the girdle
% COULD MAKE A WHILE LOOP WHICH EXPANDS BW2 UNTIL IT DEFINITELY DOESN'T
% OVERLAP THE VALVE BEFORE SUBTRACTING THAT AREA FROM THE GIRDLE STIMULUS
inv_girdle_stimulus = template_blob - inv_valve_stimulus ; % take the silhouette of the animal and increase the values
girdle_stimulus = ~ inv_girdle_stimulus; % the girdle covering stimulus

%%
transformed_blob = imwarp(girdle_stimulus, invtform,'FillValues',255, 'OutputView',outputView); 
fullscreen_fun(transformed_blob,figure_h);

end

