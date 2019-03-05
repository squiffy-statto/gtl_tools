*******************************************************************************
| Name       : scatterwithmargins1_example1.sas
| Purpose    : Examples of scatter with margins.
| SAS Version: 9.4
| Created By : Thomas Drury
| Date       : 05MAR19 
********************************************************************************/;

*** INCLUDE MVN TOOLS CODE ***;
options source2;
filename mvd url "https://mygithub.gsk.com/raw/tad66240/mvd_tools/master/mvd_tools.sas?token=AAAAtLfNkLxphIWCopzRECC4siF2oPV3ks5chqLSwA%3D%3D";
%include mvd;

*** INCLUDE GTL TOOLS CODE ***;
filename gtl url "https://mygithub.gsk.com/raw/tad66240/gtl_tools/master/scatterswithmargins1.sas?token=AAAAtMjL2v0Cj89yjMNtnjLrHoq2Jr-xks5chqXiwA%3D%3D";
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

*** CREATE HTML PLOT ***;
options nomprint;
ods html;
%scatterwithmargins_v1
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

*** DELETE WORK DATASETS ***;
proc datasets lib = work noprint;
  delete mvn_data;
run;
quit;
