#Requires AutoHotkey >=2.0
#Include <String>
#Include <Array>

/**
 * @name        JSON.ahk
 * @description JSON utility library for AutoHotkey 2.0+.
 * @version     1.4-2025.05.26
 * @requires    AutoHotkey >=2.0
 * @license     GNU GPLv3
 * Changelog:
 * v1.4 - better object identification; cyclic references can be ignored, in which case they return "null" when stringified
 * v1.3 - added private property blacklisting
 * v1.2 - added guarding against cyclic references
 * v1.1 - bugfixes for blank items
 * v1.0 - initial build
 */

; Customized Object class to make property assignment easier
class JSONObject extends Object {
	__Item[key] {
		get => this.%key%
		set => this.%key% := value
	}
}

Identify(obj) {
	if (obj.HasOwnProp("name")) {
		return obj.name
	}
	if (obj.HasOwnProp("id")) {
		return obj.id
	}
	if (obj.HasOwnProp("prototype")) {
		return obj.prototype.__Class "<" ObjPtr(obj) ">"
	} else {
		return obj.__Class "<" ObjPtr(obj) ">"
	}
}

/**
 * Static class object for serializing AHK objects to JSON, and deserializing JSON to AHK objects. https://www.json.org/
 * Basic operation:
 * - Parsing JSON: `obj := JSON.Parse('{"key":["value",123,true,{}]}')`
 * - Serializing to JSON: `jsonStr := JSON.Stringify({key:["value",123,true,{}]})`
 * - Reading a JSON file: `obj := JSON.ReadFile("path\to\file.json")`
 * - Writing a JSON file: `jsonStr := JSON.WriteFile("path\to\file.json", obj, true)` (last parameter enables pretty-printing)
 * For more details, see documentation below.
 * @class {JSON}
 */
class JSON {
	__New() {
		throw Error("JSON cannot be instanced")
	}
	
	/**
	 * Newline token.
	 * Possible values include carriage return, linefeed, or carriage return + linefeed.
	 * @type {String}
	 * @static
	 */
	static NEWLINE := "`r`n"
	
	/**
	 * Indentation token.
	 * Possible values include a tab, 2 spaces, 4 spaces, or 8 spaces, or any other valid combination of whitespace.
	 * @type {String}
	 * @static
	 */
	static INDENT := "`t"
	
	/**
	 * Placeholder for null when parsing values.
	 * Needs to be a unique value, since 0 and empty string are not sufficient.
	 * @type {Object}
	 * @static
	 */
	static NULL := {}
	
	/**
	 * Keeps track of object elements referenced when serializing, so that cyclic references don't create infinite recursion.
	 * Redundant references are allowed.
	 * @type {Object[]}
	 */
	static REFS := []
	
	/**
	 * Used to ignore properties that should not be used/serialized when parsing or stringifying.
	 * This is the only way to know since AHK does not have accessor qualifiers.
	 * @type {String}
	 */
	static PRIVATE_PROP_PREFIX := "__"
	
	/**
	 * Special property name that is used to store a list of properties to avoid serializing that aren't prefixed with `PRIVATE_PROP_PREFIX`.
	 * @type {String}
	 */
	static PRIVATE_PROP_FILTER_KEY := "__PRIVATE__"
	
	/**
	 * When a cyclic reference occurs, return an empty string rather than raising an error.
	 * @type {Boolean}
	 */
	static IGNORE_CYCLIC_REFS := true
	
	/**
	 * Converts a JSON string to an AHK object or primitive.
	 * @param {&String} str - the string object; any other type is returned as is
	 * @param {&Integer} [i=1] - the index to start parsing from, which is passed as a reference from other parsing methods
	 * @returns {String|Integer|Array|Object} an AHK object corresponding to the top-level type
	 * @static
	 */
	static Parse(str, &i := 1) {
		if (not (str is String)) {
			return str
		}
		this.__SkipWhitespace(&str, &i)
		char := str.CharAt(i)
		switch char {
			case "": this.SyntaxError(str, i, char, "")
			case "[": return this.__ParseAsArray(&str, &i)
			case "{": return this.__ParseAsObject(&str, &i)
			case '"': return this.__ParseAsString(&str, &i)
			default: return this.__ParseAsLiteral(&str, &i)
		}
	}
	
	/**
	 * Scans the string until a non-whitespace character is found or end of string.
	 * @param {&String} str - the string object
	 * @param {&Integer} [i=1] - the index to start parsing from, which is passed as a reference from other parsing methods
	 * @static
	 * @private
	 * @void
	 */
	static __SkipWhitespace(&str, &i) {
		while ((char := str.CharAt(i)) and StrWhitespace(char)) {
			i++
		}
	}
	
	/**
	 * Parses a JSON string as an Array.
	 * @param {&String} str - the string object
	 * @param {&Integer} [i=1] - the index to start parsing from, which is passed as a reference from other parsing methods
	 * @returns {Array} AHK Array object
	 * @static
	 * @private
	 */
	static __ParseAsArray(&str, &i := 1) {
		start := i
		char := str.CharAt(i++)
		if (char = "[") {
			arr := []
			value := this.NULL
			loop {
				this.__SkipWhitespace(&str, &i)
				char := str.CharAt(i)
				switch char {
					case ",":
						if (value = this.NULL) {
							this.SyntaxError(str, i, char, "any")
						}
						value := this.NULL
						i++
					case "]":
						i++
						break
					case "", ":", "}":
						this.SyntaxError(str, start, char, ",]")
					default:
						if (value = this.NULL) {
							value := this.Parse(str, &i)
							arr.Push(value)
						} else {
							this.SyntaxError(str, i, char, ",")
						}
				}
			}
			return arr
		} else {
			this.SyntaxError(str, start, char, "[")
		}
	}
	
	/**
	 * Parses a JSON string as an Object.
	 * @param {&String} str - the string object
	 * @param {&Integer} [i=1] - the index to start parsing from, which is passed as a reference from other parsing methods
	 * @returns {Object} AHK object
	 * @static
	 * @private
	 */
	static __ParseAsObject(&str, &i := 1) {
		start := i
		char := SubStr(str, i++, 1)
		if (char = "{") {
			obj := JSONObject()
			key := this.NULL
			value := this.NULL
			loop {
				this.__SkipWhitespace(&str, &i)
				char := SubStr(str, i, 1)
				switch char {
					case '"':
						if (key = this.NULL) {
							key := this.__ParseAsString(&str, &i)
						} else {
							this.SyntaxError(str, i, char, ":")
						}
					case ":":
						if (key != this.NULL and value = this.NULL) {
							i++
							value := this.Parse(str, &i)
							if (!StrStartsWith(key, this.PRIVATE_PROP_PREFIX)) {
								obj[key] := value
							}
						} else {
							this.SyntaxError(str, i, char, ",}")
						}
					case ",":
						if (key = this.NULL) {
							this.SyntaxError(str, i, char, "property string or '}'")
						}
						if (value = this.NULL) {
							this.SyntaxError(str, i, char, ":")
						}
						i++
						key := this.NULL
						value := this.NULL
					case "}":
						if (key != this.NULL and value = this.NULL) {
							this.SyntaxError(str, i, char, ":")
						}
						i++
						break
					default:
						this.SyntaxError(str, i, char, "property string or '}'")
				}
			}
			return obj
		} else {
			this.SyntaxError(str, start, char, "{")
		}
	}
	
	/**
	 * Parses a JSON string as a Map (associative array).
	 * This isn't used in the main Parse method, so you will need to call this directly to use it.
	 * The difference from `__ParseAsObject` is that keys can be parsed as embedded JSON objects themselves, allowing for object-object relations.
	 * @param {&String} str - the string object
	 * @param {&Integer} [i=1] - the index to start parsing from, which is passed as a reference from other parsing methods, will be changed to the index immediately after the end of the token
	 * @returns {Map} AHK map object
	 * @static
	 * @private
	 */
	static __ParseAsMap(&str, &i := 1) {
		start := i
		char := SubStr(str, i++, 1)
		if (char = "{") {
			obj := Map()
			key := this.NULL
			value := this.NULL
			loop {
				this.__SkipWhitespace(&str, &i)
				char := str.CharAt(i)
				switch char {
					case '"':
						if (key = this.NULL and value = this.NULL) {
							key := this.__ParseAsString(&str, &i)
							key := this.Parse(key, &i)
						} else {
							this.SyntaxError(str, i, char, ":")
						}
					case ":":
						if (key != this.NULL and value = this.NULL) {
							i++
							this.__SkipWhitespace(&str, &i)
							value := this.Parse(str, &i)
							if (!StrStartsWith(key, this.PRIVATE_PROP_PREFIX)) {
								obj.Set(key, value)
							}
						} else {
							this.SyntaxError(str, i, char, ",}")
						}
					case ",":
						if (key = this.NULL) {
							this.SyntaxError(str, i, char, '"')
						}
						if (value = this.NULL) {
							this.SyntaxError(str, i, char, ":")
						}
						i++
						key := this.NULL
						value := this.NULL
					case "}":
						if (key != this.NULL and value = this.NULL) {
							this.SyntaxError(str, i, char, ":")
						}
						i++
						break
					default:
						this.SyntaxError(str, i, char, '"}')
				}
			}
			return obj
		} else {
			this.SyntaxError(str, start, char, "{")
		}
	}
	
	/**
	 * Parses a JSON string as a String. That is, it scans for a string in quote marks and unescapes the substring, converting JSON-escaped characters into AHK escape sequences.
	 * @param {&String} str - the string object
	 * @param {&Integer} [i=1] - the index to start parsing from, which is passed as a reference from other parsing methods, will be changed to the index immediately after the end of the token
	 * @returns {String} the raw string
	 * @static
	 * @private
	 */
	static __ParseAsString(&str, &i := 1) {
		start := i
		char := str.CharAt(i++)
		if (char = '"') {
			value := char
			loop {
				value .= (char := str.CharAt(i++))
				switch char {
					case "\": value .= (char := str.CharAt(i++)) ; next character is literal
					case '"': return StrUnquote(value)
					case "": break
				}
			}
		}
		this.SyntaxError(str, start, char, '"')
	}
	
	/**
	 * Parses a JSON string as a literal. It scans until whitespace or a non-alphanumeric character is found.
	 * Python literals also supported.
	 * @param {&String} str - the string object
	 * @param {&Integer} [i=1] - the index to start parsing from, which is passed as a reference from other parsing methods, will be changed to the index immediately after the end of the token
	 * @returns {Number} the equivalent literal value (true/True = 1, false/False = 0, null/Null = 0, undefined/None = <blank>)
	 * @static
	 * @private
	 */
	static __ParseAsLiteral(&str, &i := 1) {
		start := i
		value := ""
		while (StrAlphanumeric(char := str.CharAt(i))) {
			value .= char
			i++
		}
		switch value, 0 {
			case "true": return true
			case "false": return false
			case "null", "None": return ""
			default:
				if (IsInteger(value) or IsFloat(value)) {
					return Number(value)
				} else {
					this.SyntaxError(str, start, value, "any")
				}
		}
	}
	
	/**
	 * Serializes an arbitary object structure to a JSON string.
	 * Optionally, the output can be prettified so that elements are listed by line and indented by their scope.
	 * @param {&Any} obj - the AHK object to stringify
	 * @param {Boolean} [prettify=false] - if true, the JSON string will split the elements into lines and indent them according to the depth in the object; if false, the JSON string will be packed without any whitespace
	 * @param {Integer} [__depth=1] - internally used parameter for counting nesting depth and applying indentation
	 * @returns {String} the JSON string
	 * @static
	 */
	static Stringify(obj, prettify := false, __depth := 1) {
		if (__depth = 1) {
			this.REFS := []
		}
		if (obj is Object) {
			; store to prevent cyclic references in descendant nodes
			if (this.REFS.Contains(obj)) {
				if (this.IGNORE_CYCLIC_REFS) {
					return "null"
				} else {
					throw ValueError("Cyclic reference",, Identify(obj))
				}
			} else {
				this.REFS.Push(obj)
			}
		}
		strout := ""
		switch {
			case obj is Func:   strout := "null" ; functions shouldn't be serialized
			case obj is Number:	strout := this.__StringifyNumber(&obj, prettify, __depth)
			case obj is String:	strout := this.__StringifyString(&obj, prettify, __depth)
			case obj is Array:	strout := this.__StringifyArray(&obj, prettify, __depth)
			case obj is Map:	strout := this.__StringifyMap(&obj, prettify, __depth)
			case obj is Object:	strout := this.__StringifyObject(&obj, prettify, __depth)
			default: this.ValueError(0, Type(obj), "Number, String, Array, Map, or Object")
		}
		if (obj is Object) {
			this.REFS.Pop()
		}
		return strout
	}
	
	/**
	 * Serializes a number to a JSON string.
	 * @param {&Number} obj - the AHK object to stringify
	 * @param {Boolean} [prettify=false] - if true, the JSON string will split the elements into lines and indent them according to the depth in the object; if false, the JSON string will be packed without any whitespace
	 * @param {Integer} [__depth=1] - internally used parameter for counting nesting depth and applying indentation
	 * @returns {String} the JSON string
	 * @static
	 * @private
	 */
	static __StringifyNumber(&obj, prettify := false, __depth := 1) {
		return String(obj)
	}
	
	/**
	 * Serializes an AHK string to a JSON string.
	 * While this sounds like a ridiculous method name, it is necessary to escape characters in a string before wrapping it in quote marks, as is standard in JSON.
	 * @param {&String} obj - the AHK object to stringify
	 * @param {Boolean} [prettify=false] - if true, the JSON string will split the elements into lines and indent them according to the depth in the object; if false, the JSON string will be packed without any whitespace
	 * @param {Integer} [__depth=1] - internally used parameter for counting nesting depth and applying indentation
	 * @returns {String} the JSON string
	 * @static
	 * @private
	 */
	static __StringifyString(&obj, prettify := false, __depth := 1) {
		return StrQuote(obj) ; strings are escaped and then surrounded in quote marks
	}
	
	/**
	 * Serializes an AHK Array to a JSON string.
	 * @param {&String} obj - the AHK object to stringify
	 * @param {Boolean} [prettify=false] - if true, the JSON string will split the elements into lines and indent them according to the depth in the object; if false, the JSON string will be packed without any whitespace
	 * @param {Integer} [__depth=1] - internally used parameter for counting nesting depth and applying indentation
	 * @returns {String} the JSON string
	 * @static
	 * @private
	 */
	static __StringifyArray(&obj, prettify := false, __depth := 1) {
		len := obj.Length
		if (len = 0) {
			return "[]"
		}
		props := ""
		if (prettify) {
			loop len {
				props .= StrRepeat(this.INDENT, __depth)
				props .= this.Stringify(obj[A_Index], prettify, __depth + 1)
				if (A_Index < len) {
					props .= ","
				}
				props .= this.NEWLINE
			}
			return "[" . this.NEWLINE . props . StrRepeat(this.INDENT, __depth - 1) . "]"
		} else {
			loop len {
				props .= this.Stringify(obj[A_Index], prettify, __depth + 1)
				if (A_Index < len) {
					props .= ","
				}
			}
			return "[" . props . "]"
		}
	}
	
	/**
	 * Serializes an AHK Map to a JSON string.
	 * Maps cannot be directly revived from `JSON.Parse`, so in order to deserialize a Map properly, you will need to use `JSON.__ParseAsMap` instead.
	 * @param {&Map} obj - the AHK object to stringify
	 * @param {Boolean} [prettify=false] - if true, the JSON string will split the elements into lines and indent them according to the depth in the object; if false, the JSON string will be packed without any whitespace
	 * @param {Integer} [__depth=1] - internally used parameter for counting nesting depth and applying indentation
	 * @returns {String} the JSON string
	 * @static
	 * @private
	 */
	static __StringifyMap(&obj, prettify := false, __depth := 1) {
		len := obj.Count
		if (len = 0) {
			return "{}"
		}
		props := ""
		i := 0
		if (prettify) {
			for k, v in obj {
				i++
				props .= StrRepeat(this.INDENT, __depth)
				if (k is Object) {
					props .= StrQuote(this.Stringify(k, false, __depth + 1)) ; associated arrays can have objects for keys
				} else {
					props .= StrQuote(String(k))
				}
				props .= ": "
				props .= this.Stringify(v, prettify, __depth + 1)
				if (i < len) {
					props .= ","
				}
				props .= this.NEWLINE
			}
			return "{" . this.NEWLINE . props . StrRepeat(this.INDENT, __depth - 1) . "}"
		} else {
			for k, v in obj {
				i++
				if (k is Object) {
					props .= StrQuote(this.Stringify(k, false, __depth + 1)) ; associated arrays can have objects for keys
				} else {
					props .= StrQuote(String(k))
				}
				props .= ":" . this.Stringify(v, prettify, __depth + 1)
				if (i < len) {
					props .= ","
				}
			}
			return "{" . props . "}"
		}
	}
	
	/**
	 * Serializes an AHK Object to a JSON string.
	 * Any enumerable property of an object that isn't dynamic or a method call will be used.
	 * @param {&Object} obj - the AHK object to stringify
	 * @param {Boolean} [prettify=false] - if true, the JSON string will split the elements into lines and indent them according to the depth in the object; if false, the JSON string will be packed without any whitespace
	 * @param {Integer} [__depth=1] - internally used parameter for counting nesting depth and applying indentation
	 * @returns {String} the JSON string
	 * @static
	 * @private
	 */
	static __StringifyObject(&obj, prettify := false, __depth := 1) {
		if (obj.HasMethod("ToJSON")) {
			newObj := obj.ToJSON()
			if (newObj != obj) {
				return this.Stringify(newObj, prettify, __depth)
			}
		}
		propBlacklist := []
		if (obj.HasOwnProp(this.PRIVATE_PROP_FILTER_KEY)) {
			propBlacklist := obj.%this.PRIVATE_PROP_FILTER_KEY%
			if (not (propBlacklist is Array)) {
				propBlacklist := []
			}
		}
		hasProps := false
		props := ""
		if (prettify) {
			for key in obj.OwnProps() {
				; skip private properties
				if (StrStartsWith(key, this.PRIVATE_PROP_PREFIX) or propBlacklist.Contains(key)) {
					continue
				}
				valstr := this.Stringify(obj.%key%, prettify, __depth + 1)
				; don't append null props
				if (valstr != "null") {
					props .= StrRepeat(this.INDENT, __depth) . StrQuote(key) . ": "  . valstr . "," . this.NEWLINE
					hasProps := true
				}
			}
			if (hasProps) {
				; remove trailing comma and re-add newline
				return "{" . this.NEWLINE . SubStr(props, 1, -(1+this.NEWLINE.Length)) . this.NEWLINE . StrRepeat(this.INDENT, __depth - 1) . "}"
			}
		} else {
			for key in obj.OwnProps() {
				; skip private properties
				if (StrStartsWith(key, this.PRIVATE_PROP_PREFIX) or propBlacklist.Contains(key)) {
					continue
				}
				valstr := this.Stringify(obj.%key%, prettify, __depth + 1)
				; don't append null props
				if (valstr != "null") {
					props .= StrQuote(key) . ":" . valstr . ","
					hasProps := true
				}
			}
			if (hasProps) {
				; remove trailing newline
				return "{" . SubStr(props, 1, -1) . "}"
			}
		}
		
		return "{}"
	}
	
	/**
	 * Reads the contents of a file and returns the JSON object parsed from it.
	 * @param {String} filename - path to the file to load from; ".json" at the end will be added if it is missing
	 * @returns {Object} the AHK object created from parsing the file
	 * @static
	 */
	static ReadFile(filename) {
		if (not StrEndsWith(filename, ".json")) {
			filename .= ".json"
		}
		file := FileOpen(filename, "rw", "UTF-8")
		data := file.Read()
		file.Close()
		return this.Parse(data)
	}
	
	/**
	 * Writes an arbitrary object to a file as JSON.
	 * @param {String} filename - path to the file to write to; ".json" at the end will be added if it is missing
	 * @param {&Object} contents - the object data
	 * @param {Boolean} [prettify=false] - if true, the JSON string will split the elements into lines and indent them according to the depth in the object; if false, the JSON string will be packed without any whitespace
	 * @returns {String} the JSON string written to the file
	 * @static
	 */
	static WriteFile(filename, contents, prettify := false) {
		if (not StrEndsWith(filename, ".json")) {
			filename .= ".json"
		}
		data := this.Stringify(contents, prettify)
		file := FileOpen(filename, "w", "UTF-8")
		file.Write(data)
		file.Close()
		return data
	}
	
	/**
	 * Constructs a syntax error based on a parsing index, the character(s) found, and the expected character(s).
	 * @param {Number} [index] - parsing index where the syntax error occurred
	 * @param {String} [found] - the character or substring at the index that caused the error
	 * @param {String} [expected] - the character or set of characters that was expected at the index
	 * @returns {Error}
	 * @static
	 */
	static SyntaxError(str, index, found, expected) {
		switch expected {
			case '"': 
				expected := "quote mark (`")"
				found := found or "unterminated string"
			case ':': 
				expected := "colon (:) between key and value"
				found := found or "malformed object"
			case ',': 
				expected := "comma (,) between consecutive items"
				found := found or "malformed object/array"
			case ']': 
				expected := "closing bracket (])"
				found := found or "unterminated array"
			case ',]':
				expected := "comma (,) or closing bracket (])"
				found := found or "unterminated array"
			case '}': 
				expected := "closing curly bracket (})"
				found := found or "unterminated object"
			case ',}':
				expected := "comma (,) or closing curly bracket (})"
				found := found or "unterminated object"
			case "any":
				expected := "an object/array/string/number/true/false/null"
				found := found or "empty value"
			default:
				expected := expected or "start of data block"
				found := found or "end of data"
		}
		throw Error(Format("Invalid JSON syntax: expected {}, found {} at {}`n{}", expected, found, index, SubStr(str, Max(index-10, 1), 20)))
	}
	
	/**
	 * Constructs a value error during parsing or stringifying.
	 * @param {Number} [index] - parsing index where the value error occurred; leave at 0 for non-parsing cause
	 * @param {String} [found] - the character or substring at the index that caused the error, or the value that was erroneous
	 * @param {String} [expected] - the character or set of characters that was expected at the index, or the value(s) expected
	 * @returns {Error}
	 * @static
	 */
	static ValueError(index := 0, found := "", expected := "any") {
		if (index) {
			throw Error(Format("Invalid JSON value: expected {}, found {} at {}", expected, found, index))
		} else {
			throw Error(Format("Invalid JSON value: expected {}, got {}", expected, found))
		}
	}
}
