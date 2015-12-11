Graphs = {}
Graphs.__index = Graphs

Graphs.mppsGraph = function(columns, rxFile, txFile)
  return [[
  \begin{tikzpicture}
  \begin{axis}[
  width=\textwidth,
  height=0.5\textwidth,
  ymin=0,
  xlabel={time in [s]},
  ylabel={packets in [mpps]},
  grid=major,
  legend style={at={(1.05,0.5)},anchor=north,legend cell align=left}]
  
  \addlegendentry{tx}
  \addplot [color=red,mark=*] table []] .. columns .. [[,col sep=comma] {]] .. txFile ..[[};
  \addlegendentry{rx}
  \addplot [color=blue,mark=x] table []] .. columns .. [[,col sep=comma] {]] .. rxFile ..[[};
  \end{axis}
  \end{tikzpicture}
  \caption{throughput graph}
  \label{fig:throughput}
  ]]
  end

Graphs.mbitGraph = function(columns, rxFile, txFile)
  return [[
  \begin{tikzpicture}
  \begin{axis}[
  width=\textwidth,
  height=0.5\textwidth,
  ymin=0,
  xlabel={time in [s]},
  ylabel={packets in [mbit]},
  grid=major,
  legend style={at={(1.05,0.5)},anchor=north,legend cell align=left}]
  
  \addlegendentry{tx}
  \addplot [color=red,mark=*] table []] .. columns .. [[,col sep=comma] {]] .. txFile ..[[};
  \addlegendentry{rx}
  \addplot [color=blue,mark=x] table []] .. columns .. [[,col sep=comma] {]] .. rxFile ..[[};
  \end{axis}
  \end{tikzpicture}
  \caption{throughput graph}
  \label{fig:throughput}
  ]]
  end

Graphs.pktLoss = function(total, loss)
  return [[
  \begin{tikzpicture}
  \begin{axis}[
  width=\textwidth,
  height=0.2\textwidth,
  xbar, xmin=0,
  xlabel={packet loss},
  symbolic y coords={total,loss},
  ytick=data,
  enlarge y limits=0.5,
  nodes near coords, 
  nodes near coords align={horizontal},
  legend style={at={(1.05,0.5)},anchor=north,legend cell align=left}]
  
  \addplot coordinates {(]] .. total .. [[,total)(]] .. loss .. [[,loss)};
  \end{axis}
  \end{tikzpicture}
  \caption{packet loss}
  \label{fig:pktloss}
  ]]
  end

Graphs.throughputStats = function(labels, file)
  return [[
  \begin{tikzpicture}
  \begin{axis}[
  width=\textwidth,
  height=0.8\textwidth,
  ymin=0,
  xlabel={]] .. labels.x .. [[},
  ylabel={]] .. labels.y .. [[},
  grid=major,
  xtick=data,
  legend style={at={(1.05,0.5)},anchor=north,legend cell align=left}]
  
  \addlegendentry{max}
  \addplot [color=gray,style=loosely dashed, mark=x] table [x=parameter, y=max, col sep=comma] {]] .. file ..[[};
  \addlegendentry{min}
  \addplot [color=gray,style=dashed,mark=x] table [x=parameter, y=min, col sep=comma] {]] .. file ..[[};
  \addlegendentry{avg}
  \addplot [color=blue,mark=square*] table [x=parameter, y=avg, col sep=comma] {]] .. file ..[[};
  \end{axis}
  \end{tikzpicture}
  \caption{throughput graph}
  \label{fig:throughput:stats}
  ]]
  end

Graphs.throughputStatsBars = function(labels, file)
  return [[
  \pgfplotstableread[col sep=comma]{]] .. file ..[[}\datatable
  \definecolor{mingrey}{rgb}{0.7, 0.75, 0.71}
  \definecolor{maxgrey}{rgb}{0.43, 0.5, 0.5}
  \begin{tikzpicture}
  \begin{axis}[
  width=\textwidth,
  height=0.8\textwidth,
  ybar,
  ymin=0,
  xlabel={]] .. labels.x .. [[},
  ylabel={]] .. labels.y .. [[},
  grid=major,
  xticklabels from table={\datatable}{parameter},
  x tick label style={rotate=60,anchor=east},
  xtick=data,
  enlarge x limits=0.5,
  legend style={at={(1.05,0.5)},anchor=north,legend cell align=left}]
  
  \addlegendentry{min}
  \addplot [color=black, fill=mingrey, style=dashed] table [x expr=\coordindex, y=min] {\datatable};
  \addlegendentry{avg}
  \addplot [color=black, fill=blue] table [x expr=\coordindex, y=avg] {\datatable};
  \addlegendentry{max}
  \addplot [color=black, fill=maxgrey, style=dashed] table [x expr=\coordindex, y=max] {\datatable};
  \end{axis}
  \end{tikzpicture}
  \caption{throughput graph}
  \label{fig:throughput:bars}
  ]]
  end

Graphs.throughputBoxplot = function(labels, file, count)
  local ticks = ""
  local plots = ""
  for i=1,count do
    ticks = ticks .. tostring(i) .. ","
    plots = plots .. TexBlocks.boxplotPlot(i-1)
  end
  if (string.len(ticks) > 1) then ticks = string.sub(ticks,1,string.len(ticks)-1) end
  return [[
  \begin{tikzpicture}
  ]] .. TexBlocks.boxplotSettings .. [[
  \pgfplotstableread[col sep=comma]{]] .. file ..[[}\datatable
  \begin{axis}[
  width=\textwidth,
  height=0.8\textwidth,
  boxplot/draw direction=y,
  ymin=0,
  xlabel={]] .. labels.x .. [[},
  ylabel={]] .. labels.y .. [[},
  xtick={]] .. ticks .. [[},
  xticklabels from table={\datatable}{parameter},
  x tick label style={rotate=60,anchor=east},
  legend style={at={(1.05,0.5)},anchor=north,legend cell align=left}]
  
  ]] .. plots .. [[
  \end{axis}
  \end{tikzpicture}
  \caption{}
  \label{fig:throughput:boxplot}
  ]]
  end

Graphs.histogram = function(labels, file)
  return [[
  \begin{tikzpicture}
  \begin{axis}[
  width=\textwidth,
  height=0.5\textwidth,
  xlabel={]] .. labels.x .. [[},
  ylabel={]] .. labels.y .. [[},
  ]
  \addplot[ybar,fill=blue,draw=none]table[col sep=comma]{]] .. file .. [[};
  \end{axis}
  \end{tikzpicture}
  \caption{latency histogram}
  \label{fig:latency}
  ]]
  end

return Graphs
