*============================================================*
*	Data Analysis Test
*   
*	Jose Mendoza
*  	Jan 04, 2021
*============================================================*

clear all

pause on
set more off

*------------------------------------------------------------*
*  Directory
*------------------------------------------------------------*

global dir "/Users/joseantoniomendozasanchez/Documents/GitHub/Data Task"

global data "$dir/1_data"

global code "$dir/2_code"

global charts "$dir/3_charts"

global tables "$dir/4_tables"

/*
	Data Cleaning
*/

import excel using "$data/Town Names for Analysis Test.xlsx", clear firstrow
rename TownID town_id
tempfile town_id
save `town_id'

import excel using "$data/Data for Analysis Test.xlsx", clear firstrow

drop if town_id == .

merge m:1 town_id using `town_id', nogen keep(3)

bys town_id: gen obs = _n

gen str3 aux = string(obs,"%03.0f")

egen obs_id = concat(town_id aux)
destring(obs_id), replace
drop obs aux 

codebook
summarize 

replace registered_total = .  if registered_total == -999  | registered_total == -998 
replace registered_male  = .  if registered_male  == -999  | registered_male == -998
replace registered_female = . if registered_female == -999 | registered_female == -998

gen sample = (registered_total != .)

labmask town_id, values(TownName) // Install labmask "search labmask"
drop TownName

label define treatment       0 "Control"           1 "Treatment"
label values treatment treatment
label define treatment_phase 1 "Treatment Phase 1" 2 "Treatment Phase 2"
label values treatment_phase treatment_phase
label define take_up         0 "Did take up"       1 "Did not take up"
label values take_up take_up
label define sample          1 "On Sample" 0 "Out of Sample"
label values sample sample

label var town_id            "3-digit town ID"
label var turnout_total      "Total Turnout at Pooling Booth"
label var turnout_male       "Male Turnout at Pooling Booth"
label var turnout_female     "Female Turnout at Pooling Booth"
label var registered_total   "Total Registered Pop. at Pooling Booth"
label var registered_male    "Male Registered Pop. at Pooling Booth"
label var registered_female  "Female Registered Pop. at Pooling Booth"
label var treatment          "Treatment" 
label var treatment_phase    "Treatment Phase"
label var take_up            "Treatment take up"    	
label var district           "District Name"
label var obs_id             "5-digit observation ID"
label var sample             "Final Sample"



