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

/**************************
	Data Cleaning
***************************/

/* Task 1: Import databases */

* The "town names" database is imported and saved as a temporal file for later merging with the main database
import excel using "$data/Town Names for Analysis Test.xlsx", clear firstrow
rename TownID town_id
tempfile town_id
save `town_id'

* Main database
import excel using "$data/Data for Analysis Test.xlsx", clear firstrow

* Dropping rows with missing data
drop if town_id == .

/* Task 2: Merging of both databases*/
merge m:1 town_id using `town_id', nogen keep(3)

/* Task 3: The town id is already loaded as a numerical variables*/

/* Task 4: Observation ID*/

* Enumerates each individual in each town
bys town_id: gen obs = _n

* Generates an auxiliary variable with the previous variable filled with zeroes on the left
gen str3 aux = string(obs,"%03.0f")

* Concatenates the town ID with the Auxiliary variables in order to get a 6 digit ID
egen obs_id = concat(town_id aux)
destring(obs_id), replace
drop obs aux 

/* Task 5: Missing data ¿*/

/* I use both codebook and summarize to assess whether there are any missing values in form of . (dot) or in
 form of "-999". Only "registered_*" variables have missing values with "-999" and "-998".
*/
codebook
summarize 

* Replace -999 and -998 with . 
replace registered_total = .  if registered_total == -999  | registered_total == -998 
replace registered_male  = .  if registered_male  == -999  | registered_male == -998
replace registered_female = . if registered_female == -999 | registered_female == -998

* The "Sample" variable delimits the database without dropping the observations
gen sample = (registered_total != .)

/* Task 6: Create a dummy variable for each value of Town ID*/

* Before generating the set of dummy variables, I use labmask to label the values with each Town Name
labmask town_id, values(TownName) // Install labmask "search labmask"
drop TownName

* After labeling the values, every dummy variables labeled with its corresponding Town name 
tab town_id, gen(town_id_var_)

/* Task 7: Labeling Variables*/

label var town_id            "3-digit town ID"
label var turnout_total      "Total Turnout at Polling Booth"
label var turnout_male       "Male Turnout at Polling Booth"
label var turnout_female     "Female Turnout at Polling Booth"
label var registered_total   "Total Registered Pop. at Polling Booth"
label var registered_male    "Male Registered Pop. at Polling Booth"
label var registered_female  "Female Registered Pop. at Polling Booth"
label var treatment          "Treatment" 
label var treatment_phase    "Treatment Phase"
label var take_up            "Treatment take up"    	
label var district           "District Name"
label var obs_id             "6-digit observation ID"
label var sample             "Final Sample"

/* Task 8: Labeling variables values*/

label define treatment       0 "Control"           1 "Treatment"
label values treatment treatment
label define treatment_phase 1 "1st Treatment Phase" 2 "2nd Treatment Phase"
label values treatment_phase treatment_phase
label define take_up         0 "Did take up"       1 "Did not take up"
label values take_up take_up
label define sample          1 "On Sample" 0 "Out of Sample"
label values sample sample


/*
	Descriptive Statistics
*/


/* Task 9: Average Total Turnout rate*/

* The turnout rate equals the number of voters divided by the total registered population at a Polling booth 

gen turnout_rate_total =  turnout_total*100/registered_total
label var turnout_rate_total "Turnout rate %, total"

* Summarize turnout rate
summ turnout_rate_total 
local n_obs = r(N)

/*
The average total turnout rate is 57.37862% with a minimum of 0% and a maximum of 100%.
*/

/* 
Counts the number of Polling booths with 100% of voters turnout. 
They are only 20 Polling booths with a 100% of voters turnout, this represents only 0.28% of the total
*/
count if turnout_rate_total == 100 
local max_turnou_rate_total = r(N)
display `max_turnou_rate_total'*100/`n_obs'

gen turnout_rate_male =  turnout_male*100/registered_male
label var turnout_rate_male "Turnout rate %, male"

gen turnout_rate_female =  turnout_female*100/registered_female
label var turnout_rate_female "Turnout rate %, female"

/* Task 10: By treatment, tabulate the number of booths in phases 1 and 2 of the study*/


tab treatment treatment_phase if sample == 1, col

/*
At 1st phase, 51.2% of booths were assigned on the Treatment group while 
only 48.1% were assigned at the same group at 2nd phase.
*/

/*
--------------------------------------------|
		  |	Treatment Phase                 |
--------------------------------------------|
Treatment |	1st Treat  |2nd Treat	|Total  |
--------------------------------------------|
Control	  | 1,752      |1,741	    |3,493  |
	      | 48.79%     |51.86%	    |50.27% |
--------------------------------------------|	
Treatment |	1,839      |1,616	    |3,455  |
	      | 51.21%     |48.14%	    |49.73% |
--------------------------------------------|
Total	  | 3,591      |3,357	    |6,948  |
	      | 100.00%    |100.00%	    |100.0% |
--------------------------------------------|
*/

/*Task 11: Tabulate the average turnout rate for females for each 
district which has a total turnout rate of 75% or above*/

* Generates district's average turnout rate 
bysort town_id: egen turnout_rate_total_district = mean(turnout_rate_total)
label var turnout_rate_total_district "District Average turnout"

* No district has, on average, more than 75% of voters turnout. 
summ turnout_rate_female if (turnout_rate_total_district >= 75) & sample == 1

/* Task 12: Is the average turnout rate for females notably higher in treatment
 polling booths than control? Can you say the difference is significant? How
 would you test for it?
*/

/*
The average female turnout on treatment polling booths (58.31%) is significantly
different from the average female turnout on control polling booths (56.92%) 
with a p-value of 0.0384 using a simple t-test.
*/

mean turnout_rate_female if sample == 1, over(treatment)

ttest turnout_rate_female if sample == 1, by(treatment)

/* Task 13: Create one simple, clearly-labeled bar graph that shows the 
difference in turnout between treatment and control polling booths by gender 
as well as total turnout. Please output your results in the clearest form
possibles*/

/*
The dot plot shows both the average turnout and their CI.
*/

* ssc install ciplot
ciplot turnout_rate_total turnout_rate_female turnout_rate_male ///
 if sample == 1 , by(treatment) mcolor(black) msize(*2 *2 *2) ///
 msymbol(o x s) rcap(lcolor(black)) xtitle("") ///
 legend(order(2 "Total" 3 "Female" 4 "Male") cols(3)) ///
 title("Average turnout by treatment group and sex")
graph export "$charts/graph_1.png", replace

/*
	Regression: Create one table showing the effect of Treatment on total 
	turnout. 
*/

/* Task 14: Please output yout results in Excel/Word in the clearest 
form possible. It is not necessary to show the coefficients on the 
control variables. However, do show th coefficient on registered voters*/


eststo clear
eststo: reg turnout_rate_total ib0.treatment
estadd local Controls "No"
estadd local ClusterSE "No"

eststo: reg turnout_rate_total ib0.treatment                             , vce(cluster town_id)
estadd local Controls "No"
estadd local ClusterSE "Yes"

eststo: reg turnout_rate_total ib0.treatment ib0.town_id registered_total, vce(cluster town_id)
estadd local Controls "Yes"
estadd local ClusterSE "Yes"

esttab using "$tables/results.csv", keep(1.treatment _cons registered_total) nomtitle ///
coeflabel(1.treatment "Treatment" registered_total "Tot Regist" _cons "Cons" ) ///
stats(Controls ClusterSE N) note("Dependent variables: town dummy and total registered population. Standard error on parenthesis") ///
title("Estimated Effect on Total Turnout Rate") replace

esttab using "$tables/results.rtf", keep(1.treatment _cons registered_total) nomtitle ///
coeflabel(1.treatment "Treatment" registered_total "Tot Regist" _cons "Cons" ) ///
stats(Controls ClusterSE N) note("Dependent variables: town dummy and total registered population. Standard error on parenthesis") ///
title("Estimated Intent-to-Treat Effect of Turnover Campaign on Total Turnout Rate") replace


/* Task 15: What is the mean turnout for the control group?*/

/*
The mean turnout for the control group equals the estimated constant. This is 56.89 %
*/


/* Task 16: Note down the dependent variable*/

/*
All the dependet variables are annotated as a note on the table
*/


/* Task 17: What is the change in the dependent variable after the intervention*/

/*
The change on the dependent variable equals the coefficient for treatment. This is 
close to a 1% (0.977) increase on the total turnout rate when the set of control
variables is not considered. After taking these variables into account, the 
coefficient reduces to 0.393. 
*/


/* Task 18: Is the difference in turnout between the treatment and control
booths statistically significant? Explain in no more than 50 words how would
you assess that.*/

/*
Both estimators are not significant, showing that there is no evidence in favor
of a positive effect of the treatment on the turnout rate. This means there is no 
significant difference between the treatment and the control group. Nevertheless, 
this is only an intent-to-treat estimator as is shown on the following question 
when the actual take up of the treatment is considered.  
*/


/*
	Instrumental Variables: Now assume that take-up of the intervention was not
	complete, meaning that in some of the polling booths that were assigned 
	to ger a voter turnout campaign, the turnout campaign did not actually 
	happen. 
*/

/* Task 19: Is there a variable in this dataset that is plausibly an 
instrumental variable for the presence of the voter turnout campaign*/

/*
The instrumental variable for take up is the initial assignation to a 
random or control group. By definition is random to the observed and
not observed characteristics of the town so it would only affect the 
dependet variable through the endogenous variable (take-up). 
*/

/* Task 20: Please state the relevance condition of instrumental 
variables and discuss/show why it would hold or does not hold in this
case*/

/*
The relevance condition states that the instrument and the endogenous
variable are related. In this case, this assumptions hold by definition
given that the actual take up of the campaign depends on being 
selected as part of the treatment group. Hence Cor(Treatment, Take up) \neq 0
*/


/* Task 21: Please state the exogeneity condition for instrumental 
variables and provide evidence on whether it holds. Hint: the best
variable in the data set to use for testing the exogeneity condition
is registered_total, so you can just use that one*/

/*
The exogeneity condition states that the instrument must not be related with 
any relevent variable exempt the endogenous variables. By definition, treatment 
is random so is not correlated with any relevant variable. If we take the total 
registered population as a proxy of the features of every town, then a non 
association between the treatment and the variable would indicate exogeneity 
from local characteristics. A simple regression between those variables
shows no significant correlation. 
*/

reg treatment registered_total 

/* Task 22: Please run the instrumental variables regression showing 
the effect of take_up on turnout using an instrumental variables 
approach and discuss the magnitude of this effect relative to the 
effect you found previously in question 18*/

/*
The IV strategy with the treatment variable as an instrument results on 
an increase of the coefficient. Previously, the "treatment" coefficient 
ranged from 0.393 t 0.977 while now the "take-up" coefficient ranges 
from 0.56 (when using the set of control variables) to 1.39. Regardless
of this increase, both estimators are not significant. 

The increase is expected as the regressions only considers those polling 
booths that actually received the campaign. 
*/

eststo clear
eststo: ivregress 2sls turnout_rate_total (take_up = treatment) , first 
estadd local Controls "No"
estadd local ClusterSE "No"

eststo: ivregress 2sls turnout_rate_total (take_up = treatment) , first vce(cluster town_id)
estadd local Controls "No"
estadd local ClusterSE "Yes"

eststo: ivregress 2sls turnout_rate_total ib0.town_id registered_total (take_up = treatment ib0.town_id registered_total) , first vce(cluster town_id)
estadd local Controls "Yes"
estadd local ClusterSE "Yes"

esttab using "$tables/results_takeup.csv", keep(take_up) nomtitle ///
coeflabel(take_up "Take-up") ///
stats(Controls ClusterSE N) note("Instrumental variable: Treatment" "Dependent variables: town dummy and total registered population. SE on parenthesis") ///
title("Estimated Effect on Total Turnout Rate") replace

esttab using "$tables/results_takeup.rtf", keep(take_up) nomtitle ///
coeflabel(take_up "Take-up") ///
stats(Controls ClusterSE N ) note("Instrumental variable: Treatment" "Dependent variables: town dummy and total registered population. SE on parenthesis") ///
title("Estimated Effect on Total Turnout Rate") replace










