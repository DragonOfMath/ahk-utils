#Requires AutoHotkey >=2.0
#Include <Point>
#Include <Rect>
#Include <String>

/**
 * @name        Image.ahk
 * @description Image utility library for loading, referencing, and template matching with the screen.
 * @version     1.3-2026.03.19
 * @requires    AutoHotkey >=2.0
 * @license     GNU GPLv3
 * Changelog:
 * - v1.3: SearchAll for multiple matches using a divide-and-conquer method
 * - v1.2: added lastFound property
 * - v1.1: added the ability to search for an exact match, ignoring the TransColor
 * - v1.0: initial release
 */

; Stores the screen size as a rect
global ScreenRect := Rect.FromScreen()

/**
 * Wrapper for image loaded locally, with a handle used in searching the screen.
 * The image isn't loaded until it is used for ImageSearch, so that missing images can still be referenced for future use.
 * @class {Image}
 * @property {String} name - name of the file
 * @property {Number} handle - handle of the loaded image (assumes a value after calling Load())
 * @property {Number} width - width of the image
 * @property {Number} height - height of the image
 * @property {String} trans - select which color to set as "transparent" which matches any color on screen
 * @property {Boolean} enabled - enables searching this image
 * @property {?Point} lastFound - position where the image was last found
 */
class Image {
	/**
	 * The directory of images to use.
	 * @type {String}
	 */
	static DIR := A_WorkingDir . "\assets\"

	name := ""
	handle := 0
	width := 0
	height := 0
	trans := ""
	enabled := true
	lastFound := Null

	__New(args*) {
		switch args.length {
			case 1: ; Image("image.png") or Image({})
				if (args[1] is String) {
					this.name := args[1]
				} else if (args[1] is Object) {
					this.name := args[1].name
					this.width := args[1].width
					this.height := args[1].height
					this.trans := args[1].trans
					this.enabled := args[1].enabled
				}
			case 2: ; Image("image.png", x)
				this.name := args[1]
				if (args[2] is Point) {
					this.size := args[2]
				} else if (args[2] is String) {
					this.trans := args[2]
				} else if (args[2] is Number) {
					this.enabled := args[2]
				}
			case 3:
				this.name := args[1]
				this.width := args[2]
				this.height := args[3]
			case 4:
				this.name := args[1]
				this.width := args[2]
				this.height := args[3]
				this.trans := args[4]
			case 5:
				this.name := args[1]
				this.width := args[2]
				this.height := args[3]
				this.trans := args[4]
				this.enabled := args[5]
		}
	}
	__Delete() {
		this.Unload()
	}
	
	/**
	 * Absolute path to image file.
	 * @type {String}
	 * @readonly
	 */
	path => Image.DIR . this.name
	
	/**
	 * Image dimensions.
	 * @type {Point}
	 * @readonly
	 */
	size => Point(this.width, this.height)
	
	/**
	 * Midpoint of the image.
	 * @type {Point}
	 * @readonly
	 */
	mid => Point(this.width / 2, this.height / 2)
	
	/**
	 * Loads the image if it hasn't been already.
	 * @void
	 */
	Load() {
		if (not this.handle) {
			this.handle := LoadPicture(this.path)
			if (this.handle) {
				if (this.width = 0) {
					size := Image.GetSize(this.path)
					this.width := size.width
					this.height := size.height
				}
			} else {
				throw ValueError("Failed to load Image",, this.name)
			}
		}
	}
	
	/**
	 * Unloads the image if it has an assigned handle.
	 * @void
	 */
	Unload() {
		if (this.handle) {
			DllCall("DeleteObject", "ptr", this.handle)
			this.handle := 0
		}
		this.width := 0
		this.height := 0
		this.trans := ""
		this.lastFound := Null
	}
	
	/**
	 * Searches a rectangular area of the screen for this image, given some color tolerance.
	 * @param {Rect} rect - the rectangular area in which to search; by default, uses the entire screen
	 * @param {Number} [tolerance=0] - amount of leniency when matching pixels in the image with pixels on the screen
	 * @returns {?Point} if found, returns the position where it matched
	 */
	Search(rect := ScreenRect, tolerance := 0) {
		if (this.enabled) {
			this.Load()
			if (this.handle) {
				txt := ""
				if (tolerance)
					txt .= "*" . tolerance . " "
				if (this.trans)
					txt .= "*Trans" . this.trans . " "
				txt .= "HBITMAP:*" . this.handle
				if (ImageSearch(&x, &y, rect.pos.x, rect.pos.y, rect.pos.x + rect.size.x, rect.pos.y + rect.size.y, txt))
					return this.lastFound := Point(x, y)
			}
		}
	}
	
	/**
	 * Searches a rectangular area of the screen for this exact image, regardless of transparency color.
	 * @param {Rect} rect - the rectangular area in which to search; by default, uses the entire screen
	 * @returns {?Point} if found, returns the position where it matched
	 */
	SearchExact(rect := ScreenRect) {
		if (this.enabled) {
			this.Load()
			if (this.handle and ImageSearch(&x, &y, rect.pos.x, rect.pos.y, rect.pos.x + rect.size.x, rect.pos.y + rect.size.y, "HBITMAP:*" . this.handle))
				return this.lastFound := Point(x, y)
		}
	}
	
	/**
	 * Searches for positions of all matching areas of the screen. Assumes matches are laid out in a grid pattern.
	 * @param {Rect} rect - the rectangular area in which to search; by default, uses the entire screen
	 * @param {Number} [tolerance=0] - amount of leniency when matching pixels in the image with pixels on the screen
	 * @returns {?Point[]} array of point(s) if any are found
	 */
	SearchAll(rect := ScreenRect, tolerance := 0) {
		positions := []
		
		searchRect := rect.Clone()
		found := this.Search(searchRect, tolerance)
		
		while (found) {
			positions.Push(found)
			
			searchRect.x := found.x + this.width
			searchRect.y := found.y - 1
			searchRect.width := rect.width - searchRect.x
			searchRect.height := this.height + 2
			
			found := this.Search(searchRect, tolerance)
			
			if (not found) {
				searchRect.x := 0
				searchRect.y += searchRect.height
				searchRect.width := rect.width
				searchRect.height := rect.height - searchRect.y
				
				found := this.Search(searchRect, tolerance)
			}
		}
		
		return positions
	}
	
	Debug() {
		MsgBox(Format("Image:{} Size:{}x{} Transparent:{} Enabled:{} Handle:{}", this.name, this.width, this.height, this.trans, this.enabled, this.handle))
	}
	
	/**
	 * Gets the width and height of an image (no native function to call to make this easier).
	 * https://www.autohotkey.com/boards/viewtopic.php?t=81665
	 * @param {Image} img
	 * @returns {Object} an object containing the width and height of the image in pixels
	 */
	static GetSize(img) {
		if FileExist(img) {
			; TODO: faster solution than this?
			TestImageGui := Gui()
			PicCtrl := TestImageGui.AddPicture("", img)
			ControlGetPos(,, &width, &height, PicCtrl.Hwnd, TestImageGui.Hwnd)
			TestImageGui.Destroy()
			return {width: width, height: height}
		} else {
			MsgBox("Image does not exist: " . img)
			return Null
		}
	}
}
