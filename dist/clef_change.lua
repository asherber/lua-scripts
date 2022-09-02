local __imports = {}
local __import_results = {}

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

__imports["library.client"] = function()
    --[[
    $module Client

    Get information about the current client. For the purposes of Finale Lua, the client is
    the Finale application that's running on someones machine. Therefore, the client has
    details about the user's setup, such as their Finale version, plugin version, and
    operating system.

    One of the main uses of using client details is to check its capabilities. As such,
    the bulk of this library is helper functions to determine what the client supports.
    ]] --
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

    --[[
    % get_raw_finale_version
    Returns a raw Finale version from major, minor, and (optional) build parameters. For 32-bit Finale
    this is the internal major Finale version, not the year.

    @ major (number) Major Finale version
    @ minor (number) Minor Finale version
    @ [build] (number) zero if omitted

    : (number)
    ]]
    function client.get_raw_finale_version(major, minor, build)
        local retval = bit32.bor(bit32.lshift(math.floor(major), 24), bit32.lshift(math.floor(minor), 20))
        if build then
            retval = bit32.bor(retval, math.floor(build))
        end
        return retval
    end

    --[[
    % get_lua_plugin_version
    Returns a number constructed from `finenv.MajorVersion` and `finenv.MinorVersion`. The reason not
    to use `finenv.StringVersion` is that `StringVersion` can contain letters if it is a pre-release
    version.

    : (number)
    ]]
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

    --[[
    % supports

    Checks the client supports a given feature. Returns true if the client
    supports the feature, false otherwise.

    To assert the client must support a feature, use `client.assert_supports`.

    For a list of valid features, see the [`features` table in the codebase](https://github.com/finale-lua/lua-scripts/blob/master/src/library/client.lua#L52).

    @ feature (string) The feature the client should support.
    : (boolean)
    ]]
    function client.supports(feature)
        if features[feature].test == nil then
            error("a test does not exist for feature " .. feature, 2)
        end
        return features[feature].test
    end

    --[[
    % assert_supports

    Asserts that the client supports a given feature. If the client doesn't
    support the feature, this function will throw an friendly error then
    exit the program.

    To simply check if a client supports a feature, use `client.supports`.

    For a list of valid features, see the [`features` table in the codebase](https://github.com/finale-lua/lua-scripts/blob/master/src/library/client.lua#L52).

    @ feature (string) The feature the client should support.
    : (boolean)
    ]]
    function client.assert_supports(feature)
        local error_level = finenv.DebugEnabled and 2 or 0
        if not client.supports(feature) then
            if features[feature].error then
                error(features[feature].error, error_level)
            end
            -- Generic error message
            error("Your Finale version does not support " .. to_human_string(feature), error_level)
        end
        return true
    end

    return client

end

__imports["library.clef"] = function()
    --[[
    $module Clef

    A library of general clef utility functions.
    ]] --
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


    --[[
    % get_cell_clef

    Gets the clef for any cell.

    @ measure (number) The measure number for the cell
    @ staff_number (number) The staff number for the cell
    : (number) The clef for the cell
    ]]
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

    --[[
    % get_default_clef

    Gets the default clef for any staff for a specific region.

    @ first_measure (number) The first measure of the region
    @ last_measure (number) The last measure of the region
    @ staff_number (number) The staff number for the cell
    : (number) The default clef for the staff
    ]]
    function clef.get_default_clef(first_measure, last_measure, staff_number)
        local staff = finale.FCStaff()
        local cell_clef = clef.get_cell_clef(first_measure - 1, staff_number)
        if cell_clef < 0 then -- failed, so check clef AFTER insertion
            cell_clef = clef.get_cell_clef(last_measure + 1, staff_number)
            if cell_clef < 0 then -- resort to destination staff default clef
                cell_clef = staff:Load(staff_number) and staff.DefaultClef or 0 -- default treble
            end
        end
        return cell_clef
    end

    --[[
    % restore_default_clef

    Restores the default clef for any staff for a specific region.

    @ first_measure (number) The first measure of the region
    @ last_measure (number) The last measure of the region
    @ staff_number (number) The staff number for the cell
    ]]
    function clef.restore_default_clef(first_measure, last_measure, staff_number)
        client.assert_supports("clef_change")

        local default_clef = clef.get_default_clef(first_measure, last_measure, staff_number)

        for measure = first_measure, last_measure do
            local cell = finale.FCCell(measure, staff_number)
            local cell_frame_hold = finale.FCCellFrameHold()
            cell_frame_hold:ConnectCell(cell)
            if cell_frame_hold:Load() then
                cell_frame_hold:MakeCellSingleClef(nil) -- RGPLua v0.60
                cell_frame_hold:SetClefIndex(default_clef)
                cell_frame_hold:Save()
            end
        end
    end

    --[[
    % clef_change

    Inserts a clef change in the selected region.

    @ clef (string) The clef to change to.
    @ region FCMusicRegion The region to change.
    ]]
    function clef.clef_change(clef, region)
        local clef_index = clef_map[clef]
        local staves = finale.FCStaves()
        staves:LoadAll()
        for staff in each(staves) do
            if region:IsStaffIncluded(staff:GetItemNo()) then
                local cell_frame_hold = finale.FCCellFrameHold()

                for cell_measure, cell_staff in eachcell(region) do
                    local cell = finale.FCCell(cell_measure, cell_staff)
                    cell_frame_hold:ConnectCell(cell)
                    if cell_frame_hold:Load() then -- Loads... but only if it can, preventing crashes.
                    end
                    if not region:IsFullMeasureIncluded(cell_measure) then
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
                        if cell_frame_hold.Measure == region:GetStartMeasure() then
                            mid_measure_clef:SetClefIndex(clef_index)
                            mid_measure_clef:SetMeasurePos(region:GetStartMeasurePos())
                            mid_measure_clef:Save()
                        end
                        if mid_measure_clefs then
                            mid_measure_clefs:InsertCellClefChange(mid_measure_clef)
                            mid_measure_clefs:SaveAllAsNew()
                        end

                        local last_clef = cell_frame_hold.ClefIndex
                        local last_clef_added = false

                        for mid_clef in each(mid_measure_clefs) do
                            if region.StartMeasure ~= region.EndMeasure then
                                if (cell_frame_hold.Measure == region.StartMeasure) then
                                    if mid_clef.MeasurePos <= region.StartMeasurePos then
                                        if mid_clef.MeasurePos ~= region.StartMeasurePos then
                                            last_clef = mid_clef.ClefIndex
                                        end
                                        new_mid_measure_clefs:InsertCellClefChange(mid_clef)
                                        new_mid_measure_clefs:SaveAllAsNew()
                                    end
                                end
                                if (cell_frame_hold.Measure == region.EndMeasure) then
                                    if mid_clef.MeasurePos <= region.EndMeasurePos then
                                        last_clef = mid_clef.ClefIndex
                                        cell_frame_hold:SetClefIndex(clef_index)
                                        cell_frame_hold:Save()
                                        if mid_clef.MeasurePos == 0 then
                                            mid_clef:SetClefIndex(clef_index)
                                            new_mid_measure_clefs:InsertCellClefChange(mid_clef)
                                            new_mid_measure_clefs:SaveAllAsNew()
                                        end
                                    else
                                        if not last_clef_added then
                                            mid_measure_clef:SetClefIndex(clef_index)
                                            mid_measure_clef:SetMeasurePos(0)
                                            mid_measure_clef:Save()
                                            new_mid_measure_clefs:InsertCellClefChange(mid_measure_clef)
                                            mid_measure_clef:SetClefIndex(last_clef)
                                            mid_measure_clef:SetMeasurePos(region.EndMeasurePos)
                                            mid_measure_clef:Save()
                                            new_mid_measure_clefs:InsertCellClefChange(mid_measure_clef)
                                            new_mid_measure_clefs:SaveAllAsNew()
                                            last_clef_added = true
                                        end
                                        new_mid_measure_clefs:InsertCellClefChange(mid_clef)
                                        new_mid_measure_clefs:SaveAllAsNew()
                                    end
                                end
                            elseif region.StartMeasure == region.EndMeasure then
                                if mid_clef.MeasurePos <= region.StartMeasurePos then
                                    if mid_clef.MeasurePos ~= region.StartMeasurePos then
                                        last_clef = mid_clef.ClefIndex
                                    end
                                    new_mid_measure_clefs:InsertCellClefChange(mid_clef)
                                    new_mid_measure_clefs:SaveAllAsNew()
                                elseif mid_clef.MeasurePos <= region.EndMeasurePos then
                                    last_clef = mid_clef.ClefIndex
                                else
                                    if not last_clef_added then
                                        mid_measure_clef:SetClefIndex(last_clef)
                                        mid_measure_clef:SetMeasurePos(region.EndMeasurePos)
                                        mid_measure_clef:Save()
                                        new_mid_measure_clefs:InsertCellClefChange(mid_measure_clef)
                                        new_mid_measure_clefs:SaveAllAsNew()
                                        last_clef_added = true
                                    end
                                    new_mid_measure_clefs:InsertCellClefChange(mid_clef)
                                    new_mid_measure_clefs:SaveAllAsNew()
                                end
                            end
                        end
                        if not last_clef_added then
                            mid_measure_clef:SetClefIndex(last_clef)
                            mid_measure_clef:SetMeasurePos(region.EndMeasurePos)
                            mid_measure_clef:Save()
                            new_mid_measure_clefs:InsertCellClefChange(mid_measure_clef)
                            new_mid_measure_clefs:SaveAllAsNew()
                            last_clef_added = true
                        end

                        -- Removes duplicate clefs:
                        for i = new_mid_measure_clefs.Count - 1, 1, -1 do
                            local later_clef_change = new_mid_measure_clefs:GetItemAt(i)
                            local earlier_clef_change = new_mid_measure_clefs:GetItemAt(i - 1)
                            if later_clef_change.MeasurePos < 0 then
                                new_mid_measure_clefs:ClearItemAt(i)
                                new_mid_measure_clefs:SaveAll()
                                goto continue
                            end
                            if earlier_clef_change.ClefIndex == later_clef_change.ClefIndex then
                                new_mid_measure_clefs:ClearItemAt(i)
                                new_mid_measure_clefs:SaveAll()
                            end
                            ::continue::
                        end
                        --
                        cell_frame_hold:SetCellClefChanges(new_mid_measure_clefs)
                        cell_frame_hold:Save()
                    else
                        cell_frame_hold:MakeCellSingleClef(nil) -- RGPLua v0.60
                        cell_frame_hold:SetClefIndex(clef_index)
                        cell_frame_hold:Save()
                    end
                    if not cell_frame_hold:Load() then
                        cell_frame_hold:SaveNew()
                    end

                end
            end
        end
    end

    return clef

end

function plugindef()
    -- This function and the 'finaleplugin' namespace
    -- are both reserved for the plug-in definition.
    finaleplugin.Author = "Jacob Winkler"
    finaleplugin.Copyright = "2022"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "2022-08-30"
--    finale.MinJWLuaVersion = 0.63 -- https://robertgpatterson.com/-fininfo/-rgplua/rgplua.html
    finaleplugin.AuthorEmail = "jacob.winkler@mac.com"
    finaleplugin.AdditionalMenuOptions = [[
    Clef 2: Bass
    Clef 3: Alto
    Clef 4: Tenor
    Clef 5: Tenor (Voice)
    Clef 6: Percussion
    ]]
    finaleplugin.AdditionalUndoText = [[
    Clef 2: Bass
    Clef 3: Alto
    Clef 4: Tenor
    Clef 5: Tenor (Voice)
    Clef 6: Percussion
    ]]
    finaleplugin.AdditionalDescriptions = [[
    Changes the selected region to bass clef
    Changes the selected region to alto clef
    Changes the selected region to tenor clef
    Changes the selected region to tenor voice (treble 8ba) clef
    Changes the selected region to percussion clef
    ]]
    finaleplugin.AdditionalPrefixes = [[
    clef_type = "bass"
    clef_type = "alto"
    clef_type = "tenor"
    clef_type = "tenor_voice"
    clef_type = "percussion"
    ]]
    return "Clef 1: Treble", "Clef 1: Treble", "Changes the selected region to treble clef"
end

clef_type = clef_type or "treble"

local clef = require("library.clef")

local region = finenv.Region()
region:SetCurrentSelection()
clef.clef_change(clef_type, region)