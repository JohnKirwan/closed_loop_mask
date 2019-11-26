%% Random numbers

randz = repmat([1:5],5); % random array of 20 numbers between 1 and 4
randz=randz(randperm(length(randz)));

%% Project the bg image

disp('Press any key to image') 
pause;

figure('units','normalized','outerposition',[0 0 1 1]) % to make a figure fullscreen
white_bg = ones(720,1280);
black_bg = zeros(720,1280);
imshow(white_bg)
% mons = get(0,'MonitorPositions') ; % find monitors and positions
pause;

%% Display the various stimuli
load handel.mat
messiah = y;
load gong.mat
gong = y;

for i = randz
    if randz(i) == 1   % if positive control
        beep;
        pause;
    elseif randz(i) == 2
        sound(gong);
        imshow(black_bg)
        pause;
    elseif randz(i) == 3
        sound(gong,Fs*2.5);
        % RUN THE VALVE BLACKOUT SCRIPT
        pause;
    elseif randz(i) == 4
        sound(messiah(1:18000))
        % RUN THE GIRDLE BLACKOUT SCRIPT
        pause;
    else
        beep; beep; beep;
        % RUN THE ANIMAL BLACKOUT SCRIPT
        pause;
    end
end

disp('End of 25 trials')
