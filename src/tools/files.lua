----------------
-- File Tools --
----------------


-- see if the file exists
function localfileExists(file)
  if (not file) then return false end
  local path = settings:getLocalPath() or "."
  return absfileExists(path .. "/" .. file)
end

function absfileExists(file)
  if (not file) then return false end
  local f = io.open(file, "rb")  
  if f then f:close() end
  return f ~= nil
end
