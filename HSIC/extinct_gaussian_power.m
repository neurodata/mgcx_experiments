% Setup.
% Determine where your m-file's folder is.
folder = fileparts(which(mfilename)); 
% Add that folder plus all subfolders to the path.
addpath(genpath(folder));
rng('default')

% Experiment parameters.
sampleSizes = 1200;
numSims = 300;
alpha=0.05;
phis = 0.2:0.025:.975;
numShuffles = 1500;

dataPath = "../data/extinct_rates/extinct_gaussian_phi_%s_data.mat";
powers = zeros(length(phis), 2);

tic

pool = parpool(4);
parfor i = 1:length(phis)
    phi = phis(i);
    rate = num2str(phi, "%.3f");
    process = sprintf(dataPath, rate);

    dat = load(process);
    fprintf("PROCESS: %s\n", phis(i));

    % Load data generated in Python.
    X_full = dat.X_full;
    Y_full = dat.Y_full;

    tic
    partialResults = zeros(numSims, 1);

    bootstrapedValuesShift=[];
    for s=1:numSims
        X = X_full(:, s);
        Y = Y_full(:, s);
        sigX = median_heur(X);
        sigY = median_heur(Y);
        if mod(s-1,10)==0
            [bootShift,bootstrapedValuesShift] = customShiftHSIC(X,Y,alpha,50,min(sampleSizes, numShuffles),sigX,sigY);   
        else
            bootShift = customShiftHSIC(X,Y,alpha,50,min(sampleSizes, numShuffles),sigX,sigY,bootstrapedValuesShift); 
        end       
        partialResults(s) = bootShift.areDependent;
    end           
    toc
    powers(i, :) = [phi, mean(partialResults)];
    %disp(powers)
end

toc

delete(pool)

filename = sprintf("power_curves/shiftHSIC_powers_extinct_gaussian.mat");
save(filename,'powers')

disp(powers)

