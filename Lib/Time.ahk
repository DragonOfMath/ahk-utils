#Requires AutoHotkey >=2.0
#Include <Error>

/**
 * @name        Time.ahk
 * @description Utility for granular time and date manipulation.
 * @version     1.21-2026.03.19
 * @requires    Autohotkey >= 2.0
 * @license     GNU GPLv3
 * Changelog:
 * v1.3 - 
 * v1.2 - made DayName and MonthName settable
 * v1.1 - allow DateMin, DateMax, and DateCompare to work with unset parameters
 * v1.0 - initial release
 */

global tSeconds := 1000
global tMinutes := 60 * tSeconds
global tHours := 60 * tMinutes
global tDays := 24 * tHours

global AHK_TIME_REGEX := "^\d{14}$"
global TIMEZONE_OFFSET := DateDiff(A_Now, A_NowUTC, "Hours")

Seconds(s) {
	return Integer(s * tSeconds)
}
Minutes(m) {
	return Integer(m * tMinutes)
}
Hours(h) {
	return Integer(h * tHours)
}
Days(d) {
	return Integer(d * tDays)
}

global MonthsOfTheYear := {
	January: 1,
	February: 2,
	March: 3,
	April: 4,
	May: 5,
	June: 6,
	July: 7,
	August: 8,
	September: 9,
	October: 10,
	November: 11,
	December: 12
}

global DaysOfTheWeek := {
	Sunday: 1,
	Monday: 2,
	Tuesday: 3,
	Wednesday: 4,
	Thursday: 5,
	Friday: 6,
	Saturday: 7
}

/**
 * Gets the earlier of two dates.
 * @param {String} dateA
 * @param {String} dateB
 * @param {String} [unit="Seconds"]
 * @returns {String}
 */
DateMin(dateA := "", dateB := "", unit := "Seconds") {
	dateA := dateA or A_NowUTC
	dateB := dateB or A_NowUTC
	return DateDiff(dateA, dateB, unit) > 0 ? dateB : dateA
}

/**
 * Gets the later of two dates.
 * @param {String} dateA
 * @param {String} dateB
 * @param {String} [unit="Seconds"]
 * @returns {String}
 */
DateMax(dateA := "", dateB := "", unit := "Seconds") {
	dateA := dateA or A_NowUTC
	dateB := dateB or A_NowUTC
	return DateDiff(dateA, dateB, unit) > 0 ? dateA : dateB
}

/**
 * Compares two AHK time strings by diffing them by their unit.
 * For more precise comparison, use `Time.Compare`
 * @param {String} dateA
 * @param {String} dateB
 * @param {String} [unit="Seconds"]
 * @returns {String} -1 if the first time takes place earlier than the second, 1 if it takes place later, and 0 if they are equal
 */
DateCompare(time1 := "", time2 := "", unit := "Seconds") {
	time1 := time1 or A_NowUTC
	time2 := time2 or A_NowUTC
	result := DateDiff(time1, time2, unit)
	switch {
		case result < 0: return -1
		case result > 0: return 1
		default: return 0
	}
}

/**
 * Time class for creating and manipulating AHK time strings more easily.
 * TODO: add UNIX epoch conversion
 * TODO: allow any locale month/day name conversion
 * @class {Time}
 */
class Time {
	
	/**
	 * The AHK time string assigned to this Time instance and which can be manipulated by methods.
	 * @see {https://www.autohotkey.com/docs/v2/lib/FileSetTime.htm#YYYYMMDD}
	 * @type {String}
	 */
	ahk_time := ""
	
	/**
	 * Time constructor.
	 * @param {?String} [ahk_time=A_Now] - an AHK time string, which defaults to the current local time stored in A_Now
	 * @constructor
	 */
	__New(ahk_time := A_Now) {
		this.ahk_time := ahk_time
		return this
	}
	
	/**
	 * Getter/setter for the year.
	 * @type {Number}
	 */
	Year {
		get => Time.GetYear(this.ahk_time)
		set => this.ahk_time := Time.SetYear(this.ahk_time, value)
	}
	
	/**
	 * Getter/setter for the month.
	 * @type {Number}
	 */
	Month {
		get => Time.GetMonth(this.ahk_time)
		set => this.ahk_time := Time.SetMonth(this.ahk_time, value)
	}
	
	/**
	 * Getter/setter for the day of the month.
	 * @type {Number}
	 */
	Day {
		get => Time.GetDay(this.ahk_time)
		set => this.ahk_time := Time.SetDay(this.ahk_time, value)
	}
	
	/**
	 * Getter/setter for the hour.
	 * @type {Number}
	 */
	Hour {
		get => Time.GetHour(this.ahk_time)
		set => this.ahk_time := Time.SetHour(this.ahk_time, value)
	}
	
	/**
	 * Getter/setter for the minute.
	 * @type {Number}
	 */
	Minute {
		get => Time.GetMinute(this.ahk_time)
		set => this.ahk_time := Time.SetMinute(this.ahk_time, value)
	}
	
	/**
	 * Getter/setter for the second.
	 * @type {Number}
	 */
	Second {
		get => Time.GetSecond(this.ahk_time)
		set => this.ahk_time := Time.SetSecond(this.ahk_time, value)
	}
	
	/**
	 * Getter/setter for the date substring.
	 * @type {String}
	 */
	Date {
		get => Time.GetDate(this.ahk_time)
		set => this.ahk_time := Time.SetDate(this.ahk_time, value)
	}
	
	/**
	 * Getter/setter for the time substring.
	 * @type {String}
	 */
	Time {
		get => Time.GetTime(this.ahk_time)
		set => this.ahk_time := Time.SetTime(this.ahk_time, value)
	}
	
	/**
	 * Getter/setter for the day of the week. (1 = Sunday, 7 = Saturday)
	 * @type {Number}
	 */
	DayOfWeek {
		get => Time.GetDayOfWeek(this.ahk_time)
		set => this.ahk_time := Time.SetDayOfWeek(this.ahk_time, value)
	}
	
	/**
	 * Getter/setter for the day of the year. (1 = January 1st, 365 (or 366 during a leap year) = December 31st)
	 * @type {Number}
	 */
	DayOfYear {
		get => Time.GetDayOfYear(this.ahk_time)
		set => this.ahk_time := Time.SetDayOfYear(this.ahk_time, value)
	}
	
	/**
	 * Getter/setter for the month name.
	 * @type {String}
	 */
	MonthName {
		get => Time.GetMonthName(this.ahk_time)
		set => this.ahk_time := Time.SetMonth(this.ahk_time, value)
	}
	
	/**
	 * Getter/setter for the weekday name.
	 * @type {String}
	 */
	DayName {
		get => Time.GetDayName(this.ahk_time)
		set => this.ahk_time := Time.SetDayOfWeek(this.ahk_time, value)
	}
	
	/**
	 * Whether the time stored is during a leap year.
	 * @type {Boolean}
	 * @readonly
	 */
	IsLeapYear => Time.IsLeapYear(this.ahk_time)
	
	/**
	 * Compares this instance with another instance to determine which comes sooner.
	 * @returns {Number} -1 if this comes before the other, 1 if it comes after, 0 if they are the same
	 */
	Compare(t) {
		if (not (t is Time)) {
			t := Time(t)
		}
		__Compare(a, b) {
			return a < b ? -1 : 
				   a > b ?  1 : 0
		}
		return __Compare(this.ahk_time, t.ahk_time)
		/*
		return __Compare(this.Year,   t.Year) or 
			   __Compare(this.Month,  t.Month) or 
			   __Compare(this.Day,    t.Day) or 
			   __Compare(this.Hour,   t.Hour) or 
			   __Compare(this.Minute, t.Minute) or 
			   __Compare(this.Second, t.Second)
		*/
	}
	
	/**
	 * Converts this instance to UTC time.
	 * @returns {Time} this
	 */
	ToUTC() {
		this.Hour -= TIMEZONE_OFFSET
		return this
	}
	
	/**
	 * Converts this instance to local time.
	 * @returns {Time} this
	 */
	ToLocal() {
		this.Hour += TIMEZONE_OFFSET
		return this
	}
	
	/**
	 * Serializes to the AHK time string.
	 * @returns {String}
	 */
	ToString() {
		return this.ahk_time
	}
	
	/**
	 * Serializes to the AHK time integer.
	 * @returns {Number}
	 */
	ToNumber() {
		return Integer(this.ahk_time)
	}
	
	/**
	 * Serializes the instance to a JSON-ready value.
	 * Mainly used by `JSON.ahk`.
	 * @returns {String}
	 */
	ToJSON() {
		return this.ahk_time
	}
	
	/**
	 * Creates a formatted string of the date.
	 * @param {String} [fmt] - custom format to use, defaults to 'yyyy-MM-dd'
	 * @returns {String}
	 */
	ToFormattedDate(fmt := "yyyy-MM-dd") {
		return Time.ToFormattedDate(this.ahk_time, fmt)
	}
	
	/**
	 * Creates a formatted string of the time.
	 * @param {String} [fmt] - custom format to use, defaults to 'HH:mm:ss'
	 * @returns {String}
	 */
	ToFormattedTime(fmt := "HH:mm:ss") {
		return Time.ToFormattedTime(this.ahk_time, fmt)
	}
	
	/**
	 * Creates a formatted string of the date and time.
	 * @param {String} [fmt] - custom format to use, defaults to 'yyyy-MM-dd HH:mm:ss'
	 * @returns {String}
	 */
	ToFormattedDateTime(fmt := "yyyy-MM-dd HH:mm:ss") {
		return Time.ToFormattedDateTime(this.ahk_time, fmt)
	}
	
	/**
	 * Gets the date portion of an AHK time string.
	 * @param {String} [ahk_time=A_Now]
	 * @returns {String}
	 */
	static GetDate(ahk_time := A_Now) {
		if (not (ahk_time is String))
			ahk_time := ahk_time.ToString()
		return SubStr(ahk_time, 1, 8) ;FormatTime(ahk_time, "yyyyMMdd")
	}
	
	/**
	 * Sets the date portion of an AHK time string to another date.
	 * @param {String} [ahk_time=A_Now]
	 * @param {String} date
	 * @returns {String}
	 */
	static SetDate(ahk_time := A_Now, date := A_Now) {
		if (not (ahk_time is String))
			ahk_time := ahk_time.ToString()
		return SubStr(date, 1, 8) . SubStr(ahk_time, 9)
	}
	
	/**
	 * Gets the time portion of an AHK time string.
	 * If an incomplete string is passed, it assumes the time is 000000.
	 * @param {String} [ahk_time=A_Now]
	 * @returns {String}
	 */
	static GetTime(ahk_time := A_Now) {
		if (not (ahk_time is String))
			ahk_time := ahk_time.ToString()
		return SubStr(ahk_time, 9) or "000000" ;FormatTime(ahk_time, "HHmmss")
	}
	
	/**
	 * Sets the time portion of an AHK time string to another time.
	 * @param {String} [ahk_time=A_Now]
	 * @param {String} time
	 * @returns {String}
	 */
	static SetTime(ahk_time := A_Now, time := A_Now) {
		if (not (ahk_time is String))
			ahk_time := ahk_time.ToString()
		return SubStr(ahk_time, 1, 8) . SubStr(time, -6)
	}
	
	/**
	 * Gets the year of an AHK time string.
	 * @param {String} [ahk_time=A_Now]
	 * @returns {Number}
	 */
	static GetYear(ahk_time := A_Now) {
		if (not (ahk_time is String))
			ahk_time := ahk_time.ToString()
		return Number(FormatTime(ahk_time, "yyyy"))
	}
	
	/**
	 * Sets the year of an AHK time string to another value.
	 * @param {String} [ahk_time=A_Now]
	 * @param {Number} year
	 * @returns {String}
	 */
	static SetYear(ahk_time := A_Now, year := A_Year) {
		if (not (ahk_time is String))
			ahk_time := ahk_time.ToString()
		if (year < 1601 or year > 9999)
			throw ValueError("Year out of range (1601-9999)",, year)
		return Format("{:04}", year) . SubStr(ahk_time, 5)
	}
	
	/**
	 * Modifies the year by an integer amount.
	 * @param {String} [ahk_time=A_Now]
	 * @param {Number} [years=1] - how much to change the year by
	 * @returns {String}
	 */
	static ModYear(ahk_time := A_Now, years := 1) {
		if (not (ahk_time is String))
			ahk_time := ahk_time.ToString()
		return this.SetYear(ahk_time, this.GetYear(ahk_time) + years)
	}
	
	/**
	 * Gets the month of an AHK time string.
	 * @param {String} [ahk_time=A_Now]
	 * @returns {Number}
	 */
	static GetMonth(ahk_time := A_Now) {
		if (not (ahk_time is String))
			ahk_time := ahk_time.ToString()
		return Number(FormatTime(ahk_time, "M"))
	}
	
	/**
	 * Sets the month of an AHK time string to another value.
	 * @param {String} [ahk_time=A_Now]
	 * @param {Number|String} month - index or English name of the month
	 * @returns {String}
	 */
	static SetMonth(ahk_time := A_Now, month := A_MM) {
		if (not (ahk_time is String))
			ahk_time := ahk_time.ToString()
		if (month is String) {
			if (MonthsOfTheYear.HasOwnProp(month)) {
				month := MonthsOfTheYear.%month%
			} else {
				throw ValueError("Invalid month name",, month)
			}
		}
		if (month < 1 or month > 12)
			throw ValueError("Month out of range (1-12)",, month)
		return SubStr(ahk_time, 1, 4) . Format("{:02}", month) . SubStr(ahk_time, 7)
	}
	
	/**
	 * Modifies the month by an integer amount.
	 * @param {String} [ahk_time=A_Now]
	 * @param {Number} [months=1] - how much to change the month by
	 * @returns {String}
	 */
	static ModMonth(ahk_time := A_Now, months := 1) {
		if (not (ahk_time is String))
			ahk_time := ahk_time.ToString()
		return this.SetMonth(ahk_time, this.GetMonth(ahk_time) + months)
	}
	
	/**
	 * Gets the day of the month of an AHK time string.
	 * @param {String} [ahk_time=A_Now]
	 * @returns {Number}
	 */
	static GetDay(ahk_time := A_Now) {
		if (not (ahk_time is String))
			ahk_time := ahk_time.ToString()
		return Number(FormatTime(ahk_time, "d"))
	}
	
	/**
	 * Sets the day of the month of an AHK time string to another value.
	 * If the value is negative, it goes back that many days into the month(s) before.
	 * If the value exceeds the number of days in that month, it goes into the month(s) after.
	 * @param {String} [ahk_time=A_Now]
	 * @param {Number} day
	 * @returns {String}
	 */
	static SetDay(ahk_time := A_Now, day := A_DD) {
		if (not (ahk_time is String))
			ahk_time := ahk_time.ToString()
		return DateAdd(ahk_time, day - this.GetDay(ahk_time), "Days")
	}
	
	/**
	 * Modifies the day by an integer amount.
	 * @param {String} [ahk_time=A_Now]
	 * @param {Number} [days=1] - how much to change the day by
	 * @returns {String}
	 */
	static ModDay(ahk_time := A_Now, days := 1) {
		if (not (ahk_time is String))
			ahk_time := ahk_time.ToString()
		return this.SetDay(ahk_time, this.GetDay(ahk_time) + days)
	}
	
	/**
	 * Gets the hour of an AHK time string.
	 * @param {String} [ahk_time=A_Now]
	 * @returns {Number}
	 */
	static GetHour(ahk_time := A_Now) {
		if (not (ahk_time is String))
			ahk_time := ahk_time.ToString()
		return Number(FormatTime(ahk_time, "H"))
	}
	
	/**
	 * Sets the hour of an AHK time string to another value.
	 * If the value is negative, it goes back that many hours into the previous day(s).
	 * If the value is greater than 23, it goes into the next day(s).
	 * @param {String} [ahk_time=A_Now]
	 * @param {Number} hour
	 * @returns {String}
	 */
	static SetHour(ahk_time := A_Now, hour := A_Hour) {
		if (not (ahk_time is String))
			ahk_time := ahk_time.ToString()
		return DateAdd(ahk_time, hour - this.GetHour(ahk_time), "Hours")
	}
	
	/**
	 * Modifies the hour by an integer amount.
	 * @param {String} [ahk_time=A_Now]
	 * @param {Number} [hours=1] - how much to change the hour by
	 * @returns {String}
	 */
	static ModHour(ahk_time := A_Now, hours := 1) {
		if (not (ahk_time is String))
			ahk_time := ahk_time.ToString()
		return this.SetHour(ahk_time, this.GetHour(ahk_time) + hours)
	}
	
	/**
	 * Gets the minute of an AHK time string.
	 * @param {String} [ahk_time=A_Now]
	 * @returns {Number}
	 */
	static GetMinute(ahk_time := A_Now) {
		if (not (ahk_time is String))
			ahk_time := ahk_time.ToString()
		return Number(FormatTime(ahk_time, "m"))
	}
	
	/**
	 * Sets the minute of an AHK time string to another value.
	 * If the value is negative, it goes back that many minutes into the previous hour(s).
	 * If the value is greater than 59, it goes into the next hour(s).
	 * @param {String} [ahk_time=A_Now]
	 * @param {Number} minute
	 * @returns {String}
	 */
	static SetMinute(ahk_time := A_Now, minute := A_Min) {
		if (not (ahk_time is String))
			ahk_time := ahk_time.ToString()
		return DateAdd(ahk_time, minute - this.GetMinute(ahk_time), "Minutes")
	}
	
	/**
	 * Modifies the minute by an integer amount.
	 * @param {String} [ahk_time=A_Now]
	 * @param {Number} [mins=1] - how much to change the minutes by
	 * @returns {String}
	 */
	static ModMinute(ahk_time := A_Now, mins := 1) {
		if (not (ahk_time is String))
			ahk_time := ahk_time.ToString()
		return this.SetMinute(ahk_time, this.GetMinute(ahk_time) + mins)
	}
	
	/**
	 * Gets the second of an AHK time string.
	 * @param {String} [ahk_time=A_Now]
	 * @returns {Number}
	 */
	static GetSecond(ahk_time := A_Now) {
		if (not (ahk_time is String))
			ahk_time := ahk_time.ToString()
		return Number(FormatTime(ahk_time, "s"))
	}
	
	/**
	 * Sets the second of an AHK time string to another value.
	 * If the value is negative, it goes back that many seconds into the previous minute(s).
	 * If the value is greater than 59, it goes into the next minute(s).
	 * @param {String} [ahk_time=A_Now]
	 * @param {Number} second
	 * @returns {String}
	 */
	static SetSecond(ahk_time := A_Now, second := A_Sec) {
		if (not (ahk_time is String))
			ahk_time := ahk_time.ToString()
		return DateAdd(ahk_time, second - this.GetSecond(ahk_time), "Seconds")
	}
	
	/**
	 * Modifies the second by an integer amount.
	 * @param {String} [ahk_time=A_Now]
	 * @param {Number} [secs=1] - how much to change the seconds by
	 * @returns {String}
	 */
	static ModSecond(ahk_time := A_Now, secs := 1) {
		if (not (ahk_time is String))
			ahk_time := ahk_time.ToString()
		return this.SetSecond(ahk_time, this.GetSecond(ahk_time) + secs)
	}
	
	/**
	 * Gets the full month name of the AHK time string in the current locale.
	 * @param {String} [ahk_time=A_Now]
	 * @returns {String}
	 */
	static GetMonthName(ahk_time := A_Now) {
		if (not (ahk_time is String))
			ahk_time := ahk_time.ToString()
		return FormatTime(ahk_time, "MMMM")
	}
	
	/**
	 * Gets the full day name of the AHK time string in the current locale.
	 * @param {String} [ahk_time=A_Now]
	 * @returns {String}
	 */
	static GetDayName(ahk_time := A_Now) {
		if (not (ahk_time is String))
			ahk_time := ahk_time.ToString()
		return FormatTime(ahk_time, "dddd")
	}
	
	/**
	 * Gets the day index in the week of the AHK time string.
	 * @param {String} [ahk_time=A_Now]
	 * @returns {Number}
	 */
	static GetDayOfWeek(ahk_time := A_Now) {
		if (not (ahk_time is String))
			ahk_time := ahk_time.ToString()
		return Number(FormatTime(ahk_time, "WDay"))
	}
	
	/**
	 * Sets the day index in the week of the AHK time string.
	 * @param {String} [ahk_time=A_Now]
	 * @param {Number|String} dow - index or English name of the day, starting with 1 = Sunday
	 * @returns {String}
	 */
	static SetDayOfWeek(ahk_time := A_Now, dow := A_DDDD) {
		if (not (ahk_time is String))
			ahk_time := ahk_time.ToString()
		if (dow is String) {
			if (DaysOfTheWeek.HasOwnProp(dow)) {
				dow := DaysOfTheWeek.%dow%
			} else {
				throw ValueError("Invalid day name",, dow)
			}
		}
		if (dow < 1 or dow > 7)
			throw ValueError("Day of the week out of range (1-7)",, dow)
		return DateAdd(ahk_time, dow - this.GetDayOfWeek(ahk_time), "Days")
	}
	
	/**
	 * Gets the day index in the year of the AHK time string.
	 * @param {String} [ahk_time=A_Now]
	 * @returns {Number}
	 */
	static GetDayOfYear(ahk_time := A_Now) {
		if (not (ahk_time is String))
			ahk_time := ahk_time.ToString()
		return Number(FormatTime(ahk_time, "YDay"))
	}
	
	/**
	 * Sets the day index in the year of the AHK time string.
	 * @param {String} [ahk_time=A_Now]
	 * @param {Number} doy - the day of the year as an index
	 * @returns {String}
	 */
	static SetDayOfYear(ahk_time := A_Now, doy := A_YDay) {
		if (not (ahk_time is String))
			ahk_time := ahk_time.ToString()
		limit := this.IsLeapYear(ahk_time) ? 366 : 365
		if (doy < 1 or doy > limit)
			throw ValueError("Day of the year out of range (1-" . limit . ")",, doy)
		return DateAdd(ahk_time, doy - this.GetDayOfYear(ahk_time), "Days")
	}
	
	/**
	 * Gets the week index in the year of the AHK time string.
	 * @param {String} [ahk_time=A_Now]
	 * @returns {Number}
	 */
	static GetWeekOfYear(ahk_time := A_Now) {
		if (not (ahk_time is String))
			ahk_time := ahk_time.ToString()
		return FormatTime(ahk_time, "YWeek")
	}
	
	/**
	 * Whether the year in the AHK time string is a leap year.
	 * @param {String} [ahk_time=A_Now]
	 * @returns {Boolean}
	 */
	static IsLeapYear(ahk_time := A_Now) {
		if (not (ahk_time is String))
			ahk_time := ahk_time.ToString()
		return (Mod(this.GetYear(ahk_time), 4) = 0)
	}
	
	/**
	 * Creates a formatted string of the date.
	 * @param {String} [ahk_time=A_Now]
	 * @param {String} [fmt] - custom format to use, defaults to 'yyyy-MM-dd'
	 * @returns {String}
	 */
	static ToFormattedDate(ahk_time := A_Now, fmt := "yyyy-MM-dd") {
		if (not (ahk_time is String))
			ahk_time := ahk_time.ToString()
		return FormatTime(ahk_time, fmt)
	}
	
	/**
	 * Creates a formatted string of the time.
	 * @param {String} [ahk_time=A_Now]
	 * @param {String} [fmt] - custom format to use, defaults to 'HH:mm:ss'
	 * @returns {String}
	 */
	static ToFormattedTime(ahk_time := A_Now, fmt := "HH:mm:ss") {
		if (not (ahk_time is String))
			ahk_time := ahk_time.ToString()
		return FormatTime(ahk_time, fmt)
	}
	
	/**
	 * Creates a formatted string of the date and time.
	 * @param {String} [ahk_time=A_Now]
	 * @param {String} [fmt] - custom format to use, defaults to 'yyyy-MM-dd HH:mm:ss'
	 * @returns {String}
	 */
	static ToFormattedDateTime(ahk_time := A_Now, fmt := "yyyy-MM-dd HH:mm:ss") {
		if (not (ahk_time is String))
			ahk_time := ahk_time.ToString()
		return FormatTime(ahk_time, fmt)
	}
	
	/**
	 * Converts an AHK time string to UTC time.
	 * @param {String} [ahk_time=A_Now]
	 * @returns {String}
	 */
	static ToUTC(ahk_time := A_Now) {
		if (not (ahk_time is String))
			ahk_time := ahk_time.ToString()
		return DateAdd(ahk_time, -TIMEZONE_OFFSET, "Hours")
	}
	
	/**
	 * Converts an AHK time string to local time.
	 * @param {String} [ahk_time=A_NowUTC]
	 * @returns {String}
	 */
	static ToLocal(ahk_time := A_NowUTC) {
		if (not (ahk_time is String))
			ahk_time := ahk_time.ToString()
		return DateAdd(ahk_time, TIMEZONE_OFFSET, "Hours")
	}
}