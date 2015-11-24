-------------------
-- General Tools --
-------------------

package.path = package.path .. ';src/tools/?.lua'

require "csv"
require "float"
require "tables"
require "strings"
require "files"


function pack(...)
  return {... }
end

function normalizeKey(key)
  return string.replaceAll(string.lower(key), "_", "")
end


function compareVersion(ver1, ver2)
  if (ver1 == nil or ver2 == nil) then return nil end
  if (ver1 == "unknown" or ver2 == "unknown") then return nil end
  local ver1 = string.match(string.replace(ver1, ".", ""),"%d+")
  local ver2 = string.match(string.replace(ver2, ".", ""),"%d+")
  local v1 = tonumber(string.lpad(ver1, 3, "0"))
  local v2 = tonumber(string.lpad(ver2, 3, "0"))
  if (v1 == nil or v1 == nil) then return nil end
  return v2 - v1
end


function sleep(n)
  os.execute("sleep " .. tonumber(n))
end


function exit(msg)
  if (msg) then logger.log(msg) end
  logger.finalize()
  if (msg) then os.exit(1)
  else os.exit(0) end
end