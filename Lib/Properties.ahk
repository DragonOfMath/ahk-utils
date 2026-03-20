#Requires AutoHotkey >=2.0
#Include <String>
#Include <Object>
#Include <Error>
#Include <JSON>

/**
 * @name        Properties.ahk
 * @description Simplified saving and loading of JSON data.
 * @version     1.0-2026.03.19
 * @requires    Autohotkey >=2.0
 * @license     GNU GPLv3
 */

/**
 * Interface for saving properties to and loading properties from a file.
 * The properties file uses JSON format, which is very compatible with AHK objects.
 * Double-underscore-prefixed properties are ignored during JSON serialization.
 * @class {Properties}
 * @property {String} __filename - Path to the file for saving and loading properties.
 * @property {Boolean} __loaded - Flag for when data has been loaded from file.
 * @property {Boolean} __saved - Flag for when changes to data have been saved to file.
 */
class Properties {
	__filename := ""
	__loaded := false
	__saved := false
	
	/**
	 * @constructor
	 * @param {String} filename
	 */
	__New(filename) {
		Assert(filename is String, "filename must be a String")
		this.__filename := filename
	}
	
	/**
	 * Proxy for dynamically getting/setting a property.
	 * @type {Any}
	 */
	__Item[prop] {
		get {
			return this.%prop%
		}
		set {
			this.%prop% := value
			this.__saved := false
		}
	}
	
	/**
	 * Gets a property's value.
	 * @param {String} prop - property chain, such as `prop.subprop`
	 * @returns {Any} the property's value
	 */
	Get(prop) {
		return GetObjectProp(this, prop)
	}
	
	/**
	 * Sets a property's value.
	 * @param {String} prop - property chain, such as `prop.subprop`
	 * @param {Any} value - the property's value
	 * @returns {Any} value
	 */
	Set(prop, value) {
		SetObjectProp(this, prop, value)
		this.__saved := false
		return value
	}
	
	/**
	 * Checks whether a property exists.
	 * @param {String} prop - property chain, such as `prop.subprop`
	 * @returns {Boolean}
	 */
	Has(prop) {
		return ObjectPropExists(this, prop)
	}
	
	/**
	 * Deletes a property.
	 * @param {String} prop - property chain, such as `prop.subprop`
	 * @returns {Properties}
	 */
	Delete(prop) {
		DeleteObjectProp(this, prop)
		this.__saved := false
		return this
	}
	
	/**
	 * Saves to file if changes have been made to this object's properties.
	 * @returns {Properties} this
	 */
	Save() {
		if (not this.__saved) {
			JSON.WriteFile(this.__filename, this, true)
			this.__saved := true
		}
		return this
	}
	
	/**
	 * Loads from file.
	 * @returns {Properties} this
	 */
	Load() {
		if (not this.__loaded) {
			data := JSON.ReadFile(this.__filename)
			ObjMerge(this, data)
			this.__loaded := true
			this.__saved := true
		}
		return this
	}
	
	/**
	 * Unloads the contents of this object by deleting all of its properties.
	 * @returns {Properties} this
	 */
	Unload() {
		for k,v in this.OwnProps() {
			if (StrStartsWith(k, "__")) {
				continue
			}
			if (this.HasOwnProp(k)) {
				this.DeleteProp(k)
			}
		}
		this.__loaded := false
		this.__saved := false
		return this
	}
	
	/**
	 * Reloads properties from file.
	 * @returns {Properties} this
	 */
	Reload() {
		return this.Unload().Load()
	}
}
