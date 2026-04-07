#Requires AutoHotkey >=2.0
#Include <Time>
#Include <Duration>
#Include <Error>

/**
 * @name        Scheduler.ahk
 * @description Utility library that complements Time.ahk by calculating schedules, intervals, countdowns, and more.
 * @version     1.4-2026.04.06
 * @requires    AutoHotkey >=2.0
 * @license     GNU GPLv3
 * Changelog:
 * v1.4 - Scheduler.Date and Scheduler.Time methods for partial AHK time string construction; using global constants from Time.ahk for month/weekday methods; typoes fixed.
 * v1.3 - Scheduler.Now shortcut; methods no longer use empty string for default value, avoiding an edge case where midnight "000000" is considered falsy and wasn't properly handled
 * v1.2 - Various month/weekday methods
 * v1.1 - Scheduler.Random
 * v1.0 - initial build
 */

/**
 * @class {Scheduler}
 * @static
 */
class Scheduler {
	/**
	 * Use UTC timestamps instead of local timestamps.
	 * @type {Boolean}
	 */
	static USE_UTC := true
	
	/**
	 * Unit of time for getting/setting the time remaining/elapsed.
	 * @type {String}
	 */
	static DEFAULT_UNIT := "Hours"
	
	/**
	 * Constants for common times.
	 * @type {String}
	 */
	static MIDNIGHT := "000000"
	static MORNING  := "060000"
	static NOON     := "120000"
	static EVENING  := "180000"
	
	/**
	 * Shortcut for getting either A_Now or A_NowUTC, depending on `USE_UTC`.
	 * @type {String}
	 * @readonly
	 */
	static Now => this.USE_UTC ? A_NowUTC : A_Now
	
	/**
	 * Shortcut for the timezone offset from UTC, depending on `USE_UTC`.
	 * Already calculated in Time.ahk, but this returns 0 if using UTC time.
	 * @type {Number}
	 * @readonly
	 */
	static TZ_OFFSET => this.USE_UTC ? 0 : TIMEZONE_OFFSET
	
	/**
	 * Creates a date-only string in AHK format, such as "20200202" for 2020-02-02.
	 * @param {Number} [year=A_Year] - the year
	 * @param {Number} [month=A_Mon] - the month index of the year
	 * @param {Number} [day=A_MDay] - the day of the month
	 * @returns {String}
	 */
	static Date(year := A_Year, month := A_Mon, day := A_MDay) {
		now := Time()
		now.year := year
		now.month := month
		now.day := day
		return now.date
	}
	
	/**
	 * Creates a time-only string in AHK format, such as "123000" for 12:30.
	 * @param {Number} [hour=A_Hour] - the hour
	 * @param {Number} [minute=A_Min] - the minute
	 * @param {Number} [second=A_Sec] - the second
	 * @returns {String}
	 */
	static Time(hour := A_Hour, minute := A_Min, second := A_Sec) {
		now := Time()
		now.hour := hour
		now.minute := minute
		now.second := second
		return now.time
	}
	
	/**
	 * Returns the future timestamp from now of time elapsed.
	 * @param {Number} timer
	 * @param {String} [unit]
	 * @returns {String}
	 */
	static SetTimeRemaining(timer, unit := this.DEFAULT_UNIT) {
		return DateAdd(this.Now, timer, unit)
	}
	
	/**
	 * Returns how many units of time until the specified timestamp in the future is reached.
	 * @param {String} [ahk_time]
	 * @param {String} [unit]
	 * @returns {Number}
	 */
	static GetTimeRemaining(ahk_time := this.Now, unit := this.DEFAULT_UNIT) {
		return DateDiff(ahk_time, this.Now, unit)
	}
	
	/**
	 * Returns a timestamp offset by the time elapsed since now.
	 * @param {Number} times
	 * @param {String} [unit]
	 * @returns {String}
	 */
	static SetTimeElapsed(timer, unit := this.DEFAULT_UNIT) {
		return DateAdd(this.Now, -timer, unit)
	}
	
	/**
	 * Returns how many units of time have elapsed since the specified timestamp in the past.
	 * @param {String} [ahk_time]
	 * @param {String} [unit]
	 * @returns {Number}
	 */
	static GetTimeElapsed(ahk_time := this.Now, unit := this.DEFAULT_UNIT) {
		return DateDiff(this.Now, ahk_time, unit)
	}
	
	/**
	 * Gets the time of the next interval according to the hours per interval and UTC offset.
	 * For example, if an event occurs every 6 hours starting at 12pm GMT, then at 5pm CST the next scheduled occurrence will be at 7pm.
	 * @param {Number} [interval=6] - interval period (in hours)
	 * @param {Number} [offset=0] - offset from midnight GMT
	 * @returns {String} ahk string of the next occurrence
	 */
	static NextIntervalTime(interval := 6, offset := 0) {
		now := Time()
		
		; get UTC hour
		hour_utc := now.hour - TIMEZONE_OFFSET
		
		; set hour relative to offset
		hour_start := hour_utc - offset
		
		; set how many intervals have passed after the starting hour
		if (interval is Duration) {
			interval := interval.hours
		} else if (interval is Number) {
			; ok
		} else {
			throw ValueError("Interval must be a Number or Duration",, interval)
		}
		times := Floor(hour_start / interval) + 1
		
		; calculate next interval hour
		hour_next := offset + this.TZ_OFFSET + (interval * times)
		now.hour += hour_next - now.hour
		now.minute := 0
		now.second := 0
		return now.ahk_time
	}
	
	/**
	 * Gets the time of the previous interval according to the hours per interval and UTC offset.
	 * For example, if an event occurs every 6 hours starting at 12pm GMT, then at 5pm CST the previous scheduled occurrence was at 1pm.
	 * @param {Number} [interval=6] - interval period (in hours)
	 * @param {Number} [offset=0] - offset from midnight GMT
	 * @returns {String} ahk string of the next occurrence
	 */
	static PrevIntervalTime(interval := 6, offset := 0) {
		now := Time()
		
		; get UTC hour
		hour_utc := now.hour - TIMEZONE_OFFSET
		
		; set hour relative to offset
		hour_start := hour_utc - offset
		
		; set how many intervals have passed after the starting hour
		if (interval is Duration) {
			interval := interval.hours
		} else if (interval is Number) {
			; ok
		} else {
			throw ValueError("Interval must be a Number or Duration",, interval)
		}
		times := Floor(hour_start / interval)
		
		; calculate next interval hour
		hour_next := offset + this.TZ_OFFSET + (interval * times)
		now.hour += hour_next - now.hour
		now.minute := 0
		now.second := 0
		return now.ahk_time
	}
	
	/**
	 * Sets a time for today.
	 * @param {String} [at_time] - specific time; defaults to current time, which is pointless
	 * @returns {String}
	 */
	static Today(at_time?) {
		t := Time(this.Now)
		if (IsSet(at_time))
			t.time := at_time
		return t.ahk_time
	}
	
	/**
	 * Sets a time for tomorrow.
	 * @param {String} [at_time] - specific time; defaults to current time
	 * @returns {String} AHK time string
	 */
	static Tomorrow(at_time?) {
		t := Time(this.Now)
		if (IsSet(at_time))
			t.time := at_time
		t.day++
		return t.ahk_time
	}
	
	/**
	 * Sets a time that occurred yesterday.
	 * @param {String} [at_time] - specific time; defaults to current time
	 * @returns {String} AHK time string
	 */
	static Yesterday(at_time?) {
		t := Time(this.Now)
		if (IsSet(at_time))
			t.time := at_time
		t.day--
		return t.ahk_time
	}
	
	/**
	 * Sets a time during this week.
	 * @param {Number} [weekday=A_WDay] - specific day of the week; defaults to current weekday
	 * @param {String} [at_time] - specific time; defaults to current time
	 * @returns {String} AHK time string
	 */
	static ThisWeek(weekday := A_WDay, at_time?) {
		t := Time(this.Now)
		if (IsSet(at_time))
			t.time := at_time
		t.day := weekday
		return t.ahk_time
	}
	
	/**
	 * Sets a time for next week.
	 * @param {Number} [weekday=A_WDay] - specific day of the week; defaults to current weekday
	 * @param {String} [at_time] - specific time; defaults to current time
	 * @returns {String} AHK time string
	 */
	static NextWeek(weekday := A_WDay, at_time?) {
		t := Time(this.Now)
		if (IsSet(at_time))
			t.time := at_time
		t.day += 7 - (t.DayOfWeek - weekday)
		return t.ahk_time
	}
	
	/**
	 * Sets a time that occurred in the previous week.
	 * @param {Number} [weekday=A_WDay] - specific day of the week; defaults to current weekday
	 * @param {String} [at_time] - specific time; defaults to current time
	 * @returns {String} AHK time string
	 */
	static PrevWeek(weekday := A_WDay, at_time?) {
		t := Time(this.Now)
		if (IsSet(at_time))
			t.time := at_time
		t.day -= 7 - (t.DayOfWeek - weekday)
		return t.ahk_time
	}
	
	/**
	 * Sets a time that occurred/occurs on a specific day this month, at a specific time.
	 * @param {Number} [monthday=A_MDay] - day of the month; defaults to current day
	 * @param {String} [at_time] - specific time; defaults to current time
	 * @returns {String} AHK time string
	 */
	static ThisMonth(monthday := A_MDay, at_time?) {
		t := Time(this.Now)
		if (IsSet(at_time))
			t.time := at_time
		t.day := monthday
		return t.ahk_time
	}
	
	/**
	 * Sets a time that occurs on a specific day next month, at a specific time.
	 * @param {Number} [monthday=A_MDay] - day of the month; defaults to current day
	 * @param {String} [at_time] - specific time; defaults to current time
	 * @returns {String} AHK time string
	 */
	static NextMonth(monthday := A_MDay, at_time?) {
		t := Time(this.Now)
		if (IsSet(at_time))
			t.time := at_time
		t.month++
		t.day := monthday
		return t.ahk_time
	}
	
	/**
	 * Sets a time that occurred on a specific day last month, at a specific time.
	 * @param {Number} [monthday=A_MDay] - day of the month; defaults to current day
	 * @param {String} [at_time] - specific time; defaults to current time
	 * @returns {String} AHK time string
	 */
	static PrevMonth(monthday := A_MDay, at_time?) {
		t := Time(this.Now)
		if (IsSet(at_time))
			t.time := at_time
		t.month--
		t.day := monthday
		return t.ahk_time
	}
	
	/**
	 * Sets a time that occurred/occurs during this year, at a specific month, day, and time.
	 * @param {Number} [month=A_Mon] - the month index; defaults to current month
	 * @param {Number} [monthday=A_MDay] - day of the month; defaults to current day
	 * @param {String} [at_time] - specific time; defaults to current time
	 * @returns {String} AHK time string
	 */
	static ThisYear(month := A_Mon, monthday := A_MDay, at_time?) {
		t := Time(this.Now)
		if (IsSet(at_time))
			t.time := at_time
		t.month := month
		t.day := monthday
		return t.ahk_time
	}
	
	/**
	 * Sets a time that occurs during next year, at a specific month, day, and time.
	 * @param {Number} [month=A_Mon] - the month index; defaults to current month
	 * @param {Number} [monthday=A_MDay] - day of the month; defaults to current day
	 * @param {String} [at_time] - specific time; defaults to current time
	 * @returns {String} AHK time string
	 */
	static NextYear(month := A_Mon, monthday := A_MDay, at_time?) {
		t := Time(this.Now)
		if (IsSet(at_time))
			t.time := at_time
		t.month := month
		t.day := monthday
		t.year++
		return t.ahk_time
	}
	
	/**
	 * Sets a time that occurred during last year, at a specific month, day, and time.
	 * @param {Number} [month=A_Mon] - the month index; defaults to current month
	 * @param {Number} [monthday=A_MDay] - day of the month; defaults to current day
	 * @param {String} [at_time] - specific time; defaults to current time
	 * @returns {String} AHK time string
	 */
	static PrevYear(month := A_Mon, monthday := A_MDay, at_time?) {
		t := Time(this.Now)
		if (IsSet(at_time))
			t.time := at_time
		t.month := month
		t.day := monthday
		t.year--
		return t.ahk_time
	}
	
	/**
	 * Sets a time to occur for the current or next Sunday.
	 * @param {String} [at_time] - specific time; defaults to current time
	 * @returns {String} AHK time string
	 */
	static Sunday(at_time?) {
		dotw := DaysOfTheWeek.Sunday
		if (Time.GetDay(this.Now) <= dotw) {
			return this.ThisWeek(dotw, at_time?)
		} else {
			return this.NextWeek(dotw, at_time?)
		}
	}
	
	/**
	 * Sets a time to occur for the current or next Monday.
	 * @param {String} [at_time] - specific time; defaults to current time
	 * @returns {String} AHK time string
	 */
	static Monday(at_time?) {
		dotw := DaysOfTheWeek.Monday
		if (Time.GetDay(this.Now) <= dotw) {
			return this.ThisWeek(dotw, at_time?)
		} else {
			return this.NextWeek(dotw, at_time?)
		}
	}
	
	/**
	 * Sets a time to occur for the current or next Tuesday.
	 * @param {String} [at_time] - specific time; defaults to current time
	 * @returns {String} AHK time string
	 */
	static Tuesday(at_time?) {
		dotw := DaysOfTheWeek.Tuesday
		if (Time.GetDay(this.Now) <= dotw) {
			return this.ThisWeek(dotw, at_time?)
		} else {
			return this.NextWeek(dotw, at_time?)
		}
	}
	
	/**
	 * Sets a time to occur for the current or next Wednesday.
	 * @param {String} [at_time] - specific time; defaults to current time
	 * @returns {String} AHK time string
	 */
	static Wednesday(at_time?) {
		dotw := DaysOfTheWeek.Wednesday
		if (Time.GetDay(this.Now) <= dotw) {
			return this.ThisWeek(dotw, at_time?)
		} else {
			return this.NextWeek(dotw, at_time?)
		}
	}
	
	/**
	 * Sets a time to occur for the current or next Thursday.
	 * @param {String} [at_time] - specific time; defaults to current time
	 * @returns {String} AHK time string
	 */
	static Thursday(at_time?) {
		dotw := DaysOfTheWeek.Thursday
		if (Time.GetDay(this.Now) <= dotw) {
			return this.ThisWeek(dotw, at_time?)
		} else {
			return this.NextWeek(dotw, at_time?)
		}
	}
	
	/**
	 * Sets a time to occur for the current or next Friday.
	 * @param {String} [at_time] - specific time; defaults to current time
	 * @returns {String} AHK time string
	 */
	static Friday(at_time?) {
		dotw := DaysOfTheWeek.Friday
		if (Time.GetDay(this.Now) <= dotw) {
			return this.ThisWeek(dotw, at_time?)
		} else {
			return this.NextWeek(dotw, at_time?)
		}
	}
	
	/**
	 * Sets a time to occur for the current or next Saturday.
	 * @param {String} [at_time] - specific time; defaults to current time
	 * @returns {String} AHK time string
	 */
	static Saturday(at_time?) {
		dotw := DaysOfTheWeek.Saturday
		if (Time.GetDay(this.Now) <= dotw) {
			return this.ThisWeek(dotw, at_time?)
		} else {
			return this.NextWeek(dotw, at_time?)
		}
	}
	
	/**
	 * Sets a date and time to occur for the current or next January.
	 * @param {Number} [day=1] - specific day of the month
	 * @param {String} [at_time] - specific time; defaults to current time
	 * @returns {String} AHK time string
	 */
	static January(day := A_MDay, at_time?) {
		moty := MonthsOfTheYear.January
		if (Time.GetMonth(this.Now) <= moty) {
			return this.ThisYear(moty, day, at_time?)
		} else {
			return this.NextYear(moty, day, at_time?)
		}
	}
	
	/**
	 * Sets a date and time to occur for the current or next February.
	 * @param {Number} [day=1] - specific day of the month
	 * @param {String} [at_time] - specific time; defaults to current time
	 * @returns {String} AHK time string
	 */
	static February(day := A_MDay, at_time?) {
		moty := MonthsOfTheYear.February
		if (Time.GetMonth(this.Now) <= moty) {
			return this.ThisYear(moty, day, at_time?)
		} else {
			return this.NextYear(moty, day, at_time?)
		}
	}
	
	/**
	 * Sets a date and time to occur for the current or next March.
	 * @param {Number} [day=1] - specific day of the month
	 * @param {String} [at_time] - specific time; defaults to current time
	 * @returns {String} AHK time string
	 */
	static March(day := A_MDay, at_time?) {
		moty := MonthsOfTheYear.March
		if (Time.GetMonth(this.Now) <= moty) {
			return this.ThisYear(moty, day, at_time?)
		} else {
			return this.NextYear(moty, day, at_time?)
		}
	}
	
	/**
	 * Sets a date and time to occur for the current or next April.
	 * @param {Number} [day=1] - specific day of the month
	 * @param {String} [at_time] - specific time; defaults to current time
	 * @returns {String} AHK time string
	 */
	static April(day := A_MDay, at_time?) {
		moty := MonthsOfTheYear.April
		if (Time.GetMonth(this.Now) <= moty) {
			return this.ThisYear(moty, day, at_time?)
		} else {
			return this.NextYear(moty, day, at_time?)
		}
	}
	
	/**
	 * Sets a date and time to occur for the current or next May.
	 * @param {Number} [day=1] - specific day of the month
	 * @param {String} [at_time] - specific time; defaults to current time
	 * @returns {String} AHK time string
	 */
	static May(day := A_MDay, at_time?) {
		moty := MonthsOfTheYear.May
		if (Time.GetMonth(this.Now) <= moty) {
			return this.ThisYear(moty, day, at_time?)
		} else {
			return this.NextYear(moty, day, at_time?)
		}
	}
	
	/**
	 * Sets a date and time to occur for the current or next June.
	 * @param {Number} [day=1] - specific day of the month
	 * @param {String} [at_time] - specific time; defaults to current time
	 * @returns {String} AHK time string
	 */
	static June(day := A_MDay, at_time?) {
		moty := MonthsOfTheYear.June
		if (Time.GetMonth(this.Now) <= moty) {
			return this.ThisYear(moty, day, at_time?)
		} else {
			return this.NextYear(moty, day, at_time?)
		}
	}
	
	/**
	 * Sets a date and time to occur for the current or next July.
	 * @param {Number} [day=1] - specific day of the month
	 * @param {String} [at_time] - specific time; defaults to current time
	 * @returns {String} AHK time string
	 */
	static July(day := A_MDay, at_time?) {
		moty := MonthsOfTheYear.July
		if (Time.GetMonth(this.Now) <= moty) {
			return this.ThisYear(moty, day, at_time?)
		} else {
			return this.NextYear(moty, day, at_time?)
		}
	}
	
	/**
	 * Sets a date and time to occur for the current or next August.
	 * @param {Number} [day=1] - specific day of the month
	 * @param {String} [at_time] - specific time; defaults to current time
	 * @returns {String} AHK time string
	 */
	static August(day := A_MDay, at_time?) {
		moty := MonthsOfTheYear.August
		if (Time.GetMonth(this.Now) <= moty) {
			return this.ThisYear(moty, day, at_time?)
		} else {
			return this.NextYear(moty, day, at_time?)
		}
	}
	
	/**
	 * Sets a date and time to occur for the current or next September.
	 * @param {Number} [day=1] - specific day of the month
	 * @param {String} [at_time] - specific time; defaults to current time
	 * @returns {String} AHK time string
	 */
	static September(day := A_MDay, at_time?) {
		moty := MonthsOfTheYear.September
		if (Time.GetMonth(this.Now) <= moty) {
			return this.ThisYear(moty, day, at_time?)
		} else {
			return this.NextYear(moty, day, at_time?)
		}
	}
	
	/**
	 * Sets a date and time to occur for the current or next October.
	 * @param {Number} [day=1] - specific day of the month
	 * @param {String} [at_time] - specific time; defaults to current time
	 * @returns {String} AHK time string
	 */
	static October(day := A_MDay, at_time?) {
		moty := MonthsOfTheYear.October
		if (Time.GetMonth(this.Now) <= moty) {
			return this.ThisYear(moty, day, at_time?)
		} else {
			return this.NextYear(moty, day, at_time?)
		}
	}
	
	/**
	 * Sets a date and time to occur for the current or next November.
	 * @param {Number} [day=1] - specific day of the month
	 * @param {String} [at_time] - specific time; defaults to current time
	 * @returns {String} AHK time string
	 */
	static November(day := A_MDay, at_time?) {
		moty := MonthsOfTheYear.November
		if (Time.GetMonth(this.Now) <= moty) {
			return this.ThisYear(moty, day, at_time?)
		} else {
			return this.NextYear(moty, day, at_time?)
		}
	}
	
	/**
	 * Sets a date and time to occur for the current or next December.
	 * @param {Number} [day=1] - specific day of the month
	 * @param {String} [at_time] - specific time; defaults to current time
	 * @returns {String} AHK time string
	 */
	static December(day := A_MDay, at_time?) {
		moty := MonthsOfTheYear.December
		if (Time.GetMonth(this.Now) <= moty) {
			return this.ThisYear(moty, day, at_time?)
		} else {
			return this.NextYear(moty, day, at_time?)
		}
	}
	
	/**
	 * Returns a random time between two AHK times.
	 * @param {String|Number} [ahk_time=0] - min datetime or amount of time
	 * @param {String|Number} [ahk_time2=100] - max datetime or amount of time
	 * @param {String} [unit="Seconds"] - unit of time to set the granularity of randomness, spanning from seconds, minutes, hours, to whole days
	 */
	static Random(ahk_time1 := 0, ahk_time2 := 100, unit := "Seconds") {
		s1 := ahk_time1 is String ? this.GetTimeRemaining(ahk_time1, "Seconds") : ahk_time1
		s2 := ahk_time2 is String ? this.GetTimeRemaining(ahk_time2, "Seconds") : ahk_time2
		if (s1 > s2) {
			tmp := s1
			s1 := s2
			s2 := tmp
		}
		return this.SetTimeRemaining(Random(s1, s2), unit)
	}
}