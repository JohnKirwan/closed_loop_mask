function [usb_img] = chiton_blackout(threshold,invtform,usbcam,cam_crop,outputView,figure_h,im_reps)
% Ablates the light over the chiton and not elsewhere

sumImage = double(snapshot(usbcam)); % Inialize to first image.
for i=2:im_reps % Read in remaining images.
  rgbImage = snapshot(usbcam);
  sumImage = sumImage + double(rgbImage);
  %pause(0.007); % pause to stop interference - doesn't seem to matter
end
usb_img = uint8(sumImage / im_reps);
usb_img = imcrop(usb_img,cam_crop) ;

%% Extract color channels
% this turns the structure into 3 matrices of 256 colour values
%redChannel = usb_img(:,:,1); % Red channel
%greenChannel = usb_img(:,:,2); % Green channel
blueChannel = usb_img(:,:,3); % Blue channel
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
transformed_blob = imwarp(blob_mat2, invtform,'FillValues',255,'OutputView',outputView );

fullscreen_fun(transformed_blob,figure_h);

end

