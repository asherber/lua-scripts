__imports = __imports or {}
__import_results = __import_results or {}
function require(item)
    if not __imports[item] then
        error("module '" .. item .. "' not found")
    end
    if __import_results[item] == nil then
        __import_results[item] = __imports[item]()
        if __import_results[item] == nil then
            __import_results[item] = true
        end
    end
    return __import_results[item]
end
__imports["library.configuration"] = __imports["library.configuration"] or function()



    local configuration = {}
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
    local strip_leading_trailing_whitespace = function(str)
        return str:match("^%s*(.-)%s*$")
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
                local name = strip_leading_trailing_whitespace(string.sub(line, 1, delimiter_at - 1))
                local val_string = strip_leading_trailing_whitespace(string.sub(line, delimiter_at + 1))
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
__imports["library.clef"] = __imports["library.clef"] or function()

    local clef = {}

    local client = require("library.client")

    local clef_map = {
        treble = 0,
        alto = 1,
        tenor = 2,
        bass = 3,
        perc_old = 4,
        treble_8ba = 5,
        treble_8vb = 5,
        tenor_voice = 5,
        bass_8ba = 6,
        bass_8vb = 6,
        baritone = 7,
        baritone_f = 7,
        french_violin_clef = 8,
        baritone_c = 9,
        mezzo_soprano = 10,
        soprano = 11,
        percussion = 12,
        perc_new = 12,
        treble_8va = 13,
        bass_8va = 14,
        blank = 15,
        tab_sans = 16,
        tab_serif = 17
    }



    function clef.get_cell_clef(measure, staff_number)
        local cell_clef = -1
        local cell = finale.FCCell(measure, staff_number)
        local cell_frame_hold = finale.FCCellFrameHold()

        cell_frame_hold:ConnectCell(cell)
        if cell_frame_hold:Load() then

            if cell_frame_hold.IsClefList then
                cell_clef = cell_frame_hold:CreateFirstCellClefChange().ClefIndex
            else
                cell_clef = cell_frame_hold.ClefIndex
            end
        end
        return cell_clef
    end


    function clef.get_default_clef(first_measure, last_measure, staff_number)
        local staff = finale.FCStaff()
        local cell_clef = clef.get_cell_clef(first_measure - 1, staff_number)
        if cell_clef < 0 then
            cell_clef = clef.get_cell_clef(last_measure + 1, staff_number)
            if cell_clef < 0 then
                cell_clef = staff:Load(staff_number) and staff.DefaultClef or 0
            end
        end
        return cell_clef
    end


    function clef.set_measure_clef(first_measure, last_measure, staff_number, clef_index)
        client.assert_supports("clef_change")

        for measure = first_measure, last_measure do
            local cell = finale.FCCell(measure, staff_number)
            local cell_frame_hold = finale.FCCellFrameHold()
            local clef_change = cell_frame_hold:CreateFirstCellClefChange()
            clef_change:SetClefIndex(clef_index)
            cell_frame_hold:ConnectCell(cell)
            if cell_frame_hold:Load() then
                cell_frame_hold:MakeCellSingleClef(clef_change)
                cell_frame_hold:SetClefIndex(clef_index)
                cell_frame_hold:Save()
            else
                cell_frame_hold:MakeCellSingleClef(clef_change)
                cell_frame_hold:SetClefIndex(clef_index)
                cell_frame_hold:SaveNew()
            end
        end
    end


    function clef.restore_default_clef(first_measure, last_measure, staff_number)
        client.assert_supports("clef_change")

        local default_clef = clef.get_default_clef(first_measure, last_measure, staff_number)

        clef.set_measure_clef(first_measure, last_measure, staff_number, default_clef)


    end


    function clef.process_clefs(mid_clefs)
        local clefs = {}
        local new_mid_clefs = finale.FCCellClefChanges()
        for mid_clef in each(mid_clefs) do
            table.insert(clefs, mid_clef)
        end
        table.sort(clefs, function (k1, k2) return k1.MeasurePos < k2.MeasurePos end)

        for k, mid_clef in ipairs(clefs) do
            new_mid_clefs:InsertCellClefChange(mid_clef)
            new_mid_clefs:SaveAllAsNew()
        end


        for i = new_mid_clefs.Count - 1, 1, -1 do
            local later_clef_change = new_mid_clefs:GetItemAt(i)
            local earlier_clef_change = new_mid_clefs:GetItemAt(i - 1)
            if later_clef_change.MeasurePos < 0 then
                new_mid_clefs:ClearItemAt(i)
                new_mid_clefs:SaveAll()
                goto continue
            end
            if earlier_clef_change.ClefIndex == later_clef_change.ClefIndex then
                new_mid_clefs:ClearItemAt(i)
                new_mid_clefs:SaveAll()
            end
            ::continue::
        end

        return new_mid_clefs
    end


    function clef.clef_change(clef_type, region)
        local clef_index = clef_map[clef_type]
        local cell_frame_hold = finale.FCCellFrameHold()
        local last_clef
        local last_staff = -1

        for cell_measure, cell_staff in eachcell(region) do
            local cell = finale.FCCell(region.EndMeasure, cell_staff)
            if cell_staff ~= last_staff then
                last_clef = cell:CalcClefIndexAt(region.EndMeasurePos)
                last_staff = cell_staff
            end
            cell = finale.FCCell(cell_measure, cell_staff)
            cell_frame_hold:ConnectCell(cell)
            if cell_frame_hold:Load() then
            end

            if  region:IsFullMeasureIncluded(cell_measure) then
                clef.set_measure_clef(cell_measure, cell_measure, cell_staff, clef_index)
                if not region:IsLastEndMeasure() then
                    cell = finale.FCCell(cell_measure + 1, cell_staff)
                    cell_frame_hold:ConnectCell(cell)
                    if cell_frame_hold:Load() then
                        cell_frame_hold:SetClefIndex(last_clef)
                        cell_frame_hold:Save()
                    else
                        cell_frame_hold:SetClefIndex(last_clef)
                        cell_frame_hold:SaveNew()
                    end
                end


            else
                local mid_measure_clefs = cell_frame_hold:CreateCellClefChanges()
                local new_mid_measure_clefs = finale.FCCellClefChanges()
                local mid_measure_clef = finale.FCCellClefChange()

                if not mid_measure_clefs then
                    mid_measure_clefs = finale.FCCellClefChanges()
                    mid_measure_clef:SetClefIndex(cell_frame_hold.ClefIndex)
                    mid_measure_clef:SetMeasurePos(0)
                    mid_measure_clef:Save()
                    mid_measure_clefs:InsertCellClefChange(mid_measure_clef)
                    mid_measure_clefs:SaveAllAsNew()
                end

                if cell_frame_hold.Measure == region.StartMeasure and region.StartMeasure ~= region.EndMeasure then

                    for mid_clef in each(mid_measure_clefs) do
                        if mid_clef.MeasurePos < region.StartMeasurePos then
                            new_mid_measure_clefs:InsertCellClefChange(mid_clef)
                            new_mid_measure_clefs:SaveAllAsNew()
                        end
                    end

                    mid_measure_clef:SetClefIndex(clef_index)
                    mid_measure_clef:SetMeasurePos(region.StartMeasurePos)
                    mid_measure_clef:Save()
                    new_mid_measure_clefs:InsertCellClefChange(mid_measure_clef)
                    new_mid_measure_clefs:SaveAllAsNew()
                end

                if cell_frame_hold.Measure == region.EndMeasure and region.StartMeasure ~= region.EndMeasure then


                    for mid_clef in each(mid_measure_clefs) do
                        if mid_clef.MeasurePos == 0 then
                            mid_clef:SetClefIndex(clef_index)
                            mid_clef:Save()
                            new_mid_measure_clefs:InsertCellClefChange(mid_clef)
                            new_mid_measure_clefs:SaveAllAsNew()
                        elseif mid_clef.MeasurePos > region.EndMeasurePos then
                            new_mid_measure_clefs:InsertCellClefChange(mid_clef)
                            new_mid_measure_clefs:SaveAllAsNew()
                        end
                    end


                    mid_measure_clef:SetClefIndex(last_clef)
                    mid_measure_clef:SetMeasurePos(region.EndMeasurePos)
                    mid_measure_clef:Save()
                    new_mid_measure_clefs:InsertCellClefChange(mid_measure_clef)
                    new_mid_measure_clefs:SaveAllAsNew()
                end

                if cell_frame_hold.Measure == region.StartMeasure and region.StartMeasure == region.EndMeasure then
                    local last_clef = cell:CalcClefIndexAt(region.EndMeasurePos)

                    for mid_clef in each(mid_measure_clefs) do
                        if mid_clef.MeasurePos == 0 then
                            if region.StartMeasurePos == 0 then
                                mid_clef:SetClefIndex(clef_index)
                                mid_clef:Save()
                            end
                            new_mid_measure_clefs:InsertCellClefChange(mid_clef)
                            new_mid_measure_clefs:SaveAllAsNew()
                        elseif mid_clef.MeasurePos < region.StartMeasurePos or
                        mid_clef.MeasurePos > region.EndMeasurePos then
                            new_mid_measure_clefs:InsertCellClefChange(mid_clef)
                            new_mid_measure_clefs:SaveAllAsNew()
                        end
                    end

                    mid_measure_clef:SetClefIndex(clef_index)
                    mid_measure_clef:SetMeasurePos(region.StartMeasurePos)
                    mid_measure_clef:Save()
                    new_mid_measure_clefs:InsertCellClefChange(mid_measure_clef)
                    new_mid_measure_clefs:SaveAllAsNew()

                    mid_measure_clef:SetClefIndex(last_clef)
                    mid_measure_clef:SetMeasurePos(region.EndMeasurePos)
                    mid_measure_clef:Save()
                    new_mid_measure_clefs:InsertCellClefChange(mid_measure_clef)
                    new_mid_measure_clefs:SaveAllAsNew()
                end

                new_mid_measure_clefs = clef.process_clefs(new_mid_measure_clefs)

                if cell_frame_hold:Load() then
                    cell_frame_hold:SetCellClefChanges(new_mid_measure_clefs)
                    cell_frame_hold:Save()
                else
                    cell_frame_hold:SetCellClefChanges(new_mid_measure_clefs)
                    cell_frame_hold:SaveNew()
                end
            end
        end
    end

    return clef
end
__imports["library.layer"] = __imports["library.layer"] or function()

    local layer = {}


    function layer.copy(region, source_layer, destination_layer, clone_articulations)
        local start = region.StartMeasure
        local stop = region.EndMeasure
        local sysstaves = finale.FCSystemStaves()
        sysstaves:LoadAllForRegion(region)
        source_layer = source_layer - 1
        destination_layer = destination_layer - 1
        for sysstaff in each(sysstaves) do
            staffNum = sysstaff.Staff
            local noteentry_source_layer = finale.FCNoteEntryLayer(source_layer, staffNum, start, stop)
            noteentry_source_layer:SetUseVisibleLayer(false)
            noteentry_source_layer:Load()
            local noteentry_destination_layer = noteentry_source_layer:CreateCloneEntries(
                destination_layer, staffNum, start)
            noteentry_destination_layer:Save()
            noteentry_destination_layer:CloneTuplets(noteentry_source_layer)

            if clone_articulations and noteentry_source_layer.Count == noteentry_destination_layer.Count then
                for index = 0, noteentry_destination_layer.Count - 1 do
                    local source_entry = noteentry_source_layer:GetItemAt(index)
                    local destination_entry = noteentry_destination_layer:GetItemAt(index)
                    local source_artics = source_entry:CreateArticulations()
                    for articulation in each (source_artics) do
                        articulation:SetNoteEntry(destination_entry)
                        articulation:SaveNew()
                    end
                end
            end
            noteentry_destination_layer:Save()
        end
    end


    function layer.clear(region, layer_to_clear)
        layer_to_clear = layer_to_clear - 1
        local start = region.StartMeasure
        local stop = region.EndMeasure
        local sysstaves = finale.FCSystemStaves()
        sysstaves:LoadAllForRegion(region)
        for sysstaff in each(sysstaves) do
            staffNum = sysstaff.Staff
            local  noteentry_layer = finale.FCNoteEntryLayer(layer_to_clear, staffNum, start, stop)
            noteentry_layer:SetUseVisibleLayer(false)
            noteentry_layer:Load()
            noteentry_layer:ClearAllEntries()
        end
    end


    function layer.swap(region, swap_a, swap_b)

        swap_a = swap_a - 1
        swap_b = swap_b - 1
        for measure, staff_number in eachcell(region) do
            local cell_frame_hold = finale.FCCellFrameHold()
            cell_frame_hold:ConnectCell(finale.FCCell(measure, staff_number))
            local loaded = cell_frame_hold:Load()
            local cell_clef_changes = loaded and cell_frame_hold.IsClefList and cell_frame_hold:CreateCellClefChanges() or nil
            local  noteentry_layer_one = finale.FCNoteEntryLayer(swap_a, staff_number, measure, measure)
            noteentry_layer_one:SetUseVisibleLayer(false)
            noteentry_layer_one:Load()
            noteentry_layer_one.LayerIndex = swap_b

            local  noteentry_layer_two = finale.FCNoteEntryLayer(swap_b, staff_number, measure, measure)
            noteentry_layer_two:SetUseVisibleLayer(false)
            noteentry_layer_two:Load()
            noteentry_layer_two.LayerIndex = swap_a
            noteentry_layer_one:Save()
            noteentry_layer_two:Save()
            if loaded then
                local new_cell_frame_hold = finale.FCCellFrameHold()
                new_cell_frame_hold:ConnectCell(finale.FCCell(measure, staff_number))
                if new_cell_frame_hold:Load() then
                    if cell_frame_hold.IsClefList then
                        if new_cell_frame_hold.SetCellClefChanges then
                            new_cell_frame_hold:SetCellClefChanges(cell_clef_changes)
                        end

                    else
                        new_cell_frame_hold.ClefIndex = cell_frame_hold.ClefIndex
                    end
                    new_cell_frame_hold:Save()
                end
            end
        end
    end



    function layer.max_layers()
        return finale.FCLayerPrefs.GetMaxLayers and finale.FCLayerPrefs.GetMaxLayers() or 4
    end

    return layer
end
function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "http://carlvine.com/lua/"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "v0.70"
    finaleplugin.Date = "2023/01/30"
    finaleplugin.Notes = [[
        This script is keyboard-centred requiring minimal mouse action.
        It takes music from a nominated layer in the selected staff and creates a "Cue" version on another staff.
        The cue copy is reduced in size and muted, and can duplicate nominated markings from the original.
        It is shifted to the chosen layer with a whole-note rest placed in the original layer.
        Your choices are saved in the User preferences folder after each script execution.
        This script requires an expression category called "Cue Names".
        Under RGPLua (v0.58+) the category is created automatically if needed.
        Under JWLua, before running the script you must create an Expression Category called
        "Cue Names" containing at least one text expression.
        ]]
    return "Cue Notes Create...", "Cue Notes Create", "Copy as cue notes to another staff"
end
local config = {
    copy_articulations  =   false,
    copy_expressions    =   false,
    copy_smartshapes    =   false,
    copy_slurs          =   true,
    copy_clef           =   false,
    copy_lyrics         =   false,
    mute_cuenotes       =   true,
    cuenote_percent     =   70,
    source_layer        =   1,
    cuenote_layer       =   3,
    rest_layer          =   1,
    freeze_up_down      =   0,

    cue_category_name   =   "Cue Names",
    cue_font_smaller    =   1,
}
local configuration = require("library.configuration")
local clef = require("library.clef")
local layer = require("library.layer")
configuration.get_user_settings("cue_notes_create", config, true)
function show_error(error_code)
    local errors = {
        only_one_staff = "Please select just one staff\n as the source for the new cue",
        empty_region = "Please select a region\nwith some notes in it!",
        no_notes_in_source_layer = "The music selected contains\nno notes in layer " .. config.source_layer,
        first_make_expression_category = "You must first create a new Text Expression Category called \""..config.cue_category_name.."\" containing at least one entry",
    }
    local msg = errors[error_code] or "Unknown error condition"
    finenv.UI():AlertNeutral("script: " .. plugindef(), msg)
    return -1
end
function dont_overwrite_existing_music()
    local alert = finenv.UI():AlertOkCancel("script: " .. plugindef(), "Overwrite existing music?")
    return (alert ~= finale.OKRETURN)
end
function region_contains_notes(region, layer_number)
    for entry in eachentry(region, layer_number) do
        if entry.Count > 0 then
            return true
        end
    end
    return false
end
function new_cue_name(source_staff)
    local dialog = finale.FCCustomWindow()
    local str = finale.FCString()
    str.LuaString = plugindef()
    dialog:SetTitle(str)
    str.LuaString = "New cue name:"
    dialog:CreateStatic(0, 20):SetText(str)
    local the_name = dialog:CreateEdit(0, 40)
    the_name:SetWidth(200)

    local staff = finale.FCStaff()
    staff:Load(source_staff)
    the_name:SetText(staff:CreateDisplayFullNameString())
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    local ok = (dialog:ExecuteModal(nil) == finale.EXECMODAL_OK)
    the_name:GetText(str)
    return ok, str.LuaString
end
function choose_name_index(name_list)
    local dialog = finale.FCCustomWindow()
    local str = finale.FCString()
    str.LuaString = plugindef()
    dialog:SetTitle(str)
    str.LuaString = "Select cue name:"
    dialog:CreateStatic(0, 20):SetText(str)
    local staff_list = dialog:CreateListBox(0, 40)
    staff_list:SetWidth(200)

    str.LuaString = "*** new name ***"
    staff_list:AddString(str)

    for _, v in ipairs(name_list) do
        str.LuaString = v[1]
        staff_list:AddString(str)
    end
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    local ok = (dialog:ExecuteModal(nil) == finale.EXECMODAL_OK)
    return ok, staff_list:GetSelectedItem()

end
function create_new_expression(exp_name, category_number)
    local cat_def = finale.FCCategoryDef()
    cat_def:Load(category_number)
    local tfi = cat_def:CreateTextFontInfo()
    local str = finale.FCString()
    str.LuaString = "^fontTxt"
        .. tfi:CreateEnigmaString(finale.FCString()).LuaString
        .. exp_name
    local ted = finale.FCTextExpressionDef()
    ted:SaveNewTextBlock(str)
    ted:AssignToCategory(cat_def)
    ted:SetUseCategoryPos(true)
    ted:SetUseCategoryFont(true)
    ted:SaveNew()
    return ted:GetItemNo()
end
function choose_destination_staff(source_staff)
    local staff_list = {}
    local rgn = finenv.Region()

    local original_slot = rgn.StartSlot
    rgn:SetFullMeasureStack()
    local staff = finale.FCStaff()
    for slot = rgn.StartSlot, rgn.EndSlot do
        local staff_number = rgn:CalcStaffNumber(slot)
        if staff_number ~= source_staff then
            staff:Load(staff_number)
            table.insert(staff_list, { staff_number, staff:CreateDisplayFullNameString().LuaString } )
        end
    end
    rgn.StartSlot = original_slot
    rgn.EndSlot = original_slot

    local x_grid = { 210, 310, 360 }
    local y_step = 19
    local mac_offset = finenv.UI():IsOnMac() and 3 or 0
    local user_checks = {
        "copy_articulations",  "copy_expressions",  "copy_smartshapes",
        "copy_slurs",          "copy_clef",         "copy_lyrics",
        "mute_cuenotes",       "cuenote_percent",   "source_layer",   "cuenote_layer",

    }
    local integer_options = {
        cuenote_percent = true,
        source_layer = true,
        cuenote_layer = true
    }
    local user_selections = {}
    local str = finale.FCString()
    local dialog = finale.FCCustomLuaWindow()
    str.LuaString = plugindef()
    dialog:SetTitle(str)
    local static = dialog:CreateStatic(0, 0)
    str.LuaString = "Select destination staff:"
    static:SetText(str)
    static:SetWidth(200)
    local list_box = dialog:CreateListBox(0, y_step)
    list_box:SetWidth(200)
    for _, v in ipairs(staff_list) do
        str.LuaString = v[2]
        list_box:AddString(str)
    end

    str.LuaString = "Cue Options:"
    dialog:CreateStatic(x_grid[1], 0):SetText(str)
    for i, v in ipairs(user_checks) do
        str.LuaString = string.gsub(v, '_', ' ')
        local y = y_step * i
        if integer_options[v] then
            str.LuaString = str.LuaString .. ":"
            dialog:CreateStatic(x_grid[1], y):SetText(str)
            user_selections[v] = dialog:CreateEdit(x_grid[2], y - mac_offset)
            user_selections[v]:SetInteger(config[v])
            user_selections[v]:SetWidth(50)
        else
            user_selections[v] = dialog:CreateCheckbox(x_grid[1], y)
            user_selections[v]:SetText(str)
            user_selections[v]:SetWidth(120)
            local checked = config[v] and 1 or 0
            user_selections[v]:SetCheck(checked)
        end
    end

    local stem_direction_popup = dialog:CreatePopup(x_grid[1], ((#user_checks + 1) * y_step + 5))
    str.LuaString = "Stems: normal"
    stem_direction_popup:AddString(str)
    str.LuaString = "Stems: freeze up"
    stem_direction_popup:AddString(str)
    str.LuaString = "Stems: freeze down"
    stem_direction_popup:AddString(str)
    stem_direction_popup:SetWidth(160)
    stem_direction_popup:SetSelectedItem(config.freeze_up_down)

    local clear_button = dialog:CreateButton(x_grid[3], y_step * 2)
    str.LuaString = "Clear All"
    clear_button:SetWidth(80)
    clear_button:SetText(str)
    dialog:RegisterHandleControlEvent ( clear_button,
        function()
            for _, v in ipairs(user_checks) do
                if not integer_options[v] then
                    user_selections[v]:SetCheck(0)
                end
            end
            list_box:SetKeyboardFocus()
        end
    )

    local set_button = dialog:CreateButton(x_grid[3], y_step * 4)
    str.LuaString = "Set All"
    set_button:SetWidth(80)
    set_button:SetText(str)
    dialog:RegisterHandleControlEvent ( set_button,
        function()
            for _, v in ipairs(user_checks) do
                if not integer_options[v] then
                    user_selections[v]:SetCheck(1)
                end
            end
            list_box:SetKeyboardFocus()
        end
    )

    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    local ok = (dialog:ExecuteModal(nil) == finale.EXECMODAL_OK)
    local selected_item = list_box:GetSelectedItem()
    local chosen_staff_number = staff_list[selected_item + 1][1]
    if ok then
        local max = layer.max_layers()
        for i, v in ipairs(user_checks) do
            if integer_options[v] then
                config[v] = user_selections[v]:GetInteger()
                if string.find(v, "layer") and (config[v] < 1 or config[v] > max) then
                    config[v] = (v == "source_layer") and 1 or max
                end
            else
                config[v] = (user_selections[v]:GetCheck() == 1)
            end
        end
        if config.source_layer ~= config.cuenote_layer then
            config.rest_layer = config.source_layer
        else
            config.rest_layer = (config.source_layer % max) + 1
        end
        config.freeze_up_down = stem_direction_popup:GetSelectedItem()
    end
    return ok, chosen_staff_number
end
function fix_text_expressions(region)
    local expressions = finale.FCExpressions()
    expressions:LoadAllForRegion(region)
    for expression in eachbackwards(expressions) do
        if expression.StaffGroupID == 0 then
            if config.copy_expressions then
                expression.LayerAssignment = config.cuenote_layer
                expression.ScaleWithEntry = true
                expression:Save()
            else
                expression:DeleteData()
            end
        end
    end
end
function copy_to_destination(source_region, destination_staff)
    local destination_region = finale.FCMusicRegion()
    destination_region:SetRegion(source_region)
    destination_region:CopyMusic()
    destination_region.StartStaff = destination_staff
    destination_region.EndStaff = destination_staff
    if region_contains_notes(destination_region, 0) and dont_overwrite_existing_music() then
        destination_region:ReleaseMusic()
        return false
    elseif not region_contains_notes(source_region, config.source_layer) then
        destination_region:ReleaseMusic()
        show_error("no_notes_in_source_layer")
        return false
    end

    destination_region:PasteMusic()
    destination_region:ReleaseMusic()
    for layer_number = 1, layer.max_layers() do
        if layer_number ~= config.source_layer then
            layer.clear(destination_region, layer_number)
        end
    end

    for entry in eachentrysaved(destination_region) do
        if entry:IsNote() and config.mute_cuenotes then
            entry.Playback = false
        end
        entry:SetNoteDetailFlag(true)
        local entry_mod = finale.FCEntryAlterMod()
        entry_mod:SetNoteEntry(entry)
        entry_mod:SetResize(config.cuenote_percent)
        entry_mod:Save()
        if entry.ArticulationFlag and not config.copy_articulations then
            for articulation in each(entry:CreateArticulations()) do
                articulation:DeleteData()
            end
            entry.ArticulationFlag = false
        end
        if entry.LyricFlag and not config.copy_lyrics then
            local lyrics = { finale.FCChorusSyllable(), finale.FCSectionSyllable(), finale.FCVerseSyllable() }
            for _, v in ipairs(lyrics) do
                v:SetNoteEntry(entry)
                while v:LoadFirst() do
                    v:DeleteData()
                end
            end
        end
        if config.freeze_up_down > 0 then
            entry.FreezeStem = true
            entry.StemUp = (config.freeze_up_down == 1)
        else
            entry.FreezeStem = false
        end
    end

    layer.swap(destination_region, config.source_layer, config.cuenote_layer)
    if not config.copy_clef then
        clef.restore_default_clef(destination_region.StartMeasure, destination_region.EndMeasure, destination_staff)
    end

    fix_text_expressions(destination_region)

    if not config.copy_smartshapes or not config.copy_slurs then
        local marks = finale.FCSmartShapeMeasureMarks()
        marks:LoadAllForRegion(destination_region, true)
        for m in each(marks) do
            local shape = m:CreateSmartShape()
            if (shape:IsSlur() and not config.copy_slurs) or (not shape:IsSlur() and not config.copy_smartshapes) then
                shape:DeleteData()
            end
        end
    end

    for measure = destination_region.StartMeasure, destination_region.EndMeasure do
        local notecell = finale.FCNoteEntryCell(measure, destination_staff)
        notecell:Load()
        local whole_note = notecell:AppendEntriesInLayer(config.rest_layer, 1)
        if whole_note then
            whole_note.Duration = finale.WHOLE_NOTE
            whole_note.Legality = true
            whole_note:MakeRest()
            notecell:Save()
        end
    end
    return true
end
function new_expression_category(new_name)
    local ok = false
    local category_id = 0
    if not finenv.IsRGPLua then
        return ok, category_id
    end
    local new_category = finale.FCCategoryDef()
    new_category:Load(finale.DEFAULTCATID_TECHNIQUETEXT)
    local str = finale.FCString()
    str.LuaString = new_name
    new_category:SetName(str)
    new_category:SetVerticalAlignmentPoint(finale.ALIGNVERT_STAFF_REFERENCE_LINE)
    new_category:SetVerticalBaselineOffset(30)
    new_category:SetHorizontalAlignmentPoint(finale.ALIGNHORIZ_CLICKPOS)
    new_category:SetHorizontalOffset(-18)

    local tfi = new_category:CreateTextFontInfo()
    tfi.Size = tfi.Size - config.cue_font_smaller
    new_category:SetTextFontInfo(tfi)
    ok = new_category:SaveNewWithType(finale.DEFAULTCATID_TECHNIQUETEXT)
    if ok then
        category_id = new_category:GetID()
    end
    return ok, category_id
end
function assign_expression_to_staff(staff_number, measure_number, measure_position, expression_id)
    local new_expression = finale.FCExpression()
    new_expression:SetStaff(staff_number)
    new_expression:SetVisible(true)
    new_expression:SetMeasurePos(measure_position)
    new_expression:SetScaleWithEntry(false)
    new_expression:SetPartAssignment(true)
    new_expression:SetScoreAssignment(true)
    new_expression:SetID(expression_id)
    new_expression:SaveNewToCell( finale.FCCell(measure_number, staff_number) )
end
function create_cue_notes()
    local cue_names = { }	
    local source_region = finenv.Region()
    local start_staff = source_region.StartStaff

    local ok, cd, expression_defs, cat_ID, expression_ID, name_index, destination_staff, new_expression
    if source_region:CalcStaffSpan() > 1 then
        return show_error("only_one_staff")
    elseif not region_contains_notes(source_region, 0) then
        return show_error("empty_region")
    end
    cd = finale.FCCategoryDef()
    expression_defs = finale.FCTextExpressionDefs()
    expression_defs:LoadAll()

    for text_def in each(expression_defs) do
        cat_ID = text_def.CategoryID
        cd:Load(cat_ID)
        if string.find(cd:CreateName().LuaString, config.cue_category_name) then
            local str = text_def:CreateTextString()
            str:TrimEnigmaTags()

            table.insert(cue_names, { str.LuaString, text_def.ItemNo } )
        end
    end

    if #cue_names == 0 then

        ok, cat_ID = new_expression_category(config.cue_category_name)
        if not ok then
            return show_error("first_make_expression_category")
        end
    end

    ok, name_index = choose_name_index(cue_names)
    if not ok then return end
    if name_index == 0 then	
        ok, new_expression = new_cue_name(start_staff)
        if not ok or new_expression == "" then return end
        expression_ID = create_new_expression(new_expression, cat_ID)
    else
        expression_ID = cue_names[name_index][2]
    end

    ok, destination_staff = choose_destination_staff(start_staff)
    if not ok then return end

    configuration.save_user_settings("cue_notes_create", config)

    if not copy_to_destination(source_region, destination_staff) then
        return
    end

    assign_expression_to_staff(destination_staff, source_region.StartMeasure, 0, expression_ID)

    source_region:SetInDocument()
end
create_cue_notes()
