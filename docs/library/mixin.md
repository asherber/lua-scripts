# Fluid Mixins

The Fluid Mixins library does the following:
- Modifies Finale objects to allow methods to be overridden and new methods or properties to be added. In other words, the modified Finale objects function more like regular Lua tables.
- Mixins can be used to address bugs, to introduce time-savers, or to provide custom functionality.
- Introduces a new namespace for accessing the mixin-enabled Finale objects.
- Also introduces two types of formally defined mixin: `FCM` and `FCX` classes
- As an added convenience, all methods that return zero values have a fluid interface enabled (aka method chaining)


## finalemix Namespace
To utilise the new namespace, simply include the library, which also gives access to he helper functions:
```lua
local finalemix = require('library.mixin')
```

All defined mixins can be accessed through the `finalemix` namespace in the same way as the `finale` namespace. All constructors have the same signature as their `FC` originals.

```lua
local fcstr = finale.FCString()

-- Base mixin-enabled FCString object
local fcmstr = finalemix.FCMString()

-- Customised mixin that extends FCMString
local fcxstr = finalemix.FCXString()

-- Customised mixin that extends FCXString. Still has the same constructor signature as FCString
local fcxcstr = finalemix.FCXMyCustomString()
```
For more information about naming conventions and the different types of mixins, see the 'FCM Mixins' and 'FCX Mixins' sections.


Static copies of `FCM` and `FCX` methods and properties can also be accessed through the namespace like so:
```lua
local func = finalemix.FCXMyMixin.MyMethod
```
Note that static access includes inherited methods and properties.


## Rules of the Game
- New methods can be added or existing methods can be overridden.
- New properties can be added but existing properties retain their original behaviour (ie if they are writable or read-only, and what types they can be)
- The original method can always be accessed by appending a trailing underscore to the method name
- In keeping with the above, method and property names cannot end in an underscore. Setting a method or property ending with an underscore will result in an error.
- Returned `FC` objects from all mixin methods are automatically upgraded to a mixin-enabled `FCM` object.
- All methods that return no values (returning `nil` counts as returning a value) will instead return `self`, enabling a fluid interface

There are also some additional global mixin properties and methods that have special meaning:
| Name | Description | FCM Accessible | FCM Definable | FCX Accessible | FCX Definable |
| :--- | :---------- | :------------- | :------------ | :------------- | :------------ |
| string `MixinClassName` | The class name (FCM or FCX) of the mixin. | Yes | No | Yes | No |
| string|nil `MixinParent` | The name of the mixin parent | Yes | No | Yes | Yes (required) |
| string|nil `MixinBase` | The class name of the FCM base of an FCX class | No | No | Yes | No |
| function `Init(self`) | An initialising function. This is not a constructor as it will be called after the object has been constructed. | Yes | Yes (optional) | Yes | Yes (optional) |


## FCM Mixins

`FCM` classes are the base mixin-enabled Finale objects. These are modified Finale classes which, by default (that is, without any additional modifications), retain full backward compatibility with their original counterparts.

The name of an `FCM` class corresponds to its underlying 'FC' class, with the addition of an 'M' after the 'FC'.
For example, the following will create a mixin-enabled `FCCustomLuaWindow` object:
```lua
local finalemix = require('library.mixin')

local dialog = finalemix.FCMCustomLuaWindow()
```

In addition to creating a mixin-enabled finale object, `FCM` objects also automatically load any `FCM` mixins that apply to the class or its parents. These may contain additional methods or overrides for existing methods (eg allowing a method that expects an `FCString` object to accept a regular Lua string as an alternative). The usual principles of inheritance apply (children override parents, etc).

To see if any additional methods are available, or which methods have been modified, look for a file named after the class (eg `FCMCtrlStatic.lua`) in the `mixin` directory. Also check for parent classes, as `FCM` mixins are inherited and can be set at any level in the class hierarchy.


## Defining an FCM Mixin
The following is an example of how to define an `FCM` mixin for `FCMControl`.
`src/mixin/FCMControl.lua`
```lua
-- Include the mixin namespace and helper functions
local library = require('library.general_library')
local finalemix = require('library.mixin')

local props = {

    -- An optional initialising method
    Init = function(self)
        print('Initialising...')
    end,

    -- This method is an override for the SetText method 
    -- It allows the method to accept a regular Lua string, which means that plugin authors don't need to worry anout creating an FCString objectq
    SetText = function(self, str)

        -- Check if the argument is a finale object. If not, turn it into an FCString
        if not library.is_finale_object(str)
            local tmp = str

            -- Use a mixin object so that we can take advantage of the fluid interface
            str = finalemix.FCMString():SetLuaString(tostring(str))
        end

        -- Use a trailing underscore to reference the original method from FCControl
        -- Wrapping the call in catch_and_rethrow means that any errors will show at the place where this method was called, rather than at the line below, which can be useful since this is just a decorator.
        finalemix.catch_and_rethrow(self.SetText_, 'SetText', self, str)

        -- By maintaining the original method's behaviour and not returning anything, the fluid interface can be applied.
    end
}

return props
```
Since the underlying class `FCControl` has a number of child classes, the `FCMControl` mixin will also be inherited by all child classes, unless overridden.


An example of utilizing the above mixin:
```lua
local finalemix = require('library.mixin')

local dialog = finalemix.FCMCustomLuaWindow()

-- Fluid interface means that self is returned from SetText instead of nothing
local label = dialog:CreateStatic(10, 10):SetText('Hello World')

dialog:ExecuteModal(nil)
```



## FCX Mixins
`FCX` mixins are extensions of `FCM` mixins. They are intended for defining extended functionality with no requirement for backwards compatability with the underlying `FC` object.

While `FCM` class names are directly tied to their underlying `FC` object, their is no such requirement for an `FCX` mixin. As long as it the class name is prefixed with `FCX` and is immediately followed with another uppercase letter, they can be named anything. If an `FCX` mixin is not defined, the namespace will return `nil`.

When constructing an `FCX` mixin (eg `local dialog = finalemix.FCXMyDialog()`, the library first creates the underlying `FCM` object and then adds each parent (if any) `FCX` mixin until arriving at the requested class.


Here is an example `FCX` mixin definition:

`src/mixin/FCXMyStaticCounter.lua`
```lua
-- Include the mixin namespace and helper functions
local finalemix = require('library.mixin')

-- Since mixins can't have private properties, we can store them in a table
local private = {}
setmetatable(private, {__mode = 'k'}) -- Use weak keys so that properties are automatically garbage collected along with the objects they are tied to

local props = {

    -- All FCX mixins must declare their parent. It can be an FCM class or another FCX class
    MixinParent = 'FCMCtrlStatic',

    -- Initialiser
    Init = function(self)
        -- Set up private storage for the counter value
        if not private[self] then
            private[self] = 0
            finalemix.FCMControl.SetText(self, tostring(private[self]))
        end
    end,

    -- This custom control doesn't allow manual setting of text, so we override it with an empty function
    SetText = function()
    end,

    -- Incrementing counter method
    Increment = function(self)
        private[self] = private[self] + 1

        -- We need the SetText method, but we've already overridden it! Fortunately we can take a static copy from the finalemix namespace
        finalemix.FCMControl.SetText(self, tostring(private[self]))
    end
}

return props
```

`src/mixin/FCXMyCustomDialog.lua`
```lua
-- Include the mixin namespace and helper functions
local finalemix = require('library.mixin')

local props = {
    MixinParent = 'FCMCustomLuaWindow',

    CreateStaticCounter = function(self, x, y)
        -- Create an FCMCtrlStatic and then use the subclass function to apply the FCX mixin
        return finalemix.subclass(self:CreateStatic(x, y), 'FCXMyStaticCounter')
    end
}

return props
```


Example usage:
```lua
local finalemix = require('library.mixin')

local dialog = finalemix.FCXMyCustomDialog()

local counter = dialog:CreateStaticCounter(10, 10)

counter:Increment():Increment()

-- Counter should display 2
dialog:ExecuteModal(nil)
```

- [subclass](#subclass)
- [catch_and_rethrow](#catch_and_rethrow)

## subclass

```lua
fluid_mixins.subclass(object, class_name)
```

Takes a mixin-enabled finale object and migrates it to an `FCX` subclass. Any conflicting property or method names will be overwritten.

If the object is not mixin-enabled or the current `MixinClassName` is not a parent of `class_name`, then an error will be thrown.
If the current `MixinClassName` is the same as `class_name`, this function will do nothing.


| Input | Type | Description |
| --- | --- | --- |
| `object` | `__FCMBase` |  |
| `class_name` | `string` | FCX class name. |

| Output type | Description |
| --- | --- |
| `__FCMBase\|nil` | The object that was passed with mixin applied. |

## catch_and_rethrow

```lua
fluid_mixins.catch_and_rethrow(func, name, ...)
```

Catches an error and rethrows it one level higher from where this function is called.


| Input | Type | Description |
| --- | --- | --- |
| `func` | `function` | The function to call. |
| `name` | `string` | The function name that will appear in the error message. |
@ ... (mixed) Any arguments for the function call.

| Output type | Description |
| --- | --- |
| `mixed` | Any return values from the function. |