------------------
-- String Tools --
------------------

string.special_chars = {"^", "$", "(", ")", "%", ".", "[", "]", "*", "+", "-", "?" }

string.sanitize = function(str)
  for i=1,#string.special_chars do
    str = string.gsub(str, "%"..string.special_chars[i], "%%"..string.special_chars[i])
    --if (str == string.special_chars[i]) then return "%"..str end
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
    local _str_ = string.sub(str,1, hit-1)
    str = string.sub(str,hit+#find, -1)
    _str = _str .. _str_ .. replace
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
    delim = string.sanitize(delim)
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

return string
