function plugindef()    
    return "_Playground", "", "_Playground"
end

---[[
local home = os.getenv("HOME") or os.getenv("HOMEDRIVE") .. os.getenv("HOMEPATH")
package.path = home .. "/.vscode/extensions/alexeymelnichuk.lua-mobdebug-0.0.5/lua/?.lua"
    .. ";" .. package.path
local mobdebug = require ("vscode-mobdebug")
mobdebug.start('127.0.0.1', 8172)
--]]



dofile(finenv.RunningLuaFolderPath() .. "measure_hide_empty.lua")

--[[
local assigns = finale.FCStaffStyleAssigns()
assigns:LoadAllForItem(5)
for a in each(assigns) do
    print(a.StartMeasure, a.EndMeasure, a.StyleID)
end

local foo = 8
--]]