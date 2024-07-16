function plugindef()
    finaleplugin.RequireSelection = false
    finaleplugin.HandlesUndo = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "https://carlvine.com/lua"
    finaleplugin.Copyright = "https://creativecommons.org/licenses/by/4.0/"
    finaleplugin.Version = "0.10"
    finaleplugin.Date = "2024/07/17"
    finaleplugin.MinJWLuaVersion = 0.70
    finaleplugin.Notes = [[
        Make dynamic marks in the selection louder or softer in stages. 
        This functionality is buried within __JWChange__ but is useful 
        enough to bring closer to the surface. 
        This script works similarly but allows jumping up to 9 _levels_ at once. 
        The dynamic range is from __pppppp__ to __ffffff__, though scores using 
        older (non-__SMuFL__) fonts are restricted to the range __pppp__-__ffff__. 

        To repeat the previous level shift without a confirmation dialog 
        hold down [_Shift_] when starting the script. 
    ]]
    return "Dynamic Levels...",
        "Dynamic Levels",
        "Make dynamic marks in the selection louder or softer by stages"
end

local hotkey = { -- customise hotkeys (lowercase only)
    direction  = "z", -- toggle Louder/Softer
    create_new = "e", -- toggle create_new
    show_info  = "q",
}
local config = {
    direction    = 0, -- 0 == "Louder", 1 = "Softer"
    levels       = 1, -- how many "levels" louder or softer
    create_new   = false, -- don't create new dynamics without permission
    timer_id     = 1, -- timer to track selected region changes (always Modeless)
    window_pos_x = false,
    window_pos_y = false,
}
local configuration = require("library.configuration")
local mixin = require("library.mixin")
local expression = require("library.expression")
local utils = require("library.utils")
local library = require("library.general_library")
local script_name = library.calc_script_name()
local name = plugindef():gsub("%.%.%.", "")
local selection
local saved_bounds = {}
local dyn_char = library.is_font_smufl_font() and
    { -- char numbers for SMuFL dynamics (1-14)
        0xe527, 0xe528, 0xe529, 0xe52a, 0xe52b, 0xe520, 0xe52c, -- pppppp -> mp
        0xe52d, 0xe522, 0xe52f, 0xe530, 0xe531, 0xe532, 0xe533, -- mf -> ffffff
    } or
    { -- char numbers for non-SMuFL dynamics (1-10)
         175, 184, 185, 112,  80, -- pppp -> mp
          70, 102, 196, 236, 235  -- mf -> ffff
    }
local function dialog_set_position(dialog)
    if config.window_pos_x and config.window_pos_y then
        dialog:StorePosition()
        dialog:SetRestorePositionOnlyData(config.window_pos_x, config.window_pos_y)
        dialog:RestorePosition()
    end
end

local function dialog_save_position(dialog)
    dialog:StorePosition()
    config.window_pos_x = dialog.StoredX
    config.window_pos_y = dialog.StoredY
    configuration.save_user_settings(script_name, config)
end

local function get_staff_name(staff_num)
    local staff = finale.FCStaff()
    staff:Load(staff_num)
    local str = staff:CreateDisplayAbbreviatedNameString().LuaString
    if not str or str == "" then
        str = "Staff" .. staff_num
    end
    return str
end

local function set_bounds()
    local bounds = { -- primary region selection boundaries
        "StartStaff", "StartMeasure", "StartMeasurePos",
        "EndStaff",   "EndMeasure",   "EndMeasurePos",
    }
    local rgn = finenv.Region()
    for _, property in ipairs(bounds) do
        saved_bounds[property] = rgn[property]
    end
    -- update selection
    selection = "no staff, no selection" -- default
    if not rgn:IsEmpty() then
        selection = get_staff_name(rgn.StartStaff)
        if rgn.EndStaff ~= rgn.StartStaff then
            selection = selection .. "-" .. get_staff_name(rgn.EndStaff)
        end
        selection = selection .. " m." .. rgn.StartMeasure
        if rgn.StartMeasure ~= rgn.EndMeasure then
            selection = selection .. "-" .. rgn.EndMeasure
        end
    end
end

local function create_dynamics_alert(dialog)
    local msg = "The required replacement dynamic doesn't exist in this file. "
        .. "Do you want this script to create "
        .. "additional dynamic expressions as required? "
        .. "(You can change this decision later in the dialog window.)"
    local ui = dialog and dialog:CreateChildUI() or finenv.UI()
    return ui:AlertYesNo(msg, name) == finale.YESRETURN
end

local function create_dynamic_def(expression_text, hidden)
    local cat_def = finale.FCCategoryDef()
    cat_def:Load(1) -- default "DYNAMIC" category
    local finfo = finale.FCFontInfo()
    cat_def:GetMusicFontInfo(finfo)
    finfo.EnigmaStyles = finale["ENIGMASTYLE_" .. (hidden and "HIDDEN" or "PLAIN")]
    local str = finale.FCString()
    str.LuaString = "^fontMus"
        .. finfo:CreateEnigmaString(finale.FCString()).LuaString
        .. expression_text
    local ted = mixin.FCMTextExpressionDef()
    ted:SaveNewTextBlock(str)
        :AssignToCategory(cat_def)
        :SetUseCategoryPos(true)
        :SetUseCategoryFont(true)
        :SaveNew()
    return ted:GetItemNo() -- save new item number
end

local function is_hidden_exp(exp_def)
    local str = exp_def:CreateTextString()
    return str:CreateLastFontInfo().Hidden
end

local function change_dynamics(dialog)
    if finenv.Region():IsEmpty() then
        local ui = dialog and dialog:CreateChildUI() or finenv.UI()
        ui:AlertError("Please select some music\nbefore running this script", name)
        return
    end
    local found = { show = {}, hide = {} } -- collate matched dynamic expressions
    local match_count = { show = 0, hide = 0 }
    local shift = config.levels -- how many dynamic levels to move?
    if config.direction == 1 then shift = -shift end -- softer not louder
    local dyn_len = library.is_font_smufl_font() and 3 or 2 -- dynamic max string length

        -- match all target dynamics from existing expressions
        local function match_dynamics(hidden) -- hidden is true or false
            local mode = hidden and "hide" or "show"
            local exp_defs = mixin.FCMTextExpressionDefs()
            exp_defs:LoadAll()
            for exp_def in each(exp_defs) do
                if exp_def.CategoryID == 1 and hidden == is_hidden_exp(exp_def) then
                    local str = exp_def:CreateTextString()
                    str:TrimEnigmaTags()
                    if str.LuaString:len() <= dyn_len then -- within max dynamic length
                        for i, v in ipairs(dyn_char) do -- check all dynamic glyphs
                            if not found[mode][i] and str.LuaString == utf8.char(v) then
                                found[mode][i] = exp_def.ItemNo -- matched char
                                match_count[mode] = match_count[mode] + 1
                            end
                        end
                    end
                end
                if match_count[mode] >= #dyn_char then break end -- all collected
            end
        end
    match_dynamics(true)
    match_dynamics(false)
    -- scan the selection for dynamics and change them
    finenv.StartNewUndoBlock(string.format("Dynamics %s%d %s",
        (config.direction == 0 and "+" or "-"), config.levels, selection)
    )
    for e in loadallforregion(mixin.FCMExpressions(), finenv.Region()) do
        if expression.is_dynamic(e) then
            local exp_def = e:CreateTextExpressionDef()
            if exp_def then
                local hidden = is_hidden_exp(exp_def)
                local mode = hidden and "hide" or "show"
                local str = exp_def:CreateTextString()
                str:TrimEnigmaTags()
                if str.LuaString:len() <= dyn_len then -- dynamic length
                    for i, v in ipairs(dyn_char) do -- look for matching dynamic
                        local target = math.min(math.max(1, i + shift), #dyn_char)
                        if str.LuaString == utf8.char(v) then -- dynamic match
                            if found[mode][target] then -- replacement exists
                                e:SetID(found[mode][target]):Save()
                            else -- create new dynamic
                                if not config.create_new then -- ask permission
                                    config.create_new = create_dynamics_alert(dialog)
                                end
                                if config.create_new then -- create missing dynamic exp_def
                                    if dialog then -- update checkbox condition
                                        dialog:GetControl("create_new"):SetCheck(1)
                                    end
                                    local t = utf8.char(dyn_char[target])
                                    found[mode][target] = create_dynamic_def(t, hidden)
                                    e:SetID(found[mode][target]):Save()
                                end
                            end
                            break -- all done for this target dynamic
                        end
                    end
                end
            end
        end
    end
    finenv.EndUndoBlock(true)
    finenv.Region():Redraw()
end

local function run_the_dialog()
    local y, m_offset = 0, finenv.UI():IsOnMac() and 3 or 0
    local save = config.levels
    local ctl = {}
    local dialog = mixin.FCXCustomLuaWindow():SetTitle("Dynamics")
        -- local functions
        local function yd(diff) y = y + (diff or 20) end
        local function show_info()
            utils.show_notes_dialog(dialog, "About " .. name, 330, 160)
        end
        local function cstat(horiz, vert, wide, str) -- dialog static text
            return dialog:CreateStatic(horiz, vert):SetWidth(wide):SetText(str)
        end
        local function flip_direction()
            local n = ctl.direction:GetSelectedItem()
            ctl.direction:SetSelectedItem((n + 1) % 2)
        end
        local function key_subs()
            local s = ctl.levels:GetText():lower()
            if s:find("[^1-9]") then
                if     s:find(hotkey.show_info) then show_info()
                elseif s:find(hotkey.direction) then flip_direction()
                elseif s:find(hotkey.create_new) then
                    local c = ctl.create_new
                    c:SetCheck((c:GetCheck() + 1) % 2)
                end
            else
                save = s:sub(-1) -- save last entered char only
            end
            ctl.levels:SetText(save)
        end
        local function on_timer() -- track changes in selected region
            for k, v in pairs(saved_bounds) do
                if finenv.Region()[k] ~= v then -- selection changed
                    set_bounds() -- update selection tracker
                    break -- all done
                end
            end
        end
    ctl.title = cstat(10, y, 120, name:upper())
    yd()
    -- RadioButtonGroup
    local labels = finale.FCStrings()
    labels:CopyFromStringTable{ "Louder", "Softer" }
    ctl.direction = dialog:CreateRadioButtonGroup(0, y + 1, 2)
        :SetText(labels):SetWidth(55):SetSelectedItem(config.direction)
    local softer = ctl.direction:GetItemAt(1) -- 2nd button
    softer:SetTop(y + 24)
    cstat(23, y + 11, 25, "(" .. hotkey.direction .. ")")
    -- levels
    cstat(65, y, 55, "Levels:")
    ctl.levels = dialog:CreateEdit(110, y - m_offset):SetText(config.levels):SetWidth(20)
        :AddHandleCommand(function() key_subs() end)
    yd(21)
    ctl.q = dialog:CreateButton(110, y):SetText("?"):SetWidth(20)
       :AddHandleCommand(function() show_info() end)
    yd(21)
    ctl.create_new = dialog:CreateCheckbox(0, y, "create_new")
        :SetText("Enable creation of new\ndynamic expressions")
        :SetWidth(150):SetCheck(config.create_new and 1 or 0)
        :SetHeight(30)
    -- wrap it up
    dialog:CreateOkButton()    :SetText("Apply")
    dialog:CreateCancelButton():SetText("Close")
    dialog:RegisterInitWindow(function(self)
        self:SetTimer(config.timer_id, 125)
        local bold = ctl.q:CreateFontInfo():SetBold(true)
        ctl.q:SetFont(bold)
        ctl.title:SetFont(bold)
    end)
    dialog_set_position(dialog)
    dialog:RegisterHandleTimer(on_timer)
    dialog:RegisterHandleOkButtonPressed(function()
        config.direction = ctl.direction:GetSelectedItem()
        config.levels = ctl.levels:GetInteger()
        config.create_new = (ctl.create_new:GetCheck() == 1)
        change_dynamics(dialog)
    end)
    dialog:RegisterCloseWindow(function(self)
        self:StopTimer(config.timer_id)
        dialog_save_position(self)
    end)
    dialog:RunModeless()
end

local function dynamic_levels()
    configuration.get_user_settings(script_name, config, true)
    local qim = finenv.QueryInvokedModifierKeys
    local mod_key = qim and (qim(finale.CMDMODKEY_ALT) or qim(finale.CMDMODKEY_SHIFT))
    set_bounds() -- track current selected region
    --
    if mod_key then
        change_dynamics(nil)
    else
        run_the_dialog()
    end
end

dynamic_levels()
