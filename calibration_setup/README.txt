findCalibPoints - Requests the user to select the pixel coordinate 
    associated with gridpoints on the projection surface
Input: void 
Output: calibrationPoints - 1x2 cell vector
    nx3 matrix of world coordinates and nx2 matrix of pixels

TODO: Specify OVERLAP region
TODO: Calculate gradiant mask

findCameraMatrix - Finds the parameters for the camera matrix which minimize
    the average squared distance between the world points and a 
    transformation of the image points
Input: calibrationPoints
Output: cameraMatrix - 4x3 matrix transformation from image space to world 
    space
        projectorLocation - 1x3 vector of the projector location in world
    coordinates

generateMapping - Maps each pixel in the 1140x912 image space to the X and
    Y coordinates in world space, then calls computeLuminanceAdjustment
	Parameter - maximum y/x range of world space search
Input: cameraMatrix, projectorLocation
Output: imageMap - 1140x912x2 matrix - X,Y world space coordinates at each
    pixel
        luminanceAdjustment - 1140x912 matrix - %maximum luminance of each
    pixel

        computeLuminanceAdjustment - Compute the %maximum luminance incident on
            each pixel in a given image map for a given projector location
        Input: imageMap, projectorLocation
        Output: luminanceAdjustment

computeAngularDistance - Compute the angular distance from each pixel to a 
    given zero vector. Also filter pixels outside projection bounds.
Input: imageMap, parameters
    parameters: 1x6 vector - zero vector from fly to expansion center [1:2];
	screen coordinate bounds, in inches, for active projection region [3:6]:
    [Azimuth Elevation Top Bottom Left Right]
Output: angularDistance - 1140x912 matrix - Angular distance of each pixel 
    from the given zero vector

generateStimulus - Generate a stimulus stack matching a range of parameters
    for a given angularDistance map, outputing to a named subfolder
Input: angularDistance, luminanceAdjustment, stimulusParameters, filenameBase
    stimulusParemeters: [frequency(Hz) r/v(ms) terminalRadius(radians)...
        bitDepth]
    filenameBase: string indicating folder and filename for image saves
Output: Series of images matching input parameters in folder of given name
    under the current path named in series with provided filename stem

tiledStimGeneration - Calculate angular distances and call generateStimulus
    for a range of positions through the projection surface
Input: imageMap, projectionBounds, angularBounds, stimulusParameters
    projectionBounds: boundaries for projection space in world space inches
        [top, bot, left, right]
    angularBounds: Bounds for where to generate the stimulus - 
        [lowerBoundElevation upperBoundElevation ...
        lowerBoundAzimuth upperBoundAzimuth ...
        intervalElevation intervalAzimuth]
Output: Image stacks within the specified bounds at the given interval, 
    saved under the current path with folder and filename stem based on the
    elevation and azimuth where it's generated
	
PTB incorportation pipeline:
Use BVL undistortion tool to get calibration points for pixels to azimuth/height
Use current pipeline to calculate luminance adjustments for pixels
Define stimuli by offsetting azimuth/elevation map conversion of azimuth/height by the desired azimuth/elevation of the center of the stimulus
	Test pixels which are less than the squared radial stimulus size and set black
Initialize PTB w/ undistortion parameters and luminance gain adjustment matrix
Present stimulus, then read morphed image
Provide morphed stimuli as input to stimulus generation script to generate presentation stack