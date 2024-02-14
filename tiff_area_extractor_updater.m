close all;
clear all;
% After running the tracking Python script, the next step is to reinsert 
% the output TIFF into ImageJ/Fiji and adjust its scale back 
% to the original resolution. For example, if the initial area 
% was 94 by 100, open the mask in ImageJ/Fiji, go to scale, 
% input 94 by 100, and save – this becomes your corrected 
% mask.

% In the MATLAB code, select the appropriately scaled TIFF file 
% (as adjusted in ImageJ/Fiji) and click open. A window will 
% appear with two figures and a slider. The upper figure displays 
% the Area over frames with two traces and green dots indicating
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

% Initialize a global variable for manual points
global manualPoints minPositionsg filename path;
manualPoints= [];
minPositionsg= [];

global mean_corrector_value;
mean_corrector_value=0.8;

[filename, path] = uigetfile('*.tif*', 'Choose a TIFF file'); % Choose your MASKED .tiff file after you have scaled it back to its original resolution
fullFilePath= fullfile(path, filename);

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

% minPositions= [];
% setappdata(ax1, 'minPositions', minPositions);

global windowSizeLabel mergeValueLabel; %Global values are very cool
windowSizeLabel= uilabel(uiFig, 'Text', ['Current Window Size: ' num2str(windowSize)], 'Position', [340, 115, 200, 22]);
mergeValueLabel= uilabel(uiFig, 'Text', ['Current Merge Value: ' num2str(mergevalue)], 'Position', [340, 60, 200, 22]);

global sliderWindowSize; % very efficent code

sliderWindowSize= uislider(uiFig, 'Limits', [1, 30], 'ValueChangedFcn', @(src, ~) updatePlots(1, src, smoothedData, frameRate, whitePixelCountMatrix, ax1, ax2));
sliderWindowSize.Position= [50, 115, 700, 3];
sliderWindowSize.Value= windowSize;
sliderWindowSize.MajorTicks= 1:5:30; 
sliderWindowSize.MinorTicks= 1:30;

global sliderMergeValue;
sliderMergeValue= uislider(uiFig, 'Limits', [1, 20], 'ValueChangedFcn', @(src, ~) updatePlots(2, src, smoothedData, frameRate, whitePixelCountMatrix, ax1, ax2));
sliderMergeValue.Position= [50, 60, 700, 3];
sliderMergeValue.Value= mergevalue;
sliderMergeValue.MajorTicks= 1:5:20; 
sliderMergeValue.MinorTicks= 1:20; 

%Intialize first plot
updatePlots(3, [windowSize mergevalue], smoothedData, frameRate, whitePixelCountMatrix, ax1, ax2);


% Done Button!

% Add a button for manual input
manualInputButton= uibutton(uiFig, 'push', 'Text', 'Manual Input', 'Position', [250, 140, 100, 30], 'ButtonPushedFcn', @(src, event) manualInputPopup(whitePixelCountMatrix, ax1));

% Callback function for manual input popup
doneButton= uibutton(uiFig, 'push', 'Text', 'Done', 'Position', [355, 140, 100, 30], 'ButtonPushedFcn', @(src, event) finalizeParameters(uiFig, whitePixelCountMatrix, numFrames, ax1, ax2));

undoButton= uibutton(uiFig, 'push', 'Text', 'Undo', 'Position', [455, 140, 100, 30], 'ButtonPushedFcn', @(src, event) undoLastManualInput(whitePixelCountMatrix, ax1));

% Callback function for slider value change
function updatePlots(slider, value, smoothedData, frameRate, whitePixelCountMatrix, ax1, ax2)
    global sliderMergeValue currentWindowSize mean_corrector_value path sliderWindowSize currentMergeValue;

    
    if slider==1
        if isobject(sliderMergeValue)
            mergevalue= round(sliderMergeValue.Value);
        else
            mergevalue=sliderMergeValue;
        end
        currentMergeValue=mergevalue;
        if isobject(value)
            windowSize= round(value.Value);
            currentWindowSize= windowSize;
            updateWindowSizeLabel(windowSize);
            
            
        else
            % stackoverflow told me to do this idk
            windowSize= round(value);
            currentWindowSize= windowSize;
            sliderWindowSize=windowSize;
        end
    elseif slider==2
        currentWindowSize=sliderWindowSize;
         if isobject(currentWindowSize)
            windowSize= round(currentWindowSize.Value);
        else
           windowSize=currentWindowSize;
         end
        if isobject(value)
            mergevalue= round(value.Value);
            sliderMergeValue=mergevalue;
            updateMergeValueLabel(mergevalue);
            
        else
            % stackoverflow told me to do this idk
            mergevalue= round(value);
            sliderMergeValue=mergevalue;
            updateMergeValueLabel(mergevalue);
        end
    else
        %beginning case
        windowSize=value(1);
        mergevalue=value(2);

    end

    currentMergeValue=mergevalue;
    currentWindowSize=windowSize;


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
function finalizeParameters(uiFig, whitePixelCountMatrix, numFrames,ax1,ax2, manualInputButton)
    global currentWindowSize mergeValueLabel mean_corrector_value manualPoints minPositionsg filename path currentMergeValue;

    close(uiFig);

    smoothedData= movmean(whitePixelCountMatrix(:, 2), [currentWindowSize, currentWindowSize]);
    
    averageSmoothedData= mean(smoothedData);
    stdSmoothedData=std(smoothedData);
    [minValues, minPositions]= findpeaks(-smoothedData, 'MinPeakHeight', -averageSmoothedData*mean_corrector_value);

mergevalue=currentMergeValue;
minPositions= mergeClosePeaks(minPositions, mergevalue);


minPositionsg=minPositions';

manual_temp=manualPoints;
% Iterate through each manual point and insert into minPositions if not already present
for i= 1:length(manual_temp)
    % Check if the manual point already exists in minPositions
    if ~ismember(manual_temp(i), minPositionsg)
        % Find the index where the current manual point should be inserted
        insertIndex= find(minPositionsg > manual_temp(i), 1);

        % Insert the manual point into minPositions
        minPositionsg= [minPositionsg(1:insertIndex-1), manual_temp(i), minPositionsg(insertIndex:end)];
    end
end

    minPositions=minPositionsg';

    periodsFrames= diff(minPositions);

    meanPeriodFrames= mean(periodsFrames);
    stdPeriodFrames= std(periodsFrames);

    frameRate= 125;
    periodsSeconds= periodsFrames / frameRate;
    bpm= 60 ./ periodsSeconds;
    outliers_bpm= bpm > 1500; %outlier filtering
    bpm(outliers_bpm)= mean(bpm(~outliers_bpm));

    %AI index
    meanPeriod_IBS= mean(periodsSeconds);
    stdPeriodFrames_IBS= std(periodsSeconds);
    CV= stdPeriodFrames_IBS/meanPeriod_IBS;
    AI= (CV^2)/2;

    disp(['Mean Period: ' num2str(meanPeriodFrames) ' frames']);
    disp(['STD of Periods: ' num2str(stdPeriodFrames) ' frames']);
    disp(['AI: ' num2str(AI)]);
    
    % Plot Area graph
    figure(1);
    set(gcf, 'Position', [100, 100, 800, 375]);
    plot(smoothedData, 'r', 'LineWidth', 2);
    title('Change in Heart Area as a Function of Frames',FontWeight='bold',FontSize=15);
    xlabel('Frame Number',FontWeight='bold',FontSize=14);
    ylabel('\mu m^2',FontWeight='bold',FontSize=14);

    % Plot BPM as a function of time
    timeInSeconds= (1:numFrames) / frameRate;
    figure(2);
    set(gcf, 'Position', [100, 100, 800, 375]);
    plot(timeInSeconds(minPositions(1:end-1)), bpm, 'b', 'LineWidth', 2);
    title('BPM as a Function of Time',FontWeight='bold',FontSize=15);
    xlabel('Time (seconds)',FontWeight='bold',FontSize=14);
    ylabel('Beats Per Minute',FontWeight='bold',FontSize=14);

    %Display BPM
    meanBPM= mean(bpm);
    stdBPM= std(bpm);
    disp(['Mean BPM: ' num2str(meanBPM)]);
    disp(['STD of BPM: ' num2str(stdBPM)]);
    
    %Display average Area 
    fprintf('Average Area: %.2f µm^2\n', averageSmoothedData);
    fprintf('STD Area: %.2f µm^2\n', stdSmoothedData);

    %display the mean and STD of MIN Area
    peakAreas= smoothedData(minPositions); %already merged sorted

    meanMINArea= mean(peakAreas);
    stdMINArea= std(peakAreas);
    fprintf('Average Min Area: %.2f µm^2\n', meanMINArea);
    fprintf('STD Min Area: %.2f µm^2\n', stdMINArea);

    %display the mean and STD of MAX Area
    [maxValues, maxPositions]= findpeaks(smoothedData, 'MinPeakHeight', averageSmoothedData);

    %Filter out two points that occur right next to one another
    maxPositions= mergeClosePeaks(maxPositions, mergevalue);
    peakMAXAreas= smoothedData(maxPositions);

    meanMaxArea= mean(peakMAXAreas);
    stdMaxArea= std(peakMAXAreas);
    fprintf('Average Max Area: %.2f µm^2\n', meanMaxArea);
    fprintf('STD Max Area: %.2f µm^2\n', stdMaxArea);

    answer= questdlg('Do you want to save the results to a file (optional)?', ...
                  'Save Results', ...
                  'Yes', 'No', 'No');

    if strcmpi(answer, 'Yes')
        dateStr= datestr(datetime('now'), 'mm_dd_HH_MM');
        newFilename= fullfile(path, [filename(1:end-4) '_data_' dateStr '.mat']);
        save(newFilename, 'whitePixelCountMatrix', 'bpm', 'peakMAXAreas', 'peakAreas', 'AI', 'manualPoints', 'currentWindowSize', 'currentMergeValue');
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


function manualInputPopup(whitePixelCountMatrix, ax)
    global manualPoints;
    manualInputFig= uifigure('Name', 'Manual Input', 'Position', [300, 300, 300, 150]);

    inputField= uieditfield(manualInputFig, 'numeric', 'Position', [120, 80, 50, 22], 'Value', 1, 'Limits', [1, numel(whitePixelCountMatrix)]);

    confirmButton= uibutton(manualInputFig, 'push', 'Text', 'Add Peak', 'Position', [180, 40, 100, 30], 'ButtonPushedFcn', @(src, event) addManualPeak(inputField, ax, manualInputFig));

    % Callback function for adding manual peak
function addManualPeak(inputField, ax, manualInputFig)
    frameNumber= round(inputField.Value);

    if any(manualPoints == frameNumber)
        % Frame Removel trigger
        removeIndex= manualPoints == frameNumber;
        manualPoints(removeIndex)= [];
        minPositions= getappdata(ax, 'minPositions');
        minPositions(removeIndex)= [];
        setappdata(ax, 'minPositions', minPositions);
        hold(ax, 'on');
        scatter(ax, frameNumber, whitePixelCountMatrix(frameNumber, 2), 50, 'w', 'filled'); % Use 'w' to set the dot color to white
        hold(ax, 'off');
    else
        % Green dot addition
        hold(ax, 'on');
        scatter(ax, frameNumber, whitePixelCountMatrix(frameNumber, 2), 50, 'g', 'filled');
        hold(ax, 'off');
        disp(['Manual peak added at ', num2str(frameNumber)])
        % Update minPositions in the axes app data
        minPositions= getappdata(ax, 'minPositions');
        minPositions= [minPositions, frameNumber];
        setappdata(ax, 'minPositions', minPositions);

        % update global var
        manualPoints= [manualPoints, frameNumber];
    end

        close(manualInputFig);
    end
end

% Undo button callback
function undoLastManualInput(whitePixelCountMatrix, ax)
    global manualPoints;
    if ~isempty(manualPoints)
        lastFrameNumber= manualPoints(end);

        % Frame removal
        manualPoints= manualPoints(1:end-1);
        minPositions= getappdata(ax, 'minPositions');
        minPositions= minPositions(1:end-1);
        setappdata(ax, 'minPositions', minPositions);

        % Remove dot- janky may fix later
        hold(ax, 'on');
        scatter(ax, lastFrameNumber, whitePixelCountMatrix(lastFrameNumber, 2), 50, 'w', 'filled'); % Use 'w' to set the dot color to white
        hold(ax, 'off');
    end
end