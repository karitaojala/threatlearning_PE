function secondlevel_tests(seclvlpath,m,contrasts,printresults)

if m == 1
   
    %% Axiomatic model
    
    connum = 1;
    
    % ------------------
    % Sanity check tests
    % ------------------
    
    if ismember(contrasts,connum)
        % 1. Main effect of CS
        secondlevel_1sttest(seclvlpath,'1sttest_sancheck1_CS','01',{'CS > baseline'},printresults);
    end
    connum = connum + 1;
    
    if ismember(contrasts,connum)
        % 2. Main effect of US
        secondlevel_1sttest(seclvlpath,'1sttest_sancheck2_US','02',{'US > baseline'},printresults);
    end
    connum = connum + 1;
    
    % --------------------
    % Conjunction analysis
    % --------------------
    
    if ismember(contrasts,connum)
        % Positive prediction error (2 contrasts)
        conjname = 'conjunction_axioms_posPE';
        connames = {'1sttest_ax5_CS3USp-CS4USp' '1sttest_ax6_CS2USp-CS3USp'};
        actualnames = {'CS3US+ > CS4US+' 'CS2US+ > CS3US+'};
        connums = {'09' '10'};
        secondlevel_1wayanova_forconj(seclvlpath,connames,connums,conjname,actualnames);
    end
    connum = connum + 1;
    
    if ismember(contrasts,connum)
        % Negative prediction error (2 contrasts)
        conjname = 'conjunction_axioms_negPE';
        connames = {'1sttest_ax1_CS2USm-CS3USm' '1sttest_ax2_CS1USm-CS2USm'};
        actualnames = {'CS2US- > CS3US-' 'CS1US- > CS2US-'};
        connums = {'05' '06'};
        secondlevel_1wayanova_forconj(seclvlpath,connames,connums,conjname,actualnames);
    end
    connum = connum + 1;
    
    if ismember(contrasts,connum)
        % 1. Full model (6 contrasts)
        conjname = 'conjunction_axioms12_6cons';
        connames = {'1sttest_ax1_CS2USm-CS3USm' '1sttest_ax2_CS1USm-CS2USm' '1sttest_ax3_CS3USp-CS3USm' '1sttest_ax4_CS2USp-CS2USm' '1sttest_ax5_CS3USp-CS4USp' '1sttest_ax6_CS2USp-CS3USp'};
        actualnames = {'CS2US- > CS3US-' 'CS1US- > CS2US-' 'CS3US+ > CS3US-' 'CS2US+ > CS2US-' 'CS3US+ > CS4US+' 'CS2US+ > CS3US+'};
        connums = {'05' '06' '07' '08' '09' '10'};
        secondlevel_1wayanova_forconj(seclvlpath,connames,connums,conjname,actualnames);
    end
    connum = connum + 1;
    
    if ismember(contrasts,connum)
        % Unsigned prediction error (4 contrasts)
        conjname = 'conjunction_axioms_unsignedPE';
        connames = {'1sttest_ax1_CS3USm-CS2USm' '1sttest_ax2_CS2USm-CS1USm' '1sttest_ax5_CS3USp-CS4USp' '1sttest_ax6_CS2USp-CS3USp'};
        actualnames = {'CS3US- > CS2US-' 'CS2US- > CS1US-' 'CS3US+ > CS4US+' 'CS2US+ > CS3US+'};
        connums = {'05' '06' '09' '10'};
        secondlevel_1wayanova_forconj(seclvlpath,connames,connums,conjname,actualnames);
    end
    
elseif m == 2
    %% Parametric Model 1
    connum = 1;
    
    if ismember(contrasts,connum)
        % 1. Unmodulated effect of CS
        secondlevel_1sttest(seclvlpath,'1sttest_unmod_CS','01',{'Unmodulated effect of CS'},printresults);
    end
    connum = connum + 1;
    
    if ismember(contrasts,connum)
        % 2. Effect of p(shock)
        secondlevel_1sttest(seclvlpath,'1sttest_parmod_CS_pshock','02',{'Effect of p(shock)'},printresults);
    end
    connum = connum + 1;
    
    if ismember(contrasts,connum)
        % 3. Unmodulated effect of US
        secondlevel_1sttest(seclvlpath,'1sttest_unmod_US','03',{'Unmodulated effect of US'},printresults);
    end
    connum = connum + 1;
    
    if ismember(contrasts,connum)
        % 4. Effect of US type
        secondlevel_1sttest(seclvlpath,'1sttest_parmod_US_type','04',{'Effect of US type'},printresults);
        secondlevel_1sttest(seclvlpath,'1sttest_unmod_US','03',{'Unmodulated effect of US'},printresults);
    end
    connum = connum + 1;
    
    if ismember(contrasts,connum)
        % 5. Effect of prediction error
        secondlevel_1sttest(seclvlpath,'1sttest_parmod_US_PE','05',{'Prediction error'},printresults);
    end
    
elseif m == 3
    %% Parametric Model 1b
    connum = 1;
    
    if ismember(contrasts,connum)
        % 1. Unmodulated effect of CS
        secondlevel_1sttest(seclvlpath,'1sttest_unmod_CS','01',{'Unmodulated effect of CS'},printresults);
    end
    connum = connum + 1;
    
    if ismember(contrasts,connum)
        % 2. Effect of p(shock)
        secondlevel_1sttest(seclvlpath,'1sttest_parmod_CS_exptpshock','02',{'Effect of Expected p(shock)'},printresults);
    end
    connum = connum + 1;
    
    if ismember(contrasts,connum)
        % 3. Unmodulated effect of US
        secondlevel_1sttest(seclvlpath,'1sttest_unmod_US','03',{'Unmodulated effect of US'},printresults);
    end
    connum = connum + 1;
    
    if ismember(contrasts,connum)
        % 4. Effect of US type
        secondlevel_1sttest(seclvlpath,'1sttest_parmod_US_type','04',{'Effect of US type'},printresults);
    end
    connum = connum + 1;
    
    if ismember(contrasts,connum)
        % 5. Effect of Bayesian prediction error
        secondlevel_1sttest(seclvlpath,'1sttest_parmod_US_BayesPE','05',{'Bayesian prediction error'},printresults);
    end
    
elseif m == 4
    %% Parametric Model 2 (version 2 with volatility)
    connum = 1;
    
    if ismember(contrasts,connum)
        % 1. Unmodulated effect of CS
        secondlevel_1sttest(seclvlpath,'1sttest_unmod_CS','01',{'Unmodulated effect of CS'},printresults);
    end
    connum = connum + 1;
    
    if ismember(contrasts,connum)
        % 2. Expected p(shock)
        secondlevel_1sttest(seclvlpath,'1sttest_parmod_CS_exptpshock','02',{'Expected p(shock)'},printresults);
    end
    connum = connum + 1;
    
    if ismember(contrasts,connum)
        % 3. Volatility
        secondlevel_1sttest(seclvlpath,'1sttest_parmod_CS_volatility','03',{'Volatility'},printresults);
    end
    connum = connum + 1;
    
    if ismember(contrasts,connum)
        % 4. Prior entropy p(shock)
        secondlevel_1sttest(seclvlpath,'1sttest_parmod_CS_priorentrpypshock','04',{'Prior entropy p(shock)'},printresults);
    end
    connum = connum + 1;
    
    if ismember(contrasts,connum)
        % 5. KL divergence prior-posterior from previous trial
        secondlevel_1sttest(seclvlpath,'1sttest_parmod_CS_KLdivprevtrial','05',{'KL div prev trial'},printresults);
    end
    connum = connum + 1;
    
    if ismember(contrasts,connum)
        % 6. Suprise about US from previous trial
        secondlevel_1sttest(seclvlpath,'1sttest_parmod_CS_surprUSprevtrial','06',{'Surpr US prev trial'},printresults);
    end
    connum = connum + 1;
    
    if ismember(contrasts,connum)
        % 7. Unmodulated effect of US
        secondlevel_1sttest(seclvlpath,'1sttest_unmod_US','07',{'Unmodulated effect of US'},printresults);
    end
    connum = connum + 1;
    
    if ismember(contrasts,connum)
        % 8. US type
        secondlevel_1sttest(seclvlpath,'1sttest_parmod_US_type','08',{'US type'},printresults);
        secondlevel_1sttest(seclvlpath,'1sttest_unmod_US','07',{'Unmodulated effect of US'},printresults);
    end
    connum = connum + 1;
    
    if ismember(contrasts,connum)
        % 9. KL divergence prior-posterior for current trial
        secondlevel_1sttest(seclvlpath,'1sttest_parmod_US_KLdivcurrtrial','09',{'KL div curr trial'},printresults);
    end
    connum = connum + 1;
    
    if ismember(contrasts,connum)
        % 10. Suprise about US from previous trial
        secondlevel_1sttest(seclvlpath,'1sttest_parmod_CS_surprUScurrtrial','10',{'Surpr US curr trial'},printresults);
    end
    
end

end