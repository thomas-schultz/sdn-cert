Logger = {}
Logger.__index = Logger

--------------------------------------------------------------------------------
--  logger class
--------------------------------------------------------------------------------

--- Color codes for shell ouuput
Logger.ColorCode = {
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

Logger.noColorCode = {}
setmetatable(Logger.noColorCode, {__index = function () return "" end})

--- Disables colored output.
function Logger.disableColor()
  Logger.ColorCode = {}
  local mt = {__index = function () return "" end}
  setmetatable(Logger.ColorCode, mt)
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

--- Returns a timestamp in various formats. 
function Logger.getTimestamp(format)
  local format = format or "log"
  local time = os.date("*t")
  if (format == "log") then
    return string.format("%.2d/%.2d/%.2d - %.2d:%.2d:%.2d", time.year, time.month, time.day, time.hour, time.min, time.sec) end
  if (format == "file") then
    return string.format("%.2d%.2d%.2d_%.2d%.2d%.2d", time.year, time.month, time.day, time.hour, time.min, time.sec) end
end

--- Initializes the logger.
function Logger.init(file)
  Logger.logFile = io.open(file, "a")
  Logger.log("Started")
  return Logger
end

--- Finalizes the logger.
function Logger.finalize()
  logger.log("Finished\n")
  Logger.logFile:close()
end

--- Add a message to the log. 
function Logger.log(msg, lvl)
  local lvl = (Logger.lvl[lvl] and Logger.lvl[lvl].label) or "INFO"
  Logger.logFile:write(("%s: %-10s %s\n"):format(Logger.getTimestamp(),lvl,msg))
  Logger.logFile:flush ()
end

--- Prints a message with given indention for formating purpose.
function Logger.print(msg, indent, color)
  local msg = msg or ""
  local indent = indent or 0
  local preamble = Logger.ColorCode[color] or Logger.ColorCode.normal
  local delim = Logger.ColorCode.normal
  print(preamble .. string.rep("  ", indent) .. msg .. delim)
end

--- Prints and adds a message.
function Logger.printlog(msg, lvl, color)
   Logger.log(msg, lvl)
   local color = color or (Logger.lvl[lvl] and Logger.lvl[lvl].color) or Logger.ColorCode.normal
   Logger.print(msg, 0, color)
end

--- Prints and adds a warning.
function Logger.warn(msg)
  logger.printlog(msg, "WARN")
end

--- Prints and adds an error.
function Logger.err(msg)
  logger.printlog(msg, "ERR")
end

--- Adds a debug information to the logger.
function Logger.debug(msg)
  if (debugMode and msg) then Logger.log(msg, "DEBUG") end
end 

--- prints a bar to the command line.
function Logger.printBar()
  print(Logger.ColorCode.lyellow .. string.rep("-", 80) .. Logger.ColorCode.normal)
end

return Logger

