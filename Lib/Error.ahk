#Requires AutoHotkey >=2.0

/**
 * @name        Error.ahk
 * @description Utilities related to assertion and handling of Errors.
 * @version     1.0-2026.03.19
 * @requires    AutoHotkey >=2.0
 * @license     GNU GPLv3
 */

/**
 * Creates a descriptive string from an error, including exactly where it occurred and what caused it.
 * @param {Error} err - the Error object
 * @returns {String}
 */
FormatErrorMessage(err) {
	return Format("{1}: {2}.`nSpecifically:`t{3}`n`nFile:`t{4}`nLine:`t{5}`nWhat:`t{6}`nStack:`n{7}", type(err), err.Message, err.Extra, err.File, err.Line, err.What, err.Stack)
}

/**
 * Assumes a value or function result to be truthful.
 * @param {Any} condition - condition can be any value, or a Func object, in which case it is evaluated and its return value is checked for truthiness
 * @param {String} [errorMsg] - message to be displayed if the assertion fails
 * @returns {Boolean} true if the assertion passes, otherwise throws an assertion error
 */
Assert(condition, errorMsg := "Assertion failed") {
	if (condition is Func) {
		condition := condition()
	}
	if (condition) {
		return true
	} else {
		throw Error(errorMsg,, condition)
	}
}

/**
 * Assumes the argument types match expected types (in the same order).
 * @param {Any[]} args - arguments for something
 * @param {Class[]} types - expected types
 * @returns {Boolean} true if all arguments are their expected types, otherwise throws an assertion error.
 */
AssertTypes(args, types) {
	loop args.Length {
		arg := args[A_Index]
		T := types[A_Index]
		Assert(arg is T, "Parameter " . A_Index . " must be a " . T.__Class)
	}
	return true
}

/**
 * Appends error information to a file named `errorlog.txt` in the current working directory.
 * Because AHK runtime has useless debugging.
 * @param {Error} err - the Error object
 * @param {Any[]} args* - additional stringable information to append
 * @void
 */
DumpToFile(err, args*) {
	message := "`n----------------------------------------------------`n"
	message .= FormatTime() . "`n"
	if (err is Error) {
		message .= FormatErrorMessage(err)
	} else {
		message .= String(err)
	}
	if (args.Length) {
		message .= "`nAdditional Information:`n"
		for arg in args {
			message .= "`t" . String(arg) . "`n"
		}
	}
	
	errFile := FileOpen("errorlog.txt", "a", "UTF-8")
	errFile.Write(message)
	errFile.Close()
}
