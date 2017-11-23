function im_range = getImageRange(nu_blocks,subj)

ini = 4;

% Some exceptions
if strcmp(char(subj), 'PR02010_VF180893_20160803_123831155')
    ini = 5;
elseif strcmp(char(subj), 'PR02011_LF051093_20160803_141032179')
    ini = 5;
elseif strcmp(char(subj), 'PR02118_JM211292_20160922_123539148')
    ini = 7;
end

% Range of the EPI images, e.g. 4 for the first EPI
% For every block 3 EPIs
im_range = ini:3:(ini+3*(nu_blocks-1));

if strcmp(char(subj), 'PR02012_MC030192_20160803_164430287')
    im_range = [4 7 10 13 16 22];
elseif strcmp(char(subj), 'PR02013_MR211196_20160803_181918050')
    im_range = [4 10 13 16 19 22];
elseif strcmp(char(subj), 'PR02275_MS180294_20161206_135417812')
    im_range = [4 7 10 13 19 22];
end


end

