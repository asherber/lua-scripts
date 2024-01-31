# Utility Functions

A library of general Lua utility functions.

## Functions

- [copy_table(t)](#copy_table)
- [table_remove_first(t, value)](#table_remove_first)
- [iterate_keys(t)](#iterate_keys)
- [round(num, places)](#round)
- [to_integer_if_whole(value)](#to_integer_if_whole)
- [calc_roman_numeral(num)](#calc_roman_numeral)
- [calc_ordinal(num)](#calc_ordinal)
- [calc_alphabet(num)](#calc_alphabet)
- [clamp(num, minimum, maximum)](#clamp)
- [ltrim(str)](#ltrim)
- [rtrim(str)](#rtrim)
- [trim(str)](#trim)
- [call_and_rethrow(levels, tryfunczzz)](#call_and_rethrow)
- [rethrow_placeholder()](#rethrow_placeholder)
- [show_notes_dialog(caption, width, height)](#show_notes_dialog)

### copy_table

```lua
utility_functions.copy_table(t)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/utils.lua#L19)

If a table is passed, returns a copy, otherwise returns the passed value.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `t` | `mixed` |  |

| Return type | Description |
| ----------- | ----------- |
| `mixed` |  |

### table_remove_first

```lua
utility_functions.table_remove_first(t, value)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/utils.lua#L40)

Removes the first occurrence of a value from an array table.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `t` | `table` |  |
| `value` | `mixed` |  |

### iterate_keys

```lua
utility_functions.iterate_keys(t)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/utils.lua#L57)

Returns an unordered iterator for the keys in a table.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `t` | `table` |  |

| Return type | Description |
| ----------- | ----------- |
| `function` |  |

### round

```lua
utility_functions.round(num, places)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/utils.lua#L75)

Rounds a number to the nearest integer or the specified number of decimal places.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `num` | `number` |  |
| `places` (optional) | `number` | If specified, the number of decimal places to round to. If omitted or 0, will round to the nearest integer. |

| Return type | Description |
| ----------- | ----------- |
| `number` |  |

### to_integer_if_whole

```lua
utility_functions.to_integer_if_whole(value)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/utils.lua#L92)

Takes a number and if it is an integer or whole float (eg 12 or 12.0), returns an integer.
All other floats will be returned as passed.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `value` | `number` |  |

| Return type | Description |
| ----------- | ----------- |
| `number` |  |

### calc_roman_numeral

```lua
utility_functions.calc_roman_numeral(num)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/utils.lua#L105)

Calculates the roman numeral for the input number. Adapted from https://exercism.org/tracks/lua/exercises/roman-numerals/solutions/Nia11 on 2022-08-13

| Input | Type | Description |
| ----- | ---- | ----------- |
| `num` | `number` |  |

| Return type | Description |
| ----------- | ----------- |
| `string` |  |

### calc_ordinal

```lua
utility_functions.calc_ordinal(num)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/utils.lua#L126)

Calculates the ordinal for the input number (e.g. 1st, 2nd, 3rd).

| Input | Type | Description |
| ----- | ---- | ----------- |
| `num` | `number` |  |

| Return type | Description |
| ----------- | ----------- |
| `string` |  |

### calc_alphabet

```lua
utility_functions.calc_alphabet(num)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/utils.lua#L150)

This returns one of the ways that Finale handles numbering things alphabetically, such as rehearsal marks or measure numbers.

This function was written to emulate the way Finale numbers saves when Autonumber is set to A, B, C... When the end of the alphabet is reached it goes to A1, B1, C1, then presumably to A2, B2, C2. 

| Input | Type | Description |
| ----- | ---- | ----------- |
| `num` | `number` |  |

| Return type | Description |
| ----------- | ----------- |
| `string` |  |

### clamp

```lua
utility_functions.clamp(num, minimum, maximum)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/utils.lua#L167)

Clamps a number between two values.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `num` | `number` | The number to clamp. |
| `minimum` | `number` | The minimum value. |
| `maximum` | `number` | The maximum value. |

| Return type | Description |
| ----------- | ----------- |
| `number` |  |

### ltrim

```lua
utility_functions.ltrim(str)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/utils.lua#L179)

Removes whitespace from the start of a string.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `str` | `string` |  |

| Return type | Description |
| ----------- | ----------- |
| `string` |  |

### rtrim

```lua
utility_functions.rtrim(str)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/utils.lua#L191)

Removes whitespace from the end of a string.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `str` | `string` |  |

| Return type | Description |
| ----------- | ----------- |
| `string` |  |

### trim

```lua
utility_functions.trim(str)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/utils.lua#L203)

Removes whitespace from the start and end of a string.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `str` | `string` |  |

| Return type | Description |
| ----------- | ----------- |
| `string` |  |

### call_and_rethrow

```lua
utility_functions.call_and_rethrow(levels, tryfunczzz)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/utils.lua#L223)

Calls a function and returns any returned values. If any errors are thrown at the level this function is called, they will be rethrown at the specified level with new level information.
If the error message contains the rethrow placeholder enclosed in single quotes (see `utils.rethrow_placeholder`), it will be replaced with the correct function name for the new level.

*The first argument must have the same name as the `rethrow_placeholder`, chosen for uniqueness.*

@ ... (any) Any arguments to be passed to the function.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `levels` | `number` | Number of levels to rethrow. |
| `tryfunczzz` | `function` | The function to call. |

| Return type | Description |
| ----------- | ----------- |
| `any` | If no error is caught, returns the returned values from `tryfunczzz` |

### rethrow_placeholder

```lua
utility_functions.rethrow_placeholder()
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/utils.lua#L291)

Returns the function name placeholder (enclosed in single quotes, the same as in Lua's internal errors) used in `call_and_rethrow`.

Use this in error messages where the function name is variable or unknown (eg because the error is thrown up multiple levels) and needs to be replaced with the correct one at runtime by `call_and_rethrow`.

| Return type | Description |
| ----------- | ----------- |
| `string` |  |

### show_notes_dialog

```lua
utility_functions.show_notes_dialog(caption, width, height)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/utils.lua#L304)

Displays a modal dialog with the contents of finaleplugin.RFTNotes (if present) or finaleplugin.Notes. If neither one is present, no dialog is shown.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `caption` | `string` | The caption for the dialog. Defaults to plugin name and version. |
| `width` | `number` | The width in pixels of the edit control. Defaults to 500. |
| `height` | `number` | The height inpixels of the edit control. Defaults to 350. |
