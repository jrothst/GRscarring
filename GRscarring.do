********************************************************************************
*
*	GRscarring.do
*
*	Runs files that build and execute GR Scarring project
*
*
********************************************************************************

 * Recall: to run the GRscarring project, do the following
  * project, setup
  * project GRscarring, build
  
	version 12.1

* Common settings

	set more off
	set varabbrev off	// for long projects, it's best not to abbreviate
	set linesize 132	// use 7pt font for printing
	
  which project
  *Should be:
    */accounts/projects/jr_ra/ado/plus/p/project.ado
    *! version 1.3.1  22dec2013  picard@netbox.com
  *To check for updates, type:
  * adoupdate project

  * This directory includes a local copy of -project- in a zip archive. This
  * is done to ensure replicability in case of future changes in -project- or
  * if -project- becomes unavailable, or if you are unable to install it from
  * the SSC archives. Make it part of the project
 	*project, relies_on("project.zip")

  *Display information about computer
  version
  creturn list
  set
  *assert "`c(version)'"=="14.0"

  *configure directories;
  project, doinfo
  local pdir "`r(pdir)'"
  
  						  	    // the project's main dir.
  set scheme s1color

 

********************************************************************************
********************************************************************************
************* STEP 1: READ IN, CLEAN, COMPILE, AND COLLAPSE RAW DATA ***********
********************************************************************************

*******************
     ** MISC **
*******************

project, do(`pdir'/programs/prepare/cpi.do)
project, do(`pdir'/programs/prepare/unrate.do)
project, do(`pdir'/programs/prepare/statepop.do)
project, do(`pdir'/programs/analysis/recessionlist.do)


*******************
**** FULL CPS ****
*******************
* Extract and clean the monthly CPS data
	project, do(`pdir'/programs/prepare/extractcps_v5.do)

* Generate lives with partner variable
	project, do(`pdir'/programs/prepare/findpartners_v3.do)

* Combines extractcps with the lives with partner variable and occupation specific variables
* NO LONGER USED -- FOLDED INTO FINDPARTNERS AND EXTRACTCPS
*	project, do(`pdir'/programs/prepare/cpsnewvariables.do)
	
* Collapses the data by cohort
	project, do(`pdir'/programs/prepare/collapse_bigcps.do)


*******************
**** MARCH CPS ****
*******************
* (using NBER code and structure)
global nbercode "`pdir'/programs/fromNBER"


** Read in rawraw files: **
forvalues yr=79/99 {
	project, do(${nbercode}/cpsmar`yr'.do)
}
forvalues yr=0/12 {
	if `yr'<10 local yr "0`yr'"
	project, do(${nbercode}/cpsmar`yr'.do)
}
forvalues yr=2013/2018 {
	if `yr'==2014 project, do(${nbercode}/cpsmar`yr't.do)
	else project, do(${nbercode}/cpsmar`yr'.do)
}


** Compile: **
project, do(`pdir'/programs/prepare/clean_compile_march.do)
*project, do(`pdir'/programs/prepare/prepare_march.do)
project, do(`pdir'/programs/prepare/collapse_march.do)


*******************
******* ORG *******
*******************
* Extract and clean the ORG data
project, do(`pdir'/programs/prepare/makemorg2019.do)
project, do(`pdir'/programs/prepare/extractorg_morg.do)

* Combines extractorg with occupation specific variables
*NO LONGER USED -- FOLDED INTO EXTRACTORG.DO
*	project, do(`pdir'/programs/prepare/orgnewvariables.do)

* Collapses the data by cohort
project, do(`pdir'/programs/prepare/collapse_org.do)



*******************
   **** ACS ****
*******************

project, do(`pdir'/programs/prepare/ipums_acs_youngadult.do)


*Combine ORG, March, and monthly, and combine BA and grad degrees
project, do(`pdir'/programs/prepare/combinecollapse.do)


************************
  ****Double Weight****
************************
project, do(`pdir'/programs/prepare/ipums_doubleweight.do)
project, do(`pdir'/programs/prepare/double_weight.do)

********************************************************************************
*********************************
******** STEP 3: ANALYSIS ********
**********************************

*Running and storing coefficients for models 1 - 5
	project, do(`pdir'/programs/analysis/runatc.do)
	
*Extrapolate regressions
	project, do(`pdir'/programs/analysis/extrapolate.do)

*******************
***** Figures *****
*******************

* project, do(`pdir'/programs/analysis/epopoverview.do)
* project, do(`pdir'/programs/analysis/realwageoverview.do)
* project, do(`pdir'/programs/analysis/realearnoverview.do)
 project, do(`pdir'/programs/analysis/fig_ur.do)
 project, do(`pdir'/programs/analysis/fig_ur_age.do)

 project, do(`pdir'/programs/analysis/simplecohortmeans.do)
* project, do(`pdir'/programs/analysis/fig_outcomes2526.do)
 project, do(`pdir'/programs/analysis/fig_atcfx.do)
* project, do(`pdir'/programs/analysis/fig_empageyear.do) 
* project, do(`pdir'/programs/analysis/fig_fitdeltaemp.do)
 project, do(`pdir'/programs/analysis/fig_semitransitory.do)
* project, do(`pdir'/programs/analysis/fig_empageyear_fit.do)
project, do(`pdir'/programs/analysis/fig_eduageyear.do)
* project, do(`pdir'/programs/analysis/fig_lfpepop.do)
 project, do(`pdir'/programs/analysis/cohfxregs.do)
 project, do(`pdir'/programs/analysis/summarystats.do) 
*project, do(`pdir'/programs/analysis/table_diffs.do)
* project, do(`pdir'/programs/analysis/fittedvals.do)
* project, do(`pdir'/programs/analysis/fig_particip_quit.do)
* project, do(`pdir'/programs/analysis/text_numbers.do)
*project, do(`pdir'/programs/analysis/fig_state_unemp.do)
* project, do(`pdir'/programs/analysis/ivrunatc.do)
* project, do(`pdir'/programs/analysis/counterfactualsims.do)
 project, do(`pdir'/programs/analysis/simulation.do)

*Running and storing coefficients by sex
 project, do(`pdir'/programs/analysis/runatc_bygender.do)
 project, do(`pdir'/programs/analysis/fig_atcfxbygender.do)

 *project, do(`pdir'/programs/analysis/fig_familyformation.do)

 project, do(`pdir'/programs/analysis/fig_atcfx_time.do)
 project, do(`pdir'/programs/analysis/fig_atcfx_age.do)
 project, do(`pdir'/programs/analysis/miscstats.do)

 project, do(`pdir'/programs/analysis/fig_imr.do)
 project, do(`pdir'/programs/analysis/ivrunatc.do)

 project, do(`pdir'/programs/analysis/runatc_balanced.do)
 project, do(`pdir'/programs/analysis/fig_atcfx_balanced.do)
*
** end of project **

 
