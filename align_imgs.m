%% Housekeeping
clear all
%% Get image of arena and surroundings

Pix_SS = get(0,'screensize'); % 
original = imread('letters.png');

%original = ones(Pix_SS(4),Pix_SS(3)) ; %(1080,1920);
% original = insertText(original, [400 200], 'A','BoxColor','white','FontSize',64);
% original = insertText(original, [1000 200], 'B','BoxColor','white','FontSize',64);
% original = insertText(original, [700 350], 'C','BoxColor','white','FontSize',64);
% original = insertText(original, [400 500], 'D','BoxColor','white','FontSize',64);
% original = insertText(original, [1000 500], 'E','BoxColor','white','FontSize',64);

original = rgb2gray(original);
[m, n] = size(original);
p = Pix_SS(4); % 600;
q = Pix_SS(3); % 800;
projected = padarray(original, [floor((p-m)/2) floor((q-n)/2)], 'post');
projected = padarray(projected, [ceil((p-m)/2) ceil((q-n)/2)],'pre');

%% Make the figure fill the screen and get image

pause(0.00001);
f = figure(12);
f.WindowState = 'fullscreen';
set(gcf,'MenuBar','none')
set(gca,'DataAspectRatioMode','auto')
set(gca,'Position',[0 0 1 1])
imshow(projected);

clear('usbcam'); % clears existing usbcam connections
usbcam = webcam(find(ismember(webcamlist,'USB2.0 Camera'))); % pick the USB camera
usbcam.AvailableResolutions % check possible resolutions
usbcam.Resolution = '800x600' ;% '1280x720'; % set highest res
usbcam.ExposureMode = 'manual'; % fix the exposure
usbcam.Exposure  = -10 ; % Specify exposure, in log base 2 seconds (1/2^n seconds) - more negative values are shorter
usbcam.Sharpness = 4 ; % not sure what this does exactly
usbcam.Contrast = 63 ;
%preview(usbcam);
%disp('Press any key to image')
%beep;
%pause;

% average some images
im_reps = 200; % loads of images for this step
sumImage = double(snapshot(usbcam)); % Inialize to first image.
for i=2:im_reps % Read in remaining images.
  rgbImage = snapshot(usbcam);
  sumImage = sumImage + double(rgbImage);
  %pause(0.01)
end
clear('usbcam');
meanImage = uint8(sumImage / im_reps);

close(12);
imshowpair(rgbImage,meanImage,'montage')

%% 'Manually' register the image to transform the arena shape with GUI

distorted  = meanImage(:,:,3); % Blue channel ONLY 
cpselect(original,distorted) % try doing it manually

%% Get the fit

ptsOriginal  = fixedPoints ;
ptsDistorted = movingPoints ;
% Use this transformation when the scene appears tilted. 
% Straight lines remain straight, but parallel lines converge 
% toward a vanishing point.
tform = fitgeotrans(movingPoints,fixedPoints, 'lwm', size(movingPoints,1)); % needs 6-12 pts % 'projective');

%% Detect points using automated feature matching
% ptsOriginal  = detectSURFFeatures(original);
% ptsDistorted = detectSURFFeatures(distorted);

% Extract feature descriptors.
%[featuresOriginal,  validPtsOriginal]  = extractFeatures(original,  ptsOriginal);
%[featuresDistorted, validPtsDistorted] = extractFeatures(distorted, ptsDistorted);

% Match features by using their descriptors.
%indexPairs = matchFeatures(featuresOriginal, featuresDistorted);

% Retrieve locations of corresponding points for each image.
% matchedOriginal  = validPtsOriginal(indexPairs(:,1));
% matchedDistorted = validPtsDistorted(indexPairs(:,2));
% 
% % Show putative point matches.
% figure(13);
% showMatchedFeatures(original,distorted,matchedOriginal,matchedDistorted);
% title('Putatively matched points (including outliers)');

% Estimate Transformation
% Find a transformation corresponding to the matching point pairs using the statistically robust M-estimator SAmple Consensus (MSAC) algorithm, which is a variant of the RANSAC algorithm. It removes outliers while computing the transformation matrix. You may see varying results of the transformation computation because of the random sampling employed by the MSAC algorithm.
% [tform, inlierDistorted, inlierOriginal] = estimateGeometricTransform(...
%     matchedDistorted, matchedOriginal, 'similarity');
% 
% % Display matching point pairs used in the computation of the transformation.
% figure(14);
% showMatchedFeatures(original,distorted,inlierOriginal,inlierDistorted);
% title('Matching points (inliers only)');
% legend('ptsOriginal','ptsDistorted');

%% Solve for Scale and Angle

% Use the geometric transform, tform, to recover the scale and angle. 
% Since we computed the transformation from the distorted to the original
% image, we need to compute its inverse to recover the distortion.

% Compute the inverse transformation matrix.
% Tinv  = tform.invert.T;
% ss = Tinv(2,1);
% sc = Tinv(1,1);
% scaleRecovered = sqrt(ss*ss + sc*sc); 
% thetaRecovered = atan2(ss,sc)*180/pi; 

%% Recover the Original Image

% Recover the original image by transforming the distorted image.
outputView = imref2d(size(original));
recovered  = imwarp(distorted,tform,'OutputView',outputView);

% Compare recovered to original by looking at them side-by-side in a montage.
figure(15), imshowpair(original,recovered,'montage')

%% Reproject the recovered image

mona_1 = imread('mona_1.png');
mona_1  = imwarp(mona_1,tform,'OutputView',outputView);

pause(0.00001);
f = figure(16);
f.WindowState = 'fullscreen';
set(gcf,'MenuBar','none')
set(gca,'DataAspectRatioMode','auto')
set(gca,'Position',[0 0 1 1])
imshow(mona_1);
