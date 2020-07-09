function [EllipseMask,outputArg2] = resizeEllipse(BWimage,ScaleFactor)
%UNTITLED Gets a bitmap mask by fitting a rescaled symmetrical ellipse
%   Detailed explanation goes here

%% Make an ellipse with these proporties
regionprops_obj = regionprops(BWimage,'Area','Centroid',...
      'MajorAxisLength','MinorAxisLength','Orientation','Circularity');

%imshow(BWimage)
% template_xy fits a symmetrical ellipse based on regionprops over the
% blob, with the radii scaled. 
[x, y] = template_xy_longer(regionprops_obj,ScaleFactor,1); % shortens the ellipse
EllipseMask = poly2mask(x,y,size(BWimage,1),size(BWimage,2));

end

