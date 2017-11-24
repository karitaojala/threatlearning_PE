function firstlevel_contrasts_axiomatic(subpath,phasename)

%% Initialize variables and folders
modelname = 'Model_Cat_Axiomatic';

% Subject folder names
subj      = dir(subpath);
subj      = {subj(:).name}';
subj(1:2) = [];
subj      = subj(not(cellfun('isempty', strfind(subj,'PR'))));

% Conditions

% CS
nCS = 4; % Number of different CS:
% CS1: p(US+) = 0
% CS2: p(US+) = 1/3
% CS3: p(US+) = 2/3
% CS4: p(US+) = 1

% US
nUS = 6; % Number of different US/outcome conditions:
%USind = [];
% US1: CS1/US-
% US2: CS2/US+
% US3: CS2/US-
% US4: CS3/US+
% US5: CS3/US-
% US6: CS4/US+
    
% Contrast names
% Sanity check contrasts
%   1.  (CS1 CS2 CS3 CS4) - baseline // main effect of CS
%   2.  (US1 US2 US3 US4 US5 US6) - baseline // main effect of US
%   3.  (US2 US4 US6) - (US1 US3 US5) // US+ - US-
%   4.  (US2 US4 US6) - US1 // CS+US+ - CS-US-

% 6 contrasts to test for differences (should see a difference)
%   5.  US3 - US5 // between US- with p(US+) = 1/3 and 2/3
%   6.  US1 - US3 // between US- with p(US+) = 0 and 1/3
%   7.  US4 - US5 // between US+ and US- with p(US+) = 1/3
%   8.  US2 - US3 // between US+ and US- with p(US+) = 2/3
%   9.  US4 - US6 // between US+ with p(US+) = 2/3 and 1
%   10. US2 - US4 // between US+ with p(US+) = 1/3 and 2/3
% 1 contrast to test for equivalence (should not see a difference)
%   11. US6 - US1 // between US+ and US- of certain probability

% Alternative (reduced) contrasts
%   12. (US3 & US5) - (US2 & US4)
%   13. (US5 & US6) - (US1 & US2)

connames = {'Main effect of CS' 'Main effect of US' 'US+ - US-' 'CS+US+ - CS-US-'...
    'CS+(1/3)US- - CS+(2/3)US-' 'CS-(0)US- -CS+(1/3)US-' 'CS+(2/3)US+ - CS+(2/3)US-'...
    'CS+(1/3)US+ - CS+(1/3)US-' 'CS+(2/3)US+ - CS+(1)US+' 'CS+(1/3)US+ - CS+(2/3)US+'...
    'CS+(1)US+ - CS-(0)US-' '(CS+(2/3)US+ & CS+(1/3)US+ - CS+(1/3)US- & CS+(2/3)US-'...
    '(CS-(0)US- & CS+(1/3)US+ - CS+(1)US+ & CS+(2/3)US-'};

no_contr = length(connames); % Number of contrasts

conweights = zeros(nCS+nUS,no_contr); % Initialize a vector of zeros
cn = 1; % Contrast number
% Contrast weights for each contrasts for all conditions (sum up to 0)
conweights(1:4,cn)   =  1;  cn = cn+1;
conweights(5:10,cn)  =  1;  cn = cn+1;
conweights(5,cn)     = -3;  conweights([6 8 10],cn)  =  1; cn = cn+1;
conweights(7,cn)     =  1;  conweights(9,cn)         = -1; cn = cn+1;
conweights(5,cn)     =  1;  conweights(7,cn)         = -1; cn = cn+1;
conweights(8,cn)     =  1;  conweights(9,cn)         = -1; cn = cn+1;
conweights(6,cn)     =  1;  conweights(7,cn)         = -1; cn = cn+1;
conweights(8,cn)     =  1;  conweights(10,cn)        = -1; cn = cn+1;
conweights(6,cn)     =  1;  conweights(8,cn)         = -1; cn = cn+1;
conweights(5,cn)     = -1;  conweights(10,cn)        =  1; cn = cn+1;
conweights([6 8],cn) =  1;  conweights([7 9],cn)     = -1; cn = cn+1;
conweights([5 6],cn) =  1;  conweights([9 10],cn)    = -1;

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
  
    %     copyfile(fullfile(fpath_first_old,'mask.nii'),fullfile(fpath_first));
    %     copyfile(fullfile(fpath_first_old,'ResMS.nii'),fullfile(fpath_first));
    %     copyfile(fullfile(fpath_first_old,'RPV.nii'),fullfile(fpath_first));
    %     copyfile(fullfile(fpath_first_old,'batch_s_First.mat'),fullfile(fpath_first));
    %     copyfile(fullfile(fpath_first_old,'SPM.mat'),fullfile(fpath_first));
    %     copyfile(fullfile(fpath_first_old,'beta*.nii'),fullfile(fpath_first));
    
    %% Create contrasts and matlabbatch for contrast manager:
    
    matlabbatch{1}.spm.stats.con.spmmat = {fullfile(fpath_first, 'SPM.mat')};
    
    for con = 1:no_contr
        
        matlabbatch{1}.spm.stats.con.consess{con}.tcon.name = connames{con};
        matlabbatch{1}.spm.stats.con.consess{con}.tcon.weights = conweights(:,con);
        matlabbatch{1}.spm.stats.con.consess{con}.tcon.sessrep = 'replsc'; % Contrasts are replicated and scaled across runs
        matlabbatch{1}.spm.stats.con.delete = 1;
    
    end

%% Run matlabbatch
    spm('defaults', 'FMRI');
    spm_jobman('initcfg');
    spm_jobman('run', matlabbatch);
    
    save(fullfile(fpath_first,'batch_s_Contrasts'), 'matlabbatch')
end

end