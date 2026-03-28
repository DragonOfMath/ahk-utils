#Requires AutoHotkey >=2.0
#Include <Error>

/**
 * @name        String.ahk
 * @description String utilities.
 * @version     1.3-2026.03.28
 * @requires    AutoHotkey >=2.0
 * @license     GNU GPLv3
 * Changelog:
 * v1.3 - String.prototype.Contains now calls InStr; StrEmpty checks for empty string
 * v1.2 - String.prototype.Replace now calls StrReplace
 * v1.1 - cleanup and docs
 * v1.0 - initial release
 */

/**
 * Gets the character in the string at the specified index.
 * @param {String} self
 * @param {Integer} idx
 * @returns {String}
 */
CharAt(self, idx) {
	return SubStr(self, idx, 1)
}

/**
 * Checks if a string starts with a matching substring.
 * @param {String} x - source string to check
 * @param {String} y - target string to match for
 * @returns {Boolean}
 */
StrStartsWith(x, y) {
	return (SubStr(x, 1, StrLen(y)) = y)
}

/**
 * Checks if a string ends with a matching substring.
 * @param {String} x - source string to check
 * @param {String} y - target string to match for
 * @returns {Boolean}
 */
StrEndsWith(x, y) {
	return (SubStr(x, -StrLen(y)) = y)
}

/**
 * Returns true if the string is wrapped between two parts.
 * @param {String} x - source string to check
 * @param {String} [w=""] - target wrapper string to match for
 * @returns {Boolean}
 */
StrIsWrapped(x, w := '""') {
	return StrStartsWith(x, CharAt(w, 1)) and StrEndsWith(x, CharAt(w, 2))
}

/**
 * Wraps a string between two parts.
 * @param {String} x - source string to wrap
 * @param {String} [w=""] - wrapper string
 * @returns {String}
 */
StrWrap(x, w := '""') {
	return CharAt(w, 1) . x . CharAt(w, 2)
}

/**
 * Unwraps a string by removing the start and end parts.
 * @param {String} x - source string to unwrap
 * @param {String} [w=""] - wrapper string
 * @returns {String}
 */
StrUnwrap(x, w := '""') {
	if (StrIsWrapped(x, w)) {
		return SubStr(x, 2, -1)
	} else {
		;throw ValueError("invalid wrapped string: " . x)
		return x
	}
}

/**
 * Repeats a string n times.
 * @param {String} x - source string to repeat
 * @param {Integer} [n=1] - number of times to repeat the source string
 * @returns {String}
 */
StrRepeat(x, n := 1) {
	str := ""
	loop n {
		str .= x
	}
	return str
}

/**
 * Returns true if the string is comprised entirely of whitespace.
 * @param {String} x - source string to check
 * @returns {Boolean}
 */
StrWhitespace(x) {
	return RegExMatch(x, "^\s+$")
}

; Returns true if the string contains only numeric characters
StrNumeric(x) {
	return IsNumber(x)
}

/**
 * Returns true if the string contains only letters.
 * @param {String} x - source string to check
 * @returns {Boolean}
 */
StrAlphabetic(x) {
	return RegExMatch(x, "i)^[a-z]+$")
}

/**
 * Returns true if the string contains only alphanumeric characters.
 * @param {String} x - source string to check
 * @returns {Boolean}
 */
StrAlphanumeric(x) {
	return RegExMatch(x, "i)^[0-9a-z_.-]+$")
}

/**
 * Returns true if the string contains only hexadecimal characters.
 * @param {String} x - source string to check
 * @returns {Boolean}
 */
StrHexadecimal(x) {
	return RegExMatch(x, "i)^(0x)?[0-9a-f]+$")
}

/**
 * Replaces escape sequences with literals.
 * @param {String} x - source string to escape
 * @returns {String}
 */
StrEscape(x) {
	x := StrReplace(x, "\", "\\")
	x := StrReplace(x, "/", "\/")
	x := StrReplace(x, '"', '\"')
	x := StrReplace(x, "`b", "\b")
	x := StrReplace(x, "`f", "\f")
	x := StrReplace(x, "`n", "\n")
	x := StrReplace(x, "`r", "\r")
	x := StrReplace(x, "`t", "\t")
	return x
}

/**
 * Replaces literals with escape sequences.
 * @param {String} x - source string to unescape
 * @returns {String}
 */
StrUnescape(x) {
	y := ""
	i := 1
	len := StrLen(x)
	while (i <= len) {
		c := CharAt(x, i)
		if (c = "\") {
			i++
			c := CharAt(x, i)
			switch c {
				case "t": c := "`t"
				case "r": c := "`r"
				case "n": c := "`n"
				case "f": c := "`f"
				case "b": c := "`b"
			}
		}
		y .= c
		i++
	}
	return y
}

/**
 * Places the (escaped) string in quotes.
 * @param {String} x - source string to quote
 * @returns {String}
 */
StrQuote(x) {
	return StrWrap(StrEscape(x))
}

/**
 * Removes the quotes from a string and interprets it.
 * @param {String} x - source string to unquote
 * @returns {String}
 */
StrUnquote(x) {
	return StrUnescape(StrUnwrap(x))
}

/**
 * Joins multiple strings with a delimiter string.
 * @param {String} sep - delimiter string
 * @param {String[]} params* - strings to join
 * @returns {String}
 */
StrJoin(sep, params*) {
	for index, param in params {
		str .= param . sep
	}
	return SubStr(str, 1, -StrLen(sep))
}

/**
 * Whether a string is empty (i.e. zero length).
 * @param {String} x
 * @returns {Boolean}
 */
StrEmpty(x) {
	return (x is String) and (StrLen(x) = 0)
}


StrBase := "".Base
DefProp := {}.DefineProp
DefProp(StrBase, "Length", {get: StrLen})
DefProp(StrBase, "CharAt", {call: CharAt})
DefProp(StrBase, "Replace", {call: StrReplace})
DefProp(StrBase, "Contains", {call: InStr})