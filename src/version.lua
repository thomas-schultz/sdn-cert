Version = {}
Version.__index = Version

--------------------------------------------------------------------------------
--  Version informtion
--------------------------------------------------------------------------------

Version.data = {
  versionMain = "1",
  versionSub = "0",
  versionPatch = "0",
  buildDate = "2016-02-02"
}

Version.getVersion = function()
  local versionStr = string.format("Version %s.%s.%s, Build %s", Version.data.versionMain, Version.data.versionSub, Version.data.versionPatch, Version.data.buildDate)
  return versionStr
end

return Version
