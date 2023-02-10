function plugindef()    
    return "Lua Playground", "", "Lua Playground"
end

---[[
local json = require 'lunajson.lunajson'
local debuggee = require 'vscode-debuggee'
debuggee.start(json, { redirectPrint = true })
--]]

local prefs = {}
prefs["Slurs"] = { carrot = true, banana = 5, apple = "Bob"}
prefs["Fonts"] = {}
prefs["Fonts"]["Expressions"] = { carrot = true, banana = 5, apple = "Bob"}
prefs["Fonts"]["Articulations"] = { carrot = true, banana = 5, apple = "Bob"}
prefs["Fonts"]["Durations"] = {
    { duration = 0, width = 84 }, 
    { duration = 1, width = 100 }, 
    { duration = 84, width = 120 }, 
}

function pairsbykeys (t, f)
	local a = {}
	for n in pairs(t) do table.insert(a, n) end
	table.sort(a, f)
	local i = 0
	local iter = function ()
		i = i + 1
		if a[i] == nil then return nil
		else return a[i], t[a[i]]
		end
	end
	return iter
end

function get_last_key(t)
	local result
	for k, _ in pairsbykeys(t) do result = k end
	return result
end

function get_as_json(t, indent, in_array)
    indent = indent or 0
    local result = {}

    table.insert(result, (in_array and '[' or '{') .. '\n')
    indent = indent + 1
    local spaces = string.rep(" ", indent * 2) 

    local last_key = get_last_key(t)
    for key, val in pairsbykeys(t) do
        local maybe_comma = key ~= last_key and ',' or ''        
        if type(val) == "table" then 
            local val_is_array = val[1] ~= nil

            table.insert(result, string.format('%s%s%s%s%s%s\n',
                spaces,
                in_array and '' or string.format('"%s": ', key),
                get_as_json(val, indent, val_is_array),
                spaces,
                val_is_array and ']' or '}',
                maybe_comma
            ))
        else 
            table.insert(result, string.format('%s%s%s%s\n',
                spaces, 
                in_array and '' or string.format('"%s": ', key),
                type(val) == "string" and string.format('"%s"', val) or tostring(val),
                maybe_comma
            ))
        end
    end

    if indent == 1 then
        table.insert(result, "}")
    end 
    return table.concat(result)
end


print(get_as_json(prefs))