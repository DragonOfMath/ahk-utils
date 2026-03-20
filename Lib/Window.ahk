#Requires AutoHotkey >=2.0
#Include <Point>
#Include <Rect>

/**
 * @name        Window.ahk
 * @description Utility for application window extraction and manipulation.
 * @version     1.1-2026.03.19
 * @requires    AutoHotkey >=2.0
 * @license     GNU GPLv3
 * Changelog:
 * v1.1 - cleanup and docs
 * v1.0 - initial release
 */

/**
 * Application window wrapper class.
 * @class {Window}
 * @property {String} Title - identifies the window when searching for its handle
 * @property {Rect} rect - window screen position and size
 * @property {Rect} clientRect - window inner size (position is always zero)
 */
class Window {
	Title := ""
	rect := Rect()
	clientRect := Rect()
	
	/**
	 * @constructor
	 * @param {String} title
	 */
	__New(title) {
		this.Title := title
		this.clientRect.size := this.rect.size
		return this
	}
	
	/**
	 * Handle of the window, if it exists.
	 * @type {Integer}
	 * @readonly
	 */
	Handle => WinExist(this.Title)
	
	/**
	 * Process ID of the window.
	 * @type {Integer}
	 * @readonly
	 */
	ID => WinGetID(this.Title)
	
	/**
	 * Whether the window is currently open.
	 * @type {Boolean}
	 * @readonly
	 */
	isOpen => this.Handle > 0
	
	/**
	 * Whether this is currently the active window.
	 * @type {Boolean}
	 * @readonly
	 */
	isActive => WinActive(this.Title) > 0
	
	/**
	 * Position of the window relative to the screen.
	 * @type {Point}
	 */
	pos {
		get => this.rect.pos
		set {
			this.rect.pos.Set(value.x, value.y)
			this.__updateWindow()
		}
	}
	
	/**
	 * Size of the window.
	 * @type {Point}
	 */
	size {
		get => this.rect.size
		set {
			this.rect.size.Set(value.x, value.y)
			this.__updateWindow()
		}
	}
	
	/**
	 * Width of the window.
	 * @type {Integer}
	 */
	width {
		get => this.rect.width
		set {
			this.rect.width := value
			this.__updateWindow()
		}
	}
	
	/**
	 * Height of the window.
	 * @type {Integer}
	 */
	height {
		get => this.rect.height
		set {
			this.rect.height := value
			this.__updateWindow()
		}
	}
	
	/**
	 * Sets this to be the active window.
	 * @returns {Integer} window handle
	 */
	Activate() {
		return WinActivate(this.Handle)
	}
	
	/**
	 * Puts window into fullscreen (makes it the same size as the screen).
	 * @returns {Window} this
	 */
	FullScreen() {
		this.rect.Set(0, 0, A_ScreenWidth, A_ScreenHeight)
		this.__updateWindow()
		return this
	}
	
	/**
	 * Minimizes the window.
	 * @returns {Window} this
	 */
	Minimize() {
		WinMinimize(this.Handle)
		this.__updateRect()
		return this
	}
	
	/**
	 * Maximizes the window.
	 * @returns {Window} this
	 */
	Maximize() {
		WinMaximize(this.Handle)
		this.__updateRect()
		return this
	}
	
	/**
	 * Restores the window to its previous size if minimized or maximized.
	 * @returns {Window} this
	 */
	Restore() {
		WinRestore(this.Handle)
		this.__updateRect()
		return this
	}
	
	/**
	 * Moves the window to the top-left of the screen.
	 * @returns {Window} this
	 */
	static MoveToTopLeft() {
		this.pos := Point(0, 0)
		return this
	}
	
	/**
	 * Moves the window to the bottom-left of the screen.
	 * @returns {Window} this
	 */
	MoveToBottomLeft() {
		this.pos := Point(0, A_ScreenHeight - this.height)
		return this
	}
	
	/**
	 * Moves the DML window to the top-right of the screen.
	 * @returns {Window} this
	 */
	MoveToTopRight() {
		this.pos := Point(A_ScreenWidth - this.width, 0)
		return this
	}
	
	/**
	 * Moves the window to the bottom-right of the screen.
	 * @returns {Window} this
	 */
	MoveToBottomRight() {
		this.pos := Point(A_ScreenWidth - this.width, A_ScreenHeight - this.height)
		return this
	}
	
	/**
	 * Centers the window.
	 * @returns {Window} this
	 */
	Center() {
		this.pos := Point((A_ScreenWidth-this.width)/2, (A_ScreenHeight-this.height)/2)
		return this
	}
	
	/**
	 * Closes the window.
	 * @returns {Window} this
	 */
	Close() {
		WinClose(this.Handle)
		return this
	}
	
	/**
	 * Caches the window's current position and size.
	 * @private
	 * @void
	 */
	__updateRect() {
		this.rect.FromWindow(this.Handle)
	}
	/**
	 * Applies new position and size to the window.
	 * @private
	 * @void
	 */
	__updateWindow() {
		this.rect.ToWindow(this.Handle)
	}
}