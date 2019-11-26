function [cropped_image] = image_middle(image)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here
eigth_W = floor(size(image,1)/8);
eight_H = floor(size(image,2)/8);
if ndims(image) == 3
    cropped_image = image(3*eigth_W:5*eigth_W,3*eight_H:5*eight_H,1:3);
else
    cropped_image = image(3*eigth_W:5*eigth_W,3*eight_H:5*eight_H);
end

end

