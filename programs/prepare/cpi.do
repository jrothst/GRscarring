*Updated:
* NG, 08/22/19: Update input data, extend data through July 2019
* JR, 4/14/19: Update through 4/2020 release

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
	local dofile "cpi"
	local sig "Not run as part of project!"
}

local rawdata "`pdir'/rawdata"
local scratch "`pdir'/scratch"

if `doasproject'==1 {
	project, original(`rawdata'/cpiu_CUSR0000SA0.csv)
}

#delimit;

clear;


*Note: These raw data were extracted from the BLS website series report, http://data.bls.gov/cgi-bin/srgate,
*using series ID CUSR0000SA0. (Column format, all years, all time periods, original data value, text-comma delimited)
*Most recent extraction: 4/14/2020
*project, original(`rawdata'/cpiu_CUSR0000SA0.csv);
insheet using `rawdata'/cpiu_CUSR0000SA0.csv;
gen month=real(substr(period, 2, 3));
drop period;
gen yearmo=ym(year, month);
rename value monthly;
assert seriesid=="CUSR0000SA0";
note: Series ID = CUSR0000SA0;
drop seriesid;
drop if yearmo>tm(2019,12);
save `scratch'/cpi.dta, replace;
if `doasproject'==1 project, creates(`scratch'/cpi.dta);

* Edit: incomplete year, drop to match with the other data

