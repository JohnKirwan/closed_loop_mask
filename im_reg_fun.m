function [recorded] = im_reg_fun(original,figure_handle,channel,usbcam)

if nargin < 6
    type='manual';
end
    
%% Make the figure fill the screen and get image

pause(0.00001);
fullscreen_fun(original,figure_handle);
pause(1)

usbcam.Exposure  = -8.5 ; % Specify exposure, in log base 2 seconds (1/2^n seconds) - more negative values are shorter
im_reps = 100; % loads of images for this step
sumImage = double(snapshot(usbcam)); % Inialize to first image.
for i=2:im_reps % Read in remaining images.
  rgbImage = snapshot(usbcam);
  sumImage = sumImage + double(rgbImage);
  %pause(0.01)
end
meanImage = uint8(sumImage / im_reps); % average some images
close();
%recorded  = meanImage(:,:,channel); % Blue channel ONLY is 3
recorded  = rgb2gray(meanImage);

end