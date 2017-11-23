function firstlevel_CSUSconditions_parmod(fpath1,subpath,model,phase,noisecorr)

%% Initialize variables and folders

if model == 2
    modelfile = 'parmod1'; % In the behavioural file name
    modelname = 'Model_Par_1'; % Model folder name
elseif model == 3
    modelfile = 'parmod1b';
    modelname = 'Model_Par_1b';
elseif model == 4
    modelfile = 'parmod2Bayes2';
    modelname = 'Model_Par_2';
else
    error('Invalid model number.')
end    

% Subject folder names    
subj      = dir(subpath);
subj      = {subj(:).name}';
subj(1:2) = [];
subj      = subj(not(cellfun('isempty', strfind(subj,'PR'))));

% List of subject numbers for behavioural files
subj_beh  = [155 159:162 164:167 169:177 179:182];

% Number of blocks
no_runs = 6; % All blocks
runs = 1:no_runs;

% Phase information
if phase == 1
    phasename = 'Acq';
    runs = runs(1); % Take only first acquisition block
elseif phase == 2
    phasename = 'Maint';
    runs = runs(2:5); % Take only maintenance blocks
elseif phase == 3
    phasename = 'Acq2';
    runs = runs(6); % Take only last acquisition block
elseif phase == 4
    phasename = 'AllPhases'; % All phases and blocks in the same model
elseif phase == 5
    phasename = 'BothAcq'; % Acquisition phases together
    runs = runs([1 6]);
elseif phase == 6
    phasename = 'AllPhases_Scaled'; % All phases and blocks in the same model, scaled according to block length
else
    error('Invalid phase number.')
end

% Loop over subjects (1st level analysis for each subject separately)
for subInd = 1:length(subj)
    
    clear matlabbatch
    
    % Subject's path
    fpath = fullfile(subpath, char(subj(subInd)));
    cd(fpath)
    
    % 1st level path
    fpath_first = fullfile(fpath, modelname, ['First_Level_' phasename]);
    
    % Create the folder if does not exist
    if ~exist(fpath_first, 'dir')
        mkdir(fpath_first)
    end
    
    % Range of images for EPIs (in the the file name)
    im_range = getImageRange(subj(subInd));

    %% Specify 1st level model
    sesi = 0; % Session (phase) index for matlabbatch
    
    for run = runs
        
        clear EPI episcans
        
        sesi = sesi + 1; % Increase session number
        
        % Volume number for the current block
        volno = num2str(im_range(run));
        if length(volno) < 2
            volno = ['0' volno]; %#ok<AGROW>
        end
        
        % Select EPI files
        EPIpath = fullfile(fpath,'EPI');
        cd(EPIpath)
        EPI.epiFiles = spm_vol(spm_select('ExtList',fullfile(fpath,'EPI'),['^swuabc2.*0',volno,'a001.nii$'])); % Bias corrected EPIs
        
        for epino = 1:size(EPI.epiFiles,1)
            episcans{epino} = [EPI.epiFiles(epino).fname, ',',num2str(epino)]; %#ok<AGROW>
        end
        
        % Noise correction files
        if noisecorr == 1 % Only head motion
            noisefile = ls([EPIpath, '*abc*', volno, 'a001.txt']); % Bias corrected
        elseif noisecorr == 2 % RETROICOR
            noisefile = ls([EPIpath, 'multiple_regressors_session', num2str(run), '.txt']); % CHECK THAT CORRECT
        elseif noisecorr == 3 % Full PhysIO
            noisefile = ls([EPIpath, 'multiple_regressors_session', num2str(run), '.txt']);
        end
        
        disp(['...Run ' num2str(run), ' out of ' num2str(length(im_range)), '. Found ', num2str(epino), ' EPIs...' ])
        disp(['Found ', num2str(size(noisefile,1)), ' noise correction file(s).'])
        disp('................................')
      
        % Conditions
        % -----------------------------------------------------------------
        % Multiple conditions file created with preparebehav
        condfile = fullfile(fpath1, 'Behavior', ['S' num2str(subj_beh(subInd))], ['S' num2str(subj_beh(subInd)) '_block' num2str(run) '_CSUSconds_' modelfile '.mat']);
        
        % Matlabbatch
        matlabbatch{1}.spm.stats.fmri_spec.sess(sesi).scans = episcans';
        matlabbatch{1}.spm.stats.fmri_spec.sess(sesi).cond = struct('name', {}, 'onset', {}, 'duration', {}, 'tmod', {}, 'pmod', {}, 'orth', {});
        matlabbatch{1}.spm.stats.fmri_spec.sess(sesi).multi = {condfile};
        matlabbatch{1}.spm.stats.fmri_spec.sess(sesi).regress = struct('name', {}, 'val', {});
        matlabbatch{1}.spm.stats.fmri_spec.sess(sesi).multi_reg = {fullfile(EPIpath, noisefile)};
        matlabbatch{1}.spm.stats.fmri_spec.sess(sesi).hpf = 128;
        
    end
     
    matlabbatch{1}.spm.stats.fmri_spec.dir = {fpath_first};
    matlabbatch{1}.spm.stats.fmri_spec.timing.units = 'secs';
    matlabbatch{1}.spm.stats.fmri_spec.timing.RT = 3.2;
    matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t = 40;
    matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0 = 20;
    
    matlabbatch{1}.spm.stats.fmri_spec.fact = struct('name', {}, 'levels', {});
    matlabbatch{1}.spm.stats.fmri_spec.bases.hrf.derivs = [0 0];
    matlabbatch{1}.spm.stats.fmri_spec.volt = 1;
    matlabbatch{1}.spm.stats.fmri_spec.global = 'None';
    matlabbatch{1}.spm.stats.fmri_spec.mthresh = 0.8;
    matlabbatch{1}.spm.stats.fmri_spec.mask = {''};
    matlabbatch{1}.spm.stats.fmri_spec.cvi = 'FAST';
    
    %% Estimate 1st level model
    matlabbatch{2}.spm.stats.fmri_est.spmmat = {fullfile(fpath_first, 'SPM.mat')};
    matlabbatch{2}.spm.stats.fmri_est.write_residuals = 0;
    matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;
    
    %% Run matlabbatch
    spm('defaults', 'FMRI');
    spm_jobman('initcfg');
    spm_jobman('run', matlabbatch);
    
    save(fullfile(fpath_first,'batch_s_First'), 'matlabbatch')
    
end

end