/*============================================================
Project: Demographic Table and Listing
Version: SAS 9.4

Program:          dmsetup.sas
Programmer:       Andrew Huang
Date:             July 1, 2017
Purpose:          Define general path, libraries, and table/listing styles

============================================================*/

dm 'clear output';
dm 'clear log';

%global study path ls ps _page xlsdir outdir _page;
%let study=YFH-AA-01;
%let path = D:\AH SAS Project\&study;
%let xlsdir = &path/TLFs/rawdata;
%let outdir = &path/TLFs/outdata;
%let ls = 210;
%let ps = 57;
%let _page = %str(page #{pageof});

libname source "&path/TLFs/source";
libname target "&path/TLFs/target";
libname mystyle "&path/TLFs/templates";
libname myfmt "&path/TLFs/formats";
filename macrolib "&path/TLFS/sas_code/macros";
options mautosource sasautos=(macrolib,'!SASROOT/sasautos');

options pageno=1 mautosource mlogic mtrace mprint symbolgen missing='' ls=&ls ps=&ps center 
        formchar='|__|+|__+|_/\<>*' nonumber nodate nobyline ovp nofmterr
        fmtsearch=(work formats.formats) sortpgm=SAS;

ods escapechar = "#";

****** Define variable formats needed for table;
proc format;
   value treatmnt
      1 = 'Anticancer000'
      2 = 'Anticancer001';
   value agegrp
      1 = '1-50'
	  2 = '50-60'
	  3 = '60-70'
	  4 = '70-80'
	  5 = '80-90'
	  6 = '>90';
   value racen
   		1 = 'WHITE'
		2 = 'BLACK'
		3 = 'ASIAN'
		4 = 'NATIVE'
		5 = 'HISPANIC'
		6 = 'OTHER';
run;

****** Define customized ODS style template for demographic table/listing;
proc template;
    define style demogtemp / store=mystyle.templat;
	parent = styles.RTF;

	replace fonts /
	'TitleFont' = ("Times Roman",9pt) /* Titles from TITLE statements */
	'TitleFont2' = ("Times Roman",9pt) /* Procedure titles ("The _____ Procedure")*/
	'StrongFont' = ("Times Roman",9pt)
	'EmphasisFont' = ("Times Roman",9pt)
	'headingEmphasisFont' = ("Times Roman",9pt)
	'headingFont' = ("Times Roman",9pt) /* Table column and row headings */
	'docFont' = ("Times Roman",9pt) /* Data in table cells */
	'footFont' = ("Times Roman",9pt) /* Footnotes from FOOTNOTE statements */
	'FixedEmphasisFont' = ("Courier",9pt)
	'FixedStrongFont' = ("Courier",9pt)
	'FixedHeadingFont' = ("Courier",9pt)
	'BatchFixedFont' = ("Courier",6.7pt)
	'FixedFont' = ("Courier",9pt); 

	replace color_list /
	'link' = blue /* links */
	'bgH' = White /* row and column header background */
	'fg' = black /* text color */
	'bg' = white; /* page background color */ 

	replace Body from Document /
	 bottommargin = 1in
	 topmargin = 1in
	 rightmargin = 1in
	 leftmargin = 1in; 

	 replace Table from Output /
	 frame = hsides /* outside borders: void, box, above/below, vsides/hsides, lhs/rhs */
	 rules = groups /* internal borders: none, all, cols, rows, groups */
	 cellpadding = 0pt /* the space between table cell contents and the cell border */
	 cellspacing = 1pt /* the space between table cells, allows background to show */
	 borderwidth = 1pt /* the width of the borders and rules */; 

	 end;
run;

ods path mystyle.templat(update)
         sasuser.templat(update)
         sashelp.tmplmst(read);

ods path show;

%macro chkunique(lib=work, domain=, keys=usubjid);
    proc sort data=&lib..&domain out=&lib..&domain;
          by &keys;
    run;
    
    data _null_;
          set &lib..&domain;
          by &keys;
          if first.%scan(&keys, -1)+last.%scan(&keys, -1)<2 then do;
              %str(ERR)OR "duplicate records found in &domain";
          end;
    run;
%mend;

%macro import(lib=work, xlsdir=, xlsfile=);
    **** Import demographic data from demog_data.xls;
    proc import
    	datafile="&xlsdir/&xlsfile"
    	dbms=xlsx
		out=&lib..adsl
		replace;
		sheet="Sheet1";
	run;

    %chkunique(lib=&lib, domain=adsl, keys=subjid)

	proc print data=&lib..adsl (obs=5);

%mend;

**** _____________________________ done setup ______________________________;


