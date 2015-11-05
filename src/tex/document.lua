TexDocument = {}
TexDocument.__index = TexDocument


require "tex/blocks"
require "tex/figure"
require "tex/filecontent"
require "tex/latex"
require "tex/table"
require "tex/text"

function TexDocument.create(class)
  local class = class or "report"
  local self = setmetatable({}, TexDocument)
  self.header = "\\documentclass{" .. class .. "}"
  self.usepackage = {}
  self.content = {}
  
  self:usePackage("color")
  self:usePackage("geometry", "a4paper")
  self:usePackage("fullpage")
  self:usePackage("pgfplots")
  self:usePackage("csvsimple")
  self:usePackage("filecontents")
  return self
end

function TexDocument:usePackage(name, args)
  if (args) then args = "[" .. args .. "]"
  else args = "" end
  local use = "\\usepackage" .. args .. "{" .. name .. "}"
  table.insert(self.usepackage, use)
end

function TexDocument:addElement(obj)
  table.insert(self.content, obj)
end

function TexDocument:addElements(...)
  local args = {...}
  for i,obj in pairs(args) do
    table.insert(self.content, obj)
  end
end

function TexDocument:getTex()
  local tex = self.header .. "\n\n"
  for i=1,#self.usepackage do
    tex = tex .. self.usepackage[i] .. "\n"
  end
  tex = tex .. "\n\\begin{document}\n\n"
  for i=1,#self.content do
    tex = tex .. self.content[i]:getTex() .. "\n\n"
  end
  tex = tex .. "\\end{document}"
  return(tex)
end

function TexDocument:saveToFile(file)
  self.file = file or "texDocument"
  local reportFile = io.open(settings.config.localPath .. "/" .. global.eval .. "/" .. self.file .. ".tex", "w")
  reportFile:write(self:getTex())
  io.close(reportFile)
end

function TexDocument:generatePDF(file)
  if (not self.file) then self:saveToFile(file) end
  logger.print("Saving PDF to " .. self.file .. ".pdf",1)
  local cmd = CommandLine.create("cd " .. settings.config.localPath .. "/" .. global.eval)
  cmd:addCommand("pdflatex " .. self.file .. ".tex")
  cmd:execute()
end

