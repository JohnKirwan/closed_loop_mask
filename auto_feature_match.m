function [invtform] = auto_feature_match(original,distorted)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

ptsOriginal  = detectSURFFeatures(original);
ptsDistorted = detectSURFFeatures(distorted);

% Extract feature descriptors.
[featuresOriginal,  validPtsOriginal]  = extractFeatures(original,  ptsOriginal);
[featuresDistorted, validPtsDistorted] = extractFeatures(distorted, ptsDistorted);

% Match features by using their descriptors.
indexPairs = matchFeatures(featuresOriginal, featuresDistorted);

% Retrieve locations of corresponding points for each image.
matchedOriginal  = validPtsOriginal(indexPairs(:,1));
matchedDistorted = validPtsDistorted(indexPairs(:,2));

% Show putative point matches.
figure(103);
showMatchedFeatures(original,distorted,matchedOriginal,matchedDistorted);
title('Putatively matched points (including outliers)');

%% Estimate Transformation

% Find a transformation corresponding to the matching point pairs using the statistically robust M-estimator SAmple Consensus (MSAC) algorithm, which is a variant of the RANSAC algorithm. It removes outliers while computing the transformation matrix. You may see varying results of the transformation computation because of the random sampling employed by the MSAC algorithm.
[tform, inlierDistorted, inlierOriginal] = estimateGeometricTransform(...
    matchedDistorted, matchedOriginal, 'similarity');

% Display matching point pairs used in the computation of the transformation.
figure(101);
showMatchedFeatures(original,distorted,inlierOriginal,inlierDistorted);
title('Matching points (inliers only)');
legend('ptsOriginal','ptsDistorted');

%% Solve for Scale and Angle

% Use the geometric transform, tform, to recover the scale and angle. 
% Since we computed the transformation from the distorted to the original
% image, we need to compute its inverse to recover the distortion.

%Compute the inverse transformation matrix.
Tinv  = tform.invert.T;
%ss = Tinv(2,1);
%sc = Tinv(1,1);
%scaleRecovered = sqrt(ss*ss + sc*sc); 
%thetaRecovered = atan2(ss,sc)*180/pi; 

invtform = invert(tform);

%% Recover the Original Image

% Recover the original image by transforming the distorted image.
%outputView = imref2d(size(original));
%recovered  = imwarp(distorted,tform,'OutputView',outputView);

% Compare recovered to original by looking at them side-by-side in a montage.
%figure, imshowpair(original,recovered,'montage')

end

