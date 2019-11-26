function [usb_img] = blackout(threshold,invtform,girdle_proportion,valve_proportion,usbcam,cam_crop,outputView,figure_h,im_reps,part)
% Ablates the light over the chiton and not elsewhere
fudge_factor = 1.1; % ratio of whole and girdle black spot to body size detected

if part == "girdle"
    valve_proportion = 1 - girdle_proportion*fudge_factor ; % within this script, the valve prop is 1 - girdle
end

sumImage = double(snapshot(usbcam)); % Inialize to first image.
for i=2:im_reps % Read in remaining images.
  rgbImage = snapshot(usbcam);
  sumImage = sumImage + double(rgbImage);
end
usb_img = uint8(sumImage / im_reps);
usb_img = imcrop(usb_img,cam_crop) ;

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

%% Make blob a bit bigger for the whole chiton and the girdle
if sum(part == ["whole","girdle"]) > 0  % if it is the girdle or valve   %"girdle",
  stats = regionprops('table',inv_blob_2,'Area','Centroid',...
      'MajorAxisLength','MinorAxisLength','Orientation','Circularity');
  % Increase blob size - dilate image until area increased 10%
  dilated_area = stats{1,1};
  larger_area = dilated_area * fudge_factor;
  SE = strel('disk',2); % structure used to dilate the blob
  inv_blob_2_larger = inv_blob_2;

  while dilated_area < larger_area
      inv_blob_2_larger = imdilate(inv_blob_2_larger,SE);  % or BW2 = imdilate(BW, SE);
      temp = regionprops('table',inv_blob_2_larger,'Area');
      dilated_area = temp{1,1};
  end
  % Now check the stats of the newly eroded version
  stats2 = regionprops('table',inv_blob_2_larger,'Area','Centroid',...
      'MajorAxisLength','MinorAxisLength','Orientation','Circularity');
  diff_stats = stats{1,:} - stats2{1,:}; % see diffs
  disp(diff_stats(1)*100 / stats{1,1}) % percentage diff area between old and new blob
  inv_blob_2 = inv_blob_2_larger; % invert the new blob
end

blob_mat2 = ~inv_blob_2 ;

%% Object stat and erode stuff
if sum(part == ["girdle","valve"]) > 0  % if it is the girdle or valve
  stats = regionprops('table',inv_blob_2,'Area','Centroid',...
      'MajorAxisLength','MinorAxisLength','Orientation','Circularity');

  % Reduce blob size
  % erode image until area reduced two thirds
  eroded_area = stats{1,1};
  valve_area = eroded_area * valve_proportion;
  SE = strel('disk',2); % structure used to erode the blob
  inv_valve_stimulus = inv_blob_2;

  while eroded_area > valve_area
      inv_valve_stimulus = imerode(inv_valve_stimulus,SE);  % or BW2 = imdilate(BW, SE);
      temp = regionprops('table',inv_valve_stimulus,'Area');
      eroded_area = temp{1,1};
  end

% Now check the stats of the newly eroded version
  stats2 = regionprops('table',inv_valve_stimulus,'Area','Centroid',...
      'MajorAxisLength','MinorAxisLength','Orientation','Circularity');

  diff_stats = stats{1,:} - stats2{1,:}; % see diffs
  disp(diff_stats(1)*100 / stats{1,1}) % percentage diff area between old and new blob
  valve_stimulus = ~ inv_valve_stimulus; % invert the new blob
end

%% Cover the girdle
% COULD MAKE A WHILE LOOP WHICH EXPANDS BW2 UNTIL IT DEFINITELY DOESN'T
% OVERLAP THE VALVE BEFORE SUBTRACTING THAT AREA FROM THE GIRDLE STIMULUS
if strcmp(part,"girdle") == 1
    inv_girdle_stimulus = inv_blob_2 - inv_valve_stimulus ; % take the silhouette of the animal and increase the values
    output_stimulus = ~ inv_girdle_stimulus; % the girdle covering stimulus
elseif strcmp(part,"valve") == 1
    output_stimulus = valve_stimulus;
else
    output_stimulus = blob_mat2;
end

%%
transformed_blob = imwarp(output_stimulus, invtform,'FillValues',255, 'OutputView',outputView); 
fullscreen_fun(transformed_blob,figure_h);

end
