*************************************************************************************************************** 
* NG: 9/11/2019
* fig_ur_age.do
* Creates Unemployment and non-employment figures for young college graduates 
* Edit: NG 01/10/20: Separate fig_ur_age in two groups and change some cosmetics aspects of the figures
* 		NG 02/7/20: Updated to a 7-month smoothing and changed to two panels 
*.      JR 4/1/20:   Rewritten completely
*************************************************************************************************************** 

clear

cap project, doinfo
//cap notaproject
if _rc==0 {
	local pdir "`r(pdir)'"						  	    // the project's main dir.
	local dofile "`r(dofile)'"						    // do-file's stub name
	local sig {bind:{hi:[`dofile'.dta. RP : `dofile'.do, `c(current_date)']}}	// a signature in notes
	local doasproject=1
}
else {
	local pdir "~/GRscarring"
	local dofile "fig_ur_age"
	local doasproject=0
}

set more off
local rootdir "`pdir'"
local thisdir "`pdir'"

local scratch "`pdir'/scratch"
local rawdata "`pdir'/rawdata"
local output "`pdir'/results"

if `doasproject'==1 {
	project, uses("`scratch'/extractcps.dta.gz")
}

set scheme s1color

!zcat `scratch'/extractcps.dta.gz > `scratch'/extractcps.dta 

// Program to implement simple seasonal adjustment and smoothing
cap program drop seasadj
program define seasadj
  args v
  *Simple seasonal adjustment
  areg `v' i.year, a(mon)
  predict monfx, d
  gen `v'_sa=`v'-monfx
  drop monfx
end

cap program drop smoother
program define smoother
  args v
  tsset yearmo
  gen     `v'_m7=100*((4*`v' + 3*L.`v' + 2*L2.`v' + 1*L3.`v'+ 3*F.`v'+ 2*F2.`v' + 1*F3.`v')/16)
  replace `v'_m7=100*((4*`v' + 3*L.`v' + 2*L2.`v' + 1*L3.`v'+ 3*F.`v'+ 2*F2.`v' )/15) if F3.`v'==.
  replace `v'_m7=100*((4*`v' + 3*L.`v' + 2*L2.`v' + 1*L3.`v'+ 3*F.`v' )/13) if F2.`v'==.
  replace `v'_m7=100*((4*`v' + 3*L.`v' + 2*L2.`v' + 1*L3.`v')/10) if F.`v'==.
  replace `v'_m7=100*((4*`v' + 3*L.`v' + 2*L2.`v' + 3*F.`v'+ 2*F2.`v' + 1*F3.`v')/15) if L3.`v'==.
  replace `v'_m7=100*((4*`v' + 3*L.`v' + 3*F.`v'+ 2*F2.`v' + 1*F3.`v')/13) if L2.`v'==.
  replace `v'_m7=100*((4*`v' + 3*F.`v' + 2*F2.`v' + 1*F3.`v')/10) if L.`v'==.

  gen     `v'_m9=100*((5*`v' + 4*L.`v' + 3*L2.`v' + 2*L3.`v' + 1*L4.`v' ///
                             + 4*F.`v' + 3*F2.`v' + 2*F3.`v' + 1*F4.`v')/25)
  replace `v'_m9=100*((5*`v' + 4*L.`v' + 3*L2.`v' + 2*L3.`v' + 1*L4.`v' ///
                             + 4*F.`v' + 3*F2.`v' + 2*F3.`v'           )/24) if F4.`v'==.
  replace `v'_m9=100*((5*`v' + 4*L.`v' + 3*L2.`v' + 2*L3.`v' + 1*L4.`v' ///
                             + 4*F.`v' + 3*F2.`v'                      )/22) if F3.`v'==.
  replace `v'_m9=100*((5*`v' + 4*L.`v' + 3*L2.`v' + 2*L3.`v' + 1*L4.`v' ///
                             + 4*F.`v'                                 )/19) if F2.`v'==.
  replace `v'_m9=100*((5*`v' + 4*L.`v' + 3*L2.`v' + 2*L3.`v' + 1*L4.`v' ///
                                                                       )/15) if F.`v'==.
  replace `v'_m9=100*((5*`v' + 4*L.`v' + 3*L2.`v' + 2*L3.`v'  ///
                             + 4*F.`v' + 3*F2.`v' + 2*F3.`v' + 1*F4.`v')/24) if L4.`v'==.
  replace `v'_m9=100*((5*`v' + 4*L.`v' + 3*L2.`v'   ///
                             + 4*F.`v' + 3*F2.`v' + 2*F3.`v' + 1*F4.`v')/22) if L3.`v'==.
  replace `v'_m9=100*((5*`v' + 4*L.`v'   ///
                             + 4*F.`v' + 3*F2.`v' + 2*F3.`v' + 1*F4.`v')/19) if L2.`v'==.
  replace `v'_m9=100*((5*`v'   ///
                             + 4*F.`v' + 3*F2.`v' + 2*F3.`v' + 1*F4.`v')/15) if L.`v'==.
end

cap program drop prepdata
program define prepdata
  syntax, indata(string) agerange(string) agegp(real)
  use age educ4 unem empl yearmo wgt_composite if educ4==4 & `agerange' using `indata', clear
  collapse (mean) empl unem [aw=wgt_composite], by(yearmo)
  gen year=year(dofm(yearmo))
  gen mon=month(dofm(yearmo))
  seasadj empl
  seasadj unem
  smoother empl_sa
  smoother unem_sa
  gen noempl_sa_m7=100-empl_sa_m7
  gen noempl_sa_m9=100-empl_sa_m9
  gen agegp=`agegp'
  gen recession=(yearmo>=ym(1981,7) & yearmo<=ym(1982,11)) | (yearmo>=ym(1990,7) & yearmo<=ym(1991,3)) | ///
                (yearmo>=ym(2001,3) & yearmo<=ym(2001,11)) | (yearmo>=ym(2007,12) & yearmo<=ym(2009,6))
end

*** Prepare data
 tempfile agegp0 agegp1 agegp2 agegp3 agegp4 agegp5
 prepdata, indata("`scratch'/extractcps.dta") agerange("age>=22 & age<=40") agegp(0)
 save `agegp0'
 prepdata, indata("`scratch'/extractcps.dta") agerange("age>=22 & age<=30") agegp(1)
 save `agegp1'
 prepdata, indata("`scratch'/extractcps.dta") agerange("age>=31 & age<=40") agegp(2)
 save `agegp2'
 prepdata, indata("`scratch'/extractcps.dta") agerange("age>=22 & age<=25") agegp(3)
 save `agegp3'
 prepdata, indata("`scratch'/extractcps.dta") agerange("age>=26 & age<=29") agegp(4)
 save `agegp4'
 prepdata, indata("`scratch'/extractcps.dta") agerange("age>=40 & age<=55") agegp(4)
 save `agegp5'
 use `agegp0'
 append using `agegp1'
 append using `agegp2'
 append using `agegp3'
 append using `agegp4'
 append using `agegp5'
 label def agegp_l 0 "22-40" 1 "22-30" 2 "31-40" 3 "22-25" 4 "26-29" 5 "40-55"
 label values agegp agegp_l
 
* Figure 2 - 22-40 Graduate Non-Employment & UR National rate
gen altrecession=8*recession+10 
twoway area altrecession yearmo if agegp==0, yaxis(2) color(gs13) base(10) || ///
 line  noempl_sa_m7 yearmo if agegp==0, yaxis(2) ytitle("Non-employment rate", axis(2)) ylabel(10(2)18, axis(2)) || ///
 line  unem_sa_m7  yearmo if agegp==0, yaxis(3) ytitle("Unemployment rate", axis(3)) lpattern(dash)  || ///
 , xlabel(246 "1980" 306 "1985" 366 "1990" 426 "1995" 486 "2000" 546 "2005" 606 "2010" 666 "2015" 726 "2020") ///
 xtitle("")  title("Non-employment and unemployment, college graduates aged 22-40", size(medsmall)) legend(order(2  "Non-employment rate (l. axis)" 3 "Unemployment rate (r. axis)") size(small)) ///
saving("`output'/`dofile'_base.gph", replace)



* Alternative -- non-employment for 25-30 and 31-40
replace altrecession=10+10*recession
twoway area altrecession yearmo if agegp==1, yaxis(1) color(gs13) base(10) || ///
 line  noempl_sa_m7 yearmo if agegp==1, yaxis(1) lstyle(p1) || ///
 line noempl_sa_m7 yearmo if agegp==2, yaxis(1) lstyle(p2) lpattern(dash) || ///
 , ytitle("Non-employment rate") yla(10 (2) 20) ///
  xlabel(246 "1980" 306 "1985" 366 "1990" 426 "1995" 486 "2000" 546 "2005" 606 "2010" 666 "2015" 726 "2020") ///
 xtitle("")  title("Non-employment rate, by age", size(medsmall)) legend(order(2 "Age 22-30" 3 "Age 31-40") col(2)) ///
saving("`output'/`dofile'_agegp2_noempl.gph", replace)

gen altrecessionB=7*recession
twoway area altrecessionB yearmo if agegp==1, yaxis(1) color(gs13) || ///
 line  unem_sa_m7 yearmo if agegp==1, yaxis(1) lstyle(p1) || ///
 line unem_sa_m7 yearmo if agegp==2, yaxis(1) lstyle(p2)  lpattern(dash) || ///
 , ytitle("Non-employment rate") yla(0 (1) 6) ///
  xlabel(246 "1980" 306 "1985" 366 "1990" 426 "1995" 486 "2000" 546 "2005" 606 "2010" 666 "2015" 726 "2020") ///
 xtitle("")  title("Unemployment rate, by age", size(medsmall)) legend(order(2 "Age 22-30" 3 "Age 31-40") col(2)) ///
saving("`output'/`dofile'_agegp2_unem.gph", replace)

gen altrecessionC=12*recession+78
twoway area altrecessionC yearmo if agegp==1, base(78) yaxis(1) color(gs13) || ///
 line  empl_sa_m7 yearmo if agegp==1, yaxis(1) lstyle(p1) || ///
 line empl_sa_m7 yearmo if agegp==2, yaxis(1) lstyle(p2)  lpattern(dash) || ///
 , ytitle("Employment rate") yla(78 (2) 90) ///
  xlabel(246 "1980" 306 "1985" 366 "1990" 426 "1995" 486 "2000" 546 "2005" 606 "2010" 666 "2015" 726 "2020") ///
 xtitle("")  title("Employment rate, by age", size(medsmall)) legend(order(2 "Age 22-30" 3 "Age 31-40") col(2)) ///
saving("`output'/`dofile'_agegp2_empl.gph", replace)

gen altrecessionD=18*recession+74
twoway area altrecessionD yearmo if agegp==3, yaxis(1) color(gs13) base(74) || ///
 line empl_sa_m9 yearmo if agegp==3, yaxis(1) lstyle(p1) || ///
 line empl_sa_m9 yearmo if agegp==4, yaxis(1) lstyle(p2) lpattern(longdash) || ///
 line empl_sa_m9 yearmo if agegp==2, yaxis(1) lstyle(p3) lpattern(shortdash) || ///
 , ylabel(74 (2) 92) ytitle("Employment rate") ///
   xlabel(246 "1980" 306 "1985" 366 "1990" 426 "1995" 486 "2000" 546 "2005" 606 "2010" 666 "2015" 726 "2020") ///
   xtitle("")  title("Employment rate of young college graduates, by age" , size(medsmall)) legend(order(2 " Age 22-25 " 3 " Age 26-29" 4 " Age 30-40") col(3)) ///
   saving("`output'/`dofile'_agegp3_empl.gph", replace)

save `scratch'/`dofile'.dta, replace



! rm `scratch'/extractcps.dta


if `doasproject'==1 {
      project, creates(`output'/`dofile'_base.gph)
      project, creates(`output'/`dofile'_agegp2_noempl.gph)
      project, creates(`output'/`dofile'_agegp2_unem.gph)
      project, creates(`output'/`dofile'_agegp3_empl.gph)
       project, creates(`scratch'/`dofile'.dta)
    }

