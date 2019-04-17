*******************************************************************************
| Name       : scatterwithmargins1_example1.sas
| Purpose    : Examples of scatter with margins.
| SAS Version: 9.4
| Created By : Thomas Drury
| Date       : 05MAR19 
********************************************************************************/;

*** INCLUDE MVN TOOLS CODE ***;
options source2;
filename mvd "C:\Users\tad66240\OneDrive - GSK\statistics\repositories\sas\mvd_tools\mvd_tools.sas";
%include mvd;

*** INCLUDE GTL TOOLS CODE ***;
filename gtl "C:\Users\tad66240\OneDrive - GSK\statistics\repositories\sas\gtl_tools\scatterwithmargins1\scatterswithmargins1.sas";
%include gtl;


*** CREATE MVN DATA FOR TWO TREATMENTS ***;
data mvn_data;
   call streaminit(123456);
   array y_t1[2] y1_t1 y2_t1;
   array y_t2[2] y1_t2 y2_t2;
   array m1[2]   _temporary_ (0 0);
   array m2[2]   _temporary_ (2 3);
   array r1[2,2] _temporary_ (1.00 0.40
                              0.40 1.00);
   array r2[2,2] _temporary_ (1.00  0.70
                              0.70  1.00);
   do sim = 1 to 10000;
     call sim_mvn(y_t1,m1,r1);
     call sim_mvn(y_t2,m2,r2);
     output;
   end;
run;

***  MODIFY THE ODS JOURNAL STYLE FOR USE WITH PLOT ***;
proc template;
  define Style scatterstyle; 
    parent = styles.journal;
    style GraphFonts from GraphFonts "Fonts used in graph styles" / 
      'GraphTitleFont'    = (", ",16pt,bold)
      'GraphFootnoteFont' = (", ",8pt)
      'GraphLabelFont'    = (", ",14pt) 
      'GraphValueFont'    = (", ",14pt)
      'GraphDataFont'     = (", ",14pt);
  end;
run;

*** CREATE HTML PLOT ***;
options nomprint;
ods listing close;
ods html style = scatterstyle;
%scatterwithmargins1
 (indata  = mvn_data                    
 ,xvars   = %str(y1_t1, y1_t2)                    
 ,xtype   = CONT                    
 ,xrange  = %str(-4 to 6 by 1) 
 ,xrefs   = %str(0, 1, 2)                      
 ,xlabel  = %str(Response Variable Y1)                    
 ,xgridyn = Y                   
 ,yvars   = %str(y2_t1, y2_t2)                     
 ,ytype   = CONT                    
 ,yrange  = %str(-4 to 6 by 1) 
 ,yrefs   = %str(0, 1, 2)                    
 ,ylabel  = %str(Response Variable Y2)                    
 ,ygridyn = Y                   
 ,colors  = %str(lightblue,rose,black)
 ,pixels  = 2                   
 ,fade    = 0.3                 
 ,ptitle1 = %str(Scatterwithmargins1 Example 1)                    
 ,ptitle2 =                     
 ,pfoot1  =                     
 ,pfoot2  =                     
 ,pname   = scatterwithmargins1_example1                
);
ods html close;
ods listing;

*** DELETE WORK DATASETS ***;
proc datasets lib = work noprint;
  delete mvn_data;
run;
quit;
