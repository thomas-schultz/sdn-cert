local log_file = nil

function get_timestamp()
  local time = os.date("*t")
  local timestamp = time.year .. "/" .. time.month .. "/" .. time.day .. " - " .. string.format("%.2d:%.2d:%.2d", time.hour, time.min, time.sec)
  return timestamp
end

function init_logger(file)
  log_file = io.open(file, "a")
  log("Started")
end

function finalize_logger()
  log("Finished\n")
  log_file:close()
end

local function logger_log(type, ...)
   log_file:write(get_timestamp() ..  ": ")
   log_file:write(type, ...)
   log_file:write("\n")
   log_file:flush ()
end

local function logger_printlog(type, ...)
   logger_log(type, ...)
   show(...)
end

function show(...)
  print(...)
end

function showIndent(...)
  print("  " .. (...))
end

function log(...)
  logger_log("LOG     ", ...)
end

function printlog(...)
   log(...)
   show(...)
end

function log_warn(...)
  logger_log("WARNING ", ...)
end

function printlog_warn(...)
  logger_log("WARNING ", ...)
  showIndent(...)
end

function log_err(...)
  logger_log("ERROR   ", ...)
end

function printlog_err(...)
  logger_log("ERROR   ", ...)
  showIndent(...)
end

function log_debug(...)
  if (debug_mode) then logger_log("DEBUG   ", ...) end
end 


