/*******************************************************************************
| Program Name:   scatterwithmargins_v1.sas
| Program Version: 1.0
| Program Purpose: Macro Tool to make scatter plots for continuouos and a mix. 
|                  of continuous and discrete variables. 
| SAS Version:  9.4 (University Edition).
| Created By:   Thomas Drury
| Date:         16-12-16  
|--------------------------------------------------------------------------------
| Output: PNG Plot.         
|--------------------------------------------------------------------------------
| Global macro variables created: NONE
| Macros called: NONE.
| Local macros parameters: NONE.
| Notes: Reusable tool to plot bivariate pairs of variables. See foot of program
|        for example calls. 
|        1. Continuous variables plotted as scatter with contour and margins on 
|           top and side via histograms and kdes. 
|        2. Discrete variables plotted as scatters jittered around the discrete
|           value and needle plots for margins on top and side.
|        3. Mixtures of variables plotted with scatters jittered around discrete
|           value with needle marginals and histogram and kde for continuous
|           margins. 
|--------------------------------------------------------------------------------
| Change Log:
|
|
********************************************************************************/;

%macro scatterwithmargins1(
  indata   = ,                    /*** DATASET WITH RAW VALUES IN ***/
  inwhere  = ,                    /*** ALLOWS A WHERE CLAUSE ON DATA GOING IN ***/
  xvars    = ,                    /*** COMMA SEP LIST OF VARIABLE FOR XAXIS (MUST BE SAME TYPE) ***/
  xtype    = ,                    /*** VALUE DISC OR CONT DICTATES WHAT THE SCATTER LOOKS LIKE  ***/
  xrange   = %str(0 to 1 by 0.1), /*** SPECIFY <MIN> TO <MAX> BY <INTERVAL> ***/
  xrefs    = ,                    /*** COMMA SEP LIST OF VALUE FOR REF LINES ON XAXIS ***/
  xlabel   = ,                    /*** LABEL TEXT FOR XAXIS ***/
  xgridyn  = Y,                   /*** PUT LIGHT GREY GRIDLINE ON XAXIS ***/
  yvars    = ,                    /*** COMMA SEP LIST OF VARIABLE FOR YAXIS (MUST BE SAME TYPE) ***/
  ytype    = ,                    /*** VALUE DISC OR CONT DICTATES WHAT THE SCATTER LOOKS LIKE  ***/
  yrange   = %str(0 to 1 by 0.1), /*** SPECIFY <MIN> TO <MAX> BY <INTERVAL> ***/
  yrefs    = ,                    /*** COMMA SEP LIST OF VALUE FOR REF LINES ON YAXIS ***/
  ylabel   = ,                    /*** LABEL TEXT FOR XAXIS ***/
  ygridyn  = Y,                   /*** PUT LIGHT GREY GRIDLINE ON YAXIS ***/
  colors   = %str(red,blue,black),/*** COMMA SEP LIST OF COLORS TO USE ***/
  pixels   = 4,                   /*** SIZE OF EACH SCATTER POINT IN PIXELS ***/
  fade     = 0.3,                 /*** HOW TRANSPARENT THE PLOTS ARE FOR OVERLAYING ***/
  kdeband  = 1,                   /*** BAND WIDTH FOR KDE CONTOURS WHEN CONTINUOUS PLOTTED ***/
  ptitle1  = ,                    /*** TITLE1 FOR PLOT IMAGE ***/
  ptitle2  = ,                    /*** TITLE2 FOR PLOT IMAGE ***/
  pfoot1   = ,                    /*** FOOTNOTE1 FOR PLOT IMAGE ***/
  pfoot2   = ,                    /*** FOOTNOTE2 FOR PLOT IMAGE ***/
  pname    = plot1                /*** IMAGE NAME FOR PLOT ***/
  pstyle   = listing
);

%********************************************************************************;
%*** SECTION 1: ERROR CHECKING CRITICAL INFORMATION                           ***;
%********************************************************************************;

%*** COUNT COMMA SEPERATED LISTS ***;
%let xvarsn  = %sysfunc(countw(&xvars.,%str(,)));
%let xrefsn  = %sysfunc(countw(&xrefs.,%str(,)));
%let yvarsn  = %sysfunc(countw(&yvars.,%str(,)));
%let yrefsn  = %sysfunc(countw(&yrefs.,%str(,)));
%let colorsn = %sysfunc(countw(&colors.,%str(,)));

%*** CHECK LIST TOTALS AGREE ***;
%if &xvarsn. = &yvarsn. %then %do;
  %let dim = &xvarsn.;
  %put NO%upcase(te): (scatterwithmargins): Number of X and Y Variables to Plot = &dim..;;
%end;
%else %do;
  %put ER%upcase(ror): (scatterwithmargins): Number of X and Y Variables do not match.;;
  %put XVARS  = &xvarsn.  (&xvars.); 
  %put YVARS  = &yvarsn.  (&yvars.); 
  %abort cancel;
%end;

%*** CHECK THERE ARE ENOUGH COLORS SPECIFIED ***;
%if &colorsn. ge &dim. %then %do;
  %put NO%upcase(te): (scatterwithmargins): Number of colors specified more than variables;;
%end;
%else %do;
  %put WA%upcase(rning): (scatterwithmargins): Number of colors less than variables;;
  %put DIM  = &dim.; 
  %put COLORS = &colorsn.; 
  %abort cancel;
%end;

%*** GET X AND Y AXES SPECIFICATIONS ***;
%let xtopos = %index(%upcase(&xrange.),%str(TO));
%let xbypos = %index(%upcase(&xrange.),%str(BY));
%let ytopos = %index(%upcase(&yrange.),%str(TO));
%let ybypos = %index(%upcase(&yrange.),%str(BY));

%*** CHECK AXES SPECIFIED WITH TO AND BY ***;
%if (xtopos = 0) or (xbypos = 0) %then %do;
  %put WA%upcase(rning): (scatterwithmargins): XRANGE not specified correctly. Specify as: <MIN> TO <MAX> BY <INT>.;;
  %abort cancel;
%end; 
%if (ytopos = 0) or (ybypos = 0) %then %do;
  %put WA%upcase(rning): (scatterwithmargins): YRANGE not specified correctly. Specify as: <MIN> TO <MAX> BY <INT>.;;
  %abort cancel;
%end; 

%********************************************************************************;
%*** SECTION 1: PROCESS MACRO PARAMETERS AND LISTS SUPPLIED                   ***;
%********************************************************************************;

%*** VARIBABLES AND COLORS ***;
%do ii = 1 %to &dim.;
  %let xvar&ii.  = %scan(&xvars.,&ii.,%str(,));
  %let yvar&ii.  = %scan(&yvars.,&ii.,%str(,));
  %let color&ii. = %scan(&colors.,&ii.,%str(,));
%end;

%*** X REFERENCE LINES IF ANY ***;
%do ii = 1 %to &xrefsn.;
  %let xref&ii. = %scan(&xrefs.,&ii.,%str(,));
%end;

%*** Y REFERENCE LINES IF ANY ***;
%do ii = 1 %to &yrefsn.;
  %let yref&ii. = %scan(&yrefs.,&ii.,%str(,));
%end;

%*** X AXIS VALUES ***;
%if (xtopos ne 0) and (xbypos ne 0) %then %do;
  %let string1 = %sysfunc(tranwrd( %upcase(&xrange.), %str(TO), %str(#) ));
  %let string2 = %sysfunc(tranwrd( %upcase(&string1.), %str(BY), %str(#) ));
  %let xmin = %scan(&string2.,1,%str(#));
  %let xmax = %scan(&string2.,2,%str(#));
  %let xby  = %scan(&string2.,3,%str(#));
%end; 

%*** X AXIS VALUES ***;
%if (ytopos ne 0) and (ybypos ne 0) %then %do;
  %let string1 = %sysfunc(tranwrd( %upcase(&yrange.), %str(TO), %str(#) ));
  %let string2 = %sysfunc(tranwrd( %upcase(&string1.), %str(BY), %str(#) ));
  %let ymin = %scan(&string2.,1,%str(#));
  %let ymax = %scan(&string2.,2,%str(#));
  %let yby  = %scan(&string2.,3,%str(#));
%end; 

%********************************************************************************;
%*** SECTION 3: READ IN DATASET AND MODIFY IF DISCRETE DATA                   ***;
%********************************************************************************;

*** READ IN DATA ***;
data w_scatter;
  set &indata.;
  &inwhere.;
run;

%********************************************************************************;
%*** SECTION 4: IF EITHER AXIS IS DICRETE THE CALCULATE FREQUENCIES           ***;
%********************************************************************************;

%if (%upcase(&xtype.) = DISC) %then %do;
%do ii = 1 %to &dim.;
  proc freq data = w_scatter noprint;
    tables &&xvar&ii. / out = s_xfreqs_xvar&ii.(rename =(percent=percent_xvar&ii.));
  run;
%end;
%end;

%if (%upcase(&ytype.) = DISC) %then %do;
%do ii = 1 %to &dim.;
  proc freq data = w_scatter noprint;
    tables &&yvar&ii. / out = s_yfreqs_yvar&ii.(rename=(percent=percent_yvar&ii.));
  run;
%end;
%end;

%********************************************************************************;
%*** SECTION 4: IF BOTH AXES CONTINUOUS THEN GET BIVARIATE KDE ESTIMATES      ***;
%********************************************************************************;

%if (%upcase(&xtype.) = CONT) and (%upcase(&ytype.) = CONT) %then %do;
  *** GET KDE ESTIMATES ***;
  ods select none;
  proc kde data = w_scatter;
    %do ii = 1 %to &dim.;
      bivar &&xvar&ii. &&yvar&ii. / 
      bwm   = &kdeband.
      ngrid = 200 
      out   = w_kde&ii. (rename = (value1  = density_&&xvar&ii. 
                                   value2  = density_&&yvar&ii.. 
                                   density = density_z&ii.));
    %end;
  run;
  ods select all;
%end;


%********************************************************************************;
%*** SECTION 4: SET UP GTL TEMPLATE                                           ***;
%********************************************************************************;

*** SET UP GTL TEMPLATE ***;
proc template;

  *** CREATE GRAPH TEMPLATE ***;
  define statgraph ScatterWithMargins;

    dynamic XTYPE XMIN XMAX XBY XLABEL 
            YTYPE YMIN YMAX YBY YLABEL
            FADE 
            %if %length(&ptitle1.) ne 0 %then %do; T1 %end; 
            %if %length(&ptitle2.) ne 0 %then %do; T2 %end; 
            %if %length(&pfoot1.) ne 0 %then %do; F1 %end; 
            %if %length(&pfoot2.) ne 0 %then %do; F2 %end; 
            ;

    begingraph / 
      backgroundcolor = white
      pad = 5
      designwidth  = 825px 
      designheight = 625px 
      border       = true
      borderattrs  = (color=greyaa);
      %if %length(&ptitle1.) ne 0 %then %do; entrytitle T1;   %end;
      %if %length(&ptitle2.) ne 0 %then %do; entrytitle T2;   %end;
      %if %length(&pfoot1.) ne 0 %then %do;  entryfootnote F1; %end;
      %if %length(&pfoot2.) ne 0 %then %do;  entryfootnote F2; %end;

      layout lattice / 
        pad=10
        rows            = 2 
        columns         = 2 
        rowdatarange    = union
        columndatarange = union
        rowgutter       = 10 
        columngutter    = 10
        rowweights      = (.22 .78) 
        columnweights   = (.78 .22);

        *** GREY LINE TO SEPERATE MARGIN PLOTS FROM SCATTER ***;
        drawline x1 = 0 y1 = 77 x2 = 100 y2 = 77 /
         x1space=layoutpercent y1space=layoutpercent x2space=layoutpercent y2space=layoutpercent
         lineattrs=GraphReference layer=front lineattrs=(color = greyaa thickness=1);
        drawline x1 = 77 y1 = 0 x2 = 77 y2 = 100 /
         x1space=layoutpercent y1space=layoutpercent x2space=layoutpercent y2space=layoutpercent
         lineattrs=GraphReference layer=front lineattrs=(color = greyaa thickness=1);

        *** HISTOGRAM OR NEEDLE PLOT AT TOP POSITION - CREATE NEEDLE WITH DROPLINES ON FAKE SCATTER ***;
        layout overlay / 
          walldisplay = (fill) 
          wallcolor   = GraphBackground:color 
          yaxisopts   = (display=all offsetmin=0 griddisplay=on
                         %if %upcase(&xtype.) = DISC %then %do; 
                         linearopts =(tickvaluesequence=(start=0 end=100 increment=10)viewmin=0 viewmax=100) label="Percent" 
                         %end;)
          xaxisopts   = (display=none linearopts =(tickvaluesequence=(start=XMIN end=XMAX increment= XBY) viewmin=XMIN viewmax=XMAX))
          ;

          if (upcase(XTYPE) = "DISC") 
            %do ii = 1 %to &dim.;
            scatterplot x=ordered_xvar&ii. y=percent_xvar&ii. / markerattrs = (symbol=circlefilled size=&pixels.px color=white) datatransparency=1;
            dropline    x=ordered_xvar&ii. y=percent_xvar&ii. / dropto=x lineattrs=(pattern=1 thickness=3 color=&&color&ii.);
            %end;
          else 
            %do ii = 1 %to &dim.;
            histogram &&xvar&ii. / binaxis=false fillattrs=(color=&&color&ii.) outlineattrs=(color=&&color&ii.) datatransparency = FADE;
            densityplot &&xvar&ii. / kernel(c=0.8) lineattrs=(color=black pattern=1);
            %end;
            %do ii = 1 %to &xrefsn.;
            referenceline x=&&xref&ii. / lineattrs=(color = black pattern = 20 thickness=1px); 
            %end;
          endif;
        endlayout;
 
        *** TOTAL N IN TOP LEFT CORNER ***;
        layout gridded / 
          rows   = &dim.
          order  = columnmajor 
          border = false;  
          %do ii = 1 %to &dim.; 
          entry halign=left "N&ii."  / textattrs=( size = graphlabelfont:size );
          %end;
          %do ii = 1 %to &dim.; 
          entry halign=left  "= " eval(strip(put(sum(_count_ ne .),8.0))) / textattrs=( size = graphlabelfont:size );
          %end;
        endlayout;

        *** SCATTER AND CONTOUR PLOTS ***;
        layout overlay / 
          xaxisopts = (%if (&xgridyn. = Y) and (%upcase(&xtype.) = CONT) %then %do; griddisplay=on %end;  
            label=XLABEL
            linearopts =(tickvaluesequence=(start=XMIN end=XMAX increment= XBY) viewmin=XMIN viewmax=XMAX)) 
          yaxisopts = (%if (&ygridyn. = Y) and (%upcase(&ytype.) = CONT) %then %do; griddisplay=on %end; 
            label=YLABEL
            linearopts =(tickvaluesequence=(start=YMIN end=YMAX increment=YBY) viewmin=YMIN viewmax=YMAX));
          %if (%upcase(&xtype.) = CONT) and (%upcase(&ytype.) = CONT) %then %do;
            %do ii = 1 %to &dim.;
            scatterplot x=&&xvar&ii. y=&&yvar&ii.  / 
              datatransparency = 0 
              markerattrs = (symbol=circlefilled size=&pixels.px color=&&color&ii.);
            contourplotparm  x=density_&&xvar&ii. y=density_&&yvar&ii. z=density_z&ii. / 
              contourtype=line 
              nlevels = 11 
              lineattrs = (color=black pattern=1 thickness = 1);
            %end;
            %do ii = 1 %to &xrefsn.;
            referenceline x=&&xref&ii. / lineattrs=(color = black pattern = 20 thickness=1px); 
            %end;
            %do ii = 1 %to &yrefsn.;
            referenceline y=&&yref&ii. / lineattrs=(color = black pattern = 20 thickness=1px); 
            %end;
          %end;
          %else %if (%upcase(&xtype.) = DISC) and (%upcase(&ytype.) = CONT) %then %do;
            %do ii = 1 %to &dim.;
            scatterplot x=jitered_xvar&ii. y=&&yvar&ii.  / 
              datatransparency = 0 
              markerattrs = (symbol=circlefilled size=&pixels.px color=&&color&ii.);
            %end;
            %do ii = 1 %to &yrefsn.;
            referenceline y=&&yref&ii. / lineattrs=(color = black pattern = 20 thickness=1px); 
            %end;
          %end;
          %else %if (%upcase(&xtype.) = CONT) and (%upcase(&ytype.) = DISC) %then %do;
            %do ii = 1 %to &dim.;
            scatterplot x=&&xvar&ii. y=jitered_yvar&ii.  / 
              datatransparency = 0 
              markerattrs = (symbol=circlefilled size=&pixels.px color=&&color&ii.);
            %end;
            %do ii = 1 %to &xrefsn.;
            referenceline x=&&xref&ii. / lineattrs=(color = black pattern = 20 thickness=1px); 
            %end;
          %end;
          %else %if (%upcase(&xtype.) = DISC) and (%upcase(&ytype.) = DISC) %then %do;
            %do ii = 1 %to &dim.;
            scatterplot x=jitered_xvar&ii. y=jitered_yvar&ii.  / 
              datatransparency = 0 
              markerattrs = (symbol=circlefilled size=&pixels.px color=&&color&ii.);
            %end;
          %end;
          %if (&xgridyn. = Y) and (%upcase(&xtype.) = DISC) %then %do; 
            %let ii = %sysevalf(&xmin. + (0.5*&xby.));
            %do %until(&ii. ge &xmax.);
            referenceline x=&ii. / lineattrs=(color = lightgrey pattern = 1 thickness=1px); 
            %let ii = %sysevalf(&ii.+&xby.);
            %end;
          %end;
          %if (&ygridyn. = Y) and (%upcase(&ytype.) = DISC) %then %do; 
            %let jj = %sysevalf(&ymin. + (0.5*&yby.));
            %do %until(&jj. ge &ymax.);
            referenceline y=&jj. / lineattrs=(color = lightgrey pattern = 1 thickness=1px); 
            %let jj = %sysevalf(&jj.+&yby.);
            %end;
          %end;
        endlayout;

        *** HISTOGRAM OR NEEDLE AT SIDE POSITION - CREATE NEEDLE WITH DROPLINES ON FAKE SCATTER ***;
        layout overlay / 
          walldisplay = (fill) 
          wallcolor   = GraphBackground:color 
          xaxisopts   = (display=all offsetmin=0 griddisplay=on
                         %if %upcase(&ytype.) = DISC %then %do; 
                         linearopts =(tickvaluesequence=(start=0 end=100 increment=10)viewmin=0 viewmax=100) label="Percent" 
                         %end;)
          yaxisopts   = (display=none linearopts =(tickvaluesequence=(start=YMIN end=YMAX increment= YBY) viewmin=YMIN viewmax=YMAX));
          if (upcase(YTYPE) = "DISC") 
            %do ii = 1 %to &dim.;
            scatterplot y=ordered_yvar&ii. x=percent_yvar&ii. / markerattrs = (symbol=circlefilled size=&pixels.px color=white) datatransparency=1;
            dropline y=ordered_yvar&ii. x=percent_yvar&ii. / dropto=y lineattrs=(pattern=1 thickness=3 color=&&color&ii.);
            %end;
          else 
            %do ii = 1 %to &dim.;
            histogram &&yvar&ii. / orient=horizontal binaxis=false fillattrs=(color=&&color&ii.) outlineattrs=(color=&&color&ii.) datatransparency = FADE;
            densityplot &&yvar&ii. / orient=horizontal kernel(c=0.8) lineattrs=(color=black pattern=1);
            %end;
            %do ii = 1 %to &yrefsn.;
            referenceline y=&&yref&ii. / lineattrs=(color = black pattern = 20 thickness=1px); 
            %end;
          endif;
        endlayout;

      endlayout;    
    endgraph;
  end;



%********************************************************************************;
%*** SECTION 5: STACK SCATTER DATA AND KDE ESTIMATES IF PRESENT               ***;
%********************************************************************************;

  ***  STACK ALL NECESSARY DATA ***;
  data w_scatterwithmargins;
    set w_scatter (in=a)
        %if (%upcase(&xtype.) = CONT) and (%upcase(&ytype.) = CONT) %then %do; w_kde: %end;
        %if (%upcase(&xtype.) = DISC) %then %do; s_xfreqs: %end; 
        %if (%upcase(&ytype.) = DISC) %then %do; s_yfreqs: %end; 
    ;
   if a then _count_ = 1;
 
   %if (%upcase(&xtype.) = DISC) %then %do;
   %let xincrement = %sysevalf(&xby./(&dim.+1));
   %do ii = 1 %to &dim.;
   ordered_xvar&ii. = &&xvar&ii. - (&xby./2) + (&ii.*&xincrement.);
   jitered_xvar&ii. = ordered_xvar&ii. - (0.25*&xincrement.) + (ranuni(0)*&xincrement.*0.5);
   %end;
   %end;

   %if (%upcase(&ytype.) = DISC) %then %do;
   %let yincrement = %sysevalf(&yby./(&dim.+1));
   %do ii = 1 %to &dim.;
   ordered_yvar&ii. = &&yvar&ii. - (&yby./2) + (&ii.*&yincrement.);
   jitered_yvar&ii. = ordered_yvar&ii. - (0.25*&yincrement.) + (ranuni(0)*&yincrement.*0.5);
   %end;
   %end;

  run;


%********************************************************************************;
%*** SECTION 6: CREATE RENDER                                                 ***;
%********************************************************************************;

  *** SET UP ODS GRAPH OPTIONS ***;
  ods graphics on;
  ods graphics / 
    reset 
    antialiasmax = 50000
    imagename    = "&pname." 
    imagefmt     = png;

  *** CREATE SG RENDER ***;
  proc sgrender data     = w_scatterwithmargins 
                template = ScatterWithMargins;  
  dynamic XTYPE    = "&xtype."
          XMIN     = "&xmin."
          XMAX     = "&xmax."
          XBY      = "&xby." 
          XLABEL   = "&xlabel."
          YTYPE    = "&ytype."
          YMIN     = "&ymin."
          YMAX     = "&ymax."
          YBY      = "&yby."
          YLABEL   = "&ylabel."
          FADE     = "&fade."  
          %if %length(&ptitle1.) ne 0 %then %do; T1= "&ptitle1." %end;
          %if %length(&ptitle2.) ne 0 %then %do; T2= "&ptitle2." %end;
          %if %length(&pfoot1.) ne 0 %then %do;  F1= "&pfoot1." %end;
          %if %length(&pfoot2.) ne 0 %then %do;  F2= "&pfoot2." %end;
          ;
  run;
  ods graphics off;


%********************************************************************************;
%*** SECTION 7: CLEAN UP WORK AREA                                            ***;
%********************************************************************************;

*** DELETE TEMPORARY DATASETS ***;
proc datasets lib = work nolist;
  delete w_: s_:;
run;
quit;

%mend;

/**/
/**/
/*********************************************************************************;*/
/****                              EXAMPLE CALL                                ***;*/
/*********************************************************************************;*/
/**/
/*data class;*/
/*  set sashelp.class;*/
/*  age2 = age + 1;*/
/*  weight2 = weight*0.8;*/
/*  if sex = "M" then sexn = 1;*/
/*   else sexn = 2;*/
/*run;*/
/**/
/*options nomprint;*/
/*ods html;*/
/*%scatterwithmargins1*/
/* (indata  = class                    */
/* ,xvars   = %str(sexn, sexn)                    */
/* ,xtype   = DISC                    */
/* ,xrange  = %str(0 to 3 by 1) */
/* ,xrefs   = %str(50, 100, 150)                      */
/* ,xlabel  =                     */
/* ,xgridyn = Y                   */
/* ,yvars   = %str(weight, height)                     */
/* ,ytype   = CONT                    */
/* ,yrange  = %str(0 to 200 by 10) */
/* ,yrefs   = %str(50, 100, 150)                    */
/* ,ylabel  =                     */
/* ,ygridyn = Y                   */
/* ,colors  = %str(red,blue,black)*/
/* ,pixels  = 4                   */
/* ,fade    = 0.3                 */
/* ,ptitle1 =                     */
/* ,ptitle2 =                     */
/* ,pfoot1  =                     */
/* ,pfoot2  =                     */
/* ,pname   = plot1                */
/*);*/
/*ods html close;*/


