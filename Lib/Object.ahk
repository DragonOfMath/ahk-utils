#Requires AutoHotkey >=2.0
#Include <Error>

/**
 * @name        Object.ahk
 * @description Utilities for all AHK objects.
 * @version     1.2-2026.03.19
 * @requires    Autohotkey >=2.0
 * @license     GNU GPLv3
 * Changelog:
 * v1.2 - cleanup
 * v1.1 - object merging, assigning, and property manipulation from prop chains
 * v1.0 - initial release
 */

/**
 * Asserts a value is an object.
 * @param {Any} obj
 * @param {Integer} [index=0] - optional parameter index for debugging purposes
 * @returns {Boolean} true if the value is an object; otherwise, throws an assertion error
 */
AssertObject(obj, index := 0) {
	return Assert(obj is Object, (index ? ("Parameter " . index) : "Argument") . " must be an Object")
}

/**
 * Gets the property in an object at the key address.
 * @param {Object} root
 * @param {String|String[]} key
 * @returns {Any}
 */
GetObjectProp(root, key) {
	chain := key is Array ? key : StrSplit(key, ".")
	i := 1
	key := chain[i]
	while (i < chain.Length) {
		if (root is Array) {
			root := root[key]
		} else {
			root := root.%key%
		}
		i++
		key := chain[i]
	}
	if (root is Array) {
		return root[key]
	} else {
		return root.%key%
	}
}

/**
 * Sets the property in an object at the key address.
 * @param {Object} root
 * @param {String|String[]} key
 * @param {Any} value
 * @void
 */
SetObjectProp(root, key, value) {
	chain := key is Array ? key : StrSplit(key, ".")
	i := 1
	key := chain[i]
	while (i < chain.Length) {
		if (root is Array) {
			root := root[key]
		} else {
			root := root.%key%
		}
		i++
		key := chain[i]
	}
	if (root is Array) {
		root[key] := value
	} else {
		root.%key% := value
	}
}

/**
 * Deletes the property in an object at the key address.
 * @param {Object} root
 * @param {String|String[]} key
 * @returns {Object}
 */
DeleteObjectProp(root, key) {
	chain := key is Array ? key : StrSplit(key, ".")
	key := chain.Pop()
	root := GetObjectProp(root, chain)
	root.DeleteProp(key)
	return root
}

/**
 * Checks if the property exists in the object at the key address.
 * @param {Object} root
 * @param {String|String[]} key
 * @returns {Boolean}
 */
ObjectPropExists(root, key) {
	chain := key is Array ? key : StrSplit(key, ".")
	key := chain.Pop()
	root := GetObjectProp(root, chain)
	return root.HasOwnProp(key)
}

/**
 * Copies properties from source objects to the target object.
 * @param {Object} target
 * @param {Object[]} objs*
 * @returns {Object} target
 */
ObjAssign(target, objs*) {
	AssertObject(target)
	for obj in objs {
		for k,v in obj.OwnProps() {
			target.%k% := v
		}
	}
	return target
}

/**
 * Merges objects such that properties that are objects themselves are merged with same-name properties.
 * Arrays are concatenated when merging and non-object properties overwrite the target's value.
 * @param {Object} target
 * @param {Object[]} objs*
 * @returns {Object} target
 */
ObjMerge(target, objs*) {
	AssertObject(target)
	for obj in objs {
		if (obj is Array) {
			target.Push(obj*)
		} else if (obj is Object) {
			for k,v in obj.OwnProps() {
				if (target.HasOwnProp(k) and v is Object and target.%k% is Object) {
					try {
						target.%k% := ObjMerge(target.%k%, v)
					} catch Any as err {
						throw ValueError(err,, k)
					}
				} else {
					target.%k% := v
				}
			}
		}
	}
	return target
}

/**
 * Whether an object has no self-properties.
 * @param {Object} this
 * @returns {Boolean}
 */
ObjIsEmpty(this) {
	AssertObject(this)
	return ObjOwnPropCount(this) = 0
}

/**
 * Gets the property names of an object as an array.
 * @param {Object} this
 * @returns {String[]}
 */
ObjKeys(this) {
	AssertObject(this)
	keys := []
	for key,val in this.OwnProps() {
		keys.Push(key)
	}
	return keys
}

/**
 * Gets the property values of an object as an array.
 * @param {Object} this
 * @returns {Any[]}
 */
ObjValues(this) {
	AssertObject(this)
	values := []
	for key,val in this.OwnProps() {
		values.Push(val)
	}
	return values
}

/**
 * Gets the key-value pairs of an object.
 * Alternative to OwnProps()
 * @param {Object} this
 * @returns {Any[]}
 */
ObjPairs(this) {
	AssertObject(this)
	return this.OwnProps()
}

Object.IsObject := IsObject ; https://www.autohotkey.com/docs/v2/lib/IsObject.htm
;Object.IsEmpty := ObjIsEmpty
Object.Assert := AssertObject
Object.Assign := ObjAssign
Object.Merge := ObjMerge
Object.Keys := ObjKeys
Object.Values := ObjValues
Object.Pairs := ObjPairs

ObjBase := {}.Base
ObjBase.IsEmpty := ObjIsEmpty
ObjBase.Keys := ObjKeys
ObjBase.Values := ObjValues
ObjBase.Pairs := ObjPairs