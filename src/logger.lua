local logFile = nil

ColorCode = {
  red     = "\27[31m",
  green   = "\27[32m",
  yellow  = "\27[33m",
  blue    = "\27[34m",
  cyan    = "\27[36m",
  gray    = "\27[37m",
  lred    = "\27[91m",
  lgree   = "\27[92m",
  lyellow = "\27[93m",
  lblue   = "\27[94m",
  white   = "\27[97m",
  
  bold        = "\27[1m",
  underlined  = "\27[4m",
  
  normal      = "\27[0m",
}

function get_timestamp()
  local time = os.date("*t")
  local timestamp = time.year .. "/" .. time.month .. "/" .. time.day .. " - " .. string.format("%.2d:%.2d:%.2d", time.hour, time.min, time.sec)
  return timestamp
end

function init_logger(file)
  logFile = io.open(file, "a")
  log("Started")
end

function finalize_logger()
  log("Finished\n")
  logFile:close()
end

local function logger_log(type, msg, color)
   logFile:write(get_timestamp() ..  ": ")
   logFile:write(type, msg)
   logFile:write("\n")
   logFile:flush ()
end

local function logger_printlog(type, msg, color)
   logger_log(type, msg, color)
   show(msg, color)
end

function show(msg, color)
  local msg = msg or ""
  local preamble = ColorCode[color] or ColorCode.normal
  local delim = ColorCode.normal
  print(preamble .. msg .. delim)
end

function showIndent(msg, indent, color)
  indent = indent or 0
  show(string.rep("  ", indent) .. msg, color)
end

function log(msg, color)
  logger_log("LOG     ", msg, color)
end

function printlog(msg, color)
   log(msg, color)
   show(msg, color)
end

function log_warn(msg, color)
  color = color or "yellow"
  logger_log("WARNING ", msg, color)
end

function printlog_warn(msg, color)
  color = color or "yellow"
  logger_log("WARNING ", msg, color)
  showIndent(msg, 1)
end

function log_err(msg, color)
  color = color or "red"
  logger_log("ERROR   ", msg, color)
end

function printlog_err(msg, color)
  color = color or "red"
  logger_log("ERROR   ", msg, color)
  showIndent(msg)
end

function log_debug(msg, color)
  if (debug_mode) then logger_log("DEBUG   ", msg, color) end
end 


