TexDocument = {}
TexDocument.__index = TexDocument

package.path = package.path .. ';src/tex/?.lua'

require "blocks"
require "figure"
require "filecontent"
require "graphs"
require "latex"
require "tabular"
require "text"


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
  self:usePackage("pgfplotstable")
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

function TexDocument:addClearPage(...)
  local clearpage = TexText.create()
  clearpage:add("\\clearpage")
  table.insert(self.content, clearpage)
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

function TexDocument:saveToFile(path, file)
  self.file = file or "texDocument"
  self.path = path or settings:getlocalPath() .. "/" .. global.results
  Setup.createFolder(self.path)
  local reportFile = io.open(path .. "/" .. self.file .. ".tex", "w")
  reportFile:write(self:getTex())
  io.close(reportFile)  
end

function TexDocument:getFile()
  return self.path .. "/" .. self.file
end

function TexDocument:generatePDF(path, file)
  if (not settings:doRunTex()) then
    logger.debug("Skipping pdflatex")
    return
  end
  if (not self.file or not self.path) then self:saveToFile(path, file) end
  logger.print("Saving PDF to " .. self.file .. ".pdf",1)
  local cmd = CommandLine.create("cd " .. self.path)
  cmd:addCommand("pdflatex " .. self.file .. ".tex")
  cmd:addCommand("rm *.aux")
  cmd:addCommand("rm *.log")
  cmd:addCommand("rm *.csv")
  cmd:addCommand("rm *.dat")
  cmd:execute()
end


