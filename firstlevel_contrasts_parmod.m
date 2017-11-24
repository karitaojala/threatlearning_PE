function firstlevel_contrasts_parmod(subpath,model,phasename)

%% Initialize variables and folders

% Set model name and number of condition and parametric regressors
cond_CS = 1;
cond_US = 1;
    
if model == 2 % Simple prediction error model
    modelname = 'Model_Par_1';
    pmod_CS = 1; % Parametric modulators of CS activity
    pmod_US = 2; % Parametric modulators of US activity
    connames = {'Unmodulated effect of CS' 'Effect of p(shock)' 'Unmodulated effect of US'...
        'Effect of US type' 'Effect of prediction error'};
    
elseif model == 3 % Prediction error model with expectation from the Bayesian model
    modelname = 'Model_Par_1b';
    pmod_CS = 1;
    pmod_US = 2;
    connames = {'Unmodulated effect of CS' 'Effect of expected p(shock)' 'Unmodulated effect of US'...
        'Effect of US type' 'Effect of prediction error (Bayesian)'};
    
elseif model == 4 % Bayesian learning model
    modelname = 'Model_Par_2';
    pmod_CS = 5;
    pmod_US = 3;
    connames = {'Unmodulated effect of CS' 'Effect of expected p(shock)' 'Effect of volatility'...
        'Effect of prior entropy p(shock)' 'KL div prior-posterior previous trial'...
        'Surprise on US previous trial' 'Unmodulated effect of US' 'Effect of US type'...
        'KL div prior-posterior current trial' 'Surprise on US current trial'};

else
    error('Invalid model number.')
end

% Total number of contrasts
no_contr = cond_CS + cond_US + pmod_CS + pmod_US;

% Subject folder names
subj      = dir(subpath);
subj      = {subj(:).name}';
subj(1:2) = [];
subj      = subj(not(cellfun('isempty', strfind(subj,'PR'))));

for subInd = 1:length(subj)
    
    clear matlabbatch
    
    fpath = fullfile(subpath, char(subj(subInd)));
    cd(fpath)
    
    fpath_first = fullfile(fpath, modelname, ['First_Level_' phasename]);
    if ~exist(fpath_first, 'dir')
        mkdir(fpath_first)
    end
    
    %% Create contrasts and matlabbatch for contrast manager:
    
    matlabbatch{1}.spm.stats.con.spmmat = {fullfile(fpath_first, 'SPM.mat')};
    
    for con = 1:no_contr
        
        conweights = zeros(no_contr,1);
        conweights(con) = 1;
        
        matlabbatch{1}.spm.stats.con.consess{con}.tcon.name = connames{con};
        matlabbatch{1}.spm.stats.con.consess{con}.tcon.weights = conweights;
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