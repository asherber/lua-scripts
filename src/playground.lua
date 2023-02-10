function plugindef()    
    return "Lua Playground", "", "Lua Playground"
end

---[[
local json = require 'lunajson.lunajson'
local debuggee = require 'vscode-debuggee'
debuggee.start(json, { redirectPrint = true })
--]]

local mixin = require('library.mixin')

local a = {

}


function get_evpu(val, source_unit)    
    local map = {
        dm = "10000th",
        efix = 
    }
end

local temp = mixin.FCMString()
--temp:SetMeasurement10000th(64, finale.MEASUREMENTUNIT_EVPUS)
-- pass in dm, convert to e
temp.SetMeasurement10000th(temp, 64, finale.MEASUREMENTUNIT_EVPUS)
print(temp.LuaString)