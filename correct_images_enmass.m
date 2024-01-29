
% Model correction
% After running the Python script, the next step is to reinsert 
% the output TIFF into ImageJ/Fiji and adjust its scale back 
% to the original resolution. For example, if the initial area 
% was 94 by 100, open the mask in ImageJ/Fiji, go to scale, 
% input 94 by 100, and save – this becomes your corrected 
% mask.

% In the MATLAB code, select the appropriately scaled TIFF file 
% (as adjusted in ImageJ/Fiji) and click open. A window will 
% appear with two figures and a slider. The top slider is the radius of teh
% fill and the bottom slider is the ratio between the volume of the mask
% and the radius (ie bigger mask bigger relative radius for that image
%% created by Alexander Gadin
[filename, path]= uigetfile('*.tif', 'Choose a TIFF file');
global fullFilePath;
fullFilePath= fullfile(path, filename);

info= imfinfo(fullFilePath);
numFrames= numel(info);

% Process frames to keep only the largest blob
global correctedFrames;
correctedFrames= zeros(info(1).Height, info(1).Width, numFrames);
for frame= 1:numFrames
    img= imread(fullFilePath, frame);
    CC= bwconncomp(img);
    
    if CC.NumObjects > 0
        labeledImg= bwlabel(img);
        areas= regionprops(labeledImg, 'Area');
        [~, idx]= max([areas.Area]);
        correctedFrames(:,:,frame)= ismember(labeledImg, idx);
    else
        correctedFrames(:,:,frame)= img;
    end
end



% Identify frames with holes
framesWithHoles= [];
for frame= 1:numFrames
    img= correctedFrames(:,:,frame);
    filledImg= imfill(img, 'holes');
    % Check if there are any differences (holes filled)
    if any(filledImg(:) ~= img(:))
        framesWithHoles= [framesWithHoles, frame];
    end
end

% Initialize GUI
fig= figure('Name', 'Hole Filling Parameters', 'Position', [100, 100, 800, 600]);

global ax; 
ax= zeros(2, 2);
for i= 1:2
    for j= 1:2
        ax(i, j)= subplot(2, 2, (i-1)*2 + j, 'Parent', fig);
        axis(ax(i, j), 'off');
    end
end


% Sliders! Sliders! Sliders! Sliders!
slider1= uicontrol('Style', 'slider', 'Min', 0, 'Max', 2, 'Value', 0, ...
    'Position', [700, 500, 120, 20], 'Callback', @updateUI, 'Tag', 'slider1');

slider2= uicontrol('Style', 'slider', 'Min', 0, 'Max', 2, 'Value', 0, ...
    'Position', [700, 450, 120, 20], 'Callback', @updateUI, 'Tag', 'slider2');

% done button!
doneButton= uicontrol('Style', 'pushbutton', 'String', 'Done', ...
    'Position', [700, 400, 120, 30], 'Callback', @applySettingsAndSave, 'Tag', 'doneButton');


% frames to display
global framesToDisplay;
framesToDisplay= framesWithHoles;

% initial window
updateUI();


function updateUI(~, ~)
    global framesToDisplay ax fullFilePath correctedFrames; %excellent programing right here!
    fig= gcf;
    radiusMultiplier= get(findobj(fig, 'Tag', 'slider1'), 'Value');
    ratioMultiplier= get(findobj(fig, 'Tag', 'slider2'), 'Value');

    numSubplots= min(16, numel(framesToDisplay));

    % Create a 4x4 grid of subplots
    for i= 1:numSubplots
        frame= framesToDisplay(i);

        img= correctedFrames(:,:,frame);

        [modifiedFrame, holeCenters, dimpleLocations]= modifyFrame(double(img), radiusMultiplier, ratioMultiplier);

        subplot(4, 4, i, 'Parent', fig);
        imshow(modifiedFrame);
        title(['Frame ', num2str(frame)]);

        % Fancy Markers
        hold on;
        scatter(holeCenters(:, 2), holeCenters(:, 1), 'r', 'filled');  % Red markers for hole centers
        scatter(dimpleLocations(:, 2), dimpleLocations(:, 1), 'g', 'filled');  % Green markers for dimple locations
        hold off;
    end
end

function [modifiedFrame, holeCenters, dimpleLocations]= modifyFrame(img, radiusMultiplier, ratioMultiplier)
    binaryImg= img < 0.5;
    binaryImg_b= imbinarize(img);
    whitePixelCount= sum(binaryImg_b(:));
     if ratioMultiplier>0
        rad_mul_f=whitePixelCount*ratioMultiplier*radiusMultiplier;
    else
         rad_mul_f=whitePixelCount*ratioMultiplier;
     end
    % morphological operations to fill holes and smooth edges... thanks
    % stackoverflow!
    filledImg= imfill(binaryImg, 'holes');
    filledImg= imopen(filledImg, strel('disk', round(radiusMultiplier * 10)));

    % hole locations
    holesImg= binaryImg - filledImg;

    % skeleton of the binary image
    skeletonImg= bwmorph(binaryImg, 'skel', inf);

    % Find endpoints of the skeleton as potential hole centers
    endpoints= bwmorph(skeletonImg, 'endpoints');

    % Exclude the corners from being hole centers
    endpoints(1,1)= 0;
    endpoints(1,end)= 0;
    endpoints(end,1)= 0;
    endpoints(end,end)= 0;

    % hole centers cords
    [holeRows, holeCols]= find(endpoints);
    holeCenters= [holeRows, holeCols];

    % loop through holes
    for k= 1:numel(holeRows)
        centerRow= holeRows(k);
        centerCol= holeCols(k);

        [X, Y]= meshgrid(1:size(img, 2), 1:size(img, 1));

        distances= sqrt((X - centerCol).^2 + (Y - centerRow).^2);

holeFill= double(distances <= rad_mul_f);  % intensity of 1
img(holesImg > 0)= holesImg(holesImg > 0) .* holeFill(holesImg > 0);

    end

    % dimp loc
    dimpleLocations= regionprops(binaryImg, 'Centroid');
    dimpleLocations= cat(1, dimpleLocations.Centroid);

    % Loops
    for k= 1:size(dimpleLocations, 1)
        centerRow= dimpleLocations(k, 2);
        centerCol= dimpleLocations(k, 1);

        [X, Y]= meshgrid(1:size(img, 2), 1:size(img, 1));

        distances= sqrt((X - centerCol).^2 + (Y - centerRow).^2);
    
        % coloring
        dimpleFill= double(distances <= rad_mul_f);  % fixed intensity of 1
        img(dimpleFill > 0 & ~holesImg)= 1;  

    end

    modifiedFrame= img;
end

function applySettingsAndSave(~, ~)
    global framesWithHoles correctedFrames fullFilePath;

    radiusMultiplier= get(findobj('Tag', 'slider1'), 'Value');
    ratioMultiplier= get(findobj('Tag', 'slider2'), 'Value');

    % apply the settings to all frames with holes
    for frame= framesWithHoles
        img= correctedFrames(:,:,frame);
        correctedFrames(:,:,frame)= modifyFrame(double(img), radiusMultiplier, ratioMultiplier);
    end

    % saving
    [path, name, ext]= fileparts(fullFilePath);
    outputFileName= fullfile(path, ['processed_', name, '_correctedFrames.tif']);
    
    imwrite(correctedFrames(:, :, 1), outputFileName, 'tif', 'WriteMode', 'overwrite', 'Compression', 'none');
    for frame= 2:size(correctedFrames, 3)
        imwrite(correctedFrames(:, :, frame), outputFileName, 'tif', 'WriteMode', 'append', 'Compression', 'none');
    end

    disp('Settings applied and frames saved to a new TIFF file.');
end



