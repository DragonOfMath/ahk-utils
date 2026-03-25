#Requires AutoHotkey >=2.0
#Include <Time>
#Include <Error>

/**
 * @name        Duration
 * @description	Utility class for handling and calculating durations and differences in time
 * @version     1.2-2026.03.16
 * @requires    Autohotkey >=2.0
 * @license     GNU GPLv3
 * Changelog:
 * v1.2 - added normalized instancing, instancing from plain objects, and parameter validation for some methods
 * v1.1 - added arithmetic functions such as add, subtract, multiply, and divide.
 * v1.0 - initial release
 */

/**
 * Represents an amount of time to elapse.
 * @property {Number} t - duration value
 * @property {Number} unit - duration unit, defaults to "Seconds"
 */
class Duration {
	/**
	 * The default unit for Duration instances and calculations.
	 * Possible values include: "Seconds", "Milliseconds", "Minutes", "Hours", and "Days"
	 * @type {String}
	 */
	static DEFAULT_UNIT := "Seconds"

	t := 0
	unit := Duration.DEFAULT_UNIT
	
	/**
	 * @constructor
	 * @param {Number|String|Array|Duration} value - duration of time, AHK time string, array of duration and units, or Duration instance
	 * @param {String} [unit=Duration.DEFAULT_UNIT] - optional unit of time for a numeric duration
	 */
	__New(value := 0, unit := Duration.DEFAULT_UNIT) {
		if (value is Number) {
			this.t := value
			this.unit := unit
		} else if (value is String) {
			if (RegExMatch(value, AHK_TIME_REGEX)) {
				this.SetTimeAfter(value)
			} else {
				this.t := Duration.Parse(value, unit)
			}
			this.unit := unit
		} else if (value is Array) {
			; converts everything to seconds
			this.t := Duration.Parse(value, unit)
			this.unit := unit
		} else if (value is Time) {
			this.SetTimeAfter(value.ahk_time)
			this.unit := unit
		} else if (value is Duration) {
			this.t := value.t
			this.unit := value.unit
		} else if (value is Object) {
			this.t := value.HasOwnProp("value") ? value.value : value.HasOwnProp("t") ? value.t : 0
			this.unit := value.HasOwnProp("unit") ? value.unit : value.HasOwnProp("u") ? value.u : unit
		}
	}
	
	/**
	 * Called when used for variadic parameters.
	 * https://www.autohotkey.com/docs/v2/Functions.htm#VariadicCall
	 * @returns {Array}
	 */
	__Enum(*) {
		return [Integer(this.t), this.unit]
	}
	
	/**
	 * Duration in milliseconds (thousandths of a second).
	 * @type {Number}
	 */
	ms {
		get => Integer(Duration.ToMilliseconds(this.t, this.unit))
		set => this.t := Duration.FromMilliseconds(value, this.unit)
	}
	
	/**
	 * Duration in seconds.
	 * @type {Number}
	 */
	seconds {
		get => Duration.ToSeconds(this.t, this.unit)
		set => this.t := Duration.FromSeconds(value, this.unit)
	}
	
	/**
	 * Duration in minutes.
	 * @type {Number}
	 */
	minutes {
		get => Duration.ToMinutes(this.t, this.unit)
		set => this.t := Duration.FromMinutes(value, this.unit)
	}
	
	/**
	 * Duration in hours.
	 * @type {Number}
	 */
	hours {
		get => Duration.ToHours(this.t, this.unit)
		set => this.t := Duration.FromHours(value, this.unit)
	}
	
	/**
	 * Duration in days.
	 * @type {Number}
	 */
	days {
		get => Duration.ToDays(this.t, this.unit)
		set => this.t := Duration.FromDays(value, this.unit)
	}
	
	/**
	 * Duration in weeks.
	 * @type {Number}
	 */
	weeks {
		get => Duration.ToWeeks(this.t, this.unit)
		set => this.t := Duration.FromWeeks(value, this.unit)
	}
	
	/**
	 * The time string after this duration has elapsed.
	 * When getting, it adds this duration to the reference time.
	 * When setting, it sets this duration to the offset from the reference time.
	 * @type {String}
	 * @param {String} [ref_time] - the reference time in AHK format; if unused, uses `A_NowUTC`
	 */
	time[ref_time := A_NowUTC] {
		get => DateAdd(ref_time, Integer(this.seconds), "Seconds")
		set => this.seconds := Integer(DateDiff(value, ref_time, "Seconds"))
	}
	
	/**
	 * The time string before this duration has elapsed.
	 * When getting, it subtracts the duration from the reference time.
	 * When setting, it sets the duration to the difference from the reference time.
	 * @type {String}
	 * @param {String} ref_time - the reference time in AHK format
	 */
	time_prior[ref_time := A_NowUTC] {
		get => DateAdd(ref_time, -Integer(this.seconds), "Seconds")
		set => this.seconds := Integer(DateDiff(ref_time, value, "Seconds"))
	}
	
	/**
	 * Sleeps for this duration.
	 * @returns {Duration} this
	 */
	Sleep() {
		Sleep(this.ms)
		return this
	}
	
	/**
	 * Internally changes the unit to another while keeping the duration equivalent.
	 * @param {String} toUnit - unit to convert to
	 * @returns {Number} the duration in the new units
	 */
	ChangeUnit(toUnit) {
		this.t := Duration.ConvertUnits(this.t, this.unit, toUnit)
		this.unit := this.NormalizeUnit(toUnit)
		return this.t
	}
	
	/**
	 * Gets the AHK time after this duration has elapsed from a reference time.
	 * Essentially adds the number of seconds to the reference time.
	 * @param {String} [ref_time=A_NowUTC] - reference AHK time string
	 * @returns {String}
	 */
	GetTimeAfter(ref_time := A_NowUTC) {
		return this.time[ref_time]
	}
	
	/**
	 * Sets the duration needed to elapse from now to reach a specific time.
	 * If the date occurs before now, the duration is negative.
	 * @param {String} [ref_time=A_NowUTC] - reference AHK time string
	 * @returns {Number} seconds to elapse
	 */
	SetTimeAfter(ref_time := A_NowUTC) {
		this.time[ref_time] := A_NowUTC
		return this.seconds
	}
	
	/**
	 * Gets the AHK time before this duration has elapsed to a reference time.
	 * Essentially subtracts the number of seconds from the reference time.
	 * @param {String} [ref_time=A_NowUTC] - reference AHK time string
	 * @returns {String}
	 */
	GetTimeBefore(ref_time := A_NowUTC) {
		return this.time_prior[ref_time]
	}
	
	/**
	 * Sets the duration needed to elapse from a specific time to reach now.
	 * If the date occurs before now, the duration is negative.
	 * @param {String} [ref_time=A_NowUTC] - reference AHK time string
	 * @returns {Number} seconds to elapse
	 */
	SetTimeBefore(ref_time := A_NowUTC) {
		this.time_prior[ref_time] := A_NowUTC
		return this.seconds
	}
	
	Add(args*) {
		return Duration.Add(this, args*)
	}
	Subtract(args*) {
		return Duration.Subtract(this, args*)
	}
	Multiply(args*) {
		return Duration.Multiply(this, args*)
	}
	Divide(args*) {
		return Duration.Divide(this, args*)
	}
	Equals(args*) {
		return Duration.Equals(this, args*)
	}
	GreaterThan(args*) {
		return Duration.GreaterThan(this, args*)
	}
	LessThan(args*) {
		return Duration.LessThan(this, args*)
	}
	Compare(args*) {
		return Duration.Compare(this, args*)
	}
	
	/**
	 * Resets the duration to 0 in the default units.
	 * @returns {Duration} this
	 */
	Clear() {
		this.t := 0
		this.unit := "Seconds"
		return this
	}
	
	/**
	 * Clones this instance.
	 * @returns {Duration} new instance
	 */
	Clone() {
		return Duration(this)
	}
	
	/**
	 * Returns the numeric representation of this instance.
	 * @returns {Number}
	 */
	ToNumber() {
		return this.t
	}
	
	/**
	 * Returns the boolean representation of this instance.
	 * @returns {Boolean} true if the duration is positive
	 */
	ToBoolean() {
		return this.t > 0
	}
	
	/**
	 * Serializes this instance to a string.
	 * @returns {String}
	 */
	ToString() {
		return String(this.t)
	}
	
	/**
	 * Formats this instance as a string in the form `hh:mm:ss[:ms]`.
	 * @returns {String}
	 */
	ToFormattedString() {
		return Duration.Format(this.seconds)
	}
	
	/**
	 * Serializes this instance to an array.
	 * @returns {Array}
	 */
	ToArray() {
		return [this.t, this.unit]
	}
	
	/**
	 * Serializes this instance to a JSON-ready value.
	 * @returns {Array}
	 */
	ToJSON() {
		return this.ToArray()
	}
	
	/**
	 * Instantiates Duration if the first parameter is not an instance already.
	 * @param {Duration|Number|String|Array} t
	 * @param {?String} [unit?]
	 * @returns {Duration}
	 */
	static Instance(t, unit?) {
		if (t is Duration) {
			return t
		} else {
			return Duration(t, unit?)
		}
	}
	
	/**
	 * Whether a value can be used to create a valid Duration instance.
	 * @param {Any} value
	 * @returns {Boolean}
	 */
	static CanParse(value) {
		if (value is Number) {
			return true
		} else if (value is String) {
			if (RegExMatch(value, AHK_TIME_REGEX)) {
				return true
			} else {
				return this.Parse(value) != 0
			}
		} else if (value is Array) {
			return value.Length >= 2 and Mod(value.Length, 2) = 0 and value[1] is Number and value[2] is String
		} else if (value is Time) {
			return true
		} else if (value is Duration) {
			return true
		} else if (value is Object) {
			return (value.HasOwnProp("value") or value.HasOwnProp("t")) and (value.HasOwnProp("unit") or value.HasOwnProp("u"))
		} else {
			return false
		}
	}
	
	/**
	 * Combines two durations.
	 * The result will always be in `DEFAULT_UNIT`.
	 * @param {Number|String|Array|Duration} dur1
	 * @param {Number|String|Array|Duration} dur2
	 * @returns {Duration}
	 */
	static Add(dur1, dur2) {
		dur1 := this.Instance(dur1)
		dur2 := this.Instance(dur2)
		t1 := this.ConvertUnits(dur1.t, dur1.unit, this.DEFAULT_UNIT)
		t2 := this.ConvertUnits(dur2.t, dur2.unit, this.DEFAULT_UNIT)
		return Duration(t1 + t2, this.DEFAULT_UNIT)
	}
	
	/**
	 * Gets the difference between two durations.
	 * The result will always be in `DEFAULT_UNIT`.
	 * @param {Number|String|Array|Duration} dur1
	 * @param {Number|String|Array|Duration} dur2
	 * @returns {Duration}
	 */
	static Subtract(dur1, dur2) {
		dur1 := this.Instance(dur1)
		dur2 := this.Instance(dur2)
		t1 := this.ConvertUnits(dur1.t, dur1.unit, this.DEFAULT_UNIT)
		t2 := this.ConvertUnits(dur2.t, dur2.unit, this.DEFAULT_UNIT)
		return Duration(t1 - t2, this.DEFAULT_UNIT)
	}
	
	/**
	 * Multiplies two durations. Seconds is the base factor, so a minute multiplying seconds would multiply by 60.
	 * The result will always be in `DEFAULT_UNIT`.
	 * @param {Number|String|Array|Duration} dur1
	 * @param {Number|String|Array|Duration} dur2
	 * @returns {Duration}
	 */
	static Multiply(dur1, dur2) {
		dur1 := this.Instance(dur1)
		dur2 := this.Instance(dur2)
		t1 := this.ConvertUnits(dur1.t, dur1.unit, this.DEFAULT_UNIT)
		t2 := this.ConvertUnits(dur2.t, dur2.unit, this.DEFAULT_UNIT)
		return Duration(t1 * t2, this.DEFAULT_UNIT)
	}
	
	/**
	 * Divides a duration by another. Seconds is the base factor, so dividing hours by minutes is dividing them by 60 (minutes per hour).
	 * The result will always be in `DEFAULT_UNIT`.
	 * @param {Number|String|Array|Duration} dur1
	 * @param {Number|String|Array|Duration} dur2
	 * @returns {Duration}
	 */
	static Divide(dur1, dur2) {
		dur1 := this.Instance(dur1)
		dur2 := this.Instance(dur2)
		t1 := this.ConvertUnits(dur1.t, dur1.unit, this.DEFAULT_UNIT)
		t2 := this.ConvertUnits(dur2.t, dur2.unit, this.DEFAULT_UNIT)
		return Duration(t1 / t2, this.DEFAULT_UNIT)
	}
	
	/**
	 * Checks for equality between two durations.
	 * @param {Number|String|Array|Duration} dur1
	 * @param {Number|String|Array|Duration} dur2
	 * @returns {Boolean}
	 */
	static Equals(dur1, dur2) {
		dur1 := this.Instance(dur1)
		dur2 := this.Instance(dur2)
		t1 := this.ConvertUnits(dur1.t, dur1.unit, this.DEFAULT_UNIT)
		t2 := this.ConvertUnits(dur2.t, dur2.unit, this.DEFAULT_UNIT)
		return t1 = t2
	}
	
	/**
	 * Checks for the first duration being shorter than the second.
	 * @param {Number|String|Array|Duration} dur1
	 * @param {Number|String|Array|Duration} dur2
	 * @returns {Boolean}
	 */
	static LessThan(dur1, dur2) {
		dur1 := this.Instance(dur1)
		dur2 := this.Instance(dur2)
		t1 := this.ConvertUnits(dur1.t, dur1.unit, this.DEFAULT_UNIT)
		t2 := this.ConvertUnits(dur2.t, dur2.unit, this.DEFAULT_UNIT)
		return t1 < t2
	}
	
	/**
	 * Checks for the first duration being longer than the second.
	 * @param {Number|String|Array|Duration} dur1
	 * @param {Number|String|Array|Duration} dur2
	 * @returns {Boolean}
	 */
	static GreaterThan(dur1, dur2) {
		dur1 := this.Instance(dur1)
		dur2 := this.Instance(dur2)
		t1 := this.ConvertUnits(dur1.t, dur1.unit, this.DEFAULT_UNIT)
		t2 := this.ConvertUnits(dur2.t, dur2.unit, this.DEFAULT_UNIT)
		return t1 > t2
	}
	
	/**
	 * Compares the first duration with the second.
	 * @param {Number|String|Array|Duration} dur1
	 * @param {Number|String|Array|Duration} dur2
	 * @returns {Number} -1 if the first duration is shorter, 1 if it is longer, 0 if it is equal
	 */
	static Compare(dur1, dur2) {
		dur1 := this.Instance(dur1)
		dur2 := this.Instance(dur2)
		t1 := this.ConvertUnits(dur1.t, dur1.unit, this.DEFAULT_UNIT)
		t2 := this.ConvertUnits(dur2.t, dur2.unit, this.DEFAULT_UNIT)
		return t1 < t2 ? -1 : t2 > t1 ?  1 : 0
	}
	
	/**
	 * Returns a random duration between two durations.
	 * @param {Number|String|Array|Duration} [dur1=0]
	 * @param {Number|String|Array|Duration} [dur2=999ms]
	 * @returns {Duration}
	 */
	static Random(dur1 := 0, dur2 := [999,"ms"]) {
		dur1 := this.Instance(dur1)
		dur2 := this.Instance(dur2)
		t1 := this.ConvertUnits(dur1.t, dur1.unit, this.DEFAULT_UNIT)
		t2 := this.ConvertUnits(dur2.t, dur2.unit, this.DEFAULT_UNIT)
		return Duration(Random(t1, t2), this.DEFAULT_UNIT)
	}
	
	/**
	 * Formats a duration in seconds as `[hh:]mm:ss[.ms]`.
	 * Floating-point duration will be truncated to the nearest thousandth of a second.
	 * Source: https://www.autohotkey.com/docs/v2/lib/FormatTime.htm#ExFormatSec
	 * @param {Number|Duration} t
	 * @returns {String}
	 */
	static Format(t) {
		if (t is Duration) {
			t := t.seconds
		}
		Assert(t is Number, "Parameter #1 must be a Number")
		sign := t < 0 ? -1 : 1
		t := Abs(t)
		hours := Integer(t) // 3600
		str := ""
		str .= sign = -1 ? "-" : ""
		str .= hours ? (hours . ":") : ""
		str .= FormatTime(DateAdd(Time.GetDate(), Integer(t), "Seconds"), "mm:ss")
		str .= IsFloat(t) ? Format(".{:03}", Floor(1000*(t-Floor(t)))) : ""
		return str
	}
	
	/**
	 * Parses a string or array as a series of duration values and units.
	 * @param {String|Array} value - duration string (not an AHK time string) or array of values and units
	 * @param {String} [unit=Duration.DEFAULT_UNIT] - unit to convert to
	 */
	static Parse(value, unitOut := this.DEFAULT_UNIT) {
		if (value is String) {
			value := StrSplit(value, "\s+")
		}
		t := 0
		idx := 1
		while (idx < value.Length) {
			if (value[idx] is Number) {
				t += this.ConvertUnits(Number(value[idx]), String(value[idx+1]), unitOut)
				idx += 2
			} else {
				RegExMatch(value[idx], "\d+", &val)
				RegExMatch(value[idx], "\w+", &unit)
				t += this.ConvertUnits(Number(val), unit, unitOut)
				idx++
			}
		}
		return t
	}
	
	/**
	 * De-aliases a unit of time to a preferred name. Example, `secs` becomes `Seconds`.
	 * @param {String} unit - unit of time
	 * @returns {String}
	 */
	static NormalizeUnit(unit) {
		switch unit, 0 {
			case "w","wk","wks","week","weeks":
				return "Weeks"
			case "d","day","days":
				return "Days"
			case "h","hr","hrs","hour","hours":
				return "Hours"
			case "m","min","mins","minute","minutes":
				return "Minutes"
			case "s","sec","secs","second","seconds":
				return "Seconds"
			case "ms","milli","millis","millisecond","milliseconds":
				return "Milliseconds"
			default:
				throw ValueError("Invalid unit of time",, unit)
		}
	}
	
	/**
	 * Converts an amount of time from one unit to another.
	 * @param {Number} amount - amount to convert
	 * @param {String} fromUnit - the unit of time of the amount
	 * @param {String} [toUnit] - the unit of time to convert to
	 * @returns {Number}
	 */
	static ConvertUnits(amount, fromUnit, toUnit := "Seconds") {
		static UnitOrder := ["Milliseconds","Seconds","Minutes","Hours","Days","Weeks"]
		static UnitScale := [1,1000,60,60,24,7]
		unitIdx := UnitOrder.IndexOf(this.NormalizeUnit(fromUnit))
		if (not unitIdx) {
			return 0
		}
		targetIdx := UnitOrder.IndexOf(this.NormalizeUnit(toUnit))
		if (not targetIdx) {
			return 0
		}
		while (unitIdx != targetIdx) {
			if (unitIdx < targetIdx) {
				amount /= UnitScale[++unitIdx]
			} else {
				amount *= UnitScale[unitIdx--]
			}
		}
		return amount
	}
	
	/**
	 * Converts an amount of time from one unit to milliseconds.
	 * @param {Number} amount - input amount of time
	 * @param {String} [unit="Seconds"] - unit of time of the input
	 * @returns {Number}
	 */
	static ToMilliseconds(amount, unit := "Seconds") {
		Assert(amount is Number, "Parameter #1 must be a Number")
		Assert(unit is String, "Parameter #2 must be a String")
		return this.ConvertUnits(amount, unit, "Milliseconds")
	}
	
	/**
	 * Converts an amount of time from milliseconds to another unit.
	 * @param {Number} amount - input amount of time
	 * @param {String} [unit="Seconds"] - unit of time of the output
	 * @returns {Number}
	 */
	static FromMilliseconds(amount, unit := "Seconds") {
		Assert(amount is Number, "Parameter #1 must be a Number")
		Assert(unit is String, "Parameter #2 must be a String")
		return this.ConvertUnits(amount, "Milliseconds", unit)
	}
	
	/**
	 * Converts an amount of time from one unit to seconds.
	 * @param {Number} amount - input amount of time
	 * @param {String} [unit="Seconds"] - unit of time of the input
	 * @returns {Number}
	 */
	static ToSeconds(amount, unit := "Seconds") {
		Assert(amount is Number, "Parameter #1 must be a Number")
		Assert(unit is String, "Parameter #2 must be a String")
		return this.ConvertUnits(amount, unit, "Seconds")
	}
	
	/**
	 * Converts an amount of time from seconds to another unit.
	 * @param {Number} amount - input amount of time
	 * @param {String} [unit="Seconds"] - unit of time of the output
	 * @returns {Number}
	 */
	static FromSeconds(amount, unit := "Seconds") {
		Assert(amount is Number, "Parameter #1 must be a Number")
		Assert(unit is String, "Parameter #2 must be a String")
		return this.ConvertUnits(amount, "Seconds", unit)
	}
	
	/**
	 * Converts an amount of time from one unit to minutes.
	 * @param {Number} amount - input amount of time
	 * @param {String} [unit="Seconds"] - unit of time of the input
	 * @returns {Number}
	 */
	static ToMinutes(amount, unit := "Seconds") {
		Assert(amount is Number, "Parameter #1 must be a Number")
		Assert(unit is String, "Parameter #2 must be a String")
		return this.ConvertUnits(amount, unit, "Minutes")
	}
	
	/**
	 * Converts an amount of time from minutes to another unit.
	 * @param {Number} amount - input amount of time
	 * @param {String} [unit="Seconds"] - unit of time of the output
	 * @returns {Number}
	 */
	static FromMinutes(amount, unit := "Seconds") {
		Assert(amount is Number, "Parameter #1 must be a Number")
		Assert(unit is String, "Parameter #2 must be a String")
		return this.ConvertUnits(amount, "Minutes", unit)
	}
	
	/**
	 * Converts an amount of time from one unit to hours.
	 * @param {Number} amount - input amount of time
	 * @param {String} [unit="Seconds"] - unit of time of the input
	 * @returns {Number}
	 */
	static ToHours(amount, unit := "Seconds") {
		Assert(amount is Number, "Parameter #1 must be a Number")
		Assert(unit is String, "Parameter #2 must be a String")
		return this.ConvertUnits(amount, unit, "Hours")
	}
	
	/**
	 * Converts an amount of time from hours to another unit.
	 * @param {Number} amount - input amount of time
	 * @param {String} [unit="Seconds"] - unit of time of the output
	 * @returns {Number}
	 */
	static FromHours(amount, unit := "Seconds") {
		Assert(amount is Number, "Parameter #1 must be a Number")
		Assert(unit is String, "Parameter #2 must be a String")
		return this.ConvertUnits(amount, "Hours", unit)
	}
	
	/**
	 * Converts an amount of time from one unit to days.
	 * @param {Number} amount - input amount of time
	 * @param {String} [unit="Seconds"] - unit of time of the input
	 * @returns {Number}
	 */
	static ToDays(amount, unit := "Seconds") {
		Assert(amount is Number, "Parameter #1 must be a Number")
		Assert(unit is String, "Parameter #2 must be a String")
		return this.ConvertUnits(amount, unit, "Days")
	}
	
	/**
	 * Converts an amount of time from days to another unit.
	 * @param {Number} amount - input amount of time
	 * @param {String} [unit="Seconds"] - unit of time of the output
	 * @returns {Number}
	 */
	static FromDays(amount, unit := "Seconds") {
		Assert(amount is Number, "Parameter #1 must be a Number")
		Assert(unit is String, "Parameter #2 must be a String")
		return this.ConvertUnits(amount, "Days", unit)
	}
	
	/**
	 * Converts an amount of time from one unit to weeks.
	 * @param {Number} amount - input amount of time
	 * @param {String} [unit="Seconds"] - unit of time of the input
	 * @returns {Number}
	 */
	static ToWeeks(amount, unit := "Seconds") {
		Assert(amount is Number, "Parameter #1 must be a Number")
		Assert(unit is String, "Parameter #2 must be a String")
		return this.ConvertUnits(amount, unit, "Weeks")
	}
	
	/**
	 * Converts an amount of time from weeks to another unit.
	 * @param {Number} amount - input amount of time
	 * @param {String} [unit="Seconds"] - unit of time of the output
	 * @returns {Number}
	 */
	static FromWeeks(amount, unit := "Seconds") {
		Assert(amount is Number, "Parameter #1 must be a Number")
		Assert(unit is String, "Parameter #2 must be a String")
		return this.ConvertUnits(amount, "Weeks", unit)
	}
}