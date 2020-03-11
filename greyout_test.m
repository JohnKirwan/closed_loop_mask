function [usb_img] = greyout(threshold,invtform,girdle_proportion,valve_proportion,usbcam,cam_crop,outputView,figure_h,im_reps,part)
% Ablates the light over the chiton and not elsewhere
fudge_factor = 1.32;
part = "girdle" ;% testing
valve_proportion = 0.7;

threshed = imread('test.bmp');

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
  larger_area = dilated_area * fudge_factor ;
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

%%
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

imshowpair(blob_mat,output_stimulus,'montage')

%% Make an ellipse with these proporties & make fig of one over the other
s = regionprops(threshed,'Area','Centroid',...
      'MajorAxisLength','MinorAxisLength','Orientation','Circularity');

%%
A_ratio = zeros(1,length(s));
imshow(threshed)
hold on
phi = linspace(0,2*pi,100); % a seq to calculate coords 
cosphi = cos(phi);
sinphi = sin(phi);

for k = 1%:length(s)  
    xbar = s(k).Centroid(1);
    ybar = s(k).Centroid(2);
    a = s(k).MajorAxisLength/2;
    b = s(k).MinorAxisLength/2;
    theta = pi* s(k).Orientation /180;
    R = [ cos(theta)   sin(theta)
         -sin(theta)   cos(theta)];
    xy = [a*cosphi; b*sinphi];
    xy = R*xy;
    x = xy(1,:) + xbar;
    y = xy(2,:) + ybar;
    %fill(x,y,'r','LineWidth',0.5); %plot or fill circle over the blob
    A_ratio(k) = s(k).Area / (a * b * pi) ;
end
hold off

figure(11);
BW = poly2mask(x,y,size(threshed,1),size(threshed,2));
imshow(BW)

A_ratio(1); % ratio of blob to symmetrical elliptical template

%%
transformed_blob = imwarp(output_stimulus, invtform,'FillValues',255, 'OutputView',outputView);
new_blob = transformed_blob + 0.0001 ; % new line to remakes blob
new_blob(new_blob > 1) = 1; % remove negative values
fullscreen_fun(new_blob,figure_h);

end
