TexBlocks = {}
TexBlocks.__index = TexBlocks

TexBlocks.mppsGraph = function(columns, caption, label)
return [[
\begin{tikzpicture}
\begin{axis}[
width=\textwidth,
height=0.5\textwidth,
xlabel={time in [s]},
ylabel={packets in [mpps]},
grid=major,
]
\addlegendentry{tx}
\addplot [color=red,mark=*] table []] .. columns .. [[,col sep=comma] {tx.csv};
\addlegendentry{rx}
\addplot [color=blue,mark=x] table []] .. columns .. [[,col sep=comma] {rx.csv};
\end{axis}
\end{tikzpicture}
\caption{]] .. caption .. [[}
\label{]] .. label .. "}"
end

TexBlocks.throughput = function(labels, min, avg, max, caption, label)
return [[
\begin{tikzpicture}
\begin{axis}[
width=\textwidth,
height=0.8\textwidth,
xlabel={]] .. labels.x .. [[},
ylabel={]] .. labels.y .. [[},
grid=major,
legend style={at={(1.05,0.5)},anchor=north,legend cell align=left}
]
\addlegendentry{max}
\addplot [color=gray,style=loosely dashed, mark=x] table [x index={0}, y index={]] .. max .. [[},col sep=comma] {rx.csv};
\addlegendentry{avg}
\addplot [color=blue,mark=square*] table [x index={0}, y index={]] .. avg .. [[},col sep=comma] {rx.csv};
\addlegendentry{min}
\addplot [color=gray,style=dashed,mark=x] table [x index={0}, y index={]] .. min .. [[},col sep=comma] {rx.csv};
\end{axis}
\end{tikzpicture}
\caption{throughput graph}
\label{fig:throughput}]]
end

TexBlocks.histogram = function(xlabel, ylabel, file, caption, label) return [[
\begin{tikzpicture}
\begin{axis}[
width=\textwidth,
height=0.5\textwidth,
xlabel={]] .. xlabel .. [[},
ylabel={]] .. ylabel .. [[},
]
\addplot[ybar,fill=blue,draw=none]table[col sep=comma]{]] .. file .. [[};
\end{axis}
\end{tikzpicture}
\caption{]] .. caption .. [[}
\label{]] .. label .. "}"
end

return TexBlocks
