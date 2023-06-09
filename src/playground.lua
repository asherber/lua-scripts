function plugindef()    
    return "Lua Playground", "", "Lua Playground"
end

--[[
local home = os.getenv("HOME") or os.getenv("HOMEDRIVE") .. os.getenv("HOMEPATH")
package.path = home .. "/.vscode/extensions/alexeymelnichuk.lua-mobdebug-0.0.5/lua/?.lua"
    .. ";" .. package.path
local mobdebug = require ("vscode-mobdebug")
mobdebug.start('127.0.0.1', 8172)
--]]



-- insert measure
-- loop through measure number regions
-- increment any start/end number greater than inserted measure

function measure_insert_and_shift_regions()
    local region = finenv.Region()
    local insert_pos = region.StartMeasure
    local insert_count = region:CalcMeasureSpan()

    finale.FCMeasures.Insert(insert_pos, insert_count, true)

    for r in loadall(finale.FCMeasureNumberRegions()) do
        if r.StartMeasure > insert_pos then
            r.StartMeasure = r.StartMeasure + insert_count
            
            local str = finale.FCString()
            r:GetPrefix(str)
            local prefix = str.LuaString
            if prefix == '' then
                r.StartNumber = r.StartNumber + insert_count
            else
                str.LuaString = prefix + insert_count
                r:SetPrefix(str)
            end
        end
        if r.EndMeasure >= insert_pos then
            r.EndMeasure = r.EndMeasure + insert_count
        end
        r:Save()
    end
end

measure_insert_and_shift_regions()