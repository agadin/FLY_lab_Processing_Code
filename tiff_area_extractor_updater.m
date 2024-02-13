close all;
clear all;
% After running the Python script, the next step is to reinsert 
% the output TIFF into ImageJ/Fiji and adjust its scale back 
% to the original resolution. For example, if the initial area 
% was 94 by 100, open the mask in ImageJ/Fiji, go to scale, 
% input 94 by 100, and save – this becomes your corrected 
% mask.

% In the MATLAB code, select the appropriately scaled TIFF file 
% (as adjusted in ImageJ/Fiji) and click open. A window will 
% appear with two figures and a slider. The upper figure displays 
% the volume over frames with two traces and green dots indicating
% the peaks identified by MATLAB. The upper slider facilitates 
% data smoothing, visible in the changing upper figure.

% The lower figure illustrates the frequency of points, revealing
% instances where MATLAB detected points in close proximity. If 
% two points are closely situated, MATLAB marks them with a red 
% bar on the lower figure. The lower slider enables the merging 
% of peaks within a specified threshold value, known as the Merge
% Value, by replacing them with an averaged peak value.

% Adjust the sliders to eliminate any red bars and ensure the 
% data appears smooth. Once satisfied, click "Done," and result  
% figures will be presented, with corresponding data output 
% to the command line.

%% Created by Alexander Gadin
[filename, path]= uigetfile('*.tif', 'Choose a TIFF file'); %Choose your MASKED .tiff file after you have scaled it back to its original resolution
fullFilePath= fullfile(path, filename);

mean_corrector_value=0.9;
% Reading TIFF file
info= imfinfo(fullFilePath);
numFrames= numel(info);
whitePixelCountMatrix= zeros(numFrames, 2);

for frame= 1:numFrames
    img= imread(fullFilePath, frame, 'Info', info);
    binaryImg= imbinarize(img);
    whitePixelCount= sum(binaryImg(:));
    whitePixelCountMatrix(frame, 1)= whitePixelCount;
end

whitePixelCountMatrix(:, 2)= whitePixelCountMatrix(:, 1) * 1.06925; %area calc

% Initial values
windowSize= 5;
mergevalue= 7; 
frameRate= 125;
smoothedData= movmean(whitePixelCountMatrix(:, 2), windowSize);

% main UI figure
uiFig= uifigure('Name', 'Window Size and Merge Value Adjustment', 'Position', [100, 100, 800, 600]);

ax1= axes(uiFig, 'Position', [0.1, 0.6, 0.8, 0.25]); % Reduced the height to create space
ax2= axes(uiFig, 'Position', [0.1, 0.35, 0.8, 0.25]); % Adjusted y-position to create space

global windowSizeLabel mergeValueLabel; %Global values are very cool
windowSizeLabel= uilabel(uiFig, 'Text', ['Current Window Size: ' num2str(windowSize)], 'Position', [340, 115, 200, 22]);
mergeValueLabel= uilabel(uiFig, 'Text', ['Current Merge Value: ' num2str(mergevalue)], 'Position', [340, 60, 200, 22]);

global sliderWindowSize; % very efficent code

sliderWindowSize= uislider(uiFig, 'Limits', [1, 30], 'ValueChangedFcn', @(src, ~) updatePlots(src, smoothedData, frameRate, whitePixelCountMatrix, ax1, ax2));
sliderWindowSize.Position= [50, 115, 700, 3];
sliderWindowSize.Value= windowSize;
sliderWindowSize.MajorTicks= 1:5:30; 
sliderWindowSize.MinorTicks= 1:30;

global sliderMergeValue;
sliderMergeValue= uislider(uiFig, 'Limits', [1, 20], 'ValueChangedFcn', @(src, ~) updatePlots(src, smoothedData, frameRate, whitePixelCountMatrix, ax1, ax2));
sliderMergeValue.Position= [50, 60, 700, 3];
sliderMergeValue.Value= mergevalue;
sliderMergeValue.MajorTicks= 1:5:20; 
sliderMergeValue.MinorTicks= 1:20; 

%Intialize first plot
updatePlots(windowSize, smoothedData, frameRate, whitePixelCountMatrix, ax1, ax2);


% Done Button!
doneButton= uibutton(uiFig, 'push', 'Text', 'Done', 'Position', [355, 140, 100, 30], 'ButtonPushedFcn', @(src, event) finalizeParameters(uiFig, whitePixelCountMatrix, numFrames));


% Callback function for slider value change
function updatePlots(value, smoothedData, frameRate, whitePixelCountMatrix, ax1, ax2)
    global sliderMergeValue currentWindowSize;

    if isobject(value)
        windowSize= round(value.Value);
        currentWindowSize= windowSize;
        updateWindowSizeLabel(windowSize);
        mergevalue= round(sliderMergeValue.Value);
        updateMergeValueLabel(mergevalue);
    else
        % stackoverflow told me to do this idk
        windowSize= round(value);
        currentWindowSize= windowSize;
        mergevalue= round(sliderMergeValue.Value);
    end

    smoothedData= movmean(whitePixelCountMatrix(:, 2), windowSize);

    averageSmoothedData= mean(smoothedData);
    [minValues, minPositions]= findpeaks(-smoothedData, 'MinPeakHeight', -averageSmoothedData * mean_corrector_value);

    minPositions= mergeClosePeaks(minPositions, mergevalue);
    peakDifferences= diff(minPositions);

    % Update top
    plot(ax1, whitePixelCountMatrix(:, 2), 'b', 'LineWidth', 2);
    hold(ax1, 'on');
    plot(ax1, smoothedData, 'r', 'LineWidth', 2);
    title(ax1, 'Diagnostic Original vs. Smoothed Data');
    xlabel(ax1, 'Frame Number');
    ylabel(ax1, '\mu m^2');
    scatter(ax1, minPositions, smoothedData(minPositions), 50, 'g', 'filled');
    legend(ax1, 'Original Data', 'Smoothed Data', 'Peak Locations');
    hold(ax1, 'off');

    % Update bottom
    plot(ax2, peakDifferences, 'b');
    hold(ax2, 'on');
    threshold= 10; %for highlighting
    highlightIndices= find(peakDifferences <= threshold);
    bar(ax2, highlightIndices, peakDifferences(highlightIndices), 'r');
    title(ax2, 'Differences Between Consecutive Peak Positions');
    xlabel(ax2, 'Peak Index');
    ylabel(ax2, 'Frame Difference');
    hold(ax2, 'off');
end

% Done button!
function finalizeParameters(uiFig, whitePixelCountMatrix, numFrames)
    global currentWindowSize mergeValueLabel;

    close(uiFig);

    smoothedData= movmean(whitePixelCountMatrix(:, 2), [currentWindowSize, currentWindowSize]);


averageSmoothedData= mean(smoothedData);

[minValues, minPositions]= findpeaks(-smoothedData, 'MinPeakHeight', -averageSmoothedData*mean_corrector_value);

mergevalue=mergeValueLabel;
minPositions= mergeClosePeaks(minPositions, mergevalue);

periodsFrames= diff(minPositions);

meanPeriodFrames= mean(periodsFrames);
stdPeriodFrames= std(periodsFrames);

frameRate= 125;
periodsSeconds= periodsFrames / frameRate;
bpm= 60 ./ periodsSeconds;

%AI index
CV = stdPeriodFrames/meanPeriodFrames;
AI = (CV^2) / 2;

disp(['Mean Period: ' num2str(meanPeriodFrames) ' frames']);
disp(['STD of Periods: ' num2str(stdPeriodFrames) ' frames']);
disp(['AI: ' num2str(mean_corrector_value) ' frames']);
% Plot volume graph
figure(1);
plot(smoothedData, 'r', 'LineWidth', 2);
title('Change in Heart Volume as a Function of Frames');
xlabel('Frame Number');
ylabel('\mu m^2');



% Plot BPM as a function of time
timeInSeconds= (1:numFrames) / frameRate;
figure(2);
plot(timeInSeconds(minPositions(1:end-1)), bpm, 'b', 'LineWidth', 2);
title('BPM as a Function of Time');
xlabel('Time (seconds)');
ylabel('Beats Per Minute');

    meanBPM= mean(bpm);
    stdBPM= std(bpm);
    disp(['Mean BPM: ' num2str(meanBPM)]);
    disp(['STD of BPM: ' num2str(stdBPM)]);

    %display the mean and STD of MIN volume
    peakVolumes= smoothedData(minPositions); %already merged sorted

    meanMINVolume= mean(peakVolumes);
    stdMINVolume= std(peakVolumes);
    disp(['Mean Minimum Volume: ' num2str(meanMINVolume) ' \mu m^2']);
    disp(['STD of Minimum Volume: ' num2str(stdMINVolume) ' \mu m^2']);

    %display the mean and STD of MAX volume
    [minValues, maxPositions]= findpeaks(smoothedData, 'MinPeakHeight', averageSmoothedData);

    %Filter out two points that occur right next to one another
    mergevalue=mergeValueLabel;
    maxPositions= mergeClosePeaks(maxPositions, mergevalue);
    peakMAXVolumes= smoothedData(maxPositions);

    meanMaxVolume= mean(peakMAXVolumes);
    stdMaxVolume= std(peakMAXVolumes);
    disp(['Mean Minimum Volume: ' num2str(meanMaxVolume) ' \mu m^2']);
    disp(['STD of Minimum Volume: ' num2str(stdMaxVolume) ' \mu m^2']);

answer= questdlg('Do you want to save the results to a file (optional)?', ...
                  'Save Results', ...
                  'Yes', 'No', 'No');

if strcmpi(answer, 'Yes')
    save('white_pixel_count_matrix.mat', 'whitePixelCountMatrix', 'bpm', 'currentWindowSize', 'mergeValueLabel');
    disp('Results saved successfully.');
else
    disp('Results not saved.');
end

end

% function to update the global windowSizeLabel
function updateWindowSizeLabel(size)
    global windowSizeLabel;
    windowSizeLabel.Text= ['Current Window Size: ' num2str(size)];
end

% define a function to merge close peaks
function filteredPositions= mergeClosePeaks(positions, maxDistance)
    filteredPositions= positions;
    i= 1;
    while i < numel(filteredPositions)
        % Check if the next peak is within the specified distance
        if i < numel(filteredPositions) && (filteredPositions(i + 1) - filteredPositions(i)) <= maxDistance
            % Merge the two peaks by replacing them with their average
            filteredPositions(i)= round(mean(filteredPositions(i:i+1)));
            % Remove the next entry
            filteredPositions(i + 1)= [];
        else
            i =i+1;
        end
    end
end

% function to update the global updateMergeValueLabel
function updateMergeValueLabel(value)
    global mergeValueLabel;
    mergeValueLabel.Text= ['Current Merge Value: ' num2str(value)];
end


