function pack(...)
  return {... }
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
-- Float --
-----------

float = {}

float.tonumber = function(float)
  local dot = string.find(float,"%.")
  if (not dot) then return tonumber(float) end
  local N_ = string.sub(float,1,dot-1)
  local _N = string.sub(float,dot+1, -1)
  local N = tonumber(N_.._N)
  if (not N) then return nil end
  for i=1,#_N do
    N = N/10 end
  return N
end

-----------
--  CSV  --
-----------

csv = {}

csv.parseCsv = function(file, separator)
  local separator = separator or ","
  local t = {}
  local data = io.open(file, "r")
  if (not data) then return t end
  while (true) do
    local line = data:read()
    if (line == nil) then break end
    table.insert(t, string.split(line, separator))
  end
  io.close(data)
  return t
end

csv.getStats = function(data, clipBorder)
  clipBorder = clipBorder or false
  local stats = {}
  if (not data[1]) then return stats end
  for j,_ in pairs(data[1]) do
    stats[j] = {}
    stats[j].num = 0
    stats[j].sum = 0
  end
  for i,row in pairs(data) do
    if (not clipBorder or (i>1) and (i<#data)) then
      for j,col in pairs(row) do
        local value = float.tonumber(col)
        if (value) then        
          stats[j].num = stats[j].num + 1
          stats[j].sum = stats[j].sum + value
          stats[j].min, stats[j].max = math.min(stats[j].min or value,value), math.max(stats[j].max or value,value)
          stats[j].avg = stats[j].sum / stats[j].num 
        end
      end
    end
  end
  return stats
end


-----------
-- Table --
-----------

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

table.deepcopy = function(t)
  local _t = {}
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

string.trim = function(str)
  if (type(str) ~= 'string') then return str end
  return str:match("^%s*(.-)%s*$")
end

string.replace = function (str, find, replace)
  find = string.sanitize(find)
  str,pos = string.gsub(str, find, replace)
  return str
end

string.replaceAll = function (str, find, replace)
  local _str = ""
  local hit = string.find(str, find)
  while (hit) do
    local _str_ = string.sub(str,1, hit)
    str = string.sub(str,hit+1, -1)
    _str = _str .. string.replace(_str_, find, replace)
    hit = string.find(str, find)
  end
  _str = _str .. str
  return _str
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
