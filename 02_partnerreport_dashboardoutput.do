**   Partner Performance by SNU
**   COP FY16
**   Aaron Chafetz & Josh Davis
**   Purpose: generate output for Excel monitoring dashboard
**   Date: June 20, 2016
**   Updated: 8/29/2016

/* NOTES
	- Data source: ICPI_Fact_View_PSNU_IM_20160822 [ICPI Data Store]
	- Report uses FY2016APR results since it sums up necessary values
	- Report aggregates DSD and TA
	- Report looks across HTC_TST, HTC_TST_POS, PMTCT_STAT, PMTCT_STAT_POS, 
		PMTCT_ARV, PMTCT_EID, TB_STAT, TB_STAT_POS, TB_ART, TX_NEW, TX_CURR,
		OVC_SERV, VMMC_CIRC, KP_PREV, PP_PREV, and CARE_CURR
*/
********************************************************************************

*import/open data
	capture confirm file "$output\ICPIFactView_SNUbyIM20160822.dta"
		if !_rc{
			use "$output\ICPIFactView_SNUbyIM20160822.dta", clear
		}
		else{
			import delimited "$data\ICPI_Fact_View_PSNU_IM_20160822.txt", clear
			save "$output\ICPIFactView_SNUbyIM20160822.dta", replace
		}
	*end

*replace missing SNU prioritizatoins
	replace snuprioritization="[not classified]" if snuprioritization==""

*create new indicator variable for only the ones of interest for analysis
	* for most indicators we just want their Total Numerator reported
	* exceptions = HTC_TST Positives & TX_NET_NEW --> need to "create" new var
	gen key_ind=indicator if (inlist(indicator, "HTC_TST", "CARE_NEW", ///
		"PMTCT_STAT", "PMTCT_ARV", "PMTCT_EID", "TX_NEW", "TX_CURR", ///
		"OVC_SERV", "VMMC_CIRC") | inlist(indicator, "TB_STAT", "TB_ART", ///
		"KP_PREV", "PP_PREV", "CARE_CURR")) & disaggregate=="Total Numerator"

	*HTC_TST_POS & TB_STAT_POS indicator
	replace disaggregate="Results" if disaggregate=="Result"
	foreach x in "HTC_TST" "TB_STAT" {
		replace key_ind="`x'_POS" if indicator=="`x'" & ///
		resultstatus=="Positive" & disaggregate=="Results"
		}
		*end
	*PMTCT_STAT_POS
	replace key_ind="PMTCT_STAT_POS" if indicator=="PMTCT_STAT" & ///
		disaggregate=="Known/New"

	*TX_NET_NEW indicator
		expand 2 if key_ind=="TX_CURR" & , gen(new) //create duplicate of TX_CURR
			replace key_ind= "TX_NET_NEW" if new==1 //rename duplicate TX_NET_NEW
			drop new
		*create copy periods to replace . w/ 0 for generating net new (if . using in calc --> answer == .)
		foreach x in fy2015q2 fy2015q4 fy2016q2 fy2016_targets{
			clonevar `x'_cc = `x'
			recode `x'_cc (. = 0)
			}
			*end
		*create net new variables
		gen fy2016q2_nn = fy2016q2_cc-fy2015q4_cc
		gen fy2016_targets_nn = fy2016_targets_cc - fy2015q4_cc
		drop *_cc
		*replace period values with net_new
		foreach x in fy2016q2 fy2016_targets {
			replace `x' = `x'_nn if key_ind=="TX_NET_NEW"
			drop `x'_nn
			}
			*end
		*remove tx net new values for fy15
		foreach pd in fy2015q2 fy2015q3 fy2015q4 fy2015apr {
			replace `pd' = . if key_ind=="TX_NET_NEW"
			}
			*end
*create SAPR and cumulative variable to sum up necessary variables
	foreach agg in "sapr" "cum" {
		if "`agg'"=="sapr" egen fy2016`agg' = rowtotal(fy2016q1 fy2016q2)
			else egen fy2016`agg' = rowtotal(fy2016q*)
		replace fy2016`agg' = fy2016q2 if inlist(indicator, "TX_CURR", ///
			"OVC_SERV", "PMTCT_ARV", "KP_PREV", "PP_PREV", "CARE_CURR")
		replace fy2016`agg' =. if fy2016`agg'==0 //should be missing
		}
		*end
*
	foreach pd in fy2015q3 fy2016q1 fy2016q3{
		replace `pd'=. if inlist(indicator, "TX_CURR", "OVC_SERV", ///
			"PMTCT_ARV", "KP_PREV", "PP_PREV", "CARE_CURR")
		}
*delete reporting that shouldn't have occured
	tabstat fy2015q3 fy2016q1 fy2016q3 if inlist(indicator, "TX_CURR", ///
		"OVC_SERV", "PMTCT_ARV", "KP_PREV", "PP_PREV", "CARE_CURR"), ///
		s(sum count) by(operatingunit)	
	foreach pd in fy2015q3 fy2016q1 fy2016q3{
		replace `pd'=. if inlist(indicator, "TX_CURR", "OVC_SERV", ///
			"PMTCT_ARV", "KP_PREV", "PP_PREV", "CARE_CURR")
		}
* delete extrainous vars/obs
	drop if key_ind=="" //only need data on key indicators
	drop indicator
	rename ïregion region
	rename key_ind indicator
	keep region operatingunit countryname psnu psnuuid snuprioritization ///
		fundingagency primepartner mechanismid implementingmechanismname ///
		indicator fy2015q2 fy2015q3 fy2015q4 fy2015apr fy2016_targets ///
		fy2016q1 fy2016q2 fy2016q2 fy2016sapr fy2016q3 fy2016cum
	order region operatingunit countryname psnu psnuuid snuprioritization ///
		fundingagency primepartner mechanismid implementingmechanismname ///
		indicator fy2015q2 fy2015q3 fy2015q4 fy2015apr fy2016_targets ///
		fy2016q1 fy2016q2 fy2016q2 fy2016sapr fy2016q3 fy2016cum

*export full dataset
	local date = subinstr("`c(current_date)'", " ", "", .)
	export delimited using "$excel\ICPIFactView_SNUbyIM_GLOBAL_`date'", nolabel replace dataf

*set up to loop through countries
	qui:levelsof operatingunit, local(levels)
	local date = subinstr("`c(current_date)'", " ", "", .)
	foreach ou of local levels {
		preserve
		di "export dataset: `ou' "
		qui:keep if operatingunit=="`ou'"
		qui: export delimited using "$excel\ICPIFactView_SNUbyIM_`date'_`ou'", ///
			nolabel replace dataf
		restore
		}
		*end
