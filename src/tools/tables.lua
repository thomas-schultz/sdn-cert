-----------------
-- Table Tools --
-----------------

table.toString = function(t)
  local str = ""
  for key,value in pairs(t) do str = str .. tostring(key) .. "=" .. tostring(value) .. ", " end
  return str
end

table.flatten = function(t, _t)
  local _t = _t or {}
  for k,v in pairs(t) do
    if (type(v) == 'table') then table.flatten(v, _t)
    else _t[k] = v end
  end
  return _t
end

table.deepcopy = function(t, _t)
  local _t = _t or {}
  for k,v in pairs(t) do
    if (type(v) == 'table') then _t[k] = table.deepcopy(v)
    else _t[k] = v end          
  end
  return _t
end

table.tostring = function(t, seperator)
  local str = ""
  local seperator = seperator or " "
  for k,v in pairs(t) do
    if (type(v) == 'string') then str = str .. v .. seperator end
    if (type(v) == 'number') then str = str .. tostring(v) .. seperator end
  end
  if (string.len(str) > 0) then str = string.sub(str,1,str:len()-1) end
  return string.trim(str)
end

table.getn = function(t)
  local n = 0
  for k,v in pairs(t) do
    n = n + 1
  end
  return n
end
