/********************** START **************************/

%let reported_company= Example;

%let start_day = '01jan2022'd;
%let start_date = %sysfunc(putn(&start_day, yymmddn8.));
%put start_date=&start_date;

%let end_day = '01aug2022'd;
%let end_day=%sysfunc(intnx(day,&end_day,-1));
%let end_date=%sysfunc(putn(&end_day, yymmddn8.));
%put end_date=&end_date;

%let cond1=(where=(cmd in (0 1)));
%let cond2=(where=(side in ("BUY" "SELL")) drop=flag);
%let cond3=(where=(cmd in (0 1)) drop=Dealer);


%macro set_data(filename,start,end,conds);

    %let n_month=%sysfunc(intck(month,&start,&end));
     %do i=0 %to &n_month;
      %let tmp_file=&filename._%sysfunc(intnx(month,&start,&i),yymmn6.);
        %if %sysfunc(exist(&tmp_file)) %then %do;
           &tmp_file.&conds
        %end;
    %end;

%mend set_data;



data trades_data;
 set %set_data(filename=Cosm_db.Cosmos_trades_mod, start=&start_day, end=&end_day, conds=&cond1)
     %set_data(filename=Mt5db.Mt5_trades_mod, start=&start_day, end=&end_day, conds=&cond1)
     %set_data(filename=Metat.Mt4_trades_mod, start=&start_day, end=&end_day, conds=&cond1)
     %set_data(filename=Acm1.Acm_trade_mod, start=&start_day, end=&end_day, conds=&cond2)
     Cosm_db.Cosmos_trades_mod_open&cond3
     Mt5db.Mt5_trades_mod_open&cond1
     Metat.Mt4_trades_mod_open&cond1
    ;
run;


proc sql noprint;
  select distinct partner_companie_name into:company separated by '","'
  from officies.reportable_entities(where=(partner_companie_name in ("&reported_company")));
quit;
%put company=&company;

proc sql noprint;
 select distinct label into:lei separated by '","'
 from crm_mod.companies_lei(where=(start in ("&company")));
quit;
%put lei=&lei;


 data trades_total(keep=customer_id);
   set trades_data;
    set bidata.acc_all(keep=customer_id partner_companie_name lei test_c) key=customer_id/unique;
     select(_iorc_);
       when (%sysrc(_sok)) do;
         if test_c^=1;
         if (partner_companie_name in ("&company") and lei not in (" ", "NULL")) or (lei in ("&lei"))  ;
       output;
     end;
     when (%sysrc(_Dsenom)) do;
         _error_=0;
     end;
       otherwise;
     end;
  run;


proc sort data=trades_total nodupkey out=stam.uniq_customers;
by customer_id;
run;



proc export data=stam.uniq_customers
              dbms=csv
              outfile="/mnt/netapp/SAS/tmprep/uniq_customers.csv"
              label replace;
run;




/********************** END ****************************/
