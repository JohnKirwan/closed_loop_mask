function [threshold_matrix] = rev_thresh_mat_maker(threshold,image_matrix)
%UNTITLED4 Sets a threshold and looks for values below
%   Detailed explanation goes here
threshold_matrix = true(size(image_matrix,1),size(image_matrix,2)) ;
for n = 1:size(image_matrix,1)
    for z = 1:size(image_matrix,2)
    
    if image_matrix(n,z) >= threshold
        threshold_matrix(n,z) = false ;
    end
    end

%threshold_mat = uint8(threshold_mat);
end

