--  Author: Edward Koltun
--  Date: April 2, 2022
--[[
$module FCMCtrlCheckbox

Summary of modifications:
- Added `CheckChange` custom control event.
]] --
local mixin = require("library.mixin")
local mixin_helper = require("library.mixin_helper")

local props = {}

local trigger_check_change
local each_last_check_change

--[[
% SetCheck

**[Fluid] [Override]**
Ensures that `CheckChange` event is triggered.

@ self (FCMCtrlCheckbox)
@ checked (number)
]]
function props:SetCheck(checked)
    mixin_helper.assert_argument_type(2, checked, "number")

    self:SetCheck_(checked)

    trigger_check_change(self)
end

--[[
% HandleCheckChange

**[Callback Template]**

@ control (FCMCtrlCheckbox) The control that was changed.
@ last_check (string) The previous value of the control's check state..
]]

--[[
% AddHandleChange

**[Fluid]**
Adds a handler for when the value of the control's check state changes.
The even will fire when:
- The window is created (if the check state is not `0`)
- The control is checked/unchecked by the user
- The control's check state is changed programmatically (if the check state is changed within a handler, that *same* handler will not be called again for that change.)

@ self (FCMCtrlCheckbox)
@ callback (function) See `HandleCheckChange` for callback signature.
]]

--[[
% RemoveHandleCheckChange

**[Fluid]**
Removes a handler added with `AddHandleCheckChange`.

@ self (FCMCtrlCheckbox)
@ callback (function)
]]
props.AddHandleCheckChange, props.RemoveHandleCheckChange, trigger_check_change, each_last_check_change =
    mixin_helper.create_custom_control_change_event(
        -- initial could be set to -1 to force the event to fire on InitWindow, but unlike other controls, -1 is not a valid checkstate.
        -- If it becomes necessary to force this event to fire when the window is created, change to -1
        {name = "last_check", get = "GetCheck_", initial = 0})

return props
