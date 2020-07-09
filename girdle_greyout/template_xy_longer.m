function [x_coords,y_coords] = template_xy_longer(regionprops_obj,ScaleFactor,nblob,elongate_ellipse)
%template_xy Gets xy coords for a symmetrical elliptical mask
%   Detailed explanation goes here
phi = linspace(0,2*pi,100); % a seq to calculate coords 
cosphi = cos(phi);
sinphi = sin(phi);

for k = 1:nblob  
    xbar = regionprops_obj(k).Centroid(1);
    ybar = regionprops_obj(k).Centroid(2);
    a = elongate_ellipse * ScaleFactor * regionprops_obj(k).MajorAxisLength/2; %make long side longer #############################################
    b = ScaleFactor * regionprops_obj(k).MinorAxisLength/2;
    theta = pi* regionprops_obj(k).Orientation /180;
    R = [ cos(theta)   sin(theta)
         -sin(theta)   cos(theta)];
    xy = [a*cosphi; b*sinphi];
    xy = R*xy;
    x = xy(1,:) + xbar;
    y = xy(2,:) + ybar;
end

x_coords = x;
y_coords = y;

end
