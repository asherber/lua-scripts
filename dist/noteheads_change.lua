__imports = __imports or {}
__import_results = __import_results or {}
__aaa_original_require_for_deployment__ = __aaa_original_require_for_deployment__ or require
function require(item)
    if not __imports[item] then
        return __aaa_original_require_for_deployment__(item)
    end
    if __import_results[item] == nil then
        __import_results[item] = __imports[item]()
        if __import_results[item] == nil then
            __import_results[item] = true
        end
    end
    return __import_results[item]
end
__imports["library.utils"] = __imports["library.utils"] or function()

    local utils = {}




    function utils.copy_table(t)
        if type(t) == "table" then
            local new = {}
            for k, v in pairs(t) do
                new[utils.copy_table(k)] = utils.copy_table(v)
            end
            setmetatable(new, utils.copy_table(getmetatable(t)))
            return new
        else
            return t
        end
    end

    function utils.table_remove_first(t, value)
        for k = 1, #t do
            if t[k] == value then
                table.remove(t, k)
                return
            end
        end
    end

    function utils.iterate_keys(t)
        local a, b, c = pairs(t)
        return function()
            c = a(b, c)
            return c
        end
    end

    function utils.round(value, places)
        places = places or 0
        local multiplier = 10^places
        return math.floor(value * multiplier + 0.5) / multiplier
    end

    function utils.calc_roman_numeral(num)
        local thousands = {'M','MM','MMM'}
        local hundreds = {'C','CC','CCC','CD','D','DC','DCC','DCCC','CM'}
        local tens = {'X','XX','XXX','XL','L','LX','LXX','LXXX','XC'}	
        local ones = {'I','II','III','IV','V','VI','VII','VIII','IX'}
        local roman_numeral = ''
        if math.floor(num/1000)>0 then roman_numeral = roman_numeral..thousands[math.floor(num/1000)] end
        if math.floor((num%1000)/100)>0 then roman_numeral=roman_numeral..hundreds[math.floor((num%1000)/100)] end
        if math.floor((num%100)/10)>0 then roman_numeral=roman_numeral..tens[math.floor((num%100)/10)] end
        if num%10>0 then roman_numeral = roman_numeral..ones[num%10] end
        return roman_numeral
    end

    function utils.calc_ordinal(num)
        local units = num % 10
        local tens = num % 100
        if units == 1 and tens ~= 11 then
            return num .. "st"
        elseif units == 2 and tens ~= 12 then
            return num .. "nd"
        elseif units == 3 and tens ~= 13 then
            return num .. "rd"
        end
        return num .. "th"
    end

    function utils.calc_alphabet(num)
        local letter = ((num - 1) % 26) + 1
        local n = math.floor((num - 1) / 26)
        return string.char(64 + letter) .. (n > 0 and n or "")
    end

    function utils.clamp(num, minimum, maximum)
        return math.min(math.max(num, minimum), maximum)
    end

    function utils.ltrim(str)
        return string.match(str, "^%s*(.*)")
    end

    function utils.rtrim(str)
        return string.match(str, "(.-)%s*$")
    end

    function utils.trim(str)
        return utils.ltrim(utils.rtrim(str))
    end

    local pcall_wrapper
    local rethrow_placeholder = "tryfunczzz"
    local pcall_line = debug.getinfo(1, "l").currentline + 2
    function utils.call_and_rethrow(levels, tryfunczzz, ...)
        return pcall_wrapper(levels, pcall(function(...) return 1, tryfunczzz(...) end, ...))

    end

    local source = debug.getinfo(1, "S").source
    local source_is_file = source:sub(1, 1) == "@"
    if source_is_file then
        source = source:sub(2)
    end

    pcall_wrapper = function(levels, success, result, ...)
        if not success then
            local file
            local line
            local msg
            file, line, msg = result:match("([a-zA-Z]-:?[^:]+):([0-9]+): (.+)")
            msg = msg or result
            local file_is_truncated = file and file:sub(1, 3) == "..."
            file = file_is_truncated and file:sub(4) or file



            if file
                and line
                and source_is_file
                and (file_is_truncated and source:sub(-1 * file:len()) == file or file == source)
                and tonumber(line) == pcall_line
            then
                local d = debug.getinfo(levels, "n")

                msg = msg:gsub("'" .. rethrow_placeholder .. "'", "'" .. (d.name or "") .. "'")

                if d.namewhat == "method" then
                    local arg = msg:match("^bad argument #(%d+)")
                    if arg then
                        msg = msg:gsub("#" .. arg, "#" .. tostring(tonumber(arg) - 1), 1)
                    end
                end
                error(msg, levels + 1)


            else
                error(result, 0)
            end
        end
        return ...
    end

    function utils.rethrow_placeholder()
        return "'" .. rethrow_placeholder .. "'"
    end
    return utils
end
__imports["library.configuration"] = __imports["library.configuration"] or function()



    local configuration = {}
    local utils = require("library.utils")
    local script_settings_dir = "script_settings"
    local comment_marker = "--"
    local parameter_delimiter = "="
    local path_delimiter = "/"
    local file_exists = function(file_path)
        local f = io.open(file_path, "r")
        if nil ~= f then
            io.close(f)
            return true
        end
        return false
    end
    parse_parameter = function(val_string)
        if "\"" == val_string:sub(1, 1) and "\"" == val_string:sub(#val_string, #val_string) then
            return string.gsub(val_string, "\"(.+)\"", "%1")
        elseif "'" == val_string:sub(1, 1) and "'" == val_string:sub(#val_string, #val_string) then
            return string.gsub(val_string, "'(.+)'", "%1")
        elseif "{" == val_string:sub(1, 1) and "}" == val_string:sub(#val_string, #val_string) then
            return load("return " .. val_string)()
        elseif "true" == val_string then
            return true
        elseif "false" == val_string then
            return false
        end
        return tonumber(val_string)
    end
    local get_parameters_from_file = function(file_path, parameter_list)
        local file_parameters = {}
        if not file_exists(file_path) then
            return false
        end
        for line in io.lines(file_path) do
            local comment_at = string.find(line, comment_marker, 1, true)
            if nil ~= comment_at then
                line = string.sub(line, 1, comment_at - 1)
            end
            local delimiter_at = string.find(line, parameter_delimiter, 1, true)
            if nil ~= delimiter_at then
                local name = utils.trim(string.sub(line, 1, delimiter_at - 1))
                local val_string = utils.trim(string.sub(line, delimiter_at + 1))
                file_parameters[name] = parse_parameter(val_string)
            end
        end
        local function process_table(param_table, param_prefix)
            param_prefix = param_prefix and param_prefix.."." or ""
            for param_name, param_val in pairs(param_table) do
                local file_param_name = param_prefix .. param_name
                local file_param_val = file_parameters[file_param_name]
                if nil ~= file_param_val then
                    param_table[param_name] = file_param_val
                elseif type(param_val) == "table" then
                        process_table(param_val, param_prefix..param_name)
                end
            end
        end
        process_table(parameter_list)
        return true
    end

    function configuration.get_parameters(file_name, parameter_list)
        local path = ""
        if finenv.IsRGPLua then
            path = finenv.RunningLuaFolderPath()
        else
            local str = finale.FCString()
            str:SetRunningLuaFolderPath()
            path = str.LuaString
        end
        local file_path = path .. script_settings_dir .. path_delimiter .. file_name
        return get_parameters_from_file(file_path, parameter_list)
    end


    local calc_preferences_filepath = function(script_name)
        local str = finale.FCString()
        str:SetUserOptionsPath()
        local folder_name = str.LuaString
        if not finenv.IsRGPLua and finenv.UI():IsOnMac() then

            folder_name = os.getenv("HOME") .. folder_name:sub(2)
        end
        if finenv.UI():IsOnWindows() then
            folder_name = folder_name .. path_delimiter .. "FinaleLua"
        end
        local file_path = folder_name .. path_delimiter
        if finenv.UI():IsOnMac() then
            file_path = file_path .. "com.finalelua."
        end
        file_path = file_path .. script_name .. ".settings.txt"
        return file_path, folder_name
    end

    function configuration.save_user_settings(script_name, parameter_list)
        local file_path, folder_path = calc_preferences_filepath(script_name)
        local file = io.open(file_path, "w")
        if not file and finenv.UI():IsOnWindows() then
            os.execute('mkdir "' .. folder_path ..'"')
            file = io.open(file_path, "w")
        end
        if not file then
            return false
        end
        file:write("-- User settings for " .. script_name .. ".lua\n\n")
        for k,v in pairs(parameter_list) do
            if type(v) == "string" then
                v = "\"" .. v .."\""
            else
                v = tostring(v)
            end
            file:write(k, " = ", v, "\n")
        end
        file:close()
        return true
    end

    function configuration.get_user_settings(script_name, parameter_list, create_automatically)
        if create_automatically == nil then create_automatically = true end
        local exists = get_parameters_from_file(calc_preferences_filepath(script_name), parameter_list)
        if not exists and create_automatically then
            configuration.save_user_settings(script_name, parameter_list)
        end
        return exists
    end
    return configuration
end
__imports["library.client"] = __imports["library.client"] or function()

    local client = {}
    local function to_human_string(feature)
        return string.gsub(feature, "_", " ")
    end
    local function requires_later_plugin_version(feature)
        if feature then
            return "This script uses " .. to_human_string(feature) .. "which is only available in a later version of RGP Lua. Please update RGP Lua instead to use this script."
        end
        return "This script requires a later version of RGP Lua. Please update RGP Lua instead to use this script."
    end
    local function requires_rgp_lua(feature)
        if feature then
            return "This script uses " .. to_human_string(feature) .. " which is not available on JW Lua. Please use RGP Lua instead to use this script."
        end
        return "This script requires RGP Lua, the successor of JW Lua. Please use RGP Lua instead to use this script."
    end
    local function requires_plugin_version(version, feature)
        if tonumber(version) <= 0.54 then
            if feature then
                return "This script uses " .. to_human_string(feature) .. " which requires RGP Lua or JW Lua version " .. version ..
                           " or later. Please update your plugin to use this script."
            end
            return "This script requires RGP Lua or JW Lua version " .. version .. " or later. Please update your plugin to use this script."
        end
        if feature then
            return "This script uses " .. to_human_string(feature) .. " which requires RGP Lua version " .. version .. " or later. Please update your plugin to use this script."
        end
        return "This script requires RGP Lua version " .. version .. " or later. Please update your plugin to use this script."
    end
    local function requires_finale_version(version, feature)
        return "This script uses " .. to_human_string(feature) .. ", which is only available on Finale " .. version .. " or later"
    end

    function client.get_raw_finale_version(major, minor, build)
        local retval = bit32.bor(bit32.lshift(math.floor(major), 24), bit32.lshift(math.floor(minor), 20))
        if build then
            retval = bit32.bor(retval, math.floor(build))
        end
        return retval
    end

    function client.get_lua_plugin_version()
        local num_string = tostring(finenv.MajorVersion) .. "." .. tostring(finenv.MinorVersion)
        return tonumber(num_string)
    end
    local features = {
        clef_change = {
            test = client.get_lua_plugin_version() >= 0.60,
            error = requires_plugin_version("0.58", "a clef change"),
        },
        ["FCKeySignature::CalcTotalChromaticSteps"] = {
            test = finenv.IsRGPLua and finale.FCKeySignature.__class.CalcTotalChromaticSteps,
            error = requires_later_plugin_version("a custom key signature"),
        },
        ["FCCategory::SaveWithNewType"] = {
            test = client.get_lua_plugin_version() >= 0.58,
            error = requires_plugin_version("0.58"),
        },
        ["finenv.QueryInvokedModifierKeys"] = {
            test = finenv.IsRGPLua and finenv.QueryInvokedModifierKeys,
            error = requires_later_plugin_version(),
        },
        ["FCCustomLuaWindow::ShowModeless"] = {
            test = finenv.IsRGPLua,
            error = requires_rgp_lua("a modeless dialog")
        },
        ["finenv.RetainLuaState"] = {
            test = finenv.IsRGPLua and finenv.RetainLuaState ~= nil,
            error = requires_later_plugin_version(),
        },
        smufl = {
            test = finenv.RawFinaleVersion >= client.get_raw_finale_version(27, 1),
            error = requires_finale_version("27.1", "a SMUFL font"),
        },
    }

    function client.supports(feature)
        if features[feature].test == nil then
            error("a test does not exist for feature " .. feature, 2)
        end
        return features[feature].test
    end

    function client.assert_supports(feature)
        local error_level = finenv.DebugEnabled and 2 or 0
        if not client.supports(feature) then
            if features[feature].error then
                error(features[feature].error, error_level)
            end

            error("Your Finale version does not support " .. to_human_string(feature), error_level)
        end
        return true
    end
    return client
end
__imports["library.general_library"] = __imports["library.general_library"] or function()

    local library = {}
    local client = require("library.client")

    function library.group_overlaps_region(staff_group, region)
        if region:IsFullDocumentSpan() then
            return true
        end
        local staff_exists = false
        local sys_staves = finale.FCSystemStaves()
        sys_staves:LoadAllForRegion(region)
        for sys_staff in each(sys_staves) do
            if staff_group:ContainsStaff(sys_staff:GetStaff()) then
                staff_exists = true
                break
            end
        end
        if not staff_exists then
            return false
        end
        if (staff_group.StartMeasure > region.EndMeasure) or (staff_group.EndMeasure < region.StartMeasure) then
            return false
        end
        return true
    end

    function library.group_is_contained_in_region(staff_group, region)
        if not region:IsStaffIncluded(staff_group.StartStaff) then
            return false
        end
        if not region:IsStaffIncluded(staff_group.EndStaff) then
            return false
        end
        return true
    end

    function library.staff_group_is_multistaff_instrument(staff_group)
        local multistaff_instruments = finale.FCMultiStaffInstruments()
        multistaff_instruments:LoadAll()
        for inst in each(multistaff_instruments) do
            if inst:ContainsStaff(staff_group.StartStaff) and (inst.GroupID == staff_group:GetItemID()) then
                return true
            end
        end
        return false
    end

    function library.get_selected_region_or_whole_doc()
        local sel_region = finenv.Region()
        if sel_region:IsEmpty() then
            sel_region:SetFullDocument()
        end
        return sel_region
    end

    function library.get_first_cell_on_or_after_page(page_num)
        local curr_page_num = page_num
        local curr_page = finale.FCPage()
        local got1 = false

        while curr_page:Load(curr_page_num) do
            if curr_page:GetFirstSystem() > 0 then
                got1 = true
                break
            end
            curr_page_num = curr_page_num + 1
        end
        if got1 then
            local staff_sys = finale.FCStaffSystem()
            staff_sys:Load(curr_page:GetFirstSystem())
            return finale.FCCell(staff_sys.FirstMeasure, staff_sys.TopStaff)
        end

        local end_region = finale.FCMusicRegion()
        end_region:SetFullDocument()
        return finale.FCCell(end_region.EndMeasure, end_region.EndStaff)
    end

    function library.get_top_left_visible_cell()
        if not finenv.UI():IsPageView() then
            local all_region = finale.FCMusicRegion()
            all_region:SetFullDocument()
            return finale.FCCell(finenv.UI():GetCurrentMeasure(), all_region.StartStaff)
        end
        return library.get_first_cell_on_or_after_page(finenv.UI():GetCurrentPage())
    end

    function library.get_top_left_selected_or_visible_cell()
        local sel_region = finenv.Region()
        if not sel_region:IsEmpty() then
            return finale.FCCell(sel_region.StartMeasure, sel_region.StartStaff)
        end
        return library.get_top_left_visible_cell()
    end

    function library.is_default_measure_number_visible_on_cell(meas_num_region, cell, staff_system, current_is_part)
        local staff = finale.FCCurrentStaffSpec()
        if not staff:LoadForCell(cell, 0) then
            return false
        end
        if meas_num_region:GetShowOnTopStaff() and (cell.Staff == staff_system.TopStaff) then
            return true
        end
        if meas_num_region:GetShowOnBottomStaff() and (cell.Staff == staff_system:CalcBottomStaff()) then
            return true
        end
        if staff.ShowMeasureNumbers then
            return not meas_num_region:GetExcludeOtherStaves(current_is_part)
        end
        return false
    end

    function library.calc_parts_boolean_for_measure_number_region(meas_num_region, for_part)
        if meas_num_region.UseScoreInfoForParts then
            return false
        end
        if nil == for_part then
            return finenv.UI():IsPartView()
        end
        return for_part
    end

    function library.is_default_number_visible_and_left_aligned(meas_num_region, cell, system, current_is_part, is_for_multimeasure_rest)
        current_is_part = library.calc_parts_boolean_for_measure_number_region(meas_num_region, current_is_part)
        if is_for_multimeasure_rest and meas_num_region:GetShowOnMultiMeasureRests(current_is_part) then
            if (finale.MNALIGN_LEFT ~= meas_num_region:GetMultiMeasureAlignment(current_is_part)) then
                return false
            end
        elseif (cell.Measure == system.FirstMeasure) then
            if not meas_num_region:GetShowOnSystemStart() then
                return false
            end
            if (finale.MNALIGN_LEFT ~= meas_num_region:GetStartAlignment(current_is_part)) then
                return false
            end
        else
            if not meas_num_region:GetShowMultiples(current_is_part) then
                return false
            end
            if (finale.MNALIGN_LEFT ~= meas_num_region:GetMultipleAlignment(current_is_part)) then
                return false
            end
        end
        return library.is_default_measure_number_visible_on_cell(meas_num_region, cell, system, current_is_part)
    end

    function library.update_layout(from_page, unfreeze_measures)
        from_page = from_page or 1
        unfreeze_measures = unfreeze_measures or false
        local page = finale.FCPage()
        if page:Load(from_page) then
            page:UpdateLayout(unfreeze_measures)
        end
    end

    function library.get_current_part()
        local part = finale.FCPart(finale.PARTID_CURRENT)
        part:Load(part.ID)
        return part
    end

    function library.get_score()
        local part = finale.FCPart(finale.PARTID_SCORE)
        part:Load(part.ID)
        return part
    end

    function library.get_page_format_prefs()
        local current_part = library.get_current_part()
        local page_format_prefs = finale.FCPageFormatPrefs()
        local success = false
        if current_part:IsScore() then
            success = page_format_prefs:LoadScore()
        else
            success = page_format_prefs:LoadParts()
        end
        return page_format_prefs, success
    end
    local calc_smufl_directory = function(for_user)
        local is_on_windows = finenv.UI():IsOnWindows()
        local do_getenv = function(win_var, mac_var)
            if finenv.UI():IsOnWindows() then
                return win_var and os.getenv(win_var) or ""
            else
                return mac_var and os.getenv(mac_var) or ""
            end
        end
        local smufl_directory = for_user and do_getenv("LOCALAPPDATA", "HOME") or do_getenv("COMMONPROGRAMFILES")
        if not is_on_windows then
            smufl_directory = smufl_directory .. "/Library/Application Support"
        end
        smufl_directory = smufl_directory .. "/SMuFL/Fonts/"
        return smufl_directory
    end

    function library.get_smufl_font_list()
        local font_names = {}
        local add_to_table = function(for_user)
            local smufl_directory = calc_smufl_directory(for_user)
            local get_dirs = function()
                if finenv.UI():IsOnWindows() then
                    return io.popen("dir \"" .. smufl_directory .. "\" /b /ad")
                else
                    return io.popen("ls \"" .. smufl_directory .. "\"")
                end
            end
            local is_font_available = function(dir)
                local fc_dir = finale.FCString()
                fc_dir.LuaString = dir
                return finenv.UI():IsFontAvailable(fc_dir)
            end
            for dir in get_dirs():lines() do
                if not dir:find("%.") then
                    dir = dir:gsub(" Bold", "")
                    dir = dir:gsub(" Italic", "")
                    local fc_dir = finale.FCString()
                    fc_dir.LuaString = dir
                    if font_names[dir] or is_font_available(dir) then
                        font_names[dir] = for_user and "user" or "system"
                    end
                end
            end
        end
        add_to_table(true)
        add_to_table(false)
        return font_names
    end

    function library.get_smufl_metadata_file(font_info)
        if not font_info then
            font_info = finale.FCFontInfo()
            font_info:LoadFontPrefs(finale.FONTPREF_MUSIC)
        end
        local try_prefix = function(prefix, font_info)
            local file_path = prefix .. font_info.Name .. "/" .. font_info.Name .. ".json"
            return io.open(file_path, "r")
        end
        local user_file = try_prefix(calc_smufl_directory(true), font_info)
        if user_file then
            return user_file
        end
        return try_prefix(calc_smufl_directory(false), font_info)
    end

    function library.is_font_smufl_font(font_info)
        if not font_info then
            font_info = finale.FCFontInfo()
            font_info:LoadFontPrefs(finale.FONTPREF_MUSIC)
        end
        if client.supports("smufl") then
            if nil ~= font_info.IsSMuFLFont then
                return font_info.IsSMuFLFont
            end
        end
        local smufl_metadata_file = library.get_smufl_metadata_file(font_info)
        if nil ~= smufl_metadata_file then
            io.close(smufl_metadata_file)
            return true
        end
        return false
    end

    function library.simple_input(title, text)
        local return_value = finale.FCString()
        return_value.LuaString = ""
        local str = finale.FCString()
        local min_width = 160

        function format_ctrl(ctrl, h, w, st)
            ctrl:SetHeight(h)
            ctrl:SetWidth(w)
            str.LuaString = st
            ctrl:SetText(str)
        end

        title_width = string.len(title) * 6 + 54
        if title_width > min_width then
            min_width = title_width
        end
        text_width = string.len(text) * 6
        if text_width > min_width then
            min_width = text_width
        end

        str.LuaString = title
        local dialog = finale.FCCustomLuaWindow()
        dialog:SetTitle(str)
        local descr = dialog:CreateStatic(0, 0)
        format_ctrl(descr, 16, min_width, text)
        local input = dialog:CreateEdit(0, 20)
        format_ctrl(input, 20, min_width, "")
        dialog:CreateOkButton()
        dialog:CreateCancelButton()

        function callback(ctrl)
        end

        dialog:RegisterHandleCommand(callback)

        if dialog:ExecuteModal(nil) == finale.EXECMODAL_OK then
            return_value.LuaString = input:GetText(return_value)

            return return_value.LuaString

        end
    end

    function library.is_finale_object(object)

        return object and type(object) == "userdata" and object.ClassName and object.GetClassID and true or false
    end

    function library.get_parent_class(classname)
        local class = finale[classname]
        if type(class) ~= "table" then return nil end
        if not finenv.IsRGPLua then
            local classt = class.__class
            if classt and classname ~= "__FCBase" then
                local classtp = classt.__parent
                if classtp and type(classtp) == "table" then
                    for k, v in pairs(finale) do
                        if type(v) == "table" then
                            if v.__class and v.__class == classtp then
                                return tostring(k)
                            end
                        end
                    end
                end
            end
        else
            for k, _ in pairs(class.__parent) do
                return tostring(k)
            end
        end
        return nil
    end

    function library.get_class_name(object)
        local class_name = object:ClassName(object)
        if class_name == "__FCCollection" and object.ExecuteModal then
            return object.RegisterHandleCommand and "FCCustomLuaWindow" or "FCCustomWindow"
        elseif class_name == "FCControl" then
            if object.GetCheck then
                return "FCCtrlCheckbox"
            elseif object.GetThumbPosition then
                return "FCCtrlSlider"
            elseif object.AddPage then
                return "FCCtrlSwitcher"
            else
                return "FCCtrlButton"
            end
        elseif class_name == "FCCtrlButton" and object.GetThumbPosition then
            return "FCCtrlSlider"
        end
        return class_name
    end

    function library.system_indent_set_to_prefs(system, page_format_prefs)
        page_format_prefs = page_format_prefs or library.get_page_format_prefs()
        local first_meas = finale.FCMeasure()
        local is_first_system = (system.FirstMeasure == 1)
        if (not is_first_system) and first_meas:Load(system.FirstMeasure) then
            if first_meas.ShowFullNames then
                is_first_system = true
            end
        end
        if is_first_system and page_format_prefs.UseFirstSystemMargins then
            system.LeftMargin = page_format_prefs.FirstSystemLeft
        else
            system.LeftMargin = page_format_prefs.SystemLeft
        end
        return system:Save()
    end

    function library.calc_script_name(include_extension)
        local fc_string = finale.FCString()
        if finenv.RunningLuaFilePath then

            fc_string.LuaString = finenv.RunningLuaFilePath()
        else


            fc_string:SetRunningLuaFilePath()
        end
        local filename_string = finale.FCString()
        fc_string:SplitToPathAndFile(nil, filename_string)
        local retval = filename_string.LuaString
        if not include_extension then
            retval = retval:match("(.+)%..+")
            if not retval or retval == "" then
                retval = filename_string.LuaString
            end
        end
        return retval
    end

    function library.get_default_music_font_name()
        local fontinfo = finale.FCFontInfo()
        local default_music_font_name = finale.FCString()
        if fontinfo:LoadFontPrefs(finale.FONTPREF_MUSIC) then
            fontinfo:GetNameString(default_music_font_name)
            return default_music_font_name.LuaString
        end
    end
    return library
end
__imports["library.notehead"] = __imports["library.notehead"] or function()

    local notehead = {}
    local configuration = require("library.configuration")
    local library = require("library.general_library")
    local config = {
        diamond = {
            quarter = { glyph = 79, size = 110 },
            half  = { glyph = 79, size = 110 },
            whole = { glyph = 79, size = 110, offset = 5 },
            breve = { glyph = 79, size = 110, offset = 14 },
        },
        diamond_guitar = {
            quarter = { glyph = 226, size = 110 },
            half  = { glyph = 79, size = 110 },
            whole = { glyph = 79, size = 110, offset = 5 },
            breve = { glyph = 79, size = 110, offset = 14 },
        },
        x = {
            quarter = { glyph = 192 },
            half  = { glyph = 192 },
            whole = { glyph = 192 },
            breve = { glyph = 192, size = 120 },
        },
        triangle = {



            quarter = { glyph = 209 },
            half  = { glyph = 177 },
            whole = { glyph = 177 },
            breve = { glyph = 177 },
        },
        triangle_down = {
            quarter = { glyph = 224 },
            half  = { glyph = 198 },
            whole = { glyph = 198 },
            breve = { glyph = 198 },
        },
        triangle_up = {
            quarter = { glyph = 209 },
            half  = { glyph = 177 },
            whole = { glyph = 177 },
            breve = { glyph = 177 },
        },
        slash = {
            quarter = { glyph = 243 },
            half  = { glyph = 203 },
            whole = { glyph = 213 },
            breve = { glyph = 213 },
        },
        square = {
            quarter = { glyph = 208 },
            half  = { glyph = 173 },
            whole = { glyph = 194 },
            breve = { glyph = 221 },
        },
        wedge = {
            quarter = { glyph = 108 },
            half  = { glyph = 231 },
            whole = { glyph = 231 },
            breve = { glyph = 231 },
        },
        strikethrough = {
            quarter = { glyph = 191 },
            half  = { glyph = 191 },
            whole = { glyph = 191 },
            breve = { glyph = 191 },
        },
        circled = {
            quarter = { glyph = 76 },
            half  = { glyph = 76 },
            whole = { glyph = 76 },
            breve = { glyph = 76 },
        },
        round = {
            quarter = { glyph = 76 },
            half  = { glyph = 76 },
            whole = { glyph = 191 },
            breve = { glyph = 191 },
        },
        hidden = {
            quarter = { glyph = 202 },
            half  = { glyph = 202 },
            whole = { glyph = 202 },
            breve = { glyph = 202 },
        },
        default = {
            quarter = { glyph = 207 }
        },
    }

    if library.is_font_smufl_font() then
        config = {
            diamond = {
                quarter = { glyph = 0xe0e1, size = 110 },
                half  = { glyph = 0xe0e1, size = 110 },
                whole = { glyph = 0xe0d8, size = 110 },
                breve = { glyph = 0xe0d7, size = 110 },
            },
            diamond_guitar = {
                quarter = { glyph = 0xe0e2, size = 110 },
                half  = { glyph = 0xe0e1, size = 110 },
                whole = { glyph = 0xe0d8, size = 110 },
                breve = { glyph = 0xe0d7, size = 110 },
            },
            x = {
                quarter = { glyph = 0xe0a9 },
                half  = { glyph = 0xe0a8 },
                whole = { glyph = 0xe0a7 },
                breve = { glyph = 0xe0a6 },
            },
            triangle = {



                quarter = { glyph = 0xe0be },
                half  = { glyph = 0xe0bd },
                whole = { glyph = 0xe0bc },
                breve = { glyph = 0xe0bb },
            },
            triangle_down = {
                quarter = { glyph = 0xe0c7 },
                half  = { glyph = 0xe0c6 },
                whole = { glyph = 0xe0c5 },
                breve = { glyph = 0xe0c4 },
            },
            triangle_up = {
                quarter = { glyph = 0xe0be },
                half  = { glyph = 0xe0bd },
                whole = { glyph = 0xe0bc },
                breve = { glyph = 0xe0bb },
            },
            slash = {
                quarter = { glyph = 0xe100 },
                half  = { glyph = 0xe103 },
                whole = { glyph = 0xe102 },
                breve = { glyph = 0xe10a },
            },
            square = {
                quarter = { glyph = 0xe934 },
                half  = { glyph = 0xe935 },
                whole = { glyph = 0xe937 },
                breve = { glyph = 0xe933 },
            },
            wedge = {
                quarter = { glyph = 0xe1c5 },
                half  = { glyph = 0xe1c8, size = 120 },
                whole = { glyph = 0xe1c4, size = 120 },
                breve = { glyph = 0xe1ca, size = 120 },
            },
            strikethrough = {
                quarter = { glyph = 0xe0cf },
                half  = { glyph = 0xe0d1 },
                whole = { glyph = 0xe0d3 },
                breve = { glyph = 0xe0d5 },
            },
            circled = {
                quarter = { glyph = 0xe0e4 },
                half  = { glyph = 0xe0e5 },
                whole = { glyph = 0xe0e6 },
                breve = { glyph = 0xe0e7 },
            },
            round = {
                quarter = { glyph = 0xe113 },
                half  = { glyph = 0xe114 },
                whole = { glyph = 0xe115 },
                breve = { glyph = 0xe112 },
            },
            hidden = {
                quarter = { glyph = 0xe0a5 },
                half  = { glyph = 0xe0a5 },
                whole = { glyph = 0xe0a5 },
                breve = { glyph = 0xe0a5 },
            },
            default = {
                quarter = { glyph = 0xe0a4 }
            },
        }
    end
    configuration.get_parameters("notehead.config.txt", config)

    function notehead.change_shape(note, shape)
        local notehead_mod = finale.FCNoteheadMod()
        notehead_mod:EraseAt(note)
        local notehead_char = config.default.quarter.glyph
        if type(shape) == "number" then
            notehead_char = shape
            shape = "number"
        elseif not config[shape] then
            shape = "default"
        end
        if shape == "default" then
            notehead_mod:ClearChar()
            notehead_mod.Resize = 100
            notehead_mod.HorizontalPos = 0
        else
            local entry = note:GetEntry()
            if not entry then return end
            local duration = entry.Duration
            local offset = 0
            local resize = 100
            if shape ~= "number" then
                local note_type = "quarter"
                if duration >= finale.BREVE then
                    note_type = "breve"
                elseif duration >= finale.WHOLE_NOTE then
                    note_type = "whole"
                elseif duration >= finale.HALF_NOTE then
                    note_type = "half"
                end
                local ref_table = config[shape][note_type]
                if shape == "triangle" and entry:CalcStemUp() then
                    ref_table = config["triangle_down"][note_type]
                end
                if ref_table.glyph then
                    notehead_char = ref_table.glyph
                end
                if ref_table.size then
                    resize = ref_table.size
                end
                if ref_table.offset then
                    offset = ref_table.offset
                end
            end

            notehead_mod.CustomChar = notehead_char
            if resize > 0 and resize ~= 100 then
                notehead_mod.Resize = resize
            end
            if offset ~= 0 then
                notehead_mod.HorizontalPos = (entry:CalcStemUp()) and (-1 * offset) or offset
            end
        end
        notehead_mod:SaveAt(note)
        return notehead_mod
    end
    return notehead
end
function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "http://carlvine.com/lua/"
    finaleplugin.Copyright = "https://creativecommons.org/licenses/by/4.0/"
    finaleplugin.Version = "v0.58"
    finaleplugin.Date = "2022/11/01"
    finaleplugin.MinJWLuaVersion = 0.62
    finaleplugin.AdditionalMenuOptions = [[
        Noteheads Change to Diamond
        Noteheads Change to Diamond (Guitar)
        Noteheads Change to Square
        Noteheads Change to Triangle
        Noteheads Change to Slash
        Noteheads Change to Wedge
        Noteheads Change to Strikethrough
        Noteheads Change to Circled
        Noteheads Change to Round
        Noteheads Change to Hidden
        Noteheads Change to Number...
        Noteheads Revert to Default
     ]]
     finaleplugin.AdditionalUndoText = [[
        Noteheads Change to Diamond
        Noteheads Change to Diamond (Guitar)
        Noteheads Change to Square
        Noteheads Change to Triangle
        Noteheads Change to Slash
        Noteheads Change to Wedge
        Noteheads Change to Strikethrough
        Noteheads Change to Circled
        Noteheads Change to Round
        Noteheads Change to Hidden
        Noteheads Change to Number
        Noteheads Revert to Default
	]]
     finaleplugin.AdditionalDescriptions = [[
        Change all noteheads in the selection to Diamonds
        Change all noteheads in the selection to Diamonds (Guitar - short notes filled)
        Change all noteheads in the selection to Squares
        Change all noteheads in the selection to Triangles
        Change all noteheads in the selection to Slashes
        Change all noteheads in the selection to Wedges
        Change all noteheads in the selection to Strikethrough
        Change all noteheads in the selection to Circled
        Change all noteheads in the selection to Round
        Change all noteheads in the selection to Hidden
        Change all noteheads in the selection to specific number (glyph)
        Return all noteheads in the selection to Default
    ]]
    finaleplugin.AdditionalPrefixes = [[
        new_shape = "diamond"
        new_shape = "diamond_guitar"
        new_shape = "square"
        new_shape = "triangle"
        new_shape = "slash"
        new_shape = "wedge"
        new_shape = "strikethrough"
        new_shape = "circled"
        new_shape = "round"
        new_shape = "hidden"
        new_shape = "number"
        new_shape = "default"
	]]
    finaleplugin.ScriptGroupName = "Noteheads Change"
    finaleplugin.ScriptGroupDescription = "Change all noteheads in the selection to one of eleven chosen shapes (SMuFL compliant)"
    finaleplugin.Notes = [[
        Change all noteheads in the current selection to one of these twelve shapes (SMuFL compliant):
        ```
        X
        Diamond
        Diamond (Guitar)
        Square
        Triangle
        Slash
        Wedge
        Strikethrough
        Circled
        Round
        Hidden
        Number
        Default
        ```
        In SMuFL fonts like Finale Maestro, shapes will match the appropriate duration values.
        Most of the duration-dependent shapes are not available in Finale's old (non-SMuFL) Maestro font.
    ]]
    return "Noteheads Change to X", "Noteheads Change to X", "Change all noteheads in the selection to X-Noteheads (SMuFL compliant)"
end
new_shape = new_shape or "x"
local notehead = require("library.notehead")
function user_chooses_glyph()
    local dlg = finale.FCCustomWindow()
    local x, y = 200, 10
    local y_diff = finenv.UI():IsOnMac() and 3 or 0
    local str = finale.FCString()
    str.LuaString = finaleplugin.ScriptGroupName or plugindef()
    dlg:SetTitle(str)
    str.LuaString = "Enter required character (glyph) number:"
    local static = dlg:CreateStatic(0, y)
    static:SetText(str)
    static:SetWidth(x)
    str.LuaString = "(as simple integer, or hex value like \"0xe0e1\")"
    static = dlg:CreateStatic(0, y + 20)
    static:SetText(str)
    static:SetWidth(x + 100)
    local answer = dlg:CreateEdit(x, y - y_diff)
    str.LuaString = "0xe0e1"
    answer:SetText(str)
    dlg:CreateOkButton()
    dlg:CreateCancelButton()
    local ok = dlg:ExecuteModal(nil)
    answer:GetText(str)
    return ok, tonumber(str.LuaString)
end
function change_notehead()
    local mod_down = finenv.QueryInvokedModifierKeys and (finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_ALT) or finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_SHIFT))
    if mod_down then new_shape = "default" end
    if new_shape == "number" then
        local ok
        ok, new_shape = user_chooses_glyph()
        if ok ~= finale.EXECMODAL_OK then
            return
        end
    end
    for entry in eachentrysaved(finenv.Region()) do
        if entry:IsNote() then
            for note in each(entry) do
                notehead.change_shape(note, new_shape)
            end
        end
    end
end
change_notehead()