-----------------
-- Float Tools --
-----------------

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