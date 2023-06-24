function plugindef()    
    return "Lua Playground", "", "Lua Playground"
end

---[[
local home = os.getenv("HOME") or os.getenv("HOMEDRIVE") .. os.getenv("HOMEPATH")
package.path = home .. "/.vscode/extensions/alexeymelnichuk.lua-mobdebug-0.0.5/lua/?.lua"
    .. ";" .. package.path
local mobdebug = require ("vscode-mobdebug")
mobdebug.start('127.0.0.1', 8172)
--]]



dofile(finenv.RunningLuaFolderPath() .. "measure_hide_empty.lua")