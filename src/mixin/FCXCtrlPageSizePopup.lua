--  Author: Edward Koltun
--  Date: April 13, 2021
--[[
$module FCXCtrlPageSizePopup

*Extends `FCMCtrlPopup`*

A popup for selecting a defined page size. The dimensions in the current unit are displayed along side each page size in the same way as the Page Format dialog.

## Summary of Modifications
- `SelectionChange` has been overridden with a new event, `PageSizeChange`, to match the specialised functionality.
- Setting and getting is now only performed based on page size.

## Disabled Methods
The following inherited methods have been disabled:
- `Clear`
- `AddString`
- `AddStrings`
- `SetStrings`
- `GetSelectedItem`
- `SetSelectedItem`
- `SetSelectedLast`
- `ItemExists`
- `InsertString`
- `DeleteItem`
- `GetItemText`
- `SetItemText`
- `AddHandleSelectionChange`
- `RemoveHandleSelectionChange`
]] --
local mixin = require("library.mixin")
local mixin_helper = require("library.mixin_helper")
local measurement = require("library.measurement")
local page_size = require("library.page_size")

local class = {Parent = "FCMCtrlPopup", Methods = {}}
local methods = class.Methods
local private = setmetatable({}, {__mode = "k"})

local trigger_page_size_change
local each_last_page_size_change   -- luacheck: ignore

local temp_str = finale.FCString()

-- Disabled methods
class.Disabled = {"Clear", "AddString", "AddStrings", "SetStrings", "GetSelectedItem", "SetSelectedItem", "SetSelectedLast",
    "ItemExists", "InsertString", "DeleteItem", "GetItemText", "SetItemText", "AddHandleSelectionChange", "RemoveHandleSelectionChange"}

local function repopulate(control)
    local unit = mixin_helper.is_instance_of(control:GetParent(), "FCXCustomLuaWindow") and control:GetParent():GetMeasurementUnit() or measurement.get_real_default_unit()

    if private[control].LastUnit == unit then
        return
    end

    local suffix = measurement.get_unit_abbreviation(unit)
    local selection = mixin.FCMCtrlPopup.GetSelectedItem(control)

    -- Use FCMCtrlPopup methods because `GetSelectedString` is needed in `GetSelectedPageSize`
    mixin.FCMCtrlPopup.Clear(control)

    for size, dimensions in page_size.pairs() do
        local str = size .. " ("
        temp_str:SetMeasurement(dimensions.width, unit)
        str = str .. temp_str.LuaString .. suffix .. " x "
        temp_str:SetMeasurement(dimensions.height, unit)
        str = str .. temp_str.LuaString .. suffix .. ")"

        mixin.FCMCtrlPopup.AddString(control, str)
    end

    mixin.FCMCtrlPopup.SetSelectedItem(control, selection)
    private[control].LastUnit = unit
end

--[[
% Init

**[Internal]**

@ self (FCXCtrlPageSizePopup)
]]
function class:Init()
    if private[self] then
        return
    end

    private[self] = {}

    repopulate(self)
end

--[[
% GetSelectedPageSize

**[?Fluid]**

Returns the selected page size.

@ self (FCXCtrlPageSizePopup)
@ [str] (FCString) Optional `FCString` to populate with page size.
: (string | nil) Returned if `str` is omitted. The page size or `nil` if nothing is selected.
]]
function methods:GetSelectedPageSize(str)
    mixin_helper.assert_argument_type(2, str, "FCString", "nil")

    local size = mixin.FCMCtrlPopup.GetSelectedString(self)
    if size then
       size = size:match("(.+) %(")
    end

    if str then
        str.LuaString = size or ""
    else
        return size
    end
end

--[[
% SetSelectedPageSize

**[Fluid]**

Sets the selected page size. Must be a valid page size.

@ self (FCXCtrlPageSizePopup)
@ size (FCString | string) Name of page size (case-sensitive).
]]
function methods:SetSelectedPageSize(size)
    mixin_helper.assert_argument_type(2, size, "string", "FCString")
    
    size = type(size) == "userdata" and size.LuaString or tostring(size)
    mixin_helper.assert(page_size.is_size(size), "'" .. size .. "' is not a valid page size.")

    local index = 0
    for s in page_size.pairs() do
        if size == s then
            if index ~= mixin.FCMCtrlPopup.GetSelectedItem(self) then
                mixin.FCMCtrlPopup.SetSelectedItem(self, index)
                trigger_page_size_change(self)
            end

            return
        end

        index = index + 1
    end
end

--[[
% UpdateMeasurementUnit

**[Fluid] [Internal]**

Checks the parent window's measurement and updates the displayed page dimensions if necessary.

@ self (FCXCtrlPageSizePopup)
]]
function methods:UpdateMeasurementUnit()
    repopulate(self)
end

--[[
% HandlePageSizeChange

**[Callback Template]**

@ control (FCXCtrlPageSizePopup)
@ last_page_size (string) The last page size that was selected. If no page size was previously selected, will be `false`.
]]

--[[
% AddHandlePageSizeChange

**[Fluid]**

Adds a handler for `PageSizeChange` events.
If the selected item is changed by a handler, that same handler will not be called again for that change.

The event will fire in the following cases:
- When the window is created (if an item is selected)
- Change in selected item by user or programatically (inserting an item before or after will not trigger the event)

@ self (FCXCtrlPageSizePopup)
@ callback (function) See `HandlePageSizeChange` for callback signature.
]]

--[[
% RemoveHandlePageSizeChange

**[Fluid]**

Removes a handler added with `AddHandlePageSizeChange`.

@ self (FCXCtrlPageSizePopup)
@ callback (function) Handler to remove.
]]
methods.AddHandlePageSizeChange, methods.RemoveHandlePageSizeChange, trigger_page_size_change, each_last_page_size_change = mixin_helper.create_custom_control_change_event(
    {
        name = "last_page_size",
        get = function(ctrl)
            return mixin.FCXCtrlPageSizePopup.GetSelectedPageSize(ctrl)
        end,
        initial = false,
    }
)

return class
