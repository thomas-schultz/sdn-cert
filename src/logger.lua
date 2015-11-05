Logger = {}
Logger.__index = Logger


ColorCode = {
  red     = "\27[31m",
  green   = "\27[32m",
  yellow  = "\27[33m",
  blue    = "\27[34m",
  cyan    = "\27[36m",
  gray    = "\27[37m",
  lred    = "\27[91m",
  lgreen  = "\27[92m",
  lyellow = "\27[93m",
  lblue   = "\27[94m",
  white   = "\27[97m",
  RED     = "\27[41m",
  
  bold        = "\27[1m",
  underlined  = "\27[4m",
  
  normal      = "\27[0m",
}

noColorCode = {}
setmetatable(noColorCode, {__index = function () return "" end})

function disableColor()
  ColorCode = {}
  local mt = {__index = function () return "" end}
  setmetatable(ColorCode, mt)
end

Logger.logFile = nil
Logger.lvl = {
  ["INFO"] = {
    color = "normal",
    label = "INFO",
    },
  ["DEBUG"] = {
    color = "normal",
    label = "DEBUG",
    },
  ["WARN"] = {
    color = "yellow",
    label = "WARNING",
    },
  ["ERR"] = {
    color = "red",
    label = "ERROR",
    },
  ["FATAL"] = {
    color = "RED",
    label = "FATAL"
    } 
}

function Logger.getTimestamp(format)
  local format = format or "log"
  local time = os.date("*t")
  if (format == "log") then
    return string.format("%.2d/%.2d/%.2d - %.2d:%.2d:%.2d", time.year, time.month, time.day, time.hour, time.min, time.sec) end
  if (format == "file") then
    return string.format("%.2d%.2d%.2d_%.2d%.2d%.2d", time.year, time.month, time.day, time.hour, time.min, time.sec) end
end

function Logger.init(file)
  Logger.logFile = io.open(file, "a")
  Logger.log("Started")
  return Logger
end

function Logger.finalize()
  logger.log("Finished\n")
  Logger.logFile:close()
end

function Logger.log(msg, lvl)
  local lvl = (Logger.lvl[lvl] and Logger.lvl[lvl].label) or "INFO"
  Logger.logFile:write(("%s: %-10s %s\n"):format(Logger.getTimestamp(),lvl,msg))
  Logger.logFile:flush ()
end

function Logger.print(msg, indent, color)
  local msg = msg or ""
  local indent = indent or 0
  local preamble = ColorCode[color] or ColorCode.normal
  local delim = ColorCode.normal
  print(preamble .. string.rep("  ", indent) .. msg .. delim)
end

function Logger.printlog(msg, lvl, color)
   Logger.log(msg, lvl)
   local color = color or (Logger.lvl[lvl] and Logger.lvl[lvl].color) or ColorCode.normal
   Logger.print(msg, 0, color)
end

function Logger.warn(msg)
  logger.log("WARN", msg)
end

function Logger.err(msg)
  logger.log("ERR", msg)
end

function Logger.debug(msg)
  if (debugMode and msg) then Logger.log("DEBUG", msg) end
end 

-- prints a bar to the command line
function Logger.printBar()
  print(ColorCode.lyellow .. string.rep("-", 80) .. ColorCode.normal)
end

return Logger

