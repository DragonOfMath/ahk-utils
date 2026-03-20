#Requires AutoHotkey >=2.0
#Include <Point>

/**
 * @name        Rect.ahk
 * @description Rectangle class for representing an area of the screen, partitioning, and constraining ImageSearch.
 * @version     1.0-2026.03.19
 * @requires    AutoHotkey >=2.0
 * @license     GNU GPLv3
 */

/**
 * Defines a rectangular bounding box with a given position and size.
 * @class {Rect}
 * @property {Point} pos - starting position
 * @property {Point} size - dimensions of the rect
 */
class Rect {
	/**
	 * @constructor
	 * @param {Number|Point} [x=0] - x coord or first point of rect
	 * @param {Number|Point} [y=0] - y coord or second point of rect
	 * @param {Number} [w=0] - width of rect
	 * @param {Number} [h=0] - height of rect
	 */
	__New(x := 0, y := 0, w := 0, h := 0) {
		if (x is Point and y is Point) {
			start := x.Min(y)
			end := x.Max(y)
			this.pos := start
			this.size := end.Subtract(start)
		} else {
			this.pos := Point(x, y)
			this.size := Point(w, h)
		}
	}
	
	/**
	 * X position of the rect.
	 * @type {Number}
	 */
	x {
		get => this.pos.x
		set => this.pos.x := value
	}
	
	/**
	 * Y position of the rect.
	 * @type {Number}
	 */
	y {
		get => this.pos.y
		set => this.pos.y := value
	}
	
	/**
	 * Width of the rect.
	 * @type {Number}
	 */
	width {
		get => this.size.x
		set => this.size.x := value
	}
	
	/**
	 * Height of the rect.
	 * @type {Number}
	 */
	height {
		get => this.size.y
		set => this.size.y := value
	}
	
	/**
	 * Alias for position.
	 * @type {Number}
	 */
	start {
		get => this.pos
		set => this.pos := value
	}
	
	/**
	 * Alias for dimensions.
	 * @type {Number}
	 */
	dimensions {
		get => this.size
		set => this.size := value
	}
	
	/**
	 * Ending position of the rect.
	 * @type {Number}
	 */
	end {
		get => this.pos.Add(this.size)
		set => this.size := value.Subtract(this.pos)
	}
	
	/**
	 * Midpoint of the rect.
	 * @type {Number}
	 * @readonly
	 */
	mid => this.pos.Add(this.size.MultiplyScalar(0.5))
	
	/**
	 * Area of the rect.
	 * @type {Number}
	 * @readonly
	 */
	area => this.width * this.height
	
	/**
	 * Aspect ratio of the rect (height / width).
	 * Higher value corresponds to a taller rect, while a small value corresponds to a wider rect.
	 * @type {Number}
	 */
	ratio {
		get => this.height / this.width
		set => this.height := this.width * value
	}
	
	/**
	 * Sets the rect properties.
	 * @param {Number} x
	 * @param {Number} y
	 * @param {Number} w
	 * @param {Number} h
	 */
	Set(x, y, w, h) {
		this.x := x
		this.y := y
		this.width := w
		this.height := h
		return this
	}
	
	/**
	 * Makes an identical copy of this rect.
	 * @returns {Rect} new instance
	 */
	Clone() {
		return Rect(this.pos.x, this.pos.y, this.size.x, this.size.y)
	}
	
	/**
	 * Expands a rect by some amount in each direction (double the size change).
	 * @param {Number} dx
	 * @param {Number} dy
	 * @returns {Rect} new instance
	 */
	Grow(dx, dy) {
		return Rect(this.pos.x - dx, this.y - dy, this.size.x + 2 * dx, this.size.y + 2 * dy)
	}
	
	/**
	 * Shrinks a rect by some amount in each direction (double the size change).
	 * @param {Number} dx
	 * @param {Number} dy
	 * @returns {Rect} new instance
	 */
	Shrink(dx, dy) {
		return Rect(this.pos.x + dx, this.y + dy, this.size.x - 2 * dx, this.size.y - 2 * dy)
	}
	
	/**
	 * Checks if a Point or Rect is entirely contained by this rect.
	 * @param {Point|Rect} obj
	 * @returns {Boolean}
	 */
	Contains(obj) {
		if (obj is Point) {
			p := this.pos
			e := this.end
			return (obj.x >= p.x) and (obj.x <= e.x) and (obj.y >= p.y) and (obj.y <= e.y)
		} else if (obj is Rect) {
			p := this.pos
			s := this.size
			return (p.x <= obj.pos.x) and (p.y <= obj.pos.y) and (s.x >= obj.size.x) and (s.y >= obj.size.y)
		} else {
			; don't know what this object is
			return false
		}
	}
	
	/**
	 * Checks if a Point or Rect overlaps with this rect.
	 * @param {Point|Rect} obj
	 * @returns {Boolean}
	 *
	Overlaps(obj) {
		if (obj is Point) {
			return this.Contains(obj)
		} else if (obj is Rect) {
			e0 := this.end
			e1 := obj.end
			return not ((this.pos.x > e1.x) or (this.pos.y > e1.y) or (e0.x < obj.pos.x) or (e0.y < obj.pos.y))
		} else {
			; don't know what this object is
			return false
		}
	}
	
	/**
	 * Gets the left portion of the rect when bisected at a ratio.
	 * @param {Number} [ratio=1] - ratio of left to right
	 * @returns {Rect} new instance
	 */
	Left(ratio := 1) {
		size := this.size.x * (ratio / (1 + ratio))
		return Rect(this.pos.x, this.pos.y, size, this.size.y)
	}
	
	/**
	 * Gets the right portion of the rect when bisected at a ratio.
	 * @param {Number} [ratio=1] - ratio of right to left
	 * @returns {Rect} new instance
	 */
	Right(ratio := 1) {
		size := this.size.x * ratio / (1 + ratio)
		return Rect(this.pos.x + this.size.x - size, this.pos.y, size, this.size.y)
	}
	
	/**
	 * Gets the upper portion of the rect when bisected at a ratio.
	 * @param {Number} [ratio=1] - ratio of top to bottom
	 * @returns {Rect} new instance
	 */
	Upper(ratio := 1) {
		size := this.size.y * (ratio / (1 + ratio))
		return Rect(this.pos.x, this.pos.y, this.size.x, size)
	}
	
	/**
	 * Gets the upper portion of the rect when bisected at a ratio.
	 * @param {Number} [ratio=1] - ratio of bottom to top
	 * @returns {Rect} new instance
	 */
	Lower(ratio := 1) {
		size := this.size.y * ratio / (1 + ratio)
		return Rect(this.pos.x, this.pos.y + this.size.y - size, this.size.x, size)
	}
	
	/**
	 * Crops the rectangle by trimming portions from all sides in the order of left, right, top, and bottom.
	 * @param {Float|Integer} [left] - how much to crop the left side by; float for percentage, integer for pixels
	 * @param {Float|Integer} [right] - how much to crop the right side by; float for percentage, integer for pixels
	 * @param {Float|Integer} [top] - how much to crop the top side by; float for percentage, integer for pixels
	 * @param {Float|Integer} [bottom] - how much to crop the bottom side by; float for percentage, integer for pixels
	 * @returns {Rect} new instance
	 */
	Crop(left := 0, right := 0, top := 0, bottom := 0) {
		if (left is Float) {
			left := Integer(left * this.width)
		}
		if (right is Float) {
			right := Integer(right * this.width)
		}
		if (top is Float) {
			top := Integer(top * this.height)
		}
		if (bottom is Float) {
			bottom := Integer(bottom * this.height)
		}
		Assert(left is Integer, "Parameter #1 must be a Float or Integer")
		Assert(right is Integer, "Parameter #2 must be a Float or Integer")
		Assert(top is Integer, "Parameter #3 must be a Float or Integer")
		Assert(bottom is Integer, "Parameter #4 must be a Float or Integer")
		left := Max(left, 0)
		right := Max(this.width - right, 0)
		top := Max(top, 0)
		bottom := Max(this.height - bottom, 0)
		return Rect(Point(left, top), Point(right, bottom))
	}
	
	/**
	 * Subdivides the rect along each dimension into sub-rects of equal size.
	 * By default, subdivides once each.
	 * @param {Number} [xsplits=1] - number of splits across the x-axis
	 * @param {Number} [ysplits=1] - number of splits across the y-axis
	 * @returns {Rect[]} rects are ordered from top-left to bottom-right
	 */
	Split(xsplits := 1, ysplits := 1) {
		Assert(xsplits is Integer, "Parameter #1 must be an Integer")
		Assert(xsplits >= 0, "Parameter #1 must be positive")
		Assert(ysplits is Integer, "Parameter #2 must be an Integer")
		Assert(ysplits >= 0, "Parameter #2 must be positive")
		rects := []
		xrects := xsplits + 1
		yrects := ysplits + 1
		w := this.width / xrects
		h := this.height / yrects
		loop yrects {
			y := this.y + h * (A_Index-1)
			loop xrects {
				x := this.x + w * (A_Index-1)
				rects.Push(Rect(x,y,w,h))
			}
		}
		return rects
	}
	
	/**
	 * Splits the rect horizontally into rectangles of equal size.
	 * Their height will be the same as the original rect.
	 * @param {Number} [times=1] - number of times to split the rect
	 * @returns {Rect[]}
	 */
	HSplit(times := 1) {
		return this.Split(times, 0)
	}
	
	/**
	 * Splits the rect vertically into rectangles of equal size.
	 * Their width will be the same as the original rect.
	 * @param {Number} [times=1] - number of times to split the rect
	 * @returns {Rect[]}
	 */
	VSplit(times := 1) {
		return this.Split(0, times)
	}
	
	/**
	 * Gets the position and size of a window and sets this rect's position and size to it.
	 * @param {String[]} [params*] - window handle selection
	 * @returns {Rect} this
	 */
	FromWindow(params*) {
		WinGetPos(&X, &Y, &W, &H, params*)
		return this.Set(X, Y, W, H)
	}
	
	/**
	 * Applies this rect to a window's position and size.
	 * @param {String[]} [params*] - window handle selection
	 * @return {Hwnd} handle of the window that was changed
	 */
	ToWindow(params*) {
		return WinMove(this.x, this.y, this.width, this.height, params*)
	}
	
	/**
	 * Returns the rect in String form.
	 * @returns {String}
	 */
	ToString() {
		return Format("Rect:{},{},{},{}", this.x, this.y, this.width, this.height)
	}
	
	/**
	 * @private
	 * @void
	 */
	Debug() {
		this.start.GoTo()
		Tooltip(Format("{} to {}", this.start.ToString(), this.end.ToString()))
		Sleep(2000)
		Tooltip()
		this.end.GoTo()
	}
	
	/**
	 * Gets the position and size of a window as a rect
	 * @param {String[]} [params*] - window handle selection
	 * @returns {Rect}
	 */
	static FromWindow(params*) {
		WinGetPos(&X, &Y, &W, &H, params*)
		return Rect(X, Y, W, H)
	}
	
	/**
	 * Gets the size of the screen as a rect.
	 * @returns {Rect}
	 */
	static FromScreen() {
		return Rect(0, 0, A_ScreenWidth, A_ScreenHeight)
	}
	
	/**
	 * Gets a Rect instance from an array.
	 * @param {Number[2]} arr
	 * @returns {Rect}
	 */
	static FromArray(x) {
		return Rect(x*)
	}
	
	/**
	 * Gets a Rect instance from a string.
	 * @param {String} x
	 * @returns {?Rect}
	 */
	static FromString(x) {
		if (StrStartsWith(x, "Rect:")) {
			x := StrSplit(x, ":")[2]
			values := StrSplit(x,",")
			if (values.Length = 4) {
				values := values.Map((c,*) => Number(c))
				return Rect(values*)
			}
		}
	}
	
	/**
	 * Gets the intersection of two or more rects.
	 * Box_Intersection(A,B,C,D) := Box(min(B,D),max(A,C))
	 * @param {Rect[]} rects*
	 * @returns {?Rect} a rect or null if no intersection
	 */
	static Intersection(rects*) {
		switch (rects.Length) {
			case 0: return Null
			case 1: return rects[1].Clone()
			default:
				i := rects[1].Clone()
				loop rects.Length {
					r := rects[A_Index]
					A := i.start.Min(i.end)
					B := i.start.Max(i.end)
					C := r.start.Min(r.end)
					D := r.start.Max(r.end)
					if (Max(A.x - D.x, C.x - B.x, A.y - D.y, C.y - B.y) <= 0) {
						i := Rect(B.Min(D), A.Max(C))
					}
				}
				return i
		}
	}
	
	/**
	 * Gets the union of two or more rects.
	 * @param {Rect[]} rects*
	 * @returns {Rect} a rect
	 */
	static Union(rects*) {
		switch (rects.Length) {
			case 0: return Null
			case 1: return rects[1].Clone()
			default:
				i := rects[1].Clone()
				loop rects.Length {
					r := rects[A_Index]
					A := i.start.Min(i.end)
					B := i.start.Max(i.end)
					C := r.start.Min(r.end)
					D := r.start.Max(r.end)
					i := Rect(A.Min(C), B.Max(D))
				}
				return i
		}
	}
}
