# Overview
* `Correct_images_enmass.m`- Automatic mask corrector to correct all frames at once
* `Tiff_area_extractor_updater.m`- processes corrected masks and produces area, BPM, and arrhythmia index with a nice UI to allow automatic and manual data correction.
* `IoU_Calculator.m`- Calculates IoU between uncorrected and corrected masks

## Preparing the mask for MATLAB processing
> [!CAUTION]
> Required step!

After running the tracking Python script (and manually correcting the masks with the python code if you elect), the next step is to open the output TIFF mask into ImageJ/Fiji and adjust its scale back to the original resolution. For example, if the initial area was 94 by 100, open the mask in ImageJ/Fiji, go to scale, input 94 by 100, and save – this becomes your corrected scaled mask.

If you do not remember the dimensions of the original selected region do the following:

Take the original dataset image, the one that's 128x701 pixels and your corrected mask image. Select the line option that's four slots over from the default rectangle option. Draw a line height-wise and lengthwise across the heart in the original image and record the lengths of both. Do the same for the corrected mask image. Divide the line lengths of the original image by the corrected image, and you'll get the scaling factor between the images. Multiply 128 by each of these scaling factors and you'll get the size of the original box you selected. If you did record the original selection box dimensions, ignore the above.

After you get the scaling factors to rescale the corrected masks in ImageJ//Fiji select image> scale, and then enter the height and widths in pixels of the original selected region.

## Automatic correcting of masks- Not required for final processing
Run `correct_images_enmass.m` and when prompted upload the rescaled masks (made in the previous section). After uploading, an ui with up to 16 frames will appear with two sliders. The frames shown are a sample of frames that have either a hole in the mask or a dimple (an indentation that is greater than ¼ of a circle with the diameter of the dimple). The green and red dots that appear on the frames show you where MATLAB is detecting holes/dimples. The top slider controls the radius of the fill from the center of the hole/dimple. The bottom slider controls the ratio of fill radius to the size of the mask(ie larger detected heart area=larger proportional fill radius). To fill the holes/dimples, click the right arrow on the bottom slider twice (to make sure it is not 0) and progressively slide the top slider until the holes/dimples are filled, but not over filled. The gif below shows the general process. 

![](https://github.com/agadin/FLY_lab_Processing_Code/blob/main/images/flynetcorrector.gif)


Once you are satisfied with the corrections. Hit done and a new mask will be saved which can be used in the next step.


## Processing of corrected masks
Run `tiff_area_extractor_updater.m` and when prompted upload the rescaled corrected mask (Either from the section directly above or the one before that). After uploading, an ui with two vertically stacked graphs and sliders should pop up. See the GIF below:

![](https://github.com/agadin/FLY_lab_Processing_Code/blob/main/images/flynet.gif)


The upper figure displays the area over frames with two traces (original and smoothed) and green dots indicating the peaks identified by MATLAB. The lower figure illustrates the frequency of detected minimum peaks, revealing instances where MATLAB detected peaks in close proximity to one another. The upper slider facilitates data smoothing, visible in the changing upper figure’s red line. Smoothing is accomplished with a moving mean. The lower slider enables the merging of peaks within a certain distance of one another, known as the Merge
Value. If the difference in frame numbers between two consecutive peaks are less by the Merge Value, the MATLAB code will replace both with a peak located at the average frame number of the two points.
 
You want to adjust the sliders to make sure each minimum peak has a green dot. Also you need to make sure there are no red bars on the bottom graph. These red bars indicate two consecutive detected peaks that are <20 frames apart. The goal is to keep the values for each slider as low as possible. You are also able to manually add peaks. By using the Manual Input Button and inputting the X coordinate (frame number)of peak you would like to add. After clicking okay, the peak will be added as shown by the addition of a green dot. After done adjusting the sliders and manually adding peaks, hit the done button in the UI. Two figures will appear along with output data to the command line. You are also given the option to save data to a `.mat` file.

 Here is an example of the expected output:

Mean Period: 41.4167 frames
STD of Periods: 16.8647 frames
AI: 0.082904
Mean BPM: 188.1458
STD of BPM: 31.3139
Average Area: 1015.81 µm^2
Average Min Area: 668.38 µm^2
STD Min Area: 151.86 µm^2
Average Max Area: 1328.19 µm^2
STD Max Area: 72.10 µm^2
Results saved successfully.

## IoU Calculator
Run `IoU_Calculator.m` and when prompted select the original mask first. After selecting the original mask and clicking done, another window should pop up asking you to select the corrected mask. After selecting and clicking done, results will be printed to the command window and a comparative figure will appear. 
