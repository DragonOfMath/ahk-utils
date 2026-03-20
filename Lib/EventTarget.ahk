#Requires AutoHotkey >=2.0
#Include <Array>

/**
 * @name        EventTarget.ahk
 * @description Basic event-driven extendable class.
 * @version     1.0-2026.03.19
 * @requires    AutoHotkey >=2.0
 * @license     GNU GPLv3
 */

/**
 * @class {EventTarget}
 */
class EventTarget {
	/**
	 * Callbacks mapped by event name.
	 * @type {Object}
	 */
	__listeners := {}
	
	/**
	 * Adds a callback function for an event.
	 * @param {String} event - the event name
	 * @param {Func} callback - the function to call when the event is triggered
	 * @param {Integer} [order=1] - what order to call this in the current chain of callbacks, where 1 appends to the end, and -1 prepends to the start; 0 does nothing
	 * @returns {EventTarget} this
	 */
	AddEventListener(event, callback, order := 1) {
		if (not (event is String)) {
			throw ValueError("Event name must be a string",, event)
		}
		if (not HasMethod(callback, "Call")) {
			throw ValueError("Callback must be a function",, callback)
		}
		if (not this.__listeners.HasOwnProp(event)) {
			this.__listeners.%event% := []
		}
		if (order > 0) {
			this.__listeners.%event%.Push(callback)
		} else if (order < 0) {
			this.__listeners.%event%.InsertAt(1, callback)
		}
		return this
	}
	
	/**
	 * Removes a callback function for an event.
	 * @param {String} event - the event name
	 * @param {Func} callback - the exact callback to remove
	 * @returns {EventTarget} this
	 */
	RemoveEventListener(event, callback) {
		if (not (event is String)) {
			throw ValueError("Event name must be a string",, event)
		}
		if (not HasMethod(callback, "Call")) {
			throw ValueError("Callback must be a function",, callback)
		}
		if (this.__listeners.HasOwnProp(event)) {
			listeners := this.__listeners.%event%
			idx := ArrayIndexOf(listeners, callback)
			if (idx > 0) {
				listeners.RemoveAt(idx)
				if (listeners.Length = 0) {
					this.__listeners.DeleteProp(event)
				}
			}
		}
		return this
	}
	
	/**
	 * Adds or removes a callback function for an event.
	 * @param {String} event - the event name
	 * @param {Func} callback - the function to call when the event is triggered
	 * @param {Integer} [order=1] - 0 will remove the callback, any other value will add it
	 * @void
	 */
	On(event, callback, order := 1) {
		if (order = 0) {
			return this.RemoveEventListener(event, callback)
		} else {
			return this.AddEventListener(event, callback, order)
		}
	}
	
	/**
	 * Adds a callback that can be used once when its event is triggered, then it is removed.
	 * @param {String} event - the event name
	 * @param {Func} callback - the function to call when the event is triggered
	 * @param {Integer} [order=1] - the order in which to call this in the current chain of callbacks
	 * @returns {EventTarget} this
	 */
	AddEventListenerOnce(event, callback, order := 1) {
		_this := this
		callItOnce(args*) {
			_this.RemoveEventListener(event, callItOnce)
			callback(args*)
		}
		return this.AddEventListener(event, callItOnce, order)
	}
	
	/**
	 * Limits the number of times a callback is called before it is automatically removed.
	 * @param {String} event - the event name
	 * @param {Func} callback - the function to call when the event is triggered
	 * @param {Integer} [order=1]
	 * @param {Integer} [times=1] - limits the number of times the callback may be called
	 * @returns {EventTarget} this
	 */
	AddEventListenerLimited(event, callback, order := 1, times := 1) {
		_this := this
		callItLimited(args*) {
			if (--times <= 0) {
				_this.RemoveEventListener(event, callItLimited)
			}
			callback(args*)
		}
		return this.AddEventListener(event, callItLimited, order)
	}
	
	/**
	 * Adds a callback that is called with delay between triggering and executing.
	 * @param {String} event - the event name
	 * @param {Func} callback - the function to call when the event is triggered
	 * @param {Integer} [order=1]
	 * @param {Integer} [delay=0] - delay in milliseconds after the event is triggered
	 * @returns {EventTarget} this
	 */
	AddEventListenerDelayed(event, callback, order := 1, delay = 0) {
		callItDelayed(args*) {
			Sleep(delay)
			callback(args*)
		}
		return this.AddEventListener(event, callItDelayed, order)
	}
	
	/**
	 * Removes all callbacks for an event.
	 * @param {String} event - the event name
	 * @returns {EventTarget} this
	 */
	ClearEventListeners(event) {
		if (not (event is String)) {
			throw ValueError("Event name must be a string",, event)
		}
		this.__listeners.DeleteProp(event)
		return this
	}
	
	/**
	 * Dispatches an event with the given arguments passed to each of its callbacks.
	 * @param {String} event - the event name
	 * @param {any[]} args* - arguments
	 * @void
	 */
	Trigger(event, args*) {
		if (not (event is String)) {
			throw ValueError("Event name must be a string",, event)
		}
		listeners := this.__listeners.%event%
		if (listeners) {
			for fn in listeners {
				fn(args*)
			}
		}
	}
}
