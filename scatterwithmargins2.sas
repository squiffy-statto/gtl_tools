/*******************************************************************************
| Program Name:    scatterwithmargins2.sas
| Program Purpose: GTL Template for scatter with margins
| SAS Version:     9.4
| Created By:      Thomas Drury
| Date:            07-03-19  
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

********************************************************************************;
***                        SET UP GTL TEMPLATE                               ***;
********************************************************************************;

proc template;


  ***  MODIFY THE ODS JOURNAL STYLE FOR USE WITH PLOT ***;
  define style scatterwithmargins2style; parent = styles.listing;

    style graphwalls from graphwalls / 
      frameborder=on linestyle=1 linethickness=2px 
      backgroundcolor=GraphColors("gwalls") contrastcolor=white;

    style GraphFonts from GraphFonts "Fonts used in graph styles" / 
      'GraphTitleFont'    = (", ",10pt,bold)
      'GraphFootnoteFont' = (", ",8pt)
      'GraphLabelFont'    = (", ",8pt) 
      'GraphValueFont'    = (", ",7pt)
      'GraphDataFont'     = (", ",7pt);

  end;


run;

proc template;

  *** CREATE GRAPH TEMPLATE ***;
  define statgraph scatterwithmargins2;

    dynamic XVAR XMIN XMAX XBY XLABEL 
            YVAR YMIN YMAX YBY YLABEL
            COLOR FADE 
            T1 T2 
            F1 F2 
            D10 D20 D30 D40 D50 D60 D70 D80 D90 D95;

    begingraph / 
      backgroundcolor = white
      pad = 5
      designwidth  = 825px 
      designheight = 625px 
      border       = true
      borderattrs  = (color=greyaa);
      if (exists(T1)) entrytitle T1;    endif;  
      if (exists(T2)) entrytitle T2;    endif;   
      if (exists(F1)) entryfootnote F1; endif; 
      if (exists(F2)) entryfootnote F2; endif; 

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

        *** HISTOGRAM TOP POSITION ***;
        layout overlay / 
          walldisplay = (fill) 
          wallcolor   = white 
          yaxisopts   = (display=all offsetmin=0 griddisplay=on)
          xaxisopts   = (display=none linearopts =(tickvaluesequence=(start=XMIN end=XMAX increment= XBY) viewmin=XMIN viewmax=XMAX));
          histogram XVAR / binaxis=false fillattrs=(color=COLOR) outlineattrs=(color=black) datatransparency = FADE;
          densityplot XVAR / kernel(c=0.8) lineattrs=(color=black pattern=1);
          referenceline x=XREF   / lineattrs=(color = black pattern = 20 thickness=1px); 
        endlayout;
 
        *** TOTAL N IN TOP LEFT CORNER ***;
        layout gridded / 
          rows   = 1
          order  = columnmajor 
          border = false;  
          entry halign=left "N"  / textattrs=( size = 10pt );
/*          entry halign=left  "= " eval(strip(put(sum(_count_ ne .),8.0))) / textattrs=( size = 10pt );*/
        endlayout;

        *** SCATTER AND CONTOUR PLOTS ***;
        layout overlay / 
          xaxisopts = (griddisplay=on label=XLABEL linearopts =(tickvaluesequence=(start=XMIN end=XMAX increment= XBY) viewmin=XMIN viewmax=XMAX)) 
          yaxisopts = (griddisplay=on label=YLABEL linearopts =(tickvaluesequence=(start=YMIN end=YMAX increment=YBY) viewmin=YMIN viewmax=YMAX));
          scatterplot x=XVAR y=YVAR  / datatransparency = 0 markerattrs = (symbol=circlefilled size=4px color=green);
          contourplotparm x=density_xvar y=density_yvar z=density_zvar / contourtype=line levels=(D10 D20 D30 D40 D50 D60 D70 D80 D90 D95) lineattrs=(color=black pattern=1 thickness = 1);
          referenceline x=XREF / lineattrs=(color = black pattern = 20 thickness=1px); 
          referenceline y=YREF / lineattrs=(color = black pattern = 20 thickness=1px); 
        endlayout;

        *** HISTOGRAM ***;
        layout overlay / 
          walldisplay = (fill) 
          wallcolor   = white 
          xaxisopts   = (display=all offsetmin=0 griddisplay=on)
          yaxisopts   = (display=none linearopts =(tickvaluesequence=(start=YMIN end=YMAX increment= YBY) viewmin=YMIN viewmax=YMAX));
          histogram YVAR / orient=horizontal binaxis=false fillattrs=(color=COLOR) outlineattrs=(color=black) datatransparency = FADE;
          densityplot YVAR / orient=horizontal kernel(c=0.8) lineattrs=(color=black pattern=1);
          referenceline y=YREF / lineattrs=(color = black pattern = 20 thickness=1px); 
        endlayout;

      endlayout;    
    endgraph;
  end;

run;




*** INCLUDE TOOLS CODE ***;
options source2;
filename mvd url "https://raw.githubusercontent.com/squiffy-statto/mvd_tools/master/mvd_tools.sas";
%include mvd;

data mvn;
   call streaminit(123456);
   array y[2] y1-y2;
   array m[2]   _temporary_ (0 0);
   array r[2,2] _temporary_ (1.00 0.50
                             0.50 1.00);
   do sim = 1 to 1000;
     call sim_mvn(y,m,r);
     output;
   end;
run;

ods select none;
proc kde data = mvn;
  bivar  y1 y2 / 
  bwm   = 1
  ngrid = 200 
  levels = (10 20 30 40 50 60 70 80 90 95)
  out   = kde (rename = (value1  = density_xvar 
                         value2  = density_yvar 
                         density = density_zvar));
  ods output levels = levels;
run;
ods select all;

data _null_;
  set levels;
  call symput("D"||strip(put(percent,8.)),put(density,8.4));
run;

data forplot;
  set mvn
      kde;
run;




********************************************************************************;
*** CREATE RENDER                                                 ***;
********************************************************************************;

*** SET UP ODS GRAPH OPTIONS ***;
ods graphics on;
ods graphics / 
    reset 
    antialiasmax = 50000
    imagename    = "Plot1" 
    imagefmt     = png;

*** CREATE SG RENDER ***;
ods html style = scatterwithmargins2style;
proc sgrender data     = forplot 
              template = scatterwithmargins2;  

  dynamic XVAR     = "Y1"
          XMIN     = -3
          XMAX     = 3
          XBY      = 1 
          XLABEL   = "Y1"
          XREF     = 0
          YVAR     = "Y2"
          YMIN     = -3
          YMAX     = 3
          YBY      = 1
          YLABEL   = "Y2"
          YREF     = 0
          COLOR    = "GREEN"
          FADE     = 0.3  
          ;

run;
ods graphics off;
ods html close;
ods html style = htmlblue;


