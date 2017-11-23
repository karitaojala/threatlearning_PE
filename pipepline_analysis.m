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
% 1 = Axiomatic approach
% 2 = Simple prediction error model
% 3 = Prediction error model with expected p(shock) from the Bayesian model
% 4 = Bayesian learning model

%% Behaviour
%-------------------------------------------------------------------------
if run_behav
    subj_beh = [155 159:162 164:167 169:177 179:182]; %#ok<UNRCH>
    Behavior_PFC_fMRI(fpath,subj_beh)
    checkLearning
end

%% Psychophysiological data
%-------------------------------------------------------------------------
if run_createphysioreg
    % PhysIO toolbox modelling psychophysiological noise
    % Create a nuisance regressor file for SPM fMRI analysis
    % 155 included in the fMRI analysis sample but no physio file
    physio_subj = [159:162 164:167 169:177 179:182]; %#ok<UNRCH>
    % 157, 168 and 178 out because not included in the fMRI sample
    physiopath = fullfile(mainpath,'PhysioRegressors');
    MRI_subj = subj;
    CreatePhysioRegressors(fpath,physiopath,MRI_subj,physio_subj)
end

%% fMRI
%-------------------------------------------------------------------------

if run_unzipnii
    % Need DICOM to NIFTI converted files for unzipping
    unzip_niftiis(fpath,subj) %#ok<UNRCH>
end

if run_fmripreproc
    %% 1. Preprocessing
    
    %---------------------------------------------------
    % 1.1 Combine multiple echoes of an fMRI time series
    %---------------------------------------------------
    EchoCombine(fpath,cellstr(subj)) %#ok<UNRCH>
    
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
    
    %% Model specification and estimation
    
    if run_preparebehav %#ok<UNRCH>
        % Create multiple conditions files for parametric models
        prepare_behav
    end
    
    for p = phase
        
        for m = models
            if m == 1 % Axiomatic categorical model
                firstlevel_CSUSconditions_physcorr(p)
            else % Parametric models
                firstlevel_CSUSconditions_parmod(mainpath,fpath,m,p,noisecorr)
            end
        end
        
        %------------------------
        % 2.2 1st level contrasts
        %------------------------
        
        for m = models
            if m == 1
                firstlevel_axiomcontrasts_forconjunction(fpath,p,nNoiseReg)
            else
                firstlevel_contrasts_parmod(fpath,phasename{p})
            end
        end
        
    end

end
%-----------------------------
% 2.3 Copy contrasts and masks
%-----------------------------
% To 2nd level data folder

modelname1 = 'Model_Cat_Axiomatic';
consToCopy1 = {'con_0001.nii','con_0002.nii','con_0003.nii','con_0004.nii','con_0005.nii','con_0006.nii','con_0007.nii','con_0008.nii','con_0009.nii','con_0010.nii','con_0011.nii','con_0012.nii','con_0013.nii'};

modelname2 = 'Model_Par_1';
consToCopy2 = {'con_0001.nii','con_0002.nii','con_0003.nii','con_0004.nii','con_0005.nii'};

modelname3 = 'Model_Par_1b';
consToCopy3 = {'con_0001.nii','con_0002.nii','con_0003.nii','con_0004.nii','con_0005.nii'};

modelname4 = 'Model_Par_2';
consToCopy4 = {'con_0001.nii','con_0002.nii','con_0003.nii','con_0004.nii','con_0005.nii','con_0006.nii','con_0007.nii','con_0008.nii','con_0009.nii','con_0010.nii'};

for p = 2%phase
    copy_contrasts(fpath,subj,modelname1,phasename{p},consToCopy1)
    cd(codepath)
    copy_contrasts(fpath,subj,modelname2,phasename{p},consToCopy2)
    cd(codepath)
    copy_contrasts(fpath,subj,modelname3,phasename{p},consToCopy3)
    cd(codepath)
    copy_contrasts(fpath,subj,modelname4,phasename{p},consToCopy4)
    cd(codepath)
end

%% 4. Second level analysis
%-------------------------------------------------------------------------

% phasename = {'Acq','Maint','Acq2','AllPhases','BothAcq'};
for p = 2%phase
    
    % NOT USED:
    % Create explicit mask for 2nd lvl from all subjects' individual masks
    %create_explicitmask(fullfile(seclvlpath,'data','masks'),seclvlpath,subj)
    
    %-------------------------------------------------
    % 4.1 2nd level model specification and estimation
    %-------------------------------------------------
    % 1-sample t-test
    % Input: 2nd level folder, model name (folder), contrast number
        
    %% Axiomatic approach
    % Define folder path
    seclvlpath = fullfile(fpath,'2ndlevel',modelname1,phasename{p});
    % ------------------
    % Sanity check tests
    % ------------------
    contrasts = 1;
    
    % 1. Main effect of CS
    secondlevel_1sttest(seclvlpath,'1sttest_sancheck1_CS','01',{'CS > baseline'});
    resultsreport(fullfile(seclvlpath,'1sttest_sancheck1_CS'),contrasts)
    cd(codepath)
    
    % 2. Main effect of US
    secondlevel_1sttest(seclvlpath,'1sttest_sancheck2_US','02',{'US > baseline'});
    resultsreport(fullfile(seclvlpath,'1sttest_sancheck2_US'),contrasts)
    cd(codepath)
    
    % --------------------
    % Conjunction analysis
    % --------------------
    
    % Positive prediction error (2 contrasts)
    conjname = 'conjunction_axioms_posPE';
    connames = {'1sttest_ax5_CS3USp-CS4USp' '1sttest_ax6_CS2USp-CS3USp'};
    actualnames = {'CS3US+ > CS4US+' 'CS2US+ > CS3US+'};
    connums = {'09' '10'};
    secondlevel_1wayanova_forconj(seclvlpath,connames,connums,conjname,actualnames);
    cd(codepath)
    
    % Negative prediction error (2 contrasts)
    conjname = 'conjunction_axioms_negPE';
    connames = {'1sttest_ax1_CS2USm-CS3USm' '1sttest_ax2_CS1USm-CS2USm'};
    actualnames = {'CS2US- > CS3US-' 'CS1US- > CS2US-'};
    connums = {'05' '06'};
    secondlevel_1wayanova_forconj(seclvlpath,connames,connums,conjname,actualnames);
    cd(codepath)
    
    % 1. Full model (6 contrasts)
    conjname = 'conjunction_axioms12_6cons';
    connames = {'1sttest_ax1_CS2USm-CS3USm' '1sttest_ax2_CS1USm-CS2USm' '1sttest_ax3_CS3USp-CS3USm' '1sttest_ax4_CS2USp-CS2USm' '1sttest_ax5_CS3USp-CS4USp' '1sttest_ax6_CS2USp-CS3USp'};
    actualnames = {'CS2US- > CS3US-' 'CS1US- > CS2US-' 'CS3US+ > CS3US-' 'CS2US+ > CS2US-' 'CS3US+ > CS4US+' 'CS2US+ > CS3US+'};
    connums = {'05' '06' '07' '08' '09' '10'};
    secondlevel_1wayanova_forconj(seclvlpath,connames,connums,conjname,actualnames);
    cd(codepath)
    
    % Unsigned prediction error (4 contrasts)
    conjname = 'conjunction_axioms_unsignedPE';
    connames = {'1sttest_ax1_CS3USm-CS2USm' '1sttest_ax2_CS2USm-CS1USm' '1sttest_ax5_CS3USp-CS4USp' '1sttest_ax6_CS2USp-CS3USp'};
    actualnames = {'CS3US- > CS2US-' 'CS2US- > CS1US-' 'CS3US+ > CS4US+' 'CS2US+ > CS3US+'};
    connums = {'05' '06' '09' '10'};
    secondlevel_1wayanova_forconj(seclvlpath,connames,connums,conjname,actualnames);
    cd(codepath)
    
    %% Parametric Model 1
    % Define folder path
    seclvlpath = fullfile(fpath,'2ndlevel',modelname2,phasename{p});
    % Contrasts: [1]
    contrasts = 1;
    
    % 1. Unmodulated effect of CS
    secondlevel_1sttest(seclvlpath,'1sttest_unmod_CS','01',{'Unmodulated effect of CS'});
    resultsreport(fullfile(seclvlpath,'1sttest_unmod_CS'),contrasts)
    cd(codepath)
    
    % 2. Effect of p(shock)
    secondlevel_1sttest(seclvlpath,'1sttest_parmod_CS_pshock','02',{'Effect of p(shock)'});
    resultsreport(fullfile(seclvlpath,'1sttest_parmod_CS_pshock'),contrasts)
    cd(codepath)
    
    % 3. Unmodulated effect of US
    secondlevel_1sttest(seclvlpath,'1sttest_unmod_US','03',{'Unmodulated effect of US'});
    resultsreport(fullfile(seclvlpath,'1sttest_unmod_US'),contrasts)
    cd(codepath)
    
    % 4. Effect of US type
    secondlevel_1sttest(seclvlpath,'1sttest_parmod_US_type','04',{'Effect of US type'});
    resultsreport(fullfile(seclvlpath,'1sttest_parmod_US_type'),contrasts)
    cd(codepath)
    
    % 5. Effect of prediction error
    secondlevel_1sttest(seclvlpath,'1sttest_parmod_US_PE','05',{'Prediction error'});
    resultsreport(fullfile(seclvlpath,'1sttest_parmod_US_PE'),contrasts)
    cd(codepath)
    

    %% Parametric Model 1b
    % Define folder path
    seclvlpath = fullfile(fpath,'2ndlevel',modelname3,phasename{p});
    % Contrasts: [1]
    contrasts = 1;
    
    % 1. Unmodulated effect of CS
    secondlevel_1sttest(seclvlpath,'1sttest_unmod_CS','01',{'Unmodulated effect of CS'});
    resultsreport(fullfile(seclvlpath,'1sttest_unmod_CS'),contrasts)
    cd(codepath)
    
    % 2. Effect of p(shock)
    secondlevel_1sttest(seclvlpath,'1sttest_parmod_CS_exptpshock','02',{'Effect of Expected p(shock)'});
    resultsreport(fullfile(seclvlpath,'1sttest_parmod_CS_exptpshock'),contrasts)
    cd(codepath)
    
    % 3. Unmodulated effect of US
    secondlevel_1sttest(seclvlpath,'1sttest_unmod_US','03',{'Unmodulated effect of US'});
    resultsreport(fullfile(seclvlpath,'1sttest_unmod_US'),contrasts)
    cd(codepath)
    
    % 4. Effect of US type
    secondlevel_1sttest(seclvlpath,'1sttest_parmod_US_type','04',{'Effect of US type'});
    resultsreport(fullfile(seclvlpath,'1sttest_parmod_US_type'),contrasts)
    cd(codepath)
    
    % 5. Effect of Bayesian prediction error
    secondlevel_1sttest(seclvlpath,'1sttest_parmod_US_BayesPE','05',{'Bayesian prediction error'});
    resultsreport(fullfile(seclvlpath,'1sttest_parmod_US_BayesPE'),contrasts)
    cd(codepath)
    
    %% Parametric Model 2 (version 2 with volatility)
    % Define folder path
    seclvlpath = fullfile(fpath,'2ndlevel',modelname4,phasename{p});
    % Contrasts: [1]
    contrasts = 1;
    
    % 1. Unmodulated effect of CS
    secondlevel_1sttest(seclvlpath,'1sttest_unmod_CS','01',{'Unmodulated effect of CS'});
    resultsreport(fullfile(seclvlpath,'1sttest_unmod_CS'),contrasts)
    cd(codepath)
    
    % 2. Expected p(shock)
    secondlevel_1sttest(seclvlpath,'1sttest_parmod_CS_exptpshock','02',{'Expected p(shock)'});
    resultsreport(fullfile(seclvlpath,'1sttest_parmod_CS_exptpshock'),contrasts)
    cd(codepath)
    
    % 3. Volatility
    secondlevel_1sttest(seclvlpath,'1sttest_parmod_CS_volatility','03',{'Volatility'});
    resultsreport(fullfile(seclvlpath,'1sttest_parmod_CS_volatility'),contrasts)
    cd(codepath)
    
    % 4. Prior entropy p(shock)
    secondlevel_1sttest(seclvlpath,'1sttest_parmod_CS_priorentrpypshock','04',{'Prior entropy p(shock)'});
    resultsreport(fullfile(seclvlpath,'1sttest_parmod_CS_priorentrpypshock'),contrasts)
    cd(codepath)
    
    % 5. KL divergence prior-posterior from previous trial
    secondlevel_1sttest(seclvlpath,'1sttest_parmod_CS_KLdivprevtrial','05',{'KL div prev trial'});
    resultsreport(fullfile(seclvlpath,'1sttest_parmod_CS_KLdivprevtrial'),contrasts)
    cd(codepath)
    
    % 6. Suprise about US from previous trial
    secondlevel_1sttest(seclvlpath,'1sttest_parmod_CS_surprUSprevtrial','06',{'Surpr US prev trial'});
    resultsreport(fullfile(seclvlpath,'1sttest_parmod_CS_surprUSprevtrial'),contrasts)
    cd(codepath)
    
    % 7. Unmodulated effect of US
    secondlevel_1sttest(seclvlpath,'1sttest_unmod_US','07',{'Unmodulated effect of US'});
    resultsreport(fullfile(seclvlpath,'1sttest_unmod_US'),contrasts)
    cd(codepath)
    
    % 8. US type
    secondlevel_1sttest(seclvlpath,'1sttest_parmod_US_type','08',{'US type'});
    resultsreport(fullfile(seclvlpath,'1sttest_parmod_US_type'),contrasts)
    cd(codepath)
    
    % 9. KL divergence prior-posterior for current trial
    secondlevel_1sttest(seclvlpath,'1sttest_parmod_US_KLdivcurrtrial','09',{'KL div curr trial'});
    resultsreport(fullfile(seclvlpath,'1sttest_parmod_US_KLdivcurrtrial'),contrasts)
    cd(codepath)
    
    % 10. Suprise about US from previous trial
    secondlevel_1sttest(seclvlpath,'1sttest_parmod_CS_surprUScurrtrial','10',{'Surpr US curr trial'});
    resultsreport(fullfile(seclvlpath,'1sttest_parmod_US_surprUScurrtrial'),contrasts)
    cd(codepath)

end
%end