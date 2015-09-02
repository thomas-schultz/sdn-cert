string.special_chars = {"^", "$", "(", ")", "%", ".", "[", "]", "*", "+", "-", "?" }


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

string.sanitize = function (str)
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
    return k, v
  end
  return nil
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

-- prints a bar to the command line
function printBar()
  print("---------------------------------------------------------")
end

function sleep(n)
  os.execute("sleep " .. tonumber(n))
end

function exit(code)
  if code then log("Exit code: " .. code) end
  finalize_logger()
  os.exit(code)
end