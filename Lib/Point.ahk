#Requires AutoHotkey >=2.0
#Include <String>

/**
 * @name        Point
 * @description Standard point data structure with some methods relevant to AHK.
 * @version     1.1-2026.01.06
 * @requires    AutoHotkey >=2.0
 * @license     GNU GPLv3
 * Changelog:
 *  - v1.1 - using SendMode("Event") for dragging with delay
 *  - v1.0 - initial release
 */

/**
 * Basic 2D point class, with math operations performed component-wise.
 * @class {Point}
 * @property {Number} x
 * @property {Number} y
 */
class Point {
	__New(x := 0, y := 0) {
		this.x := x
		this.y := y
		return this
	}
	
	/**
	 * Magnitude of the point.
	 * @type {Number}
	 * @readonly
	 */
	length => Sqrt(this.Dot(this))
	magnitude => Sqrt(this.Dot(this))
	
	/**
	 * Sets properties of this Point.
	 * @param {Number} x
	 * @param {Number} y
	 * @returns {Point} this
	 */
	Set(x, y) {
		this.x := x
		this.y := y
		return this
	}
	
	/**
	 * Swaps the x and y components of this point.
	 * @returns {Point} new instance
	 */
	Swap() {
		return Point(this.y, this.x)
	}
	
	/**
	 * Component-wise absolute value.
	 * @returns {Point} new instance
	 */
	Abs() {
		return Point(Abs(this.x), Abs(this.y))
	}
	
	/**
	 * Component-wise ceiling rounding.
	 * @returns {Point} new instance
	 */
	Ceil() {
		return Point(Ceil(this.x), Ceil(this.y))
	}
	
	/**
	 * Component-wise floor rounding.
	 * @returns {Point} new instance
	 */
	Floor() {
		return Point(Floor(this.x), Floor(this.y))
	}
	
	/**
	 * Component-wise exponentiation.
	 * @returns {Point} new instance
	 */
	Exp() {
		return Point(Exp(this.x), Exp(this.y))
	}
	
	/**
	 * Component-wise logarithm.
	 * @returns {Point} new instance
	 */
	Log() {
		return Point(Ln(this.x), Ln(this.y))
	}
	
	/**
	 * Component-wise addition of points.
	 * @param {Point} p
	 * @returns {Point} new instance
	 */
	Add(p) {
		return Point(this.x + p.x, this.y + p.y)
	}
	
	/**
	 * Component-wise subtraction of points.
	 * @param {Point} p
	 * @returns {Point} new instance
	 */
	Subtract(p) {
		return Point(this.x - p.x, this.y - p.y)
	}
	
	/**
	 * Component-wise multiplication of points.
	 * @param {Point} p
	 * @returns {Point} new instance
	 */
	Multiply(p) {
		return Point(this.x * p.x, this.y * p.y)
	}
	
	/**
	 * Component-wise division of points.
	 * @param {Point} p
	 * @returns {Point} new instance
	 */
	Divide(p) {
		return Point(this.x / p.x, this.y / p.y)
	}
	
	/**
	 * Component-wise integer division of points.
	 * @param {Point} p
	 * @returns {Point} new instance
	 */
	IDivide(p) {
		return Point(this.x // p.x, this.y // p.y)
	}
	
	/**
	 * Multiply by a scalar.
	 * @param {Number} s
	 * @returns {Point} new instance
	 */
	MultiplyScalar(s) {
		return Point(this.x * s, this.y * s)
	}
	
	/**
	 * Component-wise minimum of points.
	 * @param {Point} p
	 * @returns {Point} new instance
	 */
	Min(p) {
		return Point(Min(this.x, p.x), Min(this.y, p.y))
	}
	
	/**
	 * Component-wise maximum of points.
	 * @param {Point} p
	 * @returns {Point} new instance
	 */
	Max(p) {
		return Point(Max(this.x, p.x), Max(this.y, p.y))
	}
	
	/**
	 * Midpoint of two points.
	 * @param {Point} p
	 * @returns {Point} new instance
	 */
	Mid(p) {
		return Point((this.x + p.x) / 2, (this.y + p.y) / 2)
	}
	
	; 
	/**
	 * Component-wise interpolation of points.
	 * @param {Point} p
	 * @param {Number} t
	 * @returns {Point} new instance
	 */
	Mix(p, t) {
		return Point(this.x + t * (p.x - this.x), this.y + t * (p.y - this.y))
	}
	
	/**
	 * Dot product of this point and another.
	 * @param {Point} p
	 * @returns {Number}
	 */
	Dot(p) {
		return this.x * p.x + this.y * p.y
	}
	
	/**
	 * Distance from this point to another.
	 * @param {Point} p
	 * @returns {Number}
	 */
	Distance(p) {
		return this.Subtract(p).length
	}
	
	/**
	 * Component-wise equality of points.
	 * @param {Point} p
	 * @returns {Point} new instance
	 */
	Equals(p) {
		return (this.x = p.x) and (this.y = p.y)
	}
	
	/**
	 * Moves the mouse to this point on screen (relative to whatever coord settings are currently used).
	 * @void
	 */
	Goto() {
		MouseMove(this.x, this.y)
	}
	
	/**
	 * Clicks the mouse at this point on screen (relative to whatever coord settings are currently used).
	 * @void
	 */
	Click(clickParams*) {
		MouseClick("Left", this.x, this.y, clickParams*)
	}
	
	/**
	 * Drags the mouse from this point to another with a specified speed (relative to whatever coord settings are currently used).
	 * @param {Point} p
	 * @void
	 */
	DragTo(p, delay := 0) {
		if (delay > 0) {
			prevSendMode := A_SendMode
			SendMode("Event")
			MouseClick("Left", this.x, this.y, 1, 50, "D")
			Sleep(delay)
			MouseClick("Left", p.x, p.y, 1, 50, "D")
			Sleep(delay)
			MouseClick("Left",,,,, "U")
			SendMode(prevSendMode)
		} else {
			MouseClickDrag("Left", this.x, this.y, p.x, p.y)
		}
	}
	
	/**
	 * Serializes the point to a string.
	 * @returns {String}
	 */
	ToString() {
		return "Point:" . this.x . "," . this.y
	}
	
	/**
	 * Converts an array object to a Point instance.
	 * @param {Number[2]} x
	 * @returns {Point}
	 */
	static FromArray(x) {
		return Point(x[1], x[2])
	}
	
	/**
	 * Converts a string to a Point instance.
	 * @param {String} x
	 * @returns {?Point}
	 */
	static FromString(x) {
		if (StrStartsWith(x, "Point:")) {
			x := StrSplit(x, ":")[2]
			pos := StrSplit(x, ",")
			if (pos.Length = 2) {
				return Point(Number(pos[1]), Number(pos[2]))
			}
		}
	}
	
	/**
	 * Gets the position of a window as a Point instance.
	 * @param {Any[]} [params*] - window handle selection
	 * @returns {Point}
	 */
	static FromWindowPos(params*) {
		WinGetPos(&x, &y,,, params*)
		return Point(x, y)
	}
	
	/**
	 * Gets the width and height of a window as a Point instance.
	 * @param {Any[]} [params*] - window handle selection
	 * @returns {Point}
	 */
	static FromWindowSize(params*) {
		WinGetPos(,, &w, &h, params*)
		return Point(w, h)
	}
	
	/**
	 * Gets the screen size as a Point instance.
	 * @param {Any[]} [params*] - window handle selection
	 * @returns {Point}
	 */
	static FromScreen() {
		return Point(A_ScreenWidth, A_ScreenHeight)
	}
	
	/**
	 * Creates a randomized point.
	 * @param {Number} [min=0] - minimum value per component
	 * @param {Number} [max=0] - maximum value per component
	 * @returns {Point}
	 */
	static Random(min := 0.0, max := 1.0) {
		return Point(Random(min, max), Random(min, max))
	}
}

Point.Zero := Point(0,0)

global Null := 0

/**
 * Switch the mouse and pixel coord modes to use the screen domain.
 * @void
 */
UseScreenCoords() {
	CoordMode("Mouse", "Screen")
	CoordMode("Pixel", "Screen")
}

/**
 * Switch the mouse and pixel coord modes to use the window domain.
 * @void
 */
UseWindowCoords() {
	CoordMode("Mouse", "Window")
	CoordMode("Pixel", "Window")
}

/**
 * Switch the mouse and pixel coord modes to use the client domain (inner window area).
 * @void
 */
UseClientCoords() {
	CoordMode("Mouse", "Client")
	CoordMode("Pixel", "Client")
}

