% Read file

% filename = '/home/thanuja/projects/drosophila-l3/stack2/raw/00.tif';
% filename = '/home/thanuja/projects/drosophila-l3/stack2/classification/schmidhuber/median_filtered/neurons/neurons0000.png';
% filename = '/home/thanuja/projects/drosophila-l3/stack2/classification/schmidhuber/median_filtered/membrane/00_schmidhuber_membrane.tiff';
% filename = '/home/thanuja/projects/drosophila-l3/stack2/groundtruth/result_0000.tiff';

filename = '/home/thanuja/projects/data/FIBSEM_dataset/largercubes/s704/s704.tif';
imageInd = 1;
% A = double(imread(filename));
A = readTiffStackToArray(filename);
% A = A./(max(max(A)));
% A = A./255;

% C = rgb2gray(A);

% write to another file
% writefile = '/home/thanuja/Dropbox/data/RF_training_edge/I01_trainingLabels.tif';
% writeFilePath = '/home/thanuja/Dropbox/data2/raw';
% writeFilePath = '/home/thanuja/Dropbox/data2/probabilities/neuron';
writeFilePath = '/home/thanuja/projects/tests/thickness/similarityCurves/FIBSEMpng/s704DifferentPos/001/rowShifted';
% writeFilePath = '/home/thanuja/projects/toyData/set9/groundtruth';
% writeFilePath = '/home/thanuja/projects/toyData/set9/membranes';
% writeFilePath = '/home/thanuja/projects/toyData/set9/neurons';
% writeFilePath = '/home/thanuja/projects/toyData/set9/raw';

writeFileName = '200.png';
% writeType = 'tiff';
writeType = 'png';

dimx = 700;
dimy = 700;

startRow = 200;
stopRow = startRow -1 + dimy;

startCol = 1;
stopCol = startCol - 1 + dimx;

numDim = 3;

writeFileName = fullfile(writeFilePath,writeFileName);
B = A(startRow:stopRow,startCol:stopCol,imageInd)./255;
imwrite(B,writeFileName,writeType)
figure;imshow(B);

% k = 00; % file index
% for i=1:4
%     for j=1:4
%         B = A(startRow:stopRow,startCol:stopCol,:);
%         writeName = sprintf('I%02d_trainingLabels.tif',k);
%         writeFileName = strcat(writeFilePath,writeName);
%         disp(writeFileName)
%         imwrite(B,writeFileName,'tif')
%         % figure;imshow(B);
%         
%         startCol = stopCol + 1;
%         stopCol = stopCol + dimx;
%         k = k + 1;
%     end
%     startRow = stopRow + 1;
%     stopRow = stopRow + dimy;
%     startCol = 1;
%     stopCol = dimx;
% end
        
