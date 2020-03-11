function [] = fullscreen_fun(image,figure_handle)
%   Make a fullscreen image
figure_handle.WindowState = 'fullscreen';
set(gcf,'MenuBar','none')
set(gca,'DataAspectRatioMode','auto')
set(gca,'Position',[0 0 1 1])
imshow(image);
end

