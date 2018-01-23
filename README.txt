SAS SNIPPET: SQLGEN.SAS 
Created by: Andrew Toler 
Date: 08 SEP 2016 
Copyright:
None, but please copy this header as attribution if you use/alter/copy/and/or
include any of this code in your work. 
Purpose: To dynamically generate SQL
code, and therefore large tables from lists input from metadata datasets. The
use of this is to create large, exhaustive, multi-part summary tables without
having to use proc freq or proc means.

Description:
This code is rather complex. It comes in at two levels of abstraction.

After creating fake data to work with, the program will create the exhaustive
shell table from the lists you provide. In this case, it is all the variables
labeled _list.  These are used to recursively construct the shell table. The
code that drives this part is called &sqlcode.

Then, the summary of the data occurs with &sqlblock. This creates the last two
summary columns, which are then appended to the table shell.

The purpose of this code is to 1. generate sql dynamically and 2. to demonstrate
how to make large tables from small chunks of template sql code.

-awjt