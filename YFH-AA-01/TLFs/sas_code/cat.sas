/*============================================================
Project: Demographic Table and Listing
Version: SAS 9.4

Program:          cat.sas (macro)
Programmer:       Andrew Huang
Date:             July 1, 2017
Purpose:          Create statistics for character categorical variables

============================================================*/

%macro cat(inData=,outData=, treat=, varName=);

**** Get maximum treatment number and final table variable string. Create global variable
**** maxtrtn, colstr (column string), keepstr (colum string plus label and pvalue);
%prepare(inData=&inData,treat=&treat)

**** Duplicate the incoming dataset for overall column calcuations;
data _&inData;
	set &inData;
	output;
	&treat=input("&maxtrtn",2.);
	output;
run;

**** Get simple frequency counts for the variable;
proc freq 
   data = _&inData
   noprint;
      where &treat ne .; 
      tables &treat * &varName / missing outpct out = &outData;
run;
 
**** Format variable as desired;
data &outData;
   set &outData;
      where &varName ne ' ';
      length value $25;
      value = put(count,4.) || " (" || put(pct_row,5.1)||"%)";
run;

proc sort
   data = &outData;
      by &varName;
run;
  
**** Transpose the variable summary statistics;
proc transpose 
   data = &outData
   out = &outData(drop = _name_) 
   prefix = Treat;
      by &varName;
      var value;
      id &treat;
run;

**** Rename the last column to overall as it is for overal statistics;
data &outData;
   keep &varName &colstr;
   set &outData(rename=(treat&maxtrtn=overall));
run;

**** Perform a Fisher Exact test on variable comparing Active vs Placebo;
proc freq 
   data = _&inData 
   noprint;
      where &varName ne ' ' and &treat > . and &treat < %eval(&maxtrtn-(&maxtrtn-3));
      table &varName * &treat / exact;
      output out = pvalue exact;
run;

**** Create variable first row for the table;
data label;
	set pvalue(keep = xp2_fish rename = (xp2_fish = pvalue));
	length label $ 85;
	label = "#S={font_weight=bold} &varName N(%)";
run;

**** Append variable descriptive statistics to variable P value row and
**** create variable descriptive statistics row labels;
data &outData;
   length label $ 85;
   length &colstr $ 25 ;
   set label &outData;
   keep &keepstr;
   if _n_ > 1 then 
       label= "#{nbspace 9}" || propcase(&varName);	   
run;

%put keepstr=&keepstr;

%mend;
