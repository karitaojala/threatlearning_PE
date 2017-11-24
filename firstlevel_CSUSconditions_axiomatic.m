function firstlevel_CSUSconditions_axiomatic(fpath1,subpath,phase,noisecorr)

%% Initialize variables and folders
modelname = 'Model_Cat_Axiomatic';

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

if phase == 1
    phasename = 'Acq';
    runs = runs(1); % Take only first acquisition block
elseif phase == 2
    phasename = 'Maint';
    runs = runs(2:5); % Take only maintenance blocks
elseif phase == 3
    phasename = 'Acq2';
    runs = runs(6); % Take only last acquisition block
% elseif phase == 4 % WILL NOT RUN YET WITH DIFFERENT NO OF TRIALS PER BLOCK
%     blockname = 'AllPhases'; % All phases and blocks in the same model
% elseif phase == 5
%     blockname = 'BothAcq'; % Acquisition phases together
%     blocks = blocks([1 6]);
else
    error('Session number invalid.')
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
    sesi = 0; % Session index for matlabbatch
    
    % Load behavioural file with timings
    bhvdata = load(fullfile(fpath1, 'Behavior', ['S' num2str(subj_beh(subInd))], ['Behavior_S', num2str(subj_beh(subInd))]),'cond','tim');
    
    % Condition onset times and types
    for n = 1:length(runs)
        CS_on(:,n) = bhvdata.tim(runs(n)).CS_on; %#ok<*AGROW>
        US_on(:,n) = bhvdata.tim(runs(n)).US_on;
        CS_type(:,n) = bhvdata.cond(runs(n)).CS;
        US_type(:,n) = bhvdata.cond(runs(n)).US;
    end
    
    for run = runs
        
        clear EPI episcans co1 co2
        
        sesi = sesi + 1;
        
        % Volume number for the current block
        volno = num2str(im_range(run));
        if length(volno) < 2
            volno = ['0' volno];
        end
        
        % Select EPI files
        EPIpath = fullfile(fpath,'EPI');
        cd(EPIpath)
        EPI.epiFiles = spm_vol(spm_select('ExtList',fullfile(fpath,'EPI'),['^swuabc2.*0',volno,'a001.nii$'])); % Bias corrected EPIs
        
        for epino = 1:size(EPI.epiFiles,1)
            episcans{epino} = [EPI.epiFiles(epino).fname, ',',num2str(epino)];
        end
        
        % Noise correction files
        if noisecorr == 1 % Only head motion
            noisefile = ls([EPIpath, '*abc*', volno, 'a001.txt']); % Bias corrected
        elseif noisecorr == 2 % RETROICOR
            noisefile = ls([EPIpath, 'multiple_regressors_session', num2str(run), '.txt']); % CHECK THAT CORRECT
        elseif noisecorr == 3 % Full PhysIO
            noisefile = ls([EPIpath, 'multiple_regressors_session', num2str(run), '.txt']);
        end
        
        disp(['...Block ' num2str(run), ' out of ' num2str(length(im_range)), '. Found ', num2str(kk), ' EPIs...' ])
        disp(['Found ', num2str(size(noisefile,1)), ' noise correction file(s).'])
        disp('................................')
      
        % Conditions
        % -----------------------------------------------------------------
        
        SR = 1000; % Sampling rate
        
        % Find CS events and create conditions:
        nCS = 4; % Number of different CS:
        % CS1: p(US+) = 0
        % CS2: p(US+) = 1/3
        % CS3: p(US+) = 2/3
        % CS4: p(US+) = 1
        
        % CS onsets and types for the current run
        CS_on_blk = CS_on(:,sesi);
        CS_type_blk = CS_type(:,sesi);
        
        if run == 6
            
            for c = 1:nCS
                
                matlabbatch{1}.spm.stats.fmri_spec.sess(sesi).cond(c).name = ['CS', num2str(c)];
                matlabbatch{1}.spm.stats.fmri_spec.sess(sesi).cond(c).onset = CS_on_blk(CS_type_blk == (c+4))/SR; % For Acq2 phase
                matlabbatch{1}.spm.stats.fmri_spec.sess(sesi).cond(c).duration = 0;
                matlabbatch{1}.spm.stats.fmri_spec.sess(sesi).cond(c).tmod = 0;
                matlabbatch{1}.spm.stats.fmri_spec.sess(sesi).cond(c).pmod = struct('name', {}, 'param', {}, 'poly', {});
                matlabbatch{1}.spm.stats.fmri_spec.sess(sesi).cond(c).orth = 1;
                
                co1(c) = length(CS_on_blk(CS_type_blk == (c+4))/SR); % Number of events found
                
            end
            
        else
            
            for c = 1:nCS
                
                matlabbatch{1}.spm.stats.fmri_spec.sess(sesi).cond(c).name = ['CS', num2str(c)];
                matlabbatch{1}.spm.stats.fmri_spec.sess(sesi).cond(c).onset = CS_on_blk(CS_type_blk == (c))/SR;
                matlabbatch{1}.spm.stats.fmri_spec.sess(sesi).cond(c).duration = 0;
                matlabbatch{1}.spm.stats.fmri_spec.sess(sesi).cond(c).tmod = 0;
                matlabbatch{1}.spm.stats.fmri_spec.sess(sesi).cond(c).pmod = struct('name', {}, 'param', {}, 'poly', {});
                matlabbatch{1}.spm.stats.fmri_spec.sess(sesi).cond(c).orth = 1;
                
                co1(c) = length(CS_on_blk(CS_type_blk == (c))/SR); % Number of events found
                
            end
            
        end
        
        % Find US events and create conditions:
        nUS = 6; % Number of different US/outcome conditions:
        
        % US onsets and types for the current run
        US_on_blk = US_on(:,sesi);
        US_type_blk = US_type(:,sesi);
        
        if run == 6 % Acquisition 2, different numbers for CS types
            
            % US1: CS1/US-
            USind{1,:} = find((CS_type_blk == 6) & (US_type_blk == 0));
            % US2: CS2/US+
            USind{2,:} = find((CS_type_blk == 7) & (US_type_blk == 1));
            % US3: CS2/US-
            USind{3,:} = find((CS_type_blk == 7) & (US_type_blk == 0));
            % US4: CS3/US+
            USind{4,:} = find((CS_type_blk == 8) & (US_type_blk == 1));
            % US5: CS3/US-
            USind{5,:} = find((CS_type_blk == 8) & (US_type_blk == 0));
            % US6: CS4/US+
            USind{6,:} = find((CS_type_blk == 5) & (US_type_blk == 1));
            
        else
            
            % US1: CS1/US-
            USind{1,:} = find((CS_type_blk == 1) & (US_type_blk == 0));
            % US2: CS2/US+
            USind{2,:} = find((CS_type_blk == 2) & (US_type_blk == 1));
            % US3: CS2/US-
            USind{3,:} = find((CS_type_blk == 2) & (US_type_blk == 0));
            % US4: CS3/US+
            USind{4,:} = find((CS_type_blk == 3) & (US_type_blk == 1));
            % US5: CS3/US-
            USind{5,:} = find((CS_type_blk == 3) & (US_type_blk == 0));
            % US6: CS4/US+
            USind{6,:} = find((CS_type_blk == 4) & (US_type_blk == 1));
        
        end
        
        for c = 1:nUS
            
            matlabbatch{1}.spm.stats.fmri_spec.sess(sesi).cond(c+nCS).name = ['US', num2str(c)];
            matlabbatch{1}.spm.stats.fmri_spec.sess(sesi).cond(c+nCS).onset = US_on_blk(USind{c})/SR;
            matlabbatch{1}.spm.stats.fmri_spec.sess(sesi).cond(c+nCS).duration = 0;
            matlabbatch{1}.spm.stats.fmri_spec.sess(sesi).cond(c+nCS).tmod = 0;
            matlabbatch{1}.spm.stats.fmri_spec.sess(sesi).cond(c+nCS).pmod = struct('name', {}, 'param', {}, 'poly', {});
            matlabbatch{1}.spm.stats.fmri_spec.sess(sesi).cond(c+nCS).orth = 1;
            
            co2(c) = length(US_on_blk(USind{c})/SR); % Number of events found
            
        end
        
        disp(['Found ', num2str(sum(co1)), ' CS and ', num2str(sum(co2)), ' US events.'])
        disp(['Found ', num2str(size(noisefile,1)), ' noise correction file(s).'])
        disp('................................')
        
        matlabbatch{1}.spm.stats.fmri_spec.sess(sesi).scans = episcans';
        matlabbatch{1}.spm.stats.fmri_spec.sess(sesi).multi = {''};
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
    matlabbatch{1}.spm.stats.fmri_spec.mthresh = 0.5; % Original 0.8
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

%end