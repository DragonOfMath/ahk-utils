# ahk-utils
collection of my autohotkey utilities, made for AHK 2.0 and later.

# Installation
store the files in an `AutoHotkey/Lib/` folder either locally in the CWD, the user documents folder, or the standard library folder for the AHK runtime.
- https://www.autohotkey.com/docs/v2/Scripts.htm#lib
then use the `#Include` directive to import the scripts.
- https://www.autohotkey.com/docs/v2/lib/_Include.htm

# Contents

| Name | Description |
| --- | ----------- |
| [Array.ahk](./Lib/Array.ahk) | Utilities for Array objects and array-like operations |
| [Duration.ahk](./Lib/Duration.ahk) | Class for representing lapses of time as a number and unit |
| [Error.ahk](./Lib/Error.ahk) | Utilities for assertion, handling, and formatting of errors |
| [EventTarget.ahk](./Lib/EventTarget.ahk) | Class for event-driven programming |
| [Image.ahk](./Lib/Image.ahk) | Easy loading, referencing, and template matching of images |
| [JSON.ahk](./Lib/JSON.ahk) | JSON file I/O and serializing/deserializing |
| [Object.ahk](./Lib/Object.ahk) | Utilities for Object types |
| [Point.ahk](./Lib/Point.ahk) | 2D point class with AHK-specific functions |
| [Properties.ahk](./Lib/Properties.ahk) | File class for JSON application data |
| [Rect.ahk](./Lib/Rect.ahk) | 2D rectangle class with AHK-specific functions |
| [Scheduler.ahk](./Lib/Scheduler.ahk) | Create AHK-compliant timecodes for event tracking |
| [String.ahk](./Lib/String.ahk) | Utilities for strings |
| [Time.ahk](./Lib/Time.ahk) | Turns AHK's time strings into objects for easier modification |
| [Window.ahk](./Lib/Window.ahk) | Interfaces an application window |

# Remarks
some of these utilities depend on others, like Rect requiring Point.
not all utilities I have developed are listed here, but will be once they are ready and tested.