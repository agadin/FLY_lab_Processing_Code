% User selects the original mask TIFF file
[filename_original, path_original] = uigetfile('*.tif', 'Choose the original TIFF file');
fullFilePath_original = fullfile(path_original, filename_original);

% User selects the corrected mask TIFF file
[filename_corrected, path_corrected] = uigetfile('*.tif', 'Choose the corrected TIFF file');
fullFilePath_corrected = fullfile(path_corrected, filename_corrected);

% Reading TIFF files
info_original = imfinfo(fullFilePath_original);
numFrames = numel(info_original);

% Preallocate matrix for storing IoU values
iou_values = zeros(numFrames, 1);

fullFilePath= fullfile(path_corrected, filename_corrected);

% Reading TIFF file
info= imfinfo(fullFilePath);
num_Frames= numel(info);
whitePixelCountMatrix= zeros(num_Frames, 2);

for frame= 1:num_Frames
    img= imread(fullFilePath, frame, 'Info', info);
    binaryImg= imbinarize(img);
    whitePixelCount= sum(binaryImg(:));
    whitePixelCountMatrix(frame, 1)= whitePixelCount;
end
whitePixelCountMatrix(:, 2)= whitePixelCountMatrix(:, 1) * 1.06925; %area calc

% Loop through each frame
for frame = 1:numFrames
    % Read the original and corrected masks for the current frame
    original_mask = imread(fullFilePath_original, frame);
    corrected_mask = imread(fullFilePath_corrected, frame);

    % Convert masks to binary images
    binary_original_mask = original_mask > 0;
    binary_corrected_mask = corrected_mask > 0;

    % Calculate intersection and union areas
    intersection_area = sum(binary_original_mask(:) & binary_corrected_mask(:));
    union_area = sum(binary_original_mask(:) | binary_corrected_mask(:));

    % Calculate IoU for the current frame
    iou_values(frame) = intersection_area / union_area;
end

% Display or use the IoU values as needed
disp('IoU mean:');
disp(mean(iou_values));
disp('IoU STDev:');
disp(std(iou_values));
% Create a figure
figure('Position', [100, 100, 875, 375]);

% Plot IoU values on the left y-axis
yyaxis left
plot(iou_values, 'LineWidth', 2);
ylabel('IoU Value (Pixels)', 'fontweight', 'bold', 'FontSize', 14);

% Add a second y-axis on the right for the white pixel count
yyaxis right
plot(whitePixelCountMatrix(:,2), 'LineWidth', 2);
ylabel('White Pixel Count', 'fontweight', 'bold', 'FontSize', 14);

% Set common properties
title('IoU and White Pixel Count for Larva 1', 'fontweight', 'bold', 'FontSize', 15);
xlabel('Frame Number', 'fontweight', 'bold', 'FontSize', 14);

% Add legend
legend('IoU', 'White Pixel Count');

% Hold off to stop overlaying subsequent plots
hold off;