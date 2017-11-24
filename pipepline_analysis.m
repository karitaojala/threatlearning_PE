%% fMRI analysis pipeline

clear variables
addpath 'D:\spm12'

spm defaults fmri
spm_jobman initcfg
spm_get_defaults('cmdline',true)

% Folders
mainpath = 'D:\fMRI_Karita\';
codepath = fullfile(mainpath, 'scripts');

addpath(mainpath)
addpath(codepath)

% Subject list
subj      = dir(fpath);
subj      = {subj(:).name}';
subj(1:2) = [];
subj      = subj(not(cellfun('isempty', strfind(subj,'PR'))));

%% Main script options
% Run different scripts
run_behav           = false;    % Behaviour scripts: creating behavioural files, check learning
run_createphysioreg = false;    % Create PhysIO noise regressors
run_unzipnii        = false;    % Unzipping NIFTI files
run_fmripreproc     = false;    % fMRI preprocessing
run_fmri1stlvl      = false;    % fMRI 1st level (within-subject) analysis
run_preparebehav    = false;    % Multiple conditions file for parametric models
run_copycontrasts   = false;    % Copy all subjects' contrasts and masks into 2nd level folder
run_createexplmask  = false;    % Create explicit mask for 2nd lvl from all subjects' individual masks
run_fmri2ndlvl      = false;    % fMRI 2nd level (group) analysis
printresults        = false;    % Print results of 2nd level analyses

% Noise correction level
noisecorr = 1;
% 1 = only head motion correction (6 regressors)
% 2 = head motion and RETROICOR physiological noise correction (6 + x)
% 3 = head motion and full PhysIO physiological noise correction (6 + 20)

if noisecorr == 1;
    fpath = fullfile(mainpath,'biascorrected_ACorigin');
    nNoiseReg = 6;
elseif noisecorr == 2; % IMPLEMENT THIS
    fpath = fullfile(mainpath,'biascorrected_ACorigin_physcorr_RETROICOR');
    %nNoiseReg = ??; 
elseif noisecorr == 3;
    fpath = fullfile(mainpath,'biascorrected_ACorigin_physcorr');
    nNoiseReg = 26;
end

% Phase of the experiment
phase = 1:3;
phasename = {'Acq','Maint','Acq2','AllPhases','BothAcq','AllPhases_Scaled'};
% 1 = Acquisition
% 2 = Maintenance
% 3 = Re-learning / Acquisition 2
% 4 = All phases together
% 5 = Both acquisition phases
% 6 = All phases together, scaled according to run length

% Models included in this analysis
models = 1:4;
modelname = {'Model_Cat_Axiomatic' 'Model_Par_1' 'Model_Par_1b' 'Model_Par_2'};
modelcons = [13 5 5 10];
% 1 = Axiomatic approach
% 2 = Simple prediction error model
% 3 = Prediction error model with expected p(shock) from the Bayesian model
% 4 = Bayesian learning model

% 2nd level contrasts to run
contrasts = 1:10; % All contrasts
% Does this option really make sense?

%% Behaviour
%-------------------------------------------------------------------------
if run_behav
    subj_beh = [155 159:162 164:167 169:177 179:182]; %#ok<*UNRCH>
    Behavior_PFC_fMRI(fpath,subj_beh)
    checkLearning
end

%% Psychophysiological data
%-------------------------------------------------------------------------
if run_createphysioreg
    % PhysIO toolbox modelling psychophysiological noise
    % Create a nuisance regressor file for SPM fMRI analysis
    % 155 included in the fMRI analysis sample but no physio file
    physio_subj = [159:162 164:167 169:177 179:182];
    % 157, 168 and 178 out because not included in the fMRI sample
    physiopath = fullfile(mainpath,'PhysioRegressors');
    MRI_subj = subj;
    CreatePhysioRegressors(fpath,physiopath,MRI_subj,physio_subj)
end

%% fMRI
%-------------------------------------------------------------------------

if run_unzipnii
    % Need DICOM to NIFTI converted files for unzipping
    unzip_niftiis(fpath,subj)
end

if run_fmripreproc
    %% 1. Preprocessing
    
    %---------------------------------------------------
    % 1.1 Combine multiple echoes of an fMRI time series
    %---------------------------------------------------
    EchoCombine(fpath,cellstr(subj))
    
    %---------------------------------------------------------------
    % 1.2 Preprocessing including EPI bias correction and field maps
    %---------------------------------------------------------------
    % Use Part 1 / Part 2 for subjects who had to be taken out of the scanner
    preprocessing_ALL_withFieldmaps(fpath,codepath,subj)
    preprocessing_ALL_withFieldmaps_split_Part1(fpath,subj)
    preprocessing_ALL_withFieldmaps_split_Part2(fpath,subj)
    
    %-----------------------
    % 1.3 Data quality check
    %-----------------------
    CheckReg_job(fpath,subj)
    
    %----------------------
    % 1.4 Head motion check
    %----------------------
    CheckHeadMotion_job(fpath,subj)

end

if run_fmri1stlvl
    %% 2. First level analysis
    
    %-------------------------------------------------
    % 2.1 1st level model specification and estimation
    %-------------------------------------------------
    
    if run_preparebehav
        % Create multiple conditions files for parametric models
        prepare_behav
    end
    
    for p = phase
        
        for m = models
            if m == 1 % Axiomatic categorical model
                firstlevel_CSUSconditions_axiomatic(fpath,p,noisecorr)
            else % Parametric models
                firstlevel_CSUSconditions_parmod(mainpath,fpath,m,p,noisecorr)
            end
        end
        
        %------------------------
        % 2.2 1st level contrasts
        %------------------------
        
        for m = models
            if m == 1
                firstlevel_contrasts_axiomatic(fpath,phasename{p})
            else
                firstlevel_contrasts_parmod(fpath,m,phasename{p})
            end
        end
        
    end

end

if run_copycontrasts
    
    %-------------------------------------------------
    % 2.3 Copy contrasts and masks to 2nd level folder
    %-------------------------------------------------
    
    for m = models
        for p = phase
            copy_contrasts(fpath,subj,modelname{m},phasename{p},consToCopy{1:modelcons(m)})
        end
    end

end

if run_fmri2ndlvl
    %% 3. Second level analysis
    
    %-------------------------------------------------
    % 3.1 2nd level model specification and estimation
    %-------------------------------------------------
    for m = models
        
        for p = phase
            
            %----------------------------------------------
            % Create explicit mask from subjects' masks
            %----------------------------------------------
            
            seclvlpath = fullfile(fpath,'2ndlevel',modelname{m},phasename{p});
            
            if run_createexplmask
                create_explicitmask(fullfile(seclvlpath,'data','masks'),seclvlpath,subj)
            end
            
            secondlevel_tests(seclvlpath,m,contrasts,printresults)

        end
        
    end

end