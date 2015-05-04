function thicknessEstimates = doThicknessEstimation(...
    calibrationMethod,inputImageStackFileName,outputSavePath,params)

% Performs section thickness estimation using representative
% curves to determine the distance between two (adjacent) sections
% do thickness estimation based on one of the following methods to
% calibrate the similarity curve

%% Parameters

% calibrationMethod = 5;

% 1 - correlation coefficient across ZY sections, along x axis
% 2 - correlation coefficient across XY sections, along x axis
% 3 - SD of XY per pixel intensity difference
% 4 - c.o.c across ZY sections along Y
% 5 - c.o.c across XY sections, along X
% 6 - c.o.c acroxx XZ sections, along X
% 7 - 
% TODO: methods robust against registration problems

% params.xyResolution = 5; % nm
% params.maxShift = 20;
% params.maxNumImages = 20; % number of sections to initiate calibration.
%                 % the calibration curve is the mean value obtained by all
%                 % these initiations
% params.numPairs = 2; % number of section pairs to be used to estimate the thickness of onesection
% params.plotOutput = 1;
% params.usePrecomputedCurve = 0;
% params.pathToPrecomputedCurve = '';
% 
% inputImageStackFileName = '/home/thanuja/projects/data/FIBSEM_dataset/cubes/s108_1-200.tif';
% outputSavePath = '/home/thanuja/projects/tests/thickness/similarityCurves/s108_1-200_20150416';

%% 

if(calibrationMethod == 1)
    disp('Calculating c.o.c decay curve using ZY stack, along X ...')
    xcorrMat = getXcorrZYstack(inputImageStackFileName,params.maxShift,params.maxNumImages);
    disp('done!')
    % each column of xcorrMat corresponds to a sequence of shifted frames of
    % the zy plane along the x axis.
    % each row corresponds to one starting image (zy section) of the stack

elseif(calibrationMethod == 2)
    disp('Calculating c.o.c decay curve using XY images stack, along Y ...')
    xcorrMat = getXcorrXYstack(inputImageStackFileName,params.maxShift,params.maxNumImages);
    disp('done!')    
    
elseif(calibrationMethod == 3)
    disp('Calculating SD of intensity deviation curve using shifted XY sections stack, along X ...')
    xcorrMat = getIntensityDeviationXYstack(inputImageStackFileName,params.maxShift,params.maxNumImages);
    disp('done!')
    
elseif(calibrationMethod == 4)
    disp('Calculating c.o.c decay curve using ZY stack, along Y ...')
    xcorrMat = getXcorrZYstackY(inputImageStackFileName,params.maxShift,params.maxNumImages);
    disp('curve estimation done')
    
elseif(calibrationMethod == 5)
    disp('Calculating c.o.c decay curve using XY images stack, along X ...')
    xcorrMat = getXcorrXYstackX(inputImageStackFileName,params.maxShift,params.maxNumImages);
    disp('curve estimation done!')    
    
elseif(calibrationMethod == 6)
    disp('Calculating c.o.c decay curve using XZ images stack, along X ...')
    xcorrMat = getXcorrXZstackX(inputImageStackFileName,params.maxShift,params.maxNumImages);
    disp('curve estimation done!')    
    
elseif(calibrationMethod == 7)
    disp('Calculating c.o.c decay curve using XZ images stack, along Y ...')
    xcorrMat = getXcorrXZstackY(inputImageStackFileName,params.maxShift,params.maxNumImages);
    disp('curve estimation done!')
    
else
    error('Unrecognized calibration method specified. Check calibrationMethod')
end

% save calibration curve
disp('Saving xcorrMat')
matName = sprintf('xcorrMat%d.mat',calibrationMethod);
xcorrFileName = fullfile(outputSavePath,matName);
save(xcorrFileName,'xcorrMat')
disp('done')

% %% plot
% shadedErrorBar((1:params.maxShift),mean(xcorrMat,1),std(xcorrMat),'g');

%% Predict
% predict section thickness for the data set
% relZresolution = predictThicknessFromCurve(...
%         inputImageStackFileName,xcorrMat,params.maxShift,calibrationMethod);
    
relZresolution = predictThicknessFromCurveFromMultiplePairs(...
        inputImageStackFileName,xcorrMat,params.maxShift,calibrationMethod,params.numPairs);
% each row contains one set of estimates for all the sections. First row is
% from the images i and i+1, the second row is from images i and i+2 etc    
thicknessEstimates = relZresolution .* params.xyResolution;
% save predicted thickness to text file


% plot output if required
if(params.plotOutput)
    if(size(thicknessEstimates,1)==1)
        figure;plot(thicknessEstimates);
    elseif(size(thicknessEstimates,1)==2)
        figure;plot(thicknessEstimates(1,:),'r');
        hold on
        plot((thicknessEstimates(2,:).* 0.5),'g');
        hold off
    end
    title('Section thickness estimates (nm)')
    xlabel('Section index')
    ylabel('Estimated thickness (nm)')
end
