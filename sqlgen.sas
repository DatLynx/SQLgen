/* SAS SNIPPET: SQLGEN.SAS
Created by: Andrew Toler
Date: 08 SEP 2016
Copyright: None, but please copy this header as attribution if you use/alter/copy/and/or include any of this code in your work.
Purpose: To dynamically generate SQL code, and therefore large tables from lists input from metadata datasets.
	The use of this is to create large, exhaustive, multi-part summary tables without having to use proc freq or proc means.
*/
options minoperator nocenter nofmterr mprint mlogic symbolgen fullstimer compress=y;

/*1. Some fake data to use for this exercise */
data foo;
   input id name $ region $ state $ year categ;
   datalines;
01 ANDREW west TX 1970 3
02 JEREMY east TX 1978 2
03 LARS   east TX 1955 3
04 JENNY  west WI 1944 1
05 NORRIS west VT 2002 2
06 WANDA  west VT 2002 3
07 INEZ   east CA 2012 1
;
run;

/*2. The input data are processed into the usable dataset */ 
%macro makeds;  
proc sql;
 create table fac as
 select id
 		, Region
 		, State
 		, "div3" as Division
		, categ
		, year
 from foo
 union all
 select id * 10
 		, Region
 		, State
 		, "div2" as Division
		, categ
		, year
 from foo
 ;
quit;
proc print data=fac; run;
%mend;


%macro sqlmake(sqlblock, numsublevels, subsetlabels, labelextra, the_list);
%global sqlcode;
%let sqlcode=;
 %do i=1 %to %sysfunc(countW(%superQ(the_list), %str(,)));
 %let j=;
 %let j=%scan(%superQ(the_list), &i, %str(,));
   %let k=;
   %do k=1 %to &numsublevels;
    %let ff=%scan(%superQ(subsetlabels), &k, %str(,));
    %let sqlcode=&sqlcode 
    	select &i as rownum_a
      	, &k as rownum_b 
      	, "&rowvar &j., &labelextra &ff" as label
      	&sqlblock
      	where &subsetvar=%str(&k) and &rowvar="&j"
      	;
    %if &k<&numsublevels %then %let sqlcode=&sqlcode union all ;
   %end;
  %if &i<%sysfunc(countW(%superQ(the_list), %str(,))) %then %let sqlcode=&sqlcode union all ;
%end;
%mend;

%macro dosql(sqlblock, num, rowvar);
/* various lists */
%let facsize_list=%str(0 to 50, 51 to 100, 101 and up);
%let Region_list=%str(west, south, north, east);
%let division_list=%str(div1, div2, div3, div4, div5, div6, div7);
%let state_list= %str(CA, AZ, MA, ME, TX, VT, WI);
%let decade_list=%str(1940, 1950, 1960, 1970, 1980, 1990, 2000, 2010);
/* setup vars */
%let subsetvar=categ;
%let labelextra=facility size;

proc sql noprint;
	select count(distinct id) into: pplden from fac;
quit;

%let rowvar=Region;
%sqlmake(%nrbquote(&sqlblock), 3, &facsize_list, &labelextra, &Region_list);
%let sqlblock&num=&sqlcode;
%put &&sqlblock&num;

%let rowvar=State;
%sqlmake(%nrbquote(&sqlblock), 3, &facsize_list, &labelextra, &state_list);
%let sqlblock2=&sqlcode;
%put &sqlblock2;

%let rowvar=Division;
%sqlmake(%nrbquote(&sqlblock), 3, &facsize_list, &labelextra, &division_list);
%let sqlblock3=&sqlcode;
%put &sqlblock3;
%mend;

%macro sqlgen_maketbl;
proc sql;
	create table tbl as
	&sqlblock1
	union all
	&sqlblock2
	union all
	&sqlblock3
	;
quit;	
title "table output";
proc print data=tbl; run;
title;
%mend;

/* calls */
/*1. make fake dataset */	
%makeds

/*2. make the parts of the table */
%global sqlblock sqlblock1 sqlblock2 sqlblock3;
/* notes:
	pass in sql code template as a macro input parameter sqlblock
		make sure it is %quote'd
		this is the template for the table rows
*/
%let sqlblock=
%quote(
      , count(distinct id) as column1
      , count(distinct id)/&pplden as column2 format=pct8.2
     from fac
     );     
%dosql(&sqlblock, 1, Region)
%dosql(&sqlblock, 2, State)
%dosql(&sqlblock, 3, Division)

/*3. Assemble final table.*/
%sqlgen_maketbl
