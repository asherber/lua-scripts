# FCMCtrlSlider

## Summary of Modifications
- Added `ThumbPositionChange` custom control event *(see note)*.

## Note on `ThumbPositionChange` and `Command` Events
Command events do not fire for `FCCtrlSlider` controls before RGPLua 0.64, so a workaround is used to make the `ThumbPositionChange` events fire.
- If using JW/RGPLua version 0.55 or lower, then the event dispatcher will run with the next Command event for a different control. In these versions the event is unreliable as the user will need to interact with another control for the change in thumb position to be registered.
- If using version 0.56 or later, then the dispatcher will run every 1 second. This is more reliable than in earlier versions but it still will not fire immediately.

## Functions

- [RegisterParent(self, window)](#registerparent)
- [SetThumbPosition(self, position)](#setthumbposition)
- [SetMinValue(self, minvalue)](#setminvalue)
- [SetMaxValue(self, maxvalue)](#setmaxvalue)
- [HandleThumbPositionChange(control, last_position)](#handlethumbpositionchange)
- [AddHandleThumbPositionChange(self, callback)](#addhandlethumbpositionchange)
- [RemoveHandleThumbPositionChange(self, callback)](#removehandlethumbpositionchange)

### RegisterParent

```lua
fcmctrlslider.RegisterParent(self, window)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlSlider.lua#L58)

**[Internal] [Override]**

Override Changes:
- Bootstrap workaround for command events not firing on `FCCtrlSlider` controls

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlSlider` |  |
| `window` | `FCMCustomWindow` |  |

### SetThumbPosition

```lua
fcmctrlslider.SetThumbPosition(self, position)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlSlider.lua#L85)

**[Fluid] [Override]**

Override Changes:
- Ensure that `ThumbPositionChange` event is triggered.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlSlider` |  |
| `position` | `number` |  |

### SetMinValue

```lua
fcmctrlslider.SetMinValue(self, minvalue)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlSlider.lua#L104)

**[Fluid] [Override]**

Override Changes:
- Ensure that `ThumbPositionChange` is triggered.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlSlider` |  |
| `minvalue` | `number` |  |

### SetMaxValue

```lua
fcmctrlslider.SetMaxValue(self, maxvalue)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlSlider.lua#L123)

**[Fluid] [Override]**

Override Changes:
- Ensure that `ThumbPositionChange` event is triggered.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlSlider` |  |
| `maxvalue` | `number` |  |

### HandleThumbPositionChange

```lua
fcmctrlslider.HandleThumbPositionChange(control, last_position)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlSlider.lua#L141)

**[Callback Template]**

| Input | Type | Description |
| ----- | ---- | ----------- |
| `control` | `FCMCtrlSlider` | The slider that was moved. |
| `last_position` | `string` | The previous value of the control's thumb position. |

### AddHandleThumbPositionChange

```lua
fcmctrlslider.AddHandleThumbPositionChange(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlSlider.lua#L160)

**[Fluid]**

Adds a handler for when the slider's thumb position changes.
The even will fire when:
- The window is created
- The slider is moved by the user (see note regarding command events)
- The slider's postion is changed programmatically (if the thumb position is changed within a handler, that *same* handler will not be called again for that change.)

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlSlider` |  |
| `callback` | `function` | See `HandleThumbPositionChange` for callback signature. |

### RemoveHandleThumbPositionChange

```lua
fcmctrlslider.RemoveHandleThumbPositionChange(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlSlider.lua#L165)

**[Fluid]**

Removes a handler added with `AddHandleThumbPositionChange`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlSlider` |  |
| `callback` | `function` |  |
