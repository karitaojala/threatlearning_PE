function firstlevel_CSUSconditions_parmod(fpath1,subpath,model,phase)

%% Initialize variables and folders

if model == 1
    modelfile = 'parmod1';
    modelname = 'Model_Par_1';
elseif model == 2
    modelfile = 'parmod1b';
    modelname = 'Model_Par_1b';
elseif model == 3
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
nu_blocks = 6; % All blocks
blocks = 1:nu_blocks;

if phase == 1
    blockname = 'Acq';
    blocks = blocks(1); % Take only first acquisition block
elseif phase == 2
    blockname = 'Maint';
    blocks = blocks(2:5); % Take only maintenance blocks
elseif phase == 3
    blockname = 'Acq2';
    blocks = blocks(6); % Take only last acquisition block
elseif phase == 4
    blockname = 'AllPhases'; % All phases and blocks in the same model
elseif phase == 5
    blockname = 'BothAcq'; % Acquisition phases together
    blocks = blocks([1 6]);
elseif phase == 6
    blockname = 'AllPhases_Scaled'; % All phases and blocks in the same model, scaled according to block length
else
    error('Invalid phase number.')
end

for subInd = 1:length(subj)
    
    clear matlabbatch
        
    fpath = fullfile(subpath, char(subj(subInd)));
    cd(fpath)
    
    fpath_first = fullfile(fpath, modelname, ['First_Level_' blockname]);
    if ~exist(fpath_first, 'dir')
        mkdir(fpath_first)
    end
    
    ini = 4;
    
    % Some exceptions
    if strcmp(char(subj(subInd)), 'PR02010_VF180893_20160803_123831155')
        ini = 5;
    elseif strcmp(char(subj(subInd)), 'PR02011_LF051093_20160803_141032179')
        ini = 5;
    elseif strcmp(char(subj(subInd)), 'PR02118_JM211292_20160922_123539148')
        ini = 7;
    end
    
    % Range of the EPI images, e.g. 4 for the first EPI
    % For every block 3 EPIs
    im_range = ini:3:(ini+3*(nu_blocks-1));
        
    if strcmp(char(subj(subInd)), 'PR02012_MC030192_20160803_164430287')
        im_range = [4 7 10 13 16 22];
    elseif strcmp(char(subj(subInd)), 'PR02013_MR211196_20160803_181918050')
        im_range = [4 10 13 16 19 22];
    elseif strcmp(char(subj(subInd)), 'PR02275_MS180294_20161206_135417812')
        im_range = [4 7 10 13 19 22];
    end
    
    Reg_Block = []; %block regressor

    %% Specify 1st level model
    si = 0; % Session index for matlabbatch
    
    for i = blocks %length(im_range)
        
        clear co1 co2 ll EPI
        
        si = si + 1;
        
        % Volume number for the current block
        r = num2str(im_range(i));
        if length(r) < 2
            r = ['0', r];
        end
        
        % EPI files
        EPIpath = fullfile(fpath,'EPI\');
        cd(EPIpath)
        EPI.epiFiles = spm_vol(spm_select('ExtList',fullfile(fpath,'EPI'),['^swuabc2.*0',r,'a001.nii$'])); % Bias corrected EPIs
        
        for kk = 1:size(EPI.epiFiles,1)
            ll{kk} = [EPI.epiFiles(kk).fname, ',',num2str(kk)];
        end
        
        % Text files, motion correction
        head_f = ls([EPIpath, '*abc*', r, 'a001.txt']); % Bias corrected
        
        disp(['...Block ' num2str(i), ' out of ' num2str(length(im_range)), '. Found ', num2str(kk), ' EPIs...' ])
        disp(['Found ', num2str(size(head_f,1)), ' head motion correction file(s).'])
        disp('................................')
      
        % Conditions
        % -----------------------------------------------------------------
        
%         disp(['Found ', num2str(sum(co1)), ' CS and ', num2str(sum(co2)), ' US events.'])
        condfile = [fpath1, 'Behavior\S', num2str(subj_beh(subInd)), '\S', num2str(subj_beh(subInd)) '_block' num2str(i) '_CSUSconds_' modelfile '.mat'];
        
        matlabbatch{1}.spm.stats.fmri_spec.sess(si).scans = ll';
        matlabbatch{1}.spm.stats.fmri_spec.sess(si).cond = struct('name', {}, 'onset', {}, 'duration', {}, 'tmod', {}, 'pmod', {}, 'orth', {});
        matlabbatch{1}.spm.stats.fmri_spec.sess(si).multi = {condfile};
        matlabbatch{1}.spm.stats.fmri_spec.sess(si).regress = struct('name', {}, 'val', {});
        matlabbatch{1}.spm.stats.fmri_spec.sess(si).multi_reg = {[EPIpath, head_f]};
        matlabbatch{1}.spm.stats.fmri_spec.sess(si).hpf = 128;
        
    end
     
    matlabbatch{1}.spm.stats.fmri_spec.dir = {fpath_first};
    matlabbatch{1}.spm.stats.fmri_spec.timing.units = 'secs';
    matlabbatch{1}.spm.stats.fmri_spec.timing.RT = 3.2;
    matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t = 40; % 16
    matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0 = 20; % 8
    
    matlabbatch{1}.spm.stats.fmri_spec.fact = struct('name', {}, 'levels', {});
    matlabbatch{1}.spm.stats.fmri_spec.bases.hrf.derivs = [0 0];
    matlabbatch{1}.spm.stats.fmri_spec.volt = 1;
    matlabbatch{1}.spm.stats.fmri_spec.global = 'None';
    matlabbatch{1}.spm.stats.fmri_spec.mthresh = 0.8;
    matlabbatch{1}.spm.stats.fmri_spec.mask = {''};
    matlabbatch{1}.spm.stats.fmri_spec.cvi = 'FAST';
    
    %% Estimate 1st level model
    matlabbatch{2}.spm.stats.fmri_est.spmmat = {[fpath_first, 'SPM.mat']};
    matlabbatch{2}.spm.stats.fmri_est.write_residuals = 0;
    matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;
    
%% Run matlabbatch
    spm('defaults', 'FMRI');
    spm_jobman('initcfg');
    spm_jobman('run', matlabbatch);
    
    save(fullfile(fpath_first,'batch_s_First'), 'matlabbatch')
    
end

end