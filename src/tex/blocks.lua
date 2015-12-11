TexBlocks = {}
TexBlocks.__index = TexBlocks

TexBlocks.boxplotSettings = [[
  \usepgfplotslibrary{statistics}
  \definecolor{whiskergrey}{rgb}{0.7, 0.7, 0.7}
  \pgfplotsset{
      boxplot/every whisker/.style={dashed, whiskergrey},
      boxplot/every median/.style={ultra thick,blue},
      boxplot prepared from table/.code={
          \def\tikz@plot@handler{\pgfplotsplothandlerboxplotprepared}%
          \pgfplotsset{
              /pgfplots/boxplot prepared from table/.cd,
              #1,
          }
      },
      /pgfplots/boxplot prepared from table/.cd,
          table/.code={\pgfplotstablecopy{#1}\to\boxplot@datatable},
          row/.initial=0,
          make style readable from table/.style={
              #1/.code={
                  \pgfplotstablegetelem{\pgfkeysvalueof{/pgfplots/boxplot prepared from table/row}}{##1}\of\boxplot@datatable
                  \pgfplotsset{boxplot/#1/.expand once={\pgfplotsretval}}
              }
          },
          make style readable from table=lower whisker,
          make style readable from table=upper whisker,
          make style readable from table=lower quartile,
          make style readable from table=upper quartile,
          make style readable from table=median,
          make style readable from table=lower notch,
          make style readable from table=upper notch
  }
  \makeatother
]]

TexBlocks.boxplotPlot = function(index)
  return [[
  \addplot[
  boxplot prepared from table={
    table=\datatable,
    row=]] .. index .. [[,
    lower whisker=min,
    upper whisker=max,
    lower quartile=low,
    upper quartile=high,
    median=med
  }, boxplot prepared]
  coordinates {};
  ]]
  end