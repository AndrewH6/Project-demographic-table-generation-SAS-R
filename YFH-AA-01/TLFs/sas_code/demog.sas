/*============================================================
Project: Demographic Table and Listing
Version: SAS 9.4

Program:          demog.sas
Programmer:       Andrew Huang
Date:             July 1, 2017
Purpose:          Create Demographics and Baseline Characteristics table

Output:           table01_demog.rtf

============================================================*/

%let study = YFH-AA-01;
%let path = D:\AH SAS Project\&study;

%include "&path/TLFs/sas_code/dmsetup.sas";


****** Import demographic data into source.adsl domain;
%import(lib=source, xlsdir=&xlsdir,xlsfile=demog_data.xlsx)

****** Calculate age and bmi;
data adsl;
    set source.adsl;
	where itt=1;
	age=floor(intck('MONTH',input(birthdtf,yymmdd10.),today())/12);
	if input(height,best.) ^=. then
	   bmi=round(input(weight,best.)/(input(height,best.)/100)**2,.1);
run;

****** Calculate statistics for age and create temporary dataset age;
%cont(inData=adsl, outData=age, treat=treatmnt, varName=Age, varUOM=yrs);

****** Calculate statistics for height and create temporary dataset height;
%cont(inData=adsl, outData=height, treat=treatmnt, varName=Height, varUOM=cm);

****** Calculate statistics for weight and create temporary dataset weight;
%cont(inData=adsl, outData=weight, treat=treatmnt, varName=Weight, varUOM=kg);

****** Calculate statistics for weight and create temporary dataset weight;
%cont(inData=adsl, outData=bmi, treat=treatmnt, varName=BMI, varUOM=kg/m#{super 2});

****** Calculate statistics for gender and create temporary dataset gender;
%cat(inData=adsl, outData=gender, treat=treatmnt, varName=Gender);

****** Calculate statistics for race and create temporary dataset race;
%cat(inData=adsl, outData=race, treat=treatmnt, varName=Race);

****** Make sure that all race names defined will be listed in the table;
proc format library=work cntlout=allraces(keep=label);
	select racen;
run;

data allraces(keep=name);
	set allraces;
	name="#{nbspace 9}" || propcase(compress(label));
run;

proc sort data=race;
	by label;
run;

proc sort data=allraces;
	by name;
run;

data race;
	merge race allraces(rename=(name=label));
	by label;
run;

****** Fill the blank values with 0(0.0%);
data race;
	set race;
	if _n_ > 1 then
		do;
		if missing(treat1) then treat1="   0 (0.0%)";
		if missing(treat2) then treat2="   0 (0.0%)";
		if missing(overall) then overall="   0 (0.0%)";
		end;
run;

data final;
    set gender(in=in1) 
        race(in=in2) 
        age(in=in3)
        height(in=in4)
        weight(in=in5) 
        bmi(in=in6);

		group=sum(in1*1, in2*2, in3*3, in4*4, in5*5, in6*6);
		page=sum(in1*1, in2*1, in3*1, in4*2, in5*2, in6*2);
run;

****** create a temporary dataset to hold treatment number and number of observations for each treatment;
proc sql noprint;
    create table trtcount as
    	select treatmnt, count(*) as cnt
		  from adsl
         where treatmnt > .z
	    group by treatmnt;
quit;

****** Create macro variables to hold the number of observations for each treatment as well as total treatments;
data _null_;
	set trtcount end=eof;
	retain total;
	total+cnt;
	call symput('N'||compress(put(treatmnt,2.)),compress('(N='||put(cnt,4.)||')'));
	if eof then
	    call symput('NT',compress('(N='||put(total,4.)||')'));
run;

****** Create demographic table;
options orientation = landscape nodate nonumber missing = ' ';
ods escapechar='#';
ods rtf  style=demogtemp file="&outdir/t01_demog.rtf";

proc report
   data=final
   nowindows
   spacing=1
   headline
   headskip
   style(header)={just=l}
   split = "|";

   columns (page group label Treat1 Treat2 Overall pvalue);

   define page /order order=internal noprint;
   define group   /order order = internal noprint;
   define label   /display style(column)=[cellwidth=18% asis=on] "Variable|#_|#_";
   define Treat1    /display style(column)=[cellwidth=18% asis=on] "AntiCancer000|&n1**|#_";
   define Treat2    /display style(column)=[cellwidth=18% asis=on] "AntiCancer001|&n2**|#_";
   define Overall    /display style(column)=[cellwidth=18% asis=on] "Total|&nt**|#_";
   define pvalue  /display left style(column)=[cellwidth=18% asis=on] " |P-value**|#_" f = pvalue6.4;

   compute after group;
      line '';   /* changed #{newline} to '' as #{newline} produced two blank line */ 
   endcomp;

   break after page / page;

   compute after _page_ /style = {just=left bordertopcolor=white borderbottomcolor=white};
		line ' ';
		line '* ITT(Intent to Treat) population is defined as including all subjects who have at least';
		line '  one baseline assesment and one post baseline assesment.';
		line "** N is the number of subjects in the treatment group";
		line "*** P-values:  Age = Wilcoxon rank-sum, Sex = Pearson's chi-square, Race = Fisher's exact test.";
   endcomp;

   title1 h=8pt j=l 'Client: YFH LLC' j=r './TLF/sas_code/demog.sas';	                    
   title2 h=8pt j=l 'Protocol YFH 2017 Summer' j=r "&_page.";
   title3 j=c 'TABLE 1';
   title4 j=c 'DEMOGRAPHICS AND BASELINE CHARACTERISTICS';
   title6 j=c '(ITT POPULATION)*';

   footnote font='times' h=1 j=r "&sysdate9.  &systime.";
run; 
ods rtf close;
title;
footnote;
