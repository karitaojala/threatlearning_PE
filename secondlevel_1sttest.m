function secondlevel_1sttest(fpath,contrastname,contrastno,actualname,printresults)

%% 2nd level model specification
matlabbatch{1}.spm.stats.factorial_design.dir = {fullfile(fpath,contrastname)};
matlabbatch{1}.spm.stats.factorial_design.des.t1.scans = cellstr(spm_select('ExtFPList',fullfile(fpath,'data','contrasts'),['con_00' contrastno '.*.nii$'],1));
matlabbatch{1}.spm.stats.factorial_design.cov = struct('c', {}, 'cname', {}, 'iCFI', {}, 'iCC', {});
matlabbatch{1}.spm.stats.factorial_design.multi_cov = struct('files', {}, 'iCFI', {}, 'iCC', {});
matlabbatch{1}.spm.stats.factorial_design.masking.tm.tm_none = 1;
matlabbatch{1}.spm.stats.factorial_design.masking.im = 1;
matlabbatch{1}.spm.stats.factorial_design.masking.em = {''}; %cellstr(spm_select('ExtFPList',fullfile(fpath),'explicitmask.nii$',1));
matlabbatch{1}.spm.stats.factorial_design.globalc.g_omit = 1;
matlabbatch{1}.spm.stats.factorial_design.globalm.gmsca.gmsca_no = 1;
matlabbatch{1}.spm.stats.factorial_design.globalm.glonorm = 1;

%% 2nd level model estimation
matlabbatch{2}.spm.stats.fmri_est.spmmat(1) = cellstr(fullfile(fpath,contrastname,'SPM.mat'));
matlabbatch{2}.spm.stats.fmri_est.write_residuals = 0;
matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;

%% Contrasts
matlabbatch{3}.spm.stats.con.spmmat = {fullfile(fpath,contrastname,'SPM.mat')};
matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = actualname{1};
matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = 1;
matlabbatch{3}.spm.stats.con.consess{1}.tcon.sessrep = 'none';
matlabbatch{3}.spm.stats.con.delete = 1;

%% Print results
if printresults == 1
    matlabbatch{4}.spm.stats.results.spmmat = {fullfile(fpath,contrastname,'SPM.mat')};
    matlabbatch{4}.spm.stats.results.conspec.titlestr = '';
    matlabbatch{4}.spm.stats.results.conspec.contrasts = Inf;
    matlabbatch{4}.spm.stats.results.conspec.threshdesc = 'none';
    matlabbatch{4}.spm.stats.results.conspec.thresh = 0.001;
    matlabbatch{4}.spm.stats.results.conspec.extent = 0;
    matlabbatch{4}.spm.stats.results.conspec.conjunction = 1;
    matlabbatch{4}.spm.stats.results.conspec.mask.none = 1;
    matlabbatch{4}.spm.stats.results.units = 1;
    matlabbatch{4}.spm.stats.results.print = 'pdf';
    matlabbatch{4}.spm.stats.results.write.none = 1;
end

%% Run matlabbatch
spm_jobman('initcfg')
spm_jobman('run', matlabbatch)

end