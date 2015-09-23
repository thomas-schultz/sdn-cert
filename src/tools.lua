function pack(...)
  return { n = select("#", ...), ... }
end


function normalizeKey(key)
  return string.replaceAll(string.lower(key), "_", "")
end

-- see if the file exists
function localfileExists(file)
  if (not file) then return false end
  return absfileExists(settings.config.local_path .. "/" .. file)
end

function absfileExists(file)
  if (not file) then return false end
  local f = io.open(file, "rb")  
  if f then f:close() end
  return f ~= nil
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
  if (msg) then log(msg) end
  finalize_logger()
  if (msg) then os.exit(1)
  else os.exit(0) end
end

-----------
-- Table --
-----------

table.toString = function(t)
  local str = ""
  for key,value in pairs(t) do str = str .. tostring(key) .. "=" .. tostring(value) .. ", " end
  return str
end

table.copy = function(t, _t) 
    local _t = _t or {}
    for k,v in pairs(t) do _t[k] = v end
    return _t
  end

--TODO
table.flatten = function(t, _t)
  local _t = _t or {}
  for k,v in pairs(t) do
    if (type(v) == 'table') then table.flatten(v, _t)
    else _t[k] = v end
  end
  return _t
end

table.deepcopy = function(t)
  local _t = {}
  for k,v in pairs(t) do
    if (type(v) == 'table') then _t[k] = table.deepcopy(v)
    else _t[k] = v end          
  end
  return _t
end


------------
-- String --
------------

string.special_chars = {"^", "$", "(", ")", "%", ".", "[", "]", "*", "+", "-", "?" }

string.sanitize = function(str)
  for i=1,#string.special_chars do
    if (str == string.special_chars[i]) then return "%"..str end
  end
  return str
end

string.trim = function (str)
  return str:match("^%s*(.-)%s*$")
end

string.replace = function (str, find, replace)
  find = string.sanitize(find)
  str,pos = string.gsub(str, find, replace)
  return str
end

string.replaceAll = function (str, find, replace)
  find = string.sanitize(find)
  while (string.find(str, find)) do
    str = string.replace(str, find, replace)
  end
  return str
end


-- Pads str to length len with char from right
string.lpad = function(str, len, char)
    if char == nil then char = ' ' end
    return str .. string.rep(char, len - #str)
end

-- Pads str to length len with char from left
string.lpad = function(str, len, char)
    if char == nil then char = ' ' end
    return str .. string.rep(char, len - #str)
end

-- Pads str to length len with char from right
string.rpad = function(str, len, char)
    if char == nil then char = ' ' end
    return string.rep(char, len - #str) .. str
end

string.split = function (str, delim, maxNb)
    -- Eliminate bad cases...
    if str == nil or delim == nil then
        return { str }
    end
    if string.find(str, delim) == nil then
        return { str }
    end
    if maxNb == nil or maxNb < 1 then
        maxNb = 0    -- No limit
    end    
    local result = {}
    local pat = "(.-)" .. delim .. "()"
    local nb = 0
    local lastPos
    for part, pos in string.gmatch(str, pat) do
        nb = nb + 1
        result[nb] = part
        lastPos = pos
        if nb == maxNb then break end
    end
    -- Handle the last field
    if nb ~= maxNb then
        result[nb + 1] = string.sub(str, lastPos)
    end
    return result
end

string.getKeyValue = function (str, ch_split)
  if (ch_split == nil) then ch_split = global.ch_equal end
  if (not str) then return nil end
  local split = string.find(str, ch_split)
  if split then
    local k = string.trim(string.sub(str, 1, split-1))
    k = string.lower(string.replaceAll(k, "_", ""))
    local v = string.trim(string.sub(str, split+1, -1))
    if (v == "true") then v = true end
    if (v == "false") then v = false end
    return k, v
  end
  return nil
end
