***************************************************************************************************************

* extractcps.do
* JR, 7/11/2017
* Based on extractcps.do, from the replication archive for
*    Rothstein, Jesse. "The Great Recession and its Aftermath: What Role for 
*    Structural Changes?" RSF: The Russell Sage Foundation Journal of the 
*    Social Sciences 3(3), April 2017. p.p. 22-49. 
* Revisions:
*   7/26/17: Rachel Young: Add years-of-education and presence of child variables.
*   10/10/17: Rachel Young: Extended the data back to 1989
*   12/8/2017: Rachel Young: Extended data back to 1979
*   6/2018: Rachel Young: Add current school enrollment
*   8/2018: Nathaniel Ruby: Extended the data to June 2018.
*   1/2019: Nathaniel Ruby: Extended the data to November 2018.
*   8/2019: Nicolas Ghio: Extended the data to July 2019.
*   4/2020: JR: Extended to Dec 2019
*
* As written this relies on data files in ~/data/cps/bigcps/statafmt,
* which are created by ~/data/cps/bigcps/programs/readrawcps.do, using very
* lightly modified versions of Jean Roth's NBER code.
* We may at some point want to bring that into the project structure.
*
* 

cap project, doinfo
if _rc==0 {
	local doasproject=1
	local pdir "`r(pdir)'"						  	    // the project's main dir.
	local dofile "`r(dofile)'"						    // do-file's stub name
  local sig {bind:{hi:[RP : `dofile'.do]}}	// a signature in notes
}
else {
  local doasproject=0
	local pdir "~/GRscarring"
	local dofile "extractcps"
	local sig "Not run as part of project!"
}

local cpsorig "~/data/cps/bigcps/statafmt"
local intermediate "`pdir'/scratch"
local cpsraw "~/data/cps/bigcps/raw"
local temp "`pdir'/rawdata/temp"
local otherraw "`pdir'/rawdata"

if `doasproject'==1 {
	project, original(`otherraw'/stategeocodes.dta)
}

set more off
program drop _all
set type double, perm
#delimit ;

/***Define Global Directory***/

/*local startmo=ym(1978,1);*/
*local startmo=ym(1991,1);
*local endmo=ym(2017,05);

*local startmo=ym(2012,5);
*local endmo=ym(2012,5);

*local endmo=ym(2017,12);


local startmo=ym(1979,1);
*local endmo = ym(2018,11);
local endmo = ym(2019,12);


local overwrite=1;

*Define variables to pull;
*0: 1/1978-12/1983;
local uselist01 "hh_id month year a_fnlwgt stcens respline inttype anywork hh_num majact hourslw usualft classer a_ind occ linenum relhead a_age marstat race a_sex";
local uselist02 "a_hga a_hgc esr ethnic lfs wkstat explfstat a_mjind2 classdet a_mjind1 a_dtind a_hrs1 a_uslhrsr a_clswkrd rrp kidrel uslhrsr paidhrlyr";
local uselist03 "hrlywager wklyearnr ernwgt ernelg uslhrs paidhrly hrlywage wklyearn a_uslhrs uslwkearn a_ind a_wkslk";
*H: 1/1984-12/1988;
local uselistH1 "hh_id month year a_fnlwgt stcens respline inttype anywork hh_num majact hourslw usualft classer a_ind occ84 linenum relhead a_age marstat race a_sex";
local uselistH2 "a_hga a_hgc esr ethnic lfs wkstat explfstat a_mjind2 classdet a_mjind1 a_dtind a_hrs1 a_uslft a_uslhrsr a_clswkrd rrp kidrel uslhrsr paidhrlyr";
local uselistH3 "hrlywager wklyearnr ernwgt ernelg uslhrs paidhrly hrlywage wklyearn a_uslhrs a_pdhrly a_hrlywg a_wkearn uslwkearn a_ind a_wkslk occ84 a_parent";
*A:  1/1989-12/1991;
local uselistA1 "h_id h_month h_year a_fnlwgt l_fnlwgt l_lngwgt hg_fips a_age a_hga a_hgc a_sex a_lfsr";
local uselistA2 "a_clswkr a_ind a_mjind a_dtind a_mjocc a_dtocc a_wkslk l_hrs1 l_uslft a_parent a_hrlywk a_herntp a_ind a_occ";
local uselistA3 "h_hhnum a_lineno a_maritl h_tenure h_numper a_famrel a_pfnocd a_hrs1 a_uslhrs a_enrlw";
*B: 1/1992-12/1993;
local uselistB1 "h_id h_month h_year a_fnlwgt l_fnlwgt l_lngwgt hg_fips a_age a_hga a_sex a_lfsr a_parent";
local uselistB2 "a_clswkr a_ind a_mjind a_dtind a_mjocc a_dtocc a_wkslk a_hrs1 a_uslhrs a_uslft a_hrlywk a_herntp a_ind a_occ" ;
local uselistB3 "h_hhnum a_lineno a_maritl h_tenure h_numper a_famrel a_pfnocd a_enrlw";
*C: 1/1994-12/1997;
local uselistC1 "hrhhid hrmonth hryear pwsswgt pwlgwgt pworwgt gestfips peage ptage peeduca pesex pemlr peparent pemaritl pehrusl1";
local uselistC2 "peio1cow peio1icd peio2icd prdtind1 prdtind2 prmjind1 prmjind2 peio1ocd peio2ocd prdtocc1 prdtocc2 prmjocc1 prmjocc2 prunedur prmarsta";
local uselistC3 "huhhnum pulineno prmarsta hetenure hrnumhou prfamrel pehruslt pxhrusl1 pxhractt peernhro pehractt peschenr ";
*D: 1/1998-12/2002;
local uselistD1 "hrhhid hrmonth hryear4 pwsswgt pwcmpwgt pwlgwgt pworwgt gestfips peage ptage peeduca pesex pemlr peparent pemaritl pehrusl1";
local uselistD2 "peio1cow peio1icd peio2icd prdtind1 prdtind2 prmjind1 prmjind2 peio1ocd peio2ocd prdtocc1 prdtocc2 prmjocc1 prmjocc2 prunedur pemjot";
local uselistD3 "huhhnum pulineno prmarsta hetenure hrnumhou prfamrel pehruslt pxhrusl1 pxhractt peernhro pehractt peschenr";
*E: 1/2003-4/2004;
local uselistE1 "hrhhid hrmonth hryear4 pwsswgt pwcmpwgt pwlgwgt pworwgt gestfips peage ptage peeduca pesex pemlr peparent pemaritl pehrusl1";
local uselistE2 "peio1cow peio1icd peio2icd primind1 primind2 prdtind1 prdtind2 prmjind1 prmjind2 peio1ocd peio2ocd prdtocc1 prdtocc2 prmjocc1 prmjocc2 prunedur pemjot";
local uselistE3 "huhhnum pulineno prmarsta hetenure hrnumhou prfamrel prchld pehruslt  pxhrusl1 pxhractt peernhro pehractt peschenr";
*F: 5/2004-04/2012 (or later?);
local uselistF1 "hrhhid hrhhid2 hrmonth hryear4 pwsswgt pwcmpwgt pwlgwgt pworwgt gestfips peage prtfage peeduca pesex pemlr peparent pemaritl pehrusl1";
local uselistF2 "peio1cow peio1icd peio2icd primind1 primind2 prdtind1 prdtind2 prmjind1 prmjind2 peio1ocd peio2ocd prdtocc1 prdtocc2 prmjocc1 prmjocc2 prunedur pemjot";
local uselistF3 "hrhhid2 pulineno prmarsta hetenure hrnumhou prfamrel prchld pehruslt pxhrusl1 pxhractt peernhro pehractt peschenr";
*G: 5/2012- (or later?);
local uselistG1 "hrhhid hrhhid2 hrmonth hryear4 pwsswgt pwcmpwgt pwlgwgt pworwgt gestfips prtage prtfage peeduca pesex pemlr peparent pemaritl pehrusl1 prhrusl";
local uselistG2 "peio1cow peio1icd peio2icd primind1 primind2 prdtind1 prdtind2 prmjind1 prmjind2 peio1ocd peio2ocd prdtocc1 prdtocc2 prmjocc1 prmjocc2 prunedur pemjot peernhro";
local uselistG3 "hrhhid2 pulineno prmarsta hetenure hrnumhou prfamrel prchld pulineno  pxhrusl1 pxhractt pehractt peschenr";

*Define labels;
cap program drop makelabels;
program define makelabels;
label define educ4_label
	1	"lessthanhs"
	2	"hs"
	3	"someba"
	4	"baplus"
	;
label define educ5_label
	1	"lessthanhs"
	2	"hs"
	3	"someba"
	4	"ba"
	5 	"advdeg"
	;
label define agecat_label
	0	"0to15"
	1	"16to24"
	2	"25to34"
	3	"35to44"
	4	"45to54"
	5	"55to64"
	6	"65plus"
	;
label define sex_label
	0	"female"
	1	"male"
	;
label define edsex_label
	1	"lessthanhs_male"
	2	"lessthanhs_female"
	3	"hs_male"
	4	"hs_female"
	5	"someba_male"
	6	"someba_female"
	7	"baplus_male"
	8	"baplus_female"
	;
label define labfor_label
	0	"nilf"
	1	"inlaborforce"
	;
label define empl_label
	0	"unemployed"
	1	"employed"
	;
label define unem_label
	1	"unemployed"
	0	"employed"
	;
label define ind20_label
	1	"agriculture"
	2	"mining-logging"
	3	"construction"
	4	"manuf-durable"
	5 	"manuf-nondurable"
	6 	"wholesale trade"
	7 	"retail trade"
	8 	"transportation"
	9 	"utilities"
	10 	"information"
	11 	"finance-insurance"
	12 	"real estate"
	13 	"prof/business svcs"
	14 	"education"
	15 	"health"
	16 	"leisure_hospitality"
	17 	"othersvcs"
	18 	"govt-federal"
	19 	"govt-state"
	20 	"govt-local";
	;
label define indjolts_label
	1	"agriculture"
	2	"mining-logging"
	3	"construction"
	4	"manuf-durable"
	5 	"manuf-nondurable"
	6 	"wholesale trade"
	7 	"retail trade"
	8 	"transport-util"
	9 	"information"
	10 	"finance-insurance"
	11 	"real estate"
	12 	"prof/business svcs"
	13 "education"
	14 "health"
	15 "Arts-entertain"
	16 "Accom-food"
	17 "othersvcs"
	18 "govt-federal"
	19 "govt-state/local"
	;
label define ind14_label
	1	"ag_forestry_fish_hunt"
	2	"mining"
	3	"construction"
	4	"manufacturing"
	5	"wholsale_retail_ltrade"
	6	"transportation_utilities"
	7	"information"
	8	"financialactivities"
	9	"professional_business_svcs"
	10	"education_health_svcs"
	11	"leisure_hospitality"
	12	"othersvcs"
	13	"publicadmin"
	14	"armedforces"
	;
label define occ11_label
	1	"mgmt_business_finance"
	2	"professional_related"
	3	"service"
	4	"sales_related"
	5	"office_admin_support"
	6	"farm_fish_forestry"
	7	"construct_extract"
	8	"install_maint_repair"
	9	"production"
	10	"transport_matermov"
	11	"armedforces"
	;
label define ltue_label
	1	"unem27wksormore"
	0	"unemlessthan27wks"
	;
label define stfips_label
	1	"AL"
	2	"AK"
	4	"AZ"
	5	"AR"
	6	"CA"
	8	"CO"
	9	"CT"
	10	"DE"
	11	"DC"
	12	"FL"
	13	"GA"
	15	"HI"
	16	"ID"
	17	"IL"
	18	"IN"
	19	"IA"
	20	"KS"
	21	"KY"
	22	"LA"
	23	"ME"
	24	"MD"
	25	"MA"
	26	"MI"
	27	"MN"
	28	"MS"
	29	"MO"
	30	"MT"
	31	"NE"
	32	"NV"
	33	"NH"
	34	"NJ"
	35	"NM"
	36	"NY"
	37	"NC"
	38	"ND"
	39	"OH"
	40	"OK"
	41	"OR"
	42	"PA"
	44	"RI"
	45	"SC"
	46	"SD"
	47	"TN"
	48	"TX"
	49	"UT"
	50	"VT"
	51	"VA"
	53	"WA"
	54	"WV"
	55	"WI"
	56	"WY"
	;

end;  //End program makelabels;

cap program drop recode0;
program define recode0;
  *For 01/1978-12/1983 ;

  rename a_maritl prmarsta;
  
  gen educ4=.;
  replace educ4=4 if inlist(a_hga,17,18,19)==1;  //note that assumption is finish college after 4 years;
  replace educ4=3 if a_hga==17 & a_hgc==2;
  replace educ4=3 if inlist(a_hga,14,15,16)==1;
  *Following Jaeger, MLR 8/97, code 13 years, not complete as some college;
  *replace educ4=2 if a_hga==14 & a_hgc==2;
  replace educ4=2 if inlist(a_hga,13)==1;
  replace educ4=1 if a_hga==13 & a_hgc==2;
  replace educ4=1 if inlist(a_hga,1,2,3,4,5,6,7,8,9,10,11,12)==1;

  gen educ5=educ4;
  replace educ5=5 if a_hga==19 | (a_hga==18 & a_hgc==1);
   
  rename a_age age;
  recode a_sex (-1=.) (1=1) (2=0), gen(sex);
  drop a_sex;
  gen edsex=(2*educ4)-sex if inlist(educ4,1,2,3,4)==1 & inlist(sex,0,1)==1;
 
  *add years-of-education;
   gen educ_yr = a_hga if a_hgc==1;
   replace educ_yr = a_hga-1 if a_hgc==2;
   *gen educ_yr=(a_hga - 1) if a_hga>0;
   compare educ_yr a_hga;
  
  *Make presence of child dummy;
   *First, figure out age of householder -- defined as oldest person with linenum==1.;
   *Note that unique IDs are <hh_id hh_num hh_tiebreak linenum p_tiebreak>;
    isid hh_id hh_num hh_tiebreak linenum p_tiebreak;
    gen hasage=(age<.);
    gsort hh_id hh_num hh_tiebreak linenum -hasage -age p_tiebreak;
    by hh_id hh_num hh_tiebreak: gen hhrespage=age[1] if linenum[1]==1; 
   *Now find children in household. Set to 0 if missing data.;    
    gen chld=(age<18 & hhrespage-age>=15)*(age<. & hhrespage<.);
    gen chld_age=age if chld==1;
    egen hhchldage=min(chld_age), by(hh_id hh_num hh_tiebreak);
    *Now define the presence of a child in the HH;
    egen chld_pr=max(chld), by(hh_id hh_num hh_tiebreak);
    replace chld_pr=0 if chld==1;
    replace chld_pr=0 if age>18 & age-hhchldage<15;

*Add live-with-parent dummy (identifies each person that is living with their parents);
   *Now find children in household. Set to 0 if missing data.;    
    gen chld_g=(hhrespage-age>=15)*(age<. & hhrespage<.);
    *Now create identifier for living with parent;
    gen livewithprnt=0; 
    replace livewithprnt=1 if chld_g==1;
  
 /*note that the codes for the labor force are slightly different from later codes*/
 /*code 4 is housework/NILF instead of unemployed*/
  rename esr a_lfsr;
  rename a_lfsr pemlr;
  recode pemlr (1/3=1) (4/7=0) (else=.), gen(labfor);
  recode pemlr (1/2=1) (3/7=0) (else=.), gen(empl);
  gen unem=1-empl if labfor;
  
  *recode pemlr (1/4=1) (5/7=0) (else=.), gen(labfor);
  *recode pemlr (1/2=1) (3/7=0) (else=.), gen(empl);
  *gen unem=1-empl if labfor;
  replace pemlr=-1 if pemlr==.;

  *Note:  These are identically 0 for some months;
  rename a_fnlwgt wgt_final;
  
  rename h_month month;

  recode a_mjind (1 21=1) (2=2) (3=3) (4=4) (5=5) (6=8) (7=8) (8=9)
                 (9=6) (10=7) /*11 is split */ (12 14=17) /*13 is split*/
                 (15=16) (16 17 18=15) (19=14) (20=13) /* 22 23 are odd*/
                 (else=.), gen(ind20);
  *communications->information, 10;
   replace ind20=10 if inlist(a_ind, 447, 448, 449) & year<1983;
   replace ind20=10 if inlist(a_ind, 440, 441, 442) & year>=1983;
  * banking	35;
   replace ind20=11 if a_mjind==11 & a_dtind==35;
  * other finance	36;
   replace ind20=12 if a_mjind==11 & a_dtind==36;
  * business services	38;
   replace ind20=13 if a_mjind==13 & a_dtind==38;
  * repair services	39;
   replace ind20=17 if a_mjind==13 & a_dtind==39;
  *Public workers;
   replace ind20=18 if a_clswkr==2;
   replace ind20=19 if a_clswkr==3;
   replace ind20=20 if a_clswkr==4;  

  recode a_mjind (1 21=1) (2=2) (3=3) (4=4) (5=5) (6=8) (7=8) (8=8)
                 (9=6) (10=7) /*11 is split */ (12 14=17) /*13 is split*/
                 (15=15) (16 17 18=14) (19=13) (20=12) /* 22 23 are odd*/
                 (else=.), gen(indjolts);
  replace indjolts=9 if inlist(a_ind, 447, 448, 449) & year<1983;
  replace indjolts=9 if inlist(a_ind, 440, 441, 442) & year>=1983;
  replace indjolts=10 if a_mjind==11 & a_dtind==35;
  replace indjolts=11 if a_mjind==11 & a_dtind==36;
  replace indjolts=12 if a_mjind==13 & a_dtind==38;
  *hotels and motels	777 / 762;
  *lodging places	778 / 770;
  *eating and drinking places	669 / 641;
  replace indjolts=16 if inlist(a_ind, 777, 778, 669) & year<1983;
  replace indjolts=16 if inlist(a_ind, 762, 770, 641) & year>=1983;
  replace indjolts=17 if a_mjind==13 & a_dtind==39;
  replace indjolts=18 if a_clswkr==2;
  replace indjolts=19 if a_clswkr==3 | a_clswkr==4;

  gen ind1_2003=.;
  replace ind1_2003=1 if inlist(a_mjind,1,21)==1;
  replace ind1_2003=2 if inlist(a_mjind,2)==1;
  replace ind1_2003=3 if inlist(a_mjind,3)==1;
  replace ind1_2003=4 if inlist(a_mjind,4,5)==1;
  replace ind1_2003=5 if inlist(a_mjind,9,10)==1;
  replace ind1_2003=6 if inlist(a_mjind,6,8)==1;
  replace ind1_2003=7 if inlist(a_mjind,7)==1;
  replace ind1_2003=8 if inlist(a_mjind,11)==1;
  replace ind1_2003=9 if inlist(a_mjind,13,20)==1;
  replace ind1_2003=10 if inlist(a_mjind,16,17,18,19)==1;
  replace ind1_2003=11 if inlist(a_mjind,15)==1;
  replace ind1_2003=12 if inlist(a_mjind,12,14)==1;
  replace ind1_2003=13 if inlist(a_mjind,22)==1;
  replace ind1_2003=14 if inlist(a_mjind,23)==1;
  
  gen occ1_2003=.;
  gen a_mjocc=a_occ;
  replace occ1_2003=1 if inlist(a_mjocc,1)==1;
  replace occ1_2003=2 if inlist(a_mjocc,2,3)==1;
  replace occ1_2003=3 if inlist(a_mjocc,6,7,8)==1;
  replace occ1_2003=4 if inlist(a_mjocc,4)==1;
  replace occ1_2003=5 if inlist(a_mjocc,5)==1;
  replace occ1_2003=6 if inlist(a_mjocc,13)==1;
  /*No matches for occ1_2003=7*/;
  /*No matches for occ1_2003=8*/;
  replace occ1_2003=9 if inlist(a_mjocc,9,10,12)==1;
  replace occ1_2003=10 if inlist(a_mjocc,11)==1;
  replace occ1_2003=11 if inlist(a_mjocc,14)==1;
  gen byte occ2_2003=.;

  gen ltue=1 if a_wkslk>=27 & a_wkslk!=. & unem==1;
  replace ltue=0 if ltue==. & unem==1;
  
  rename hourslw pehractt; // Added 8/11/15;
  replace pehractt = . if pehractt == -1;

  sum wklyearn uslwkearn hrlywager, detail;


end;

cap program drop recodeH;
program define recodeH;
  *For 01/1984-12/1988 ;
  rename a_maritl prmarsta;
  
  gen educ4=.;
  replace educ4=4 if inlist(a_hga,17,18,19)==1;  //note that assumption is finish college after 4 years;
  replace educ4=3 if a_hga==17 & a_hgc==2;
  replace educ4=3 if inlist(a_hga,14,15,16)==1;
  *Following Jaeger, MLR 8/97, code 13 years, not complete as some college;
  *replace educ4=2 if a_hga==14 & a_hgc==2;
  replace educ4=2 if inlist(a_hga,13)==1;
  replace educ4=1 if a_hga==13 & a_hgc==2;
  replace educ4=1 if inlist(a_hga,1,2,3,4,5,6,7,8,9,10,11,12)==1;

  gen educ5=educ4;
  replace educ5=5 if a_hga==19 | (a_hga==18 & a_hgc==1);
   
  rename a_age age;
  recode a_sex (-1=.) (1=1) (2=0), gen(sex);
  drop a_sex;
  gen edsex=(2*educ4)-sex if inlist(educ4,1,2,3,4)==1 & inlist(sex,0,1)==1;
 
  *add years-of-education;
   gen educ_yr = a_hga if a_hgc==1;
   replace educ_yr = a_hga-1 if a_hgc==2;
   *gen educ_yr=(a_hga - 1) if a_hga>0;
   compare educ_yr a_hga;
  
  *Make presence of child dummy;
   *First, figure out age of householder -- defined as oldest person with linenum==1.;
   *Note that unique IDs are <hh_id hh_num hh_tiebreak linenum p_tiebreak>;
    isid hh_id hh_num hh_tiebreak linenum p_tiebreak;
    gen hasage=(age<.);
    gsort hh_id hh_num hh_tiebreak linenum -hasage -age p_tiebreak;
    by hh_id hh_num hh_tiebreak: gen hhrespage=age[1] if linenum[1]==1; 
   *Now find children in household. Set to 0 if missing data.;    
    gen chld=(age<18 & hhrespage-age>=15)*(age<. & hhrespage<.);
    gen chld_age=age if chld==1;
    egen hhchldage=min(chld_age), by(hh_id hh_num hh_tiebreak);
    *Now define the presence of a child in the HH;
    egen chld_pr=max(chld), by(hh_id hh_num hh_tiebreak);
    replace chld_pr=0 if chld==1;
    replace chld_pr=0 if age>18 & age-hhchldage<15;

*Add live-with-parent dummy (identifies each person that is living with their parents);
  gen livewithprnt=(a_parent>0)*(a_parent<.);  
  
 /*note that the codes for the labor force are slightly different from later codes*/
 /*code 4 is housework/NILF instead of unemployed*/
  rename esr a_lfsr;
  rename a_lfsr pemlr;
  recode pemlr (1/3=1) (4/7=0) (else=.), gen(labfor);
  recode pemlr (1/2=1) (3/7=0) (else=.), gen(empl);
  gen unem=1-empl if labfor;
  
  *recode pemlr (1/4=1) (5/7=0) (else=.), gen(labfor);
  *recode pemlr (1/2=1) (3/7=0) (else=.), gen(empl);
  *gen unem=1-empl if labfor;
  replace pemlr=-1 if pemlr==.;

  *Note:  These are identically 0 for some months;
  rename a_fnlwgt wgt_final;
  
  rename h_month month;

  recode a_mjind (1 21=1) (2=2) (3=3) (4=4) (5=5) (6=8) (7=8) (8=9)
                 (9=6) (10=7) /*11 is split */ (12 14=17) /*13 is split*/
                 (15=16) (16 17 18=15) (19=14) (20=13) /* 22 23 are odd*/
                 (else=.), gen(ind20);
  *communications->information, 10;
   replace ind20=10 if inlist(a_ind, 447, 448, 449) & year<1983;
   replace ind20=10 if inlist(a_ind, 440, 441, 442) & year>=1983;
  * banking	35;
   replace ind20=11 if a_mjind==11 & a_dtind==35;
  * other finance	36;
   replace ind20=12 if a_mjind==11 & a_dtind==36;
  * business services	38;
   replace ind20=13 if a_mjind==13 & a_dtind==38;
  * repair services	39;
   replace ind20=17 if a_mjind==13 & a_dtind==39;
  *Public workers;
   replace ind20=18 if a_clswkr==2;
   replace ind20=19 if a_clswkr==3;
   replace ind20=20 if a_clswkr==4;  

  recode a_mjind (1 21=1) (2=2) (3=3) (4=4) (5=5) (6=8) (7=8) (8=8)
                 (9=6) (10=7) /*11 is split */ (12 14=17) /*13 is split*/
                 (15=15) (16 17 18=14) (19=13) (20=12) /* 22 23 are odd*/
                 (else=.), gen(indjolts);
  replace indjolts=9 if inlist(a_ind, 447, 448, 449) & year<1983;
  replace indjolts=9 if inlist(a_ind, 440, 441, 442) & year>=1983;
  replace indjolts=10 if a_mjind==11 & a_dtind==35;
  replace indjolts=11 if a_mjind==11 & a_dtind==36;
  replace indjolts=12 if a_mjind==13 & a_dtind==38;
  *hotels and motels	777 / 762;
  *lodging places	778 / 770;
  *eating and drinking places	669 / 641;
  replace indjolts=16 if inlist(a_ind, 777, 778, 669) & year<1983;
  replace indjolts=16 if inlist(a_ind, 762, 770, 641) & year>=1983;
  replace indjolts=17 if a_mjind==13 & a_dtind==39;
  replace indjolts=18 if a_clswkr==2;
  replace indjolts=19 if a_clswkr==3 | a_clswkr==4;

  gen ind1_2003=.;
  replace ind1_2003=1 if inlist(a_mjind,1,21)==1;
  replace ind1_2003=2 if inlist(a_mjind,2)==1;
  replace ind1_2003=3 if inlist(a_mjind,3)==1;
  replace ind1_2003=4 if inlist(a_mjind,4,5)==1;
  replace ind1_2003=5 if inlist(a_mjind,9,10)==1;
  replace ind1_2003=6 if inlist(a_mjind,6,8)==1;
  replace ind1_2003=7 if inlist(a_mjind,7)==1;
  replace ind1_2003=8 if inlist(a_mjind,11)==1;
  replace ind1_2003=9 if inlist(a_mjind,13,20)==1;
  replace ind1_2003=10 if inlist(a_mjind,16,17,18,19)==1;
  replace ind1_2003=11 if inlist(a_mjind,15)==1;
  replace ind1_2003=12 if inlist(a_mjind,12,14)==1;
  replace ind1_2003=13 if inlist(a_mjind,22)==1;
  replace ind1_2003=14 if inlist(a_mjind,23)==1;
  
  gen occ1_2003=.;
  gen a_mjocc=a_occ;
  replace occ1_2003=1 if inlist(a_mjocc,1)==1;
  replace occ1_2003=2 if inlist(a_mjocc,2,3)==1;
  replace occ1_2003=3 if inlist(a_mjocc,6,7,8)==1;
  replace occ1_2003=4 if inlist(a_mjocc,4)==1;
  replace occ1_2003=5 if inlist(a_mjocc,5)==1;
  replace occ1_2003=6 if inlist(a_mjocc,13)==1;
  /*No matches for occ1_2003=7*/;
  /*No matches for occ1_2003=8*/;
  replace occ1_2003=9 if inlist(a_mjocc,9,10,12)==1;
  replace occ1_2003=10 if inlist(a_mjocc,11)==1;
  replace occ1_2003=11 if inlist(a_mjocc,14)==1;
  gen byte occ2_2003=.;

  gen ltue=1 if a_wkslk>=27 & a_wkslk!=. & unem==1;
  replace ltue=0 if ltue==. & unem==1;
  
  rename hourslw pehractt; // Added 8/11/15;
  replace pehractt = . if pehractt == -1;
  
  sum wklyearn uslwkearn hrlywager, detail;


end;  
  
cap program drop recodeA;
program define recodeA;
  *For 01/1989-12/1991 ;
  rename a_maritl prmarsta;

  gen educ4=.;
  replace educ4=4 if inlist(a_hga,16,17,18)==1;  //note that assumption is finish college after 4 years;
  replace educ4=3 if a_hga==16 & a_hgc==2;
  replace educ4=3 if inlist(a_hga,13,14,15)==1;
  *Following Jaeger, MLR 8/97, code 13 years, not complete as some college;
  *replace educ4=2 if a_hga==13 & a_hgc==2;
  replace educ4=2 if inlist(a_hga,12)==1;
  replace educ4=1 if a_hga==12 & a_hgc==2;
  replace educ4=1 if inlist(a_hga,0,1,2,3,4,5,6,7,8,9,10,11)==1;
  
  gen educ5=educ4;
  replace educ5=5 if (a_hga>=18 & a_hga<.) | (a_hga==17 & a_hgc==1);
      
  rename a_age age;
  recode a_sex (-1=.) (1=1) (2=0), gen(sex);
  drop a_sex;
  gen edsex=(2*educ4)-sex if inlist(educ4,1,2,3,4)==1 & inlist(sex,0,1)==1;
  
  *add years-of-education;
   gen educ_yr=(a_hga - 1) if a_hga>0;
   compare educ_yr a_hga;
  
  *Make presence of child dummy;
   *First, figure out age of householder -- defined as oldest person with linenum==1.;
   *Note that unique IDs are <hh_id hh_num hh_tiebreak linenum p_tiebreak>;
    isid hh_id hh_num hh_tiebreak linenum p_tiebreak;
    gen hasage=(age<.);
    gsort hh_id hh_num hh_tiebreak linenum -hasage -age p_tiebreak;
    by hh_id hh_num hh_tiebreak: gen hhrespage=age[1] if linenum[1]==1; 
   *Now find children in household. Set to 0 if missing data.;    
    gen chld=(age<18 & hhrespage-age>=15)*(age<. & hhrespage<.);
    gen chld_age=age if chld==1;
    egen hhchldage=min(chld_age), by(hh_id hh_num hh_tiebreak);
    *Now define the presence of a child in the HH;
    egen chld_pr=max(chld), by(hh_id hh_num hh_tiebreak);
    replace chld_pr=0 if chld==1;
    replace chld_pr=0 if age>18 & age-hhchldage<15;

*Add live-with-parent dummy (identifies each person that is living with their parents);
  gen livewithprnt=(a_parent>0)*(a_parent<.);
  
  rename a_lfsr pemlr;
  recode pemlr (1/4=1) (5/7=0) (else=.), gen(labfor);
  recode pemlr (1/2=1) (3/7=0) (else=.), gen(empl);
  gen unem=1-empl if labfor;
  replace pemlr=-1 if pemlr==.;
  
  *Note:  These are identically 0 for some months;
  rename a_fnlwgt wgt_final;
  count if l_fnlwgt<.;
  if r(N)>0 {;
    rename l_fnlwgt wgt_longfinal;
  };
  rename l_lngwgt wgt_long;
  
  recode h_year (9=1989) (0=1990) (1=1991), gen(year);
  drop h_year;
  rename h_month month;
  
  recode a_mjind (1 21=1) (2=2) (3=3) (4=4) (5=5) (6=8) (7=10) (8=9)
                 (9=6) (10=7) /*11 is split */ (12 14=17) /*13 is split*/
                 (15=16) (16 17 19=15) (18=14) (20=13) /* 22 23 are odd*/
                 (else=.), gen(ind20);
  replace ind20=11 if a_mjind==11 & a_dtind==34;
  replace ind20=12 if a_mjind==11 & a_dtind==35;
  replace ind20=13 if a_mjind==13 & a_dtind==37;
  replace ind20=17 if a_mjind==13 & a_dtind==38;
  replace ind20=18 if a_clswkr==2;
  replace ind20=19 if a_clswkr==3;
  replace ind20=20 if a_clswkr==4;               

  recode a_mjind (1 21=1) (2=2) (3=3) (4=4) (5=5) (6 8=8) (7=9)
                 (9=6) (10=7) /*11 is split */ (12 14=17) /*13 is split*/
                 (15=15) (16 17 19=14) (18=13) (20=12) /* 22 23 are odd*/
                 (else=.), gen(indjolts);
  replace indjolts=10 if a_mjind==11 & a_dtind==34;
  replace indjolts=11 if a_mjind==11 & a_dtind==35;
  replace indjolts=12 if a_mjind==13 & a_dtind==37;
  replace indjolts=16 if inlist(a_ind, 762, 770, 641);
  replace indjolts=17 if a_mjind==13 & a_dtind==38;
  replace indjolts=18 if a_clswkr==2;
  replace indjolts=19 if a_clswkr==3 | a_clswkr==4;
                 
  gen ind1_2003=.;
  replace ind1_2003=1 if inlist(a_mjind,1,21)==1;
  replace ind1_2003=2 if inlist(a_mjind,2)==1;
  replace ind1_2003=3 if inlist(a_mjind,3)==1;
  replace ind1_2003=4 if inlist(a_mjind,4,5)==1;
  replace ind1_2003=5 if inlist(a_mjind,9,10)==1;
  replace ind1_2003=6 if inlist(a_mjind,6,8)==1;
  replace ind1_2003=7 if inlist(a_mjind,7)==1;
  replace ind1_2003=8 if inlist(a_mjind,11)==1;
  replace ind1_2003=9 if inlist(a_mjind,13,20)==1;
  replace ind1_2003=10 if inlist(a_mjind,16,17,18,19)==1;
  replace ind1_2003=11 if inlist(a_mjind,15)==1;
  replace ind1_2003=12 if inlist(a_mjind,12,14)==1;
  replace ind1_2003=13 if inlist(a_mjind,22)==1;
  replace ind1_2003=14 if inlist(a_mjind,23)==1;
  
  gen occ1_2003=.;
  replace occ1_2003=1 if inlist(a_mjocc,1)==1;
  replace occ1_2003=2 if inlist(a_mjocc,2,3)==1;
  replace occ1_2003=3 if inlist(a_mjocc,6,7,8)==1;
  replace occ1_2003=4 if inlist(a_mjocc,4)==1;
  replace occ1_2003=5 if inlist(a_mjocc,5)==1;
  replace occ1_2003=6 if inlist(a_mjocc,13)==1;
  /*No matches for occ1_2003=7*/;
  /*No matches for occ1_2003=8*/;
  replace occ1_2003=9 if inlist(a_mjocc,9,10,12)==1;
  replace occ1_2003=10 if inlist(a_mjocc,11)==1;
  replace occ1_2003=11 if inlist(a_mjocc,14)==1;
  gen byte occ2_2003=.;
  
  gen ltue=1 if a_wkslk>=27 & a_wkslk!=. & unem==1;
  replace ltue=0 if ltue==. & unem==1;

  rename hg_fips stfips;
  rename a_hrs1 pehractt; // Added 8/11/15;
  replace pehractt = . if pehractt == -1;
  
  gen byte howner=(h_tenure==1 & (h_numper==1 | inlist(a_famrel,1,2)));
  
end;

cap program drop recodeB;
program define recodeB;
  *For 01/1992-12/1993 ;
  rename a_maritl prmarsta;

  gen educ4=.;
  replace educ4=1 if inlist(a_hga,31,32,33,34,35,36,37)==1;
  *Following Jaeger, MLR 8/97, code 12th grade, no diploma as HS grad;
  replace educ4=2 if inlist(a_hga,38,39)==1;
  replace educ4=3 if inlist(a_hga,40,41,42)==1;
  replace educ4=4 if inlist(a_hga,43,44,45,46)==1;
  
  gen educ5=educ4;
  replace educ5=5 if inlist(a_hga,44,45,46);
  
  rename a_age age;
  recode a_sex (-1=.) (1=1) (2=0), gen(sex);
  drop a_sex;
  gen edsex=(2*educ4)-sex if inlist(educ4,1,2,3,4)==1 & inlist(sex,0,1)==1;
  
 *Add years-of-education: The conversion is based on Jaeger 1997;
   gen educ_yr=.;
   replace educ_yr=0 if a_hga==31;
   replace educ_yr=2.5 if a_hga==32;
   replace educ_yr=5.5 if a_hga==33;
   replace educ_yr=7.5 if a_hga==34;
   replace educ_yr=9 if a_hga==35;
   replace educ_yr=10 if a_hga==36;
   replace educ_yr=11 if a_hga==37;
   replace educ_yr=12 if a_hga==38 | a_hga==39;
   replace educ_yr=13 if a_hga==40;
   replace educ_yr=14 if a_hga==41 | a_hga==42;
   replace educ_yr=16 if a_hga==43;
   replace educ_yr=18 if a_hga==44 | a_hga==45 | a_hga==46;

*Make presence of child dummy;
   *First, figure out age of householder -- defined as oldest person with linenum==1.;
   *Note that unique IDs are <hh_id hh_num hh_tiebreak linenum p_tiebreak>;
    isid hh_id hh_num hh_tiebreak linenum p_tiebreak;
    gen hasage=(age<.);
    gsort hh_id hh_num hh_tiebreak linenum -hasage -age p_tiebreak;
    by hh_id hh_num hh_tiebreak: gen hhrespage=age[1] if linenum[1]==1; 
   *Now find children in household. Set to 0 if missing data.;    
    gen chld=(age<18 & hhrespage-age>=15)*(age<. & hhrespage<.);
    gen chld_age=age if chld==1;
    egen hhchldage=min(chld_age), by(hh_id hh_num hh_tiebreak);
    *Now define the presence of a child in the HH;
    egen chld_pr=max(chld), by(hh_id hh_num hh_tiebreak);
    replace chld_pr=0 if chld==1;
    replace chld_pr=0 if age>18 & age-hhchldage<15;

*Add live-with-parent dummy (identifies each person that is living with their parents);
  gen livewithprnt=(a_parent>0)*(a_parent<.);
  
  rename a_lfsr pemlr;
  recode pemlr (1/4=1) (5/7=0) (else=.), gen(labfor);
  recode pemlr (1/2=1) (3/7=0) (else=.), gen(empl);
  gen unem=1-empl if labfor;
  
  rename a_fnlwgt wgt_final;
  rename l_fnlwgt wgt_final_long;
  rename l_lngwgt wgt_long;
  
  gen year=1990+h_year;
  rename h_month month;
  drop h_year;
  
  recode a_mjind (1 21=1) (2=2) (3=3) (4=4) (5=5) (6=8) (7=10) (8=9)
                 (9=6) (10=7) /*11 is split */ (12 14=17) /*13 is split*/
                 (15=16) (16 17 19=15) (18=14) (20=13) /* 22 23 are odd*/
                 (else=.), gen(ind20);
  replace ind20=11 if a_mjind==11 & a_dtind==34;
  replace ind20=12 if a_mjind==11 & a_dtind==35;
  replace ind20=13 if a_mjind==13 & a_dtind==37;
  replace ind20=17 if a_mjind==13 & a_dtind==38;
  replace ind20=18 if a_clswkr==2;
  replace ind20=19 if a_clswkr==3;
  replace ind20=20 if a_clswkr==4;               

  recode a_mjind (1 21=1) (2=2) (3=3) (4=4) (5=5) (6 8=8) (7=9)
                 (9=6) (10=7) /*11 is split */ (12 14=17) /*13 is split*/
                 (15=15) (16 17 19=14) (18=13) (20=12) /* 22 23 are odd*/
                 (else=.), gen(indjolts);
  replace indjolts=10 if a_mjind==11 & a_dtind==34;
  replace indjolts=11 if a_mjind==11 & a_dtind==35;
  replace indjolts=12 if a_mjind==13 & a_dtind==37;
  replace indjolts=16 if inlist(a_ind, 762, 770, 641);
  replace indjolts=17 if a_mjind==13 & a_dtind==38;
  replace indjolts=18 if a_clswkr==2;
  replace indjolts=19 if a_clswkr==3 | a_clswkr==4;
                 
  gen ind1_2003=.;
  replace ind1_2003=1 if inlist(a_mjind,1,21)==1;
  replace ind1_2003=2 if inlist(a_mjind,2)==1;
  replace ind1_2003=3 if inlist(a_mjind,3)==1;
  replace ind1_2003=4 if inlist(a_mjind,4,5)==1;
  replace ind1_2003=5 if inlist(a_mjind,9,10)==1;
  replace ind1_2003=6 if inlist(a_mjind,6,8)==1;
  replace ind1_2003=7 if inlist(a_mjind,7)==1;
  replace ind1_2003=8 if inlist(a_mjind,11)==1;
  replace ind1_2003=9 if inlist(a_mjind,13,20)==1;
  replace ind1_2003=10 if inlist(a_mjind,16,17,18,19)==1;
  replace ind1_2003=11 if inlist(a_mjind,15)==1;
  replace ind1_2003=12 if inlist(a_mjind,12,14)==1;
  replace ind1_2003=13 if inlist(a_mjind,22)==1;
  replace ind1_2003=14 if inlist(a_mjind,23)==1;
  
  gen occ1_2003=.;
  replace occ1_2003=1 if inlist(a_mjocc,1)==1;
  replace occ1_2003=2 if inlist(a_mjocc,2,3)==1;
  replace occ1_2003=3 if inlist(a_mjocc,6,7,8)==1;
  replace occ1_2003=4 if inlist(a_mjocc,4)==1;
  replace occ1_2003=5 if inlist(a_mjocc,5)==1;
  replace occ1_2003=6 if inlist(a_mjocc,13)==1;
  /*No matches for occ1_2003=7*/;
  /*No matches for occ1_2003=8*/;
  replace occ1_2003=9 if inlist(a_mjocc,9,10,12)==1;
  replace occ1_2003=10 if inlist(a_mjocc,11)==1;
  replace occ1_2003=11 if inlist(a_mjocc,14)==1;
  gen byte occ2_2003=.;
  
  gen ltue=1 if a_wkslk>=27 & a_wkslk!=. & unem==1;
  replace ltue=0 if ltue==. & unem==1;
  
  rename hg_fips stfips;
  
  rename a_hrs1 pehractt; // Added 8/11/15;
  replace pehractt = . if pehractt == -1;

  gen byte howner=(h_tenure==1 & (h_numper==1 | inlist(a_famrel,1,2)));

end;

cap program drop recodeC;
program define recodeC;
  *For 01/1994-12/1997;
  gen educ4=.;
  replace educ4=1 if inlist(peeduca,31,32,33,34,35,36,37)==1;
  replace educ4=2 if inlist(peeduca,38,39)==1;
  replace educ4=3 if inlist(peeduca,40,41,42)==1;
  replace educ4=4 if inlist(peeduca,43,44,45,46)==1;
  
  gen educ5=educ4;
  replace educ5=5 if inlist(peeduca,44,45,46);
  
  rename peage age;
  recode pesex (-1=.) (1=1) (2=0), gen(sex);
  drop pesex;
  gen edsex=(2*educ4)-sex if inlist(educ4,1,2,3,4)==1 & inlist(sex,0,1)==1;
  
*Add years-of-education: The conversion is based on Jaeger 1997;
   gen educ_yr=.;
   replace educ_yr=0 if peeduca==31;
   replace educ_yr=2.5 if peeduca==32;
   replace educ_yr=5.5 if peeduca==33;
   replace educ_yr=7.5 if peeduca==34;
   replace educ_yr=9 if peeduca==35;
   replace educ_yr=10 if peeduca==36;
   replace educ_yr=11 if peeduca==37;
   replace educ_yr=12 if peeduca==38 | peeduca==39;
   replace educ_yr=13 if peeduca==40;
   replace educ_yr=14 if peeduca==41 | peeduca==42;
   replace educ_yr=16 if peeduca==43;
   replace educ_yr=18 if peeduca==44 | peeduca==45 | peeduca==46;
   
*Make presence of child dummy;
   *First, figure out age of householder -- defined as oldest person with linenum==1.;
   *Note that unique IDs are <hh_id hh_num hh_tiebreak linenum p_tiebreak>;
    isid hh_id hh_num hh_tiebreak linenum p_tiebreak;
    gen hasage=(age<.);
    gsort hh_id hh_num hh_tiebreak linenum -hasage -age p_tiebreak;
    by hh_id hh_num hh_tiebreak: gen hhrespage=age[1] if linenum[1]==1; 
   *Now find children in household. Set to 0 if missing data.;    
    gen chld=(age<18 & hhrespage-age>=15)*(age<. & hhrespage<.);
    gen chld_age=age if chld==1;
    egen hhchldage=min(chld_age), by(hh_id hh_num hh_tiebreak);
    *Now define the presence of a child in the HH;
    egen chld_pr=max(chld), by(hh_id hh_num hh_tiebreak);
    replace chld_pr=0 if chld==1;
    replace chld_pr=0 if age>18 & age-hhchldage<15;

*Add live-with-parent dummy (identifies each person that is living with their parents);
  gen livewithprnt=(peparent>0)*(peparent<.);
  
  *rename a_lfsr pemlr;
  recode pemlr (1/4=1) (5/7=0) (else=.), gen(labfor);
  recode pemlr (1/2=1) (3/7=0) (else=.), gen(empl);
  gen unem=1-empl if labfor;
  
  rename pwsswgt wgt_final;
  rename pwlgwgt wgt_long;
  rename pworwgt wgt_ord;
  
  gen year=hryear+1900;
  rename hrmonth month;
  drop hryear;
  
 *Major industry recoded (job 1);
  recode prmjind1 (1 21=1) (2=2) (3=3) (4=4) (5=5) (6=8) (7=10) (8=9)
                  (9=6) (10=7) /*11 is split */ (12 14=17) /*13 is split*/
                  (15=16) (16 17 19=15) (18=14) (20=13) /* 22 23 are odd*/
                 (else=.), gen(ind20);
  replace ind20=11 if prmjind1==11 & inlist(peio1icd, 700, 701, 702, 710, 711);
  replace ind20=12 if prmjind1==11 & peio1icd==712;
  replace ind20=13 if prmjind1==13 & peio1icd>=721 & peio1icd<=741;
  replace ind20=17 if prmjind1==13 & peio1icd>=742 & peio1icd<=760;
  replace ind20=18 if peio1cow==1;
  replace ind20=19 if peio1cow==2;
  replace ind20=20 if peio1cow==3;               

  recode prmjind1 (1 21=1) (2=2) (3=3) (4=4) (5=5) (6 8=8) (7=9)
                 (9=6) (10=7) /*11 is split */ (12 14=17) /*13 is split*/
                 (15=15) (16 17 19=14) (18=13) (20=12) /* 22 23 are odd*/
                 (else=.), gen(indjolts);
  replace indjolts=10 if prmjind1==11 & inlist(peio1icd, 700, 701, 702, 710, 711);
  replace indjolts=11 if prmjind1==11 & peio1icd==712;
  replace indjolts=12 if prmjind1==13 & peio1icd>=721 & peio1icd<=741;
  replace indjolts=16 if inlist(peio1icd, 762, 770, 641);
  replace indjolts=17 if prmjind1==13 & peio1icd>=742 & peio1icd<=760;
  replace indjolts=18 if peio1cow==1;
  replace indjolts=19 if peio1cow==2 | peio1cow==3;

  gen ind1_2003=.;
  replace ind1_2003=1 if inlist(prmjind1,1,21)==1;
  replace ind1_2003=2 if inlist(prmjind1,2)==1;
  replace ind1_2003=3 if inlist(prmjind1,3)==1;
  replace ind1_2003=4 if inlist(prmjind1,4,5)==1;
  replace ind1_2003=5 if inlist(prmjind1,9,10)==1;
  replace ind1_2003=6 if inlist(prmjind1,6,8)==1;
  replace ind1_2003=7 if inlist(prmjind1,7)==1;
  replace ind1_2003=8 if inlist(prmjind1,11)==1;
  replace ind1_2003=9 if inlist(prmjind1,13,20)==1;
  replace ind1_2003=10 if inlist(prmjind1,16,17,18,19)==1;
  replace ind1_2003=11 if inlist(prmjind1,15)==1;
  replace ind1_2003=12 if inlist(prmjind1,12,14)==1;
  replace ind1_2003=13 if inlist(prmjind1,22)==1;
  replace ind1_2003=14 if inlist(prmjind1,23)==1;
  
  gen ind2_2003=.;
  replace ind2_2003=1 if inlist(prmjind2,1,21)==1;
  replace ind2_2003=2 if inlist(prmjind2,2)==1;
  replace ind2_2003=3 if inlist(prmjind2,3)==1;
  replace ind2_2003=4 if inlist(prmjind2,4,5)==1;
  replace ind2_2003=5 if inlist(prmjind2,9,10)==1;
  replace ind2_2003=6 if inlist(prmjind2,6,8)==1;
  replace ind2_2003=7 if inlist(prmjind2,7)==1;
  replace ind2_2003=8 if inlist(prmjind2,11)==1;
  replace ind2_2003=9 if inlist(prmjind2,13,20)==1;
  replace ind2_2003=10 if inlist(prmjind2,16,17,18,19)==1;
  replace ind2_2003=11 if inlist(prmjind2,15)==1;
  replace ind2_2003=12 if inlist(prmjind2,12,14)==1;
  replace ind2_2003=13 if inlist(prmjind2,22)==1;
  replace ind2_2003=14 if inlist(prmjind2,23)==1;
  
  gen occ1_2003=.;
  replace occ1_2003=1 if inlist(prmjocc1,1)==1;
  replace occ1_2003=2 if inlist(prmjocc1,2,3)==1;
  replace occ1_2003=3 if inlist(prmjocc1,6,7,8)==1;
  replace occ1_2003=4 if inlist(prmjocc1,4)==1;
  replace occ1_2003=5 if inlist(prmjocc1,5)==1;
  replace occ1_2003=6 if inlist(prmjocc1,13)==1;
  /*No matches for occ1_2003=7*/;
  /*No matches for occ1_2003=8*/;
  replace occ1_2003=9 if inlist(prmjocc1,9,10,12)==1;
  replace occ1_2003=10 if inlist(prmjocc1,11)==1;
  replace occ1_2003=11 if inlist(prmjocc1,14)==1;
  
  gen occ2_2003=.;
  replace occ2_2003=1 if inlist(prmjocc2,1)==1;
  replace occ2_2003=2 if inlist(prmjocc2,2,3)==1;
  replace occ2_2003=3 if inlist(prmjocc2,6,7,8)==1;
  replace occ2_2003=4 if inlist(prmjocc2,4)==1;
  replace occ2_2003=5 if inlist(prmjocc2,5)==1;
  replace occ2_2003=6 if inlist(prmjocc2,13)==1;
  /*No matches for occ2_2003=7*/;
  /*No matches for occ2_2003=8*/;
  replace occ2_2003=9 if inlist(prmjocc2,9,10,12)==1;
  replace occ2_2003=10 if inlist(prmjocc2,11)==1;
  replace occ2_2003=11 if inlist(prmjocc2,14)==1;
  
  gen ltue=1 if prunedur>=27 & prunedur!=. & unem==1;
  replace ltue=0 if ltue==. & unem==1;
  
  rename gestfips stfips;
  replace pehractt = . if pehractt == -1;

  gen byte howner=(hetenure==1 & (hrnumhou==1 | inlist(prfamrel,1,2)));

end;

cap program drop recodeD;
program define recodeD;
  *For 01/1998-12/2002;
  gen educ4=.;
  replace educ4=1 if inlist(peeduca,31,32,33,34,35,36,37)==1;
  replace educ4=2 if inlist(peeduca,38,39)==1;
  replace educ4=3 if inlist(peeduca,40,41,42)==1;
  replace educ4=4 if inlist(peeduca,43,44,45,46)==1;
  
  gen educ5=educ4;
  replace educ5=5 if inlist(peeduca,44,45,46);

  rename peage age;
  recode pesex (-1=.) (1=1) (2=0), gen(sex);
  drop pesex;
  gen edsex=(2*educ4)-sex if inlist(educ4,1,2,3,4)==1 & inlist(sex,0,1)==1;
  
*Add years-of-education: The conversion is based on Jaeger 1997;
   gen educ_yr=.;
   replace educ_yr=0 if peeduca==31;
   replace educ_yr=2.5 if peeduca==32;
   replace educ_yr=5.5 if peeduca==33;
   replace educ_yr=7.5 if peeduca==34;
   replace educ_yr=9 if peeduca==35;
   replace educ_yr=10 if peeduca==36;
   replace educ_yr=11 if peeduca==37;
   replace educ_yr=12 if peeduca==38 | peeduca==39;
   replace educ_yr=13 if peeduca==40;
   replace educ_yr=14 if peeduca==41 | peeduca==42;
   replace educ_yr=16 if peeduca==43;
   replace educ_yr=18 if peeduca==44 | peeduca==45 | peeduca==46;

*Make presence of child dummy;
   *First, figure out age of householder -- defined as oldest person with linenum==1.;
   *Note that unique IDs are <hh_id hh_num hh_tiebreak linenum p_tiebreak>;
    isid hh_id hh_num hh_tiebreak linenum p_tiebreak;
    gen hasage=(age<.);
    gsort hh_id hh_num hh_tiebreak linenum -hasage -age p_tiebreak;
    by hh_id hh_num hh_tiebreak: gen hhrespage=age[1] if linenum[1]==1; 
   *Now find children in household. Set to 0 if missing data.;    
    gen chld=(age<18 & hhrespage-age>=15)*(age<. & hhrespage<.);
    gen chld_age=age if chld==1;
    egen hhchldage=min(chld_age), by(hh_id hh_num hh_tiebreak);
    *Now define the presence of a child in the HH;
    egen chld_pr=max(chld), by(hh_id hh_num hh_tiebreak);
    replace chld_pr=0 if chld==1;
    replace chld_pr=0 if age>18 & age-hhchldage<15;
    
*Add live-with-parent dummy (identifies each person that is living with their parents);
  gen livewithprnt=(peparent>0)*(peparent<.);

  recode pemlr (1/4=1) (5/7=0) (else=.), gen(labfor);
  recode pemlr (1/2=1) (3/7=0) (else=.), gen(empl);
  gen unem=1-empl if labfor;
  
  rename pwcmpwgt wgt_comp;
  rename pwsswgt wgt_final;
  rename pwlgwgt wgt_long;
  rename pworwgt wgt_ord;
  
  rename hryear4 year;
  rename hrmonth month;
  
   *Major industry recoded (job 1);
  recode prmjind1 (1 21=1) (2=2) (3=3) (4=4) (5=5) (6=8) (7=10) (8=9)
                  (9=6) (10=7) /*11 is split */ (12 14=17) /*13 is split*/
                  (15=16) (16 17 19=15) (18=14) (20=13) /* 22 23 are odd*/
                 (else=.), gen(ind20);
  replace ind20=11 if prmjind1==11 & inlist(peio1icd, 700, 701, 702, 710, 711);
  replace ind20=12 if prmjind1==11 & peio1icd==712;
  replace ind20=13 if prmjind1==13 & peio1icd>=721 & peio1icd<=741;
  replace ind20=17 if prmjind1==13 & peio1icd>=742 & peio1icd<=760;
  replace ind20=18 if peio1cow==1;
  replace ind20=19 if peio1cow==2;
  replace ind20=20 if peio1cow==3;               

  recode prmjind1 (1 21=1) (2=2) (3=3) (4=4) (5=5) (6 8=8) (7=9)
                 (9=6) (10=7) /*11 is split */ (12 14=17) /*13 is split*/
                 (15=15) (16 17 19=14) (18=13) (20=12) /* 22 23 are odd*/
                 (else=.), gen(indjolts);
  replace indjolts=10 if prmjind1==11 & inlist(peio1icd, 700, 701, 702, 710, 711);
  replace indjolts=11 if prmjind1==11 & peio1icd==712;
  replace indjolts=12 if prmjind1==13 & peio1icd>=721 & peio1icd<=741;
  replace indjolts=16 if inlist(peio1icd, 762, 770, 641);
  replace indjolts=17 if prmjind1==13 & peio1icd>=742 & peio1icd<=760;
  replace indjolts=18 if peio1cow==1;
  replace indjolts=19 if peio1cow==2 | peio1cow==3;

  gen ind1_2003=.;
  replace ind1_2003=1 if inlist(prmjind1,1,21)==1;
  replace ind1_2003=2 if inlist(prmjind1,2)==1;
  replace ind1_2003=3 if inlist(prmjind1,3)==1;
  replace ind1_2003=4 if inlist(prmjind1,4,5)==1;
  replace ind1_2003=5 if inlist(prmjind1,9,10)==1;
  replace ind1_2003=6 if inlist(prmjind1,6,8)==1;
  replace ind1_2003=7 if inlist(prmjind1,7)==1;
  replace ind1_2003=8 if inlist(prmjind1,11)==1;
  replace ind1_2003=9 if inlist(prmjind1,13,20)==1;
  replace ind1_2003=10 if inlist(prmjind1,16,17,18,19)==1;
  replace ind1_2003=11 if inlist(prmjind1,15)==1;
  replace ind1_2003=12 if inlist(prmjind1,12,14)==1;
  replace ind1_2003=13 if inlist(prmjind1,22)==1;
  replace ind1_2003=14 if inlist(prmjind1,23)==1;
  
  gen ind2_2003=.;
  replace ind2_2003=1 if inlist(prmjind2,1,21)==1;
  replace ind2_2003=2 if inlist(prmjind2,2)==1;
  replace ind2_2003=3 if inlist(prmjind2,3)==1;
  replace ind2_2003=4 if inlist(prmjind2,4,5)==1;
  replace ind2_2003=5 if inlist(prmjind2,9,10)==1;
  replace ind2_2003=6 if inlist(prmjind2,6,8)==1;
  replace ind2_2003=7 if inlist(prmjind2,7)==1;
  replace ind2_2003=8 if inlist(prmjind2,11)==1;
  replace ind2_2003=9 if inlist(prmjind2,13,20)==1;
  replace ind2_2003=10 if inlist(prmjind2,16,17,18,19)==1;
  replace ind2_2003=11 if inlist(prmjind2,15)==1;
  replace ind2_2003=12 if inlist(prmjind2,12,14)==1;
  replace ind2_2003=13 if inlist(prmjind2,22)==1;
  replace ind2_2003=14 if inlist(prmjind2,23)==1;
  
  gen occ1_2003=.;
  replace occ1_2003=1 if inlist(prmjocc1,1)==1;
  replace occ1_2003=2 if inlist(prmjocc1,2,3)==1;
  replace occ1_2003=3 if inlist(prmjocc1,6,7,8)==1;
  replace occ1_2003=4 if inlist(prmjocc1,4)==1;
  replace occ1_2003=5 if inlist(prmjocc1,5)==1;
  replace occ1_2003=6 if inlist(prmjocc1,13)==1;
  /*No matches for occ1_2003=7*/;
  /*No matches for occ1_2003=8*/;
  replace occ1_2003=9 if inlist(prmjocc1,9,10,12)==1;
  replace occ1_2003=10 if inlist(prmjocc1,11)==1;
  replace occ1_2003=11 if inlist(prmjocc1,14)==1;
  
  gen occ2_2003=.;
  replace occ2_2003=1 if inlist(prmjocc2,1)==1;
  replace occ2_2003=2 if inlist(prmjocc2,2,3)==1;
  replace occ2_2003=3 if inlist(prmjocc2,6,7,8)==1;
  replace occ2_2003=4 if inlist(prmjocc2,4)==1;
  replace occ2_2003=5 if inlist(prmjocc2,5)==1;
  replace occ2_2003=6 if inlist(prmjocc2,13)==1;
  /*No matches for occ2_2003=7*/;
  /*No matches for occ2_2003=8*/;
  replace occ2_2003=9 if inlist(prmjocc2,9,10,12)==1;
  replace occ2_2003=10 if inlist(prmjocc2,11)==1;
  replace occ2_2003=11 if inlist(prmjocc2,14)==1;
  
  gen ltue=1 if prunedur>=27 & prunedur!=. & unem==1;
  replace ltue=0 if ltue==. & unem==1;
  
  rename gestfips stfips;
  replace pehractt = . if pehractt == -1;
  
  gen byte howner=(hetenure==1 & (hrnumhou==1 | inlist(prfamrel,1,2)));

end;

  
cap program drop recodeE;
program define recodeE;
 recodeF;
end;

cap program drop recodeF;
program define recodeF;
  *For 05/2004-4/2012 ;
   gen educ4=.;
   replace educ4=1 if inlist(peeduca,31,32,33,34,35,36,37)==1;
   replace educ4=2 if inlist(peeduca,38,39)==1;
   replace educ4=3 if inlist(peeduca,40,41,42)==1;
   replace educ4=4 if inlist(peeduca,43,44,45,46)==1;
  
  gen educ5=educ4;
  replace educ5=5 if inlist(peeduca,44,45,46);
  
   rename peage age;
   recode pesex (-1=.) (1=1) (2=0), gen(sex);
   drop pesex;
   gen edsex=(2*educ4)-sex if inlist(educ4,1,2,3,4)==1 & inlist(sex,0,1)==1;


*Add years-of-education: The conversion is based on Jaeger 1997;
   gen educ_yr=.;
   replace educ_yr=0 if peeduca==31;
   replace educ_yr=2.5 if peeduca==32;
   replace educ_yr=5.5 if peeduca==33;
   replace educ_yr=7.5 if peeduca==34;
   replace educ_yr=9 if peeduca==35;
   replace educ_yr=10 if peeduca==36;
   replace educ_yr=11 if peeduca==37;
   replace educ_yr=12 if peeduca==38 | peeduca==39;
   replace educ_yr=13 if peeduca==40;
   replace educ_yr=14 if peeduca==41 | peeduca==42;
   replace educ_yr=16 if peeduca==43;
   replace educ_yr=18 if peeduca==44 | peeduca==45 | peeduca==46;

*Make presence of child dummy;
   *First, figure out age of householder -- defined as oldest person with linenum==1.;
   *Note that unique IDs are <hh_id hh_num hh_tiebreak linenum p_tiebreak>;
    isid hh_id hh_num hh_tiebreak linenum p_tiebreak;
    gen hasage=(age<.);
    gsort hh_id hh_num hh_tiebreak linenum -hasage -age p_tiebreak;
    by hh_id hh_num hh_tiebreak: gen hhrespage=age[1] if linenum[1]==1; 
   *Now find children in household. Set to 0 if missing data.;    
    gen chld=(age<18 & hhrespage-age>=15)*(age<. & hhrespage<.);
    gen chld_age=age if chld==1;
    egen hhchldage=min(chld_age), by(hh_id hh_num hh_tiebreak);
    *Now define the presence of a child in the HH;
    egen chld_pr=max(chld), by(hh_id hh_num hh_tiebreak);
    replace chld_pr=0 if chld==1;
    replace chld_pr=0 if age>18 & age-hhchldage<15;
    
*Add live-with-parent dummy (identifies each person that is living with their parents);
  gen livewithprnt=(peparent>0)*(peparent<.);
    
   recode pemlr (1/4=1) (5/7=0) (else=.), gen(labfor);
   recode pemlr (1/2=1) (3/7=0) (else=.), gen(empl);
   gen unem=1-empl if labfor;

   rename pwcmpwgt wgt_comp;
   rename pwsswgt wgt_final;
   rename pwlgwgt wgt_long;
   rename pworwgt wgt_ord;
   
   *Major industry recoded (job 1);
  recode primind1 (1=1) (2=2) (3=3) (4=4) (5=5) (6=6) (7=7) (8=8) (9=9) (10=10)
                  (11=11) (12=12) (13 14=13) (15=14) (16=15) (17 18=16)
                  (19 20=17) /* 21,22 are odd*/
                 (else=.), gen(ind20);
  replace ind20=18 if peio1cow==1;
  replace ind20=19 if peio1cow==2;
  replace ind20=20 if peio1cow==3;               

  recode primind1 (1=1) (2=2) (3=3) (4=4) (5=5) (6=6) (7=7) (8/9=8) (10=9)
                  (11=10) (12=11) (13 14=12) (15=13) (16=14) (17=15) (18=16)
                  (19 20=17) /* 21,22 are odd*/
                 (else=.), gen(indjolts);
  replace indjolts=18 if peio1cow==1;
  replace indjolts=19 if peio1cow==2 | peio1cow==3;

   gen ind1_2003=prmjind1 if prmjind1>=0;
   gen ind2_2003=prmjind2 if prmjind2>=0;
   gen occ1_2003=prmjocc1 if prmjocc1>=0;
   gen occ2_2003=prmjocc2 if prmjocc2>=0;
   drop prmjind? prmjocc?;
   
   gen ltue=1 if prunedur>=27 & prunedur!=. & unem==1;
   replace ltue=0 if ltue==. & unem==1;

   rename hryear4 year;
   rename hrmonth month;
   
   rename gestfips stfips;
   replace pehractt = . if pehractt == -1;

  gen byte howner=(hetenure==1 & (hrnumhou==1 | inlist(prfamrel,1,2)));
  
  *Average Education Level by Occupation;
  egen educ_occup=mean(educ_yr), by(peio1ocd);


end;


cap program drop recodeG;
program define recodeG;
  *For 05/2012-;
   gen educ4=.;
   replace educ4=1 if inlist(peeduca,31,32,33,34,35,36,37)==1;
   replace educ4=2 if inlist(peeduca,38,39)==1;
   replace educ4=3 if inlist(peeduca,40,41,42)==1;
   replace educ4=4 if inlist(peeduca,43,44,45,46)==1;
 
  gen educ5=educ4;
  replace educ5=5 if inlist(peeduca,44,45,46);
      
   rename prtage age;
   recode pesex (-1=.) (1=1) (2=0), gen(sex);
   drop pesex;
   gen edsex=(2*educ4)-sex if inlist(educ4,1,2,3,4)==1 & inlist(sex,0,1)==1;
  
*Add years-of-education: The conversion is based on Jaeger 1997;
   gen educ_yr=.;
   replace educ_yr=0 if peeduca==31;
   replace educ_yr=2.5 if peeduca==32;
   replace educ_yr=5.5 if peeduca==33;
   replace educ_yr=7.5 if peeduca==34;
   replace educ_yr=9 if peeduca==35;
   replace educ_yr=10 if peeduca==36;
   replace educ_yr=11 if peeduca==37;
   replace educ_yr=12 if peeduca==38 | peeduca==39;
   replace educ_yr=13 if peeduca==40;
   replace educ_yr=14 if peeduca==41 | peeduca==42;
   replace educ_yr=16 if peeduca==43;
   replace educ_yr=18 if peeduca==44 | peeduca==45 | peeduca==46;

*Make presence of child dummy;
   *First, figure out age of householder -- defined as oldest person with linenum==1.;
   *Note that unique IDs are <hh_id hh_num hh_tiebreak linenum p_tiebreak>;
    isid hh_id hh_num hh_tiebreak linenum p_tiebreak;
    gen hasage=(age<.);
    gsort hh_id hh_num hh_tiebreak linenum -hasage -age p_tiebreak;
    by hh_id hh_num hh_tiebreak: gen hhrespage=age[1] if linenum[1]==1; 
   *Now find children in household. Set to 0 if missing data.;    
    gen chld=(age<18 & hhrespage-age>=15)*(age<. & hhrespage<.);
    gen chld_age=age if chld==1;
    egen hhchldage=min(chld_age), by(hh_id hh_num hh_tiebreak);
    *Now define the presence of a child in the HH;
    egen chld_pr=max(chld), by(hh_id hh_num hh_tiebreak);
    replace chld_pr=0 if chld==1;
    replace chld_pr=0 if age>18 & age-hhchldage<15;
    
*Add live-with-parent dummy (identifies each person that is living with their parents);
  gen livewithprnt=(peparent>0)*(peparent<.);
	
   recode pemlr (1/4=1) (5/7=0) (else=.), gen(labfor);
   recode pemlr (1/2=1) (3/7=0) (else=.), gen(empl);
   gen unem=1-empl if labfor;

   rename pwcmpwgt wgt_comp;
   rename pwsswgt wgt_final;
   rename pwlgwgt wgt_long;
   rename pworwgt wgt_ord;
  
   *Major industry recoded (job 1);
  recode primind1 (1=1) (2=2) (3=3) (4=4) (5=5) (6=6) (7=7) (8=8) (9=9) (10=10)
                  (11=11) (12=12) (13 14=13) (15=14) (16=15) (17 18=16)
                  (19 20=17) /* 21,22 are odd*/
                 (else=.), gen(ind20);
  replace ind20=18 if peio1cow==1;
  replace ind20=19 if peio1cow==2;
  replace ind20=20 if peio1cow==3;               

  recode primind1 (1=1) (2=2) (3=3) (4=4) (5=5) (6=6) (7=7) (8/9=8) (10=9)
                  (11=10) (12=11) (13 14=12) (15=13) (16=14) (17=15) (18=16)
                  (19 20=17) /* 21,22 are odd*/
                 (else=.), gen(indjolts);
  replace indjolts=18 if peio1cow==1;
  replace indjolts=19 if peio1cow==2 | peio1cow==3;

   gen ind1_2003=prmjind1 if prmjind1>=0;
   gen ind2_2003=prmjind2 if prmjind2>=0;
   gen occ1_2003=prmjocc1 if prmjocc1>=0;
   gen occ2_2003=prmjocc2 if prmjocc2>=0;
   drop prmjind? prmjocc?;
   
   gen ltue=1 if prunedur>=27 & prunedur!=. & unem==1;
   replace ltue=0 if ltue==. & unem==1;

   rename hryear4 year;
   rename hrmonth month;
   
   rename gestfips stfips;
   replace pehractt = . if pehractt == -1;

  gen byte howner=(hetenure==1 & (hrnumhou==1 | inlist(prfamrel,1,2)));
  
  
end;

// Loop to read in housing tenure variables -- not currently used;
/* forvalues m=`startmo'/`endmo' {;
 	 tempfile month`m';
 	 *Assign to categories;
 	  if `m'>=ym(1978,1) & `m'<=ym(1988,12) local cat="0";
 	  else if `m'>=ym(1989,1) & `m'<=ym(1991,12) local cat="A";
 	  else if `m'>=ym(1992,1) & `m'<=ym(1993,12) local cat="B";
 	  else if `m'>=ym(1994,1) & `m'<=ym(1997,12) local cat="C";
 	  else if `m'>=ym(1998,1) & `m'<=ym(2002,12) local cat="D";
 	  else if `m'>=ym(2003,1) & `m'<=ym(2004,4) local cat="E";
 	  else if `m'>=ym(2004,5) & `m'<=ym(2012,4) local cat="F";
 	  else if `m'>=ym(2012,5) & `m'<=ym(2017,5) local cat="G";
 	  else {;
 	  	 di "ERROR: MONTH " %tm `m' "OUT OF RANGE";
 	  	 error;
 	  };
 	  di "Starting month " %tm `m' ".  Category `cat'";
 	  
    local year=year(dofm(`m'));
    local month=month(dofm(`m'));
    if `year'<2000 local yy=`year'-1900;
    else if `year'>=2010 local yy=`year'-2000;
    else {;
    	local yy=`year'-2000;
    	local yy "0`yy'";
    };

    if `month'<10 local yearmo "`year'0`month'";
    else local yearmo "`year'`month'";
    if `month'<10 local yymo "`yy'0`month'";
    else local yymo "`yy'`month'";

    local origfile "cpsb`yymo'"; 
    
    //Read in HETENURE variable, if appropriate, and create temp file ;
  	if `m'>=ym(1999,1) & `m'<=ym(2002,12)  {;
  	  if `month'==1 local mon "jan";
  	  if `month'==2 local mon "feb";
  	  if `month'==3 local mon "mar";
  	  if `month'==4 local mon "apr";
  	  if `month'==5 local mon "may";
  	  if `month'==6 local mon "jun";
  	  if `month'==7 local mon "jul";
  	  if `month'==8 local mon "aug";
  	  if `month'==9 local mon "sep";
  	  if `month'==10 local mon "oct";
  	  if `month'==11 local mon "nov";
  	  if `month'==12 local mon "dec";
  	  local monyy "`mon'`yy'";
di "For month " %tm `m' " we came up with monyy=<`monyy'>";
  	  
		  //need to rename the csv files?;
		  insheet using `cpsraw'/hetenure_`monyy'.csv, clear; 
			tempfile hetenure_`m';
			save `hetenure_`m'';
    };
    
	 
	 * 2003 has all the months together in one csv file.;
	 else if `m'>=ym(2003,1) & `m'<=ym(2003,12) {;
		 insheet using `cpsraw'/hetenure03.csv, clear;
		 keep if ym(hryear4, hrmonth)==`m';
		 drop hryear4 hrmonth;
		 tempfile hetenure_`m';
		 save `hetenure_`m'', replace; //having saving issue "invalid name";
	 };

};
*End of housing tenure loop.  */;

*Loop;
 forvalues m=`startmo'/`endmo' {;
 	 tempfile month`m';
 	 *Assign to categories;
 	  if `m'>=ym(1978,1) & `m'<=ym(1983,12) local cat="0";
	  else if `m'>=ym(1984,1) & `m'<=ym(1988,12) local cat="H";
 	  else if `m'>=ym(1989,1) & `m'<=ym(1991,12) local cat="A";
 	  else if `m'>=ym(1992,1) & `m'<=ym(1993,12) local cat="B";
 	  else if `m'>=ym(1994,1) & `m'<=ym(1997,12) local cat="C";
 	  else if `m'>=ym(1998,1) & `m'<=ym(2002,12) local cat="D";
 	  else if `m'>=ym(2003,1) & `m'<=ym(2004,4)  local cat="E";
 	  else if `m'>=ym(2004,5) & `m'<=ym(2012,4)  local cat="F";
 	  else if `m'>=ym(2012,5) & `m'<=ym(2019,12) local cat="G";
 	  else {;
 	  	 di "ERROR: MONTH " %tm `m' "OUT OF RANGE";
 	  	 error;
 	  };
 	  di "Starting month " %tm `m' ".  Category `cat'";
 	  
    local year=year(dofm(`m'));
    local month=month(dofm(`m'));
    if `year'<2000 local yy=`year'-1900;
    else if `year'>=2010 local yy=`year'-2000;
    else {;
    	local yy=`year'-2000;
    	local yy "0`yy'";
    };
    
    if `month'<10 local yearmo "`year'0`month'";
    else local yearmo "`year'`month'";
    if `month'<10 local yymo "`yy'0`month'";
    else local yymo "`yy'`month'";

    local origfile "cpsb`yymo'"; 	 
 	 
   *Read in the data;
    if `doasproject'==1 project, original("`cpsorig'/`origfile'.dta.gz");
    !zcat `cpsorig'/`origfile'.dta.gz > ./tmp_`origfile'.dta;
    *use `cpsorig'/`origfile'.dta;
    use `uselist`cat'1' `uselist`cat'2' `uselist`cat'3' using tmp_`origfile'.dta, clear;
    !rm -f tmp_`origfile'.dta;
    

  //Fix IDs to be unique;
  //In principle, hh_id-hh_num-linenum are supposed to uniquely identify individuals;
  //(except in 4/1994-5/1995, when stfips is needed also). In practice, they don't.;
  //Fix this by making a new variable that breaks ties based on file listing order.;
     //Start by renaming ID variables to be uniform;
   if `m'>=ym(1989,1) & `m'<=ym(1993,12) {;
        rename h_id hh_id;
        rename h_hhnum hh_num;
        rename a_lineno linenum;
	rename a_enrlw peschenr;
      };
      else if `m'>=ym(1994,1) {;
        rename hrhhid hh_id;
        if `m'<ym(2004,5) rename huhhnum hh_num;
        else destring hrhhid2, gen(hh_num);
        rename pulineno linenum;
      };
     //Clean up a few missings;
      su hh_num, meanonly;
      qui replace hh_num=r(max)+1 if hh_num==.;
      su linenum, meanonly;
      qui replace linenum=r(max)+1 if linenum==.; 
     //Now give each new HH a sort-order number, and use this to generate a tiebreaker;
      gen origorder=_n;
      gen newhh=(hh_id~=hh_id[_n-1] | hh_num~=hh_num[_n-1]) ;
      replace newhh=1 if _n==1;
      gen hh_sortnum=sum(newhh);
      drop newhh;
      sort hh_id hh_num hh_sortnum linenum origorder;
      egen hh_sortnum2=group(hh_id hh_num hh_sortnum);
      by hh_id hh_num: gen hh_tiebreak=1+(hh_sortnum2-hh_sortnum2[1]);
     //There are still a few ties -- people listed all together in the same HH
     //with the same line number. Break these ties also./
      sort hh_id hh_num hh_tiebreak linenum origorder;
      by hh_id hh_num hh_tiebreak linenum: gen p_tiebreak=_n;
      isid hh_id hh_num hh_tiebreak linenum p_tiebreak;
      drop hh_sortnum;
      sort origorder;
      drop origorder;
  *Renaming and cleaning up some vairables from the earlier years;
     if `m'<=ym(1983,12) {;
	rename paidhrlyr a_hrlywk;
	rename occ a_occ;
	*rename a_uslft l_uslft;
	gen l_uslft=.;
	rename hrlywage a_herntp;
	rename marstat a_maritl;
	*rename esr l_lfsr;
	rename month h_month;
	rename a_mjind2 a_mjind;
	gen howner=.;
	gen a_clswkr=classer; //is this right?
	merge m:1 stcens using `otherraw'/stategeocodes.dta, nogen;
	drop stcens;
	gen peschenr=.;
     };
     if `m'>=ym(1984,1) & `m'<=ym(1988,12) {;
	rename paidhrlyr a_hrlywk;
	rename occ84 a_occ;
	*rename a_uslft l_uslft;
	gen l_uslft=.;
	rename hrlywage a_herntp;
	rename marstat a_maritl;
	*rename esr l_lfsr;
	rename month h_month;
	rename a_mjind2 a_mjind;
	gen howner=.;
	gen a_clswkr=classer; //is this right?
	merge m:1 stcens using `otherraw'/stategeocodes.dta, nogen;
	drop stcens;
	gen peschenr=.;
     };
 * Usual Hours; //something is going wrong for years before 1989
       if `m'<=ym(1991,12) {;
       * generate hoursvary;
	gen byte hrsvary=0 if a_hrs1~=-1 & a_hrs1~=0;
	replace hrsvary=1 if a_hrs1==-4;
	lab var a_hrs1 "Usual hours, main (BLS)";
	
	gen byte hrernhr=0 if l_uslft~=.;
	replace hrernhr=1 if l_uslft==1 & (1<=a_uslhrs & a_uslhrs<=99); 
     };
      if `m'>=ym(1992,1) & `m'<=ym(1993,12) {;
       * generate hoursvary;
	gen byte hrsvary=0 if a_hrs1~=-1 & a_hrs1~=0;
	replace hrsvary=1 if a_hrs1==-4;
	lab var a_hrs1 "Usual hours, main (BLS)";
	
	gen byte hrernhr=0 if a_uslft~=.;
	replace hrernhr=1 if a_uslft==1 & (1<=a_uslhrs & a_uslhrs<=99); 
     };
      if `m'>=ym(1994,1) {;
       * generate hoursvary;
	gen byte hrsvary=0 if pehrusl1~=-1 & pehrusl1~=0;
	replace hrsvary=1 if pehrusl1==-4;
	lab var pehrusl1 "Usual hours, main (BLS)";
	
	gen byte hrernhr=0 if hrsvary~=.;
	replace hrernhr=1 if hrsvary==1 & (1<=peernhro & peernhro<=99); 
     };
     
     if `m'<=ym(1993,12) {;
     // if hours don't vary, use usual hours at main job;
		gen uhours=a_hrs1 if hrsvary==0;
	   /* if hours vary and respondent answers "usual hours  worked at this rate" 
	      (peernhro) use this as estimate for usual hours */;
		replace uhours=a_hrlywk if a_herntp==1;
		replace uhours=round(uhours,1);
     };
     else if `m'>=ym(1994,1) & `m'<=ym(2012,4) { ;  // if hours don't vary, use usual hours at main job;
        // if hours don't vary, use usual hours at main job;
		gen uhours=pehrusl1 if hrsvary==0;
	   /* if hours vary and respondent answers "usual hours  worked at this rate" 
	      (peernhro) use this as estimate for usual hours */;
		replace uhours=peernhro if hrernhr==1;
		replace uhours=round(uhours,1); 
     };
     else if `m'>=ym(2012,5) {;
	   // if hours don't vary, use usual hours at main job;
		gen uhours=pehrusl1 if hrsvary==0;
	   /* if hours vary and respondent answers "usual hours  worked at this rate" 
	      (peernhro) use this as estimate for usual hours */;
		replace uhours=peernhro if hrernhr==1;
		replace uhours=round(uhours,1);
     };
      
  *Recode variables;
   qui recode`cat';
   qui keep if age>=16 & age<.;
   *qui recode age (-1=.) (0/15=0) (16/24=1) (25/34=2) (35/44=3) (45/54=4) (55/64=5) (65/99=6), gen(agecat);
   gen yearmo=ym(year,month);
   format yearmo %tm;
    
  *Composite weight;
   if `m'<ym(1998,1) rename wgt_final wgt_composite;
   else rename wgt_comp wgt_composite;
   
   if `m'<=ym(1993,12) {;
	rename a_occ peio1ocd;
	rename a_ind peio1icd;
   };
   
   rename pehractt hourslw;     
  *Save data;
   keep year month yearmo stfips age pemlr wgt_composite educ4 educ5 educ_yr
        sex labfor empl unem ind20 indjolts occ1_2003 occ2_2003 
        prmarsta howner chld_pr livewithprnt hourslw uhours
        hh_id hh_num linenum hh_tiebreak p_tiebreak hh_tiebreak p_tiebreak
        peio1ocd peschenr;
	
   qui compress;
   qui save `month`m'', replace;
 };
 
     local start=1;
     forvalues m=`startmo'/`endmo' {;
     local year=year(dofm(`m'));
     local month=month(dofm(`m'));
     if `month'<10 local yearmo "`year'0`month'";
     else local yearmo "`year'`month'";
     if `start'==1 {;
     	 use `month`m'';
     	 local start=0;
     };
     else {;
    	 di "Appending month " %tm `m' ".";
     	 append using `month`m'';
     };
   };
   

   /* Marital status */
    gen byte married=.;
    replace married=0 if prmarsta~=.;
    replace married=1 if 1<=prmarsta & prmarsta<=3;
    lab var married "Married";
    notes married: CPS: derived from prmarsta, a-maritl;
    drop prmarsta;
    
   /*Create occupation dependent variables*/
   *Occupation period (based on changes to the census occupation coding: bls.gov/cps/spcoccind.htm);
    gen period=.;
    replace period=1980 if year<=1982;
    replace period=1990 if year>=1983 & year<=1991;
    replace period=1992 if year>=1992 & year<=2002;
    replace period=2003 if year>=2003 & year<=2010;
    replace period=2011 if year==2011;
	replace period=2011 if year==2012 & month<=4;
	replace period=2012 if year==2012 & month>=5;
    replace period=2012 if year>=2013;
  
   *Occupation mean education;
    sort period peio1ocd;
    by period peio1ocd: egen educ_occup=mean(educ_yr) if peio1ocd>=1 ; //issue with this for years prior to 1983
    
   /*Occupation mean earnings;
    sort period peio1ocd;
    by period peio1ocd: egen wage_occup=mean(wage_jr) if peio1ocd>=1 ;*/

  *Label values;
   makelabels;
   cap label values educ4 educ4_label;
   cap label values educ5 educ5_label;
   cap label values agecat agecat_label;
   cap label values sex sex_label;
   cap label values edsex edsex_label;
   cap label values labfor labfor_label;
   cap label values empl empl_label;
   cap label values unem unem_label;
   cap label values ind20 ind20_label;
   cap label values indjolts indjolts_label;
   cap label values ind1_2003 ind14_label;
   cap label values occ1_2003 occ11_label;
   cap label values ind2_2003 ind14_label;
   cap label values occ2_2003 occ11_label;
   cap label values ltue ltue_label;
   cap label values stfips stfips_label;
   cap label var hh_id "Household ID (from h_id or hrhhid)";
   cap label var hh_num "Household number within address (from h_hhnum or huhhnum)";
   cap label var linenum "Person line number (from a_lineno or pulineno)";
   cap label var hh_tiebreak "HH number tiebreaker, based on orig file sort order";
   cap label var pu_tiebreak "Line number tiebreaker, for dups in HH";



   if "`overwrite'"=="1" {;
   	  compress;
   	  save `intermediate'/extractcps, replace;
   };
 d;
 su;
 codebook;
 
 ! gzip -f `intermediate'/extractcps.dta;
 
 if `doasproject'==1 project, creates("`intermediate'/extractcps.dta.gz");
 
