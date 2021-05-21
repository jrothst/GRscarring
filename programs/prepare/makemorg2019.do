/*
Variables we'd need for MORG 2019 extract

intmonth.   raworg.           hrmonth
minsamp.    raworg.           hrmis
lineno.     raworg.           pulineno
weight.     raworg.           pwsswgt
hhid.       raworg.           hrhhid
hhnum.      raworg.           5th digit of hrhhid2
class94.    raworg            peio1cow
occ2012.    raworg            peio1ocd
stfips.     raworg.           gestfips
year.       raworg            hryear4
sex.        raworg            pesex
marital.    raworg            pemaritl
hurespli.   raworg            <same>
grade92.    raworg            peeduca
lfsr94.     raworg            pemlr
paidhre.    raworg            peernhry
earnhre.    raworg            prernhly
prhernal.   ??? alloc only
pwernal.    ??? alloc only
peernhry.   ??? alloc only
earnwke                       prernwa
uhourse                       peernhro                       
ftpt94                        prwkstat
hourslw                       pehractt
peio1ocd                      peio1ocd
*/

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
	local dofile "makemorg2019"
	local sig "Not run as part of project!"
}

local cpsorig "~/data/cps/bigcps/statafmt"
local intermediate "`pdir'/scratch"
local cpsraw "~/data/cps/bigcps/raw"
local temp "`pdir'/rawdata/temp"
local otherraw "`pdir'/rawdata"

forvalues m=1/12 {
  if `m'<10 local mo "0`m'"
  else local mo "`m'"
  local origfile "cpsb19`mo'"

   *Read in the data;
    if `doasproject'==1 project, original("`cpsorig'/`origfile'.dta.gz")
    !zcat `cpsorig'/`origfile'.dta.gz > ./tmp_`origfile'.dta
    use hrmonth hrmis pulineno pwsswgt pworwgt hrhhid hrhhid2 peio1cow peio1ocd ///
        gestfips hryear4 pesex pemaritl hurespli peeduca pemlr peernhry prernhly ///
        prernwa pehrusl1 prwkstat pehractt prtage ///
        if (hrmis==4 | hrmis==8) & prtage>=16 using tmp_`origfile'.dta, clear
    !rm -f tmp_`origfile'.dta
  tempfile month`m'
  save `month`m''
}
use `month1'
forvalues m=2/12 {
  append using `month`m''
}
rename prtage age
rename hrmonth intmonth
rename hrmis minsamp
rename pulineno lineno
rename pwsswgt weight
rename pworwgt earnwt
rename hrhhid hhid
rename peio1cow class94
rename peio1ocd occ2012
rename gestfips stfips
rename hryear4 year
rename pesex sex
rename pemaritl marital
rename peeduca grade92
rename pemlr lfsr94
rename peernhry paidhre
rename prernhly earnhre
replace earnhre=earnhre*100
rename prernwa earnwke
rename pehrusl1 uhourse
replace uhourse=. if uhourse<0
rename prwkstat ftpt94
rename pehractt hourslw
replace hourslw=. if hourslw<0
gen byte hhnum=real(substr(hrhhid2,5,1))

save `intermediate'/morg2019.dta, replace

if `doasproject'==1 project, creates("`intermediate'/morg2019.dta")


