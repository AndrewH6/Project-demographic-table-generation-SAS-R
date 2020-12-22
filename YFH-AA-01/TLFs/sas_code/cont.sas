/*============================================================
Project: Demographic Table and Listing
Version: SAS 9.4

Program:          cont.sas (macro)
Programmer:       Andrew Huang
Date:             July 1, 2017
Purpose:          Create statistics for continuous variables

============================================================*/

%macro cont(inData=,outData=, treat=, varName=, varUOM=);

****** Get maximum treatment number and final table variable string. Create global variable
****** maxtrtn, colstr (column string), keepstr (colum string plus label and pvalue);
%prepare(inData=&inData,treat=&treat)

****** Duplicate the incoming dataset for overall column calcuations so
****** now treat with new maximum treatment number = overall;
data _&inData;
	set &inData;
	output;
	&treat=input("&maxtrtn",2.);
	output;
run;

****** Get P value from non parametric comparison of variable means;
proc npar1way 
   data = _&inData
   wilcoxon 
   noprint;
      where &treat < %eval(&maxtrtn-(&maxtrtn-3));
      class &treat;
      var &varName;
      output out=pvalue wilcoxon;
run;

****** Sort data by the grouping variable;
proc sort 
	data=_&inData;
      by &treat;
run;
 
****** Get variable descriptive statistics N, Mean, STD, Min, and Max;
proc univariate 
	data = _&inData noprint;
      by &treat;
      var &varName;
      output out = &outData 
             n = _n mean = _mean std = _std min = _min max = _max;
run;

****** Format variable descriptive statistics for the table;
data &outData;
	set &outData;

   	format n mean std min max $14.;
   	drop _n _mean _std _min _max;
    n = put(_n,5.);
   	mean = put(_mean,7.1);
    std = put(_std,8.2);
    min = put(_min,7.1);
    max = put(_max,7.1);
run;

****** Transpose variable descriptive statistics into columns;
proc transpose 
   data = &outData
   out = &outData
   prefix = treat;
      var n mean std min max;
      id &treat;
run; 

****** Rename the last column to overall as it is for overal statistics;
data &outData;
   keep _NAME_ &colstr;
   set &outData(rename=(treat&maxtrtn=Overall));
run;
 
****** Create variable first row for the table with label and P value;
data label;
   set pvalue(keep = p2_wil rename = (p2_wil = pvalue));
   length label $ 85;
   label = "#S={font_weight=bold} &varName (&varUOM)";
run;

****** Append variable descriptive statistics to the variable P value row and
****** create variable descriptive statistic row labels;
data &outData;
   length label $ 85;
   length &colstr $ 25 ;
   set label &outData;

   keep &keepstr ;
   if _n_ > 1 then 
      select;
         when(_NAME_ = 'n')    label = "#{nbspace 9}N";
         when(_NAME_ = 'mean') label = "#{nbspace 9}Mean";
         when(_NAME_ = 'std')  label = "#{nbspace 9}Standard Deviation";
         when(_NAME_ = 'min')  label = "#{nbspace 9}Minimum";
         when(_NAME_ = 'max')  label = "#{nbspace 9}Maximum";
         otherwise;
      end;
run;

%mend;
