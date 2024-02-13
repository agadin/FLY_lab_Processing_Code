% original mask TIFF file
[filename_original, path_original]= uigetfile('*.tif*', 'Choose the original TIFF file');
fullFilePath_original= fullfile(path_original, filename_original);

% corrected mask TIFF file
[filename_corrected, path_corrected]= uigetfile('*.tif*', 'Choose the corrected TIFF file');
fullFilePath_corrected= fullfile(path_corrected, filename_corrected);


info_original= imfinfo(fullFilePath_original);
numFrames= numel(info_original);

iou_values= zeros(numFrames, 1);

fullFilePath= fullfile(path_corrected, filename_corrected);

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


for frame= 1:numFrames
    original_mask= imread(fullFilePath_original, frame);
    corrected_mask= imread(fullFilePath_corrected, frame);

    binary_original_mask= original_mask > 0;
    binary_corrected_mask= corrected_mask > 0;

    intersection_area= sum(binary_original_mask(:) & binary_corrected_mask(:));
    union_area= sum(binary_original_mask(:) | binary_corrected_mask(:));

    iou_values(frame)= intersection_area / union_area;
end

disp('IoU mean:');
disp(mean(iou_values));
disp('IoU STDev:');
disp(std(iou_values));

figure('Position', [100, 100, 875, 375]);

yyaxis left
plot(iou_values, 'LineWidth', 2);
ylabel('IoU Value (Pixels)', 'fontweight', 'bold', 'FontSize', 14);

yyaxis right
plot(whitePixelCountMatrix(:,2), 'LineWidth', 2);
ylabel('White Pixel Count', 'fontweight', 'bold', 'FontSize', 14);

title('IoU and White Pixel Count for Larva 1', 'fontweight', 'bold', 'FontSize', 15);
xlabel('Frame Number', 'fontweight', 'bold', 'FontSize', 14);
legend('IoU', 'White Pixel Count', 'FontSize', 14);

hold off;