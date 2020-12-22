/*============================================================
Project: Demographic Table and Listing
Version: SAS 9.4

Program:          prep.sas (macro)
Programmer:       Andrew Huang
Date:             July 1, 2017
Purpose:          Get maximum treatment number and create global variables maxtrtn, colstr, keepstr

============================================================*/

%macro prepare (inData=,treat=);

****** Get the existing maximum treatment number;
proc sql noprint;
    select max(&treat) into :max
	  from &inData;
quit;

****** Calculate the new maximum treatment number that will be used for the overall 
****** statitics calculation;
%global maxtrtn;
%let maxtrtn=%eval(&max+1);

****** Construct a string of column names treat1 treat2 .... treatn. This string will be used
****** later when creating the final table of statistics;
proc sql noprint;
    select 'Treat'||compress(put(treatment,2.)) into :columns separated by ' '
	  from (select distinct &treat as treatment
	          from &inDAta);
quit;

%global colstr;

****** Rename the last column to overall for treatN as the last column contains overall statistics;
data _null_;
    call symputx('colstr',"&columns Overall"); 
run;

%put colstr=&colstr;

%global keepstr;
%let keepstr=label &colstr pvalue;

%mend;
