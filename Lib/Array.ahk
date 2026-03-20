#Requires AutoHotkey >=2.0
#Include <Error>

/**
 * @name        Array.ahk
 * @description Library that extends the Array class to bring features similar to JavaScript and other languages.
 * @version     1.4-2026.01.12
 * @requires    Autohotkey >=2.0
 * @license     GNU GPLv3
 * Changelog:
 * v1.4 - upgrade Reduce to behave more like JavaScript, which allows for an unset initial value; added IsArray, ArrayAssert, ArrayFill, ArrayLastIndexOf, and ArrayReduceRight, ArraySearchLast; added Set-like methods
 * v1.3 - added Reduce and GroupBy methods, and automatic ToString calls when Joining
 * v1.2 - added Flat, Some, and Every methods
 * v1.1 - added Sort and Random methods
 * v1.0 - initial release
 */

__IdentityFunc := (x,*) => x
__DefaultComparator := (a,b,*) => a < b ? -1 : a > b ? 1 : 0

/**
 * Whether a value is an Array.
 * @param {Any} arr
 * @returns {Boolean}
 */
IsArray(arr,*) {
	return arr is Array
}

/**
 * Constructs a new array filled with items mapped from 1 to the length specified.
 * @param {Number} length - number of elements to create
 * @param {Func} [map] - maps indices to values
 * @returns {Array}
 */
ArrayComprehend(length, map := __IdentityFunc) {
	AssertTypes([length, map], [Integer, Func])
	arr := []
	loop length {
		arr.Push(map(A_Index))
	}
	return arr
}

/**
 * Fills an array with values from a range.
 * @param {Number} [start]
 * @param {Number} [end]
 * @param {Number} [step]
 */
ArrayRange(start := 0, end := 1, step := 1) {
	return ArrayComprehend(1 + (end - start) // step, (i) => start + step * (i - 1))
}

/**
 * Asserts each item in the array with a conditional.
 * @param {Array} arr
 * @param {Func} condition - conditional function for passing assertion, defaults to the identity function
 * @param {String} [msg] - custom fail message
 */
ArrayAssert(arr, condition := __IdentityFunc, msg := "failed assertion") {
	AssertTypes([arr, condition, msg], [Array, Func, String])
	loop arr.Length {
		Assert(condition(arr[A_Index], A_Index, arr), "Item " . A_Index . " " . msg)
	}
	return arr
}

/**
 * Asserts that all arguments are Arrays.
 * @param {Array[]} arrs*
 * @returns {Boolean}
 */
AssertArrays(arrs*) {
	return ArrayAssert(arrs, IsArray, "must be an Array")
}

/**
 * Checks if an array contains a value.
 * @param {Array} this
 * @param {Any} val
 * @returns {Boolean} true if found, otherwise false
 */
ArrayContains(this, val) {
	AssertArrays(this)
	loop this.Length {
		if (this[A_Index] = val) {
			return true
		}
	}
	return false
}

/**
 * Finds the index of a value in an array.
 * @param {Array} this
 * @param {Any} val
 * @returns {Number} index of the first match, or 0 if not found
 */
ArrayIndexOf(this, val) {
	AssertArrays(this)
	loop this.Length {
		if (this[A_Index] = val) {
			return A_Index
		}
	}
	return 0
}

/**
 * Finds the last index of a value in an array.
 * @param {Array} this
 * @param {Any} val
 * @returns {Number} index of the first match, or 0 if not found
 */
ArrayLastIndexOf(this, val) {
	AssertArrays(this)
	len := this.Length
	loop len {
		idx := len - (A_Index - 1)
		if (this[idx] = val) {
			return idx
		}
	}
	return 0
}

/**
 * Removes all items in an array.
 * @param {Array} this
 * @returns {Array}
 */
ArrayClear(this) {
	AssertArrays(this)
	while (this.Length) {
		this.Pop()
	}
	return this
}

/**
 * Fills an array with the same value.
 * @param {Array} this
 * @param {Any} value
 * @returns {Array}
 */
ArrayFill(this, value) {
	AssertArrays(this)
	loop this.Length {
		this[A_Index] := value
	}
	return this
}

/**
 * Joins the items of an array.
 * @param {Array} this
 * @param {String} [sep=","] - delimiter to separate elements
 * @returns {String}
 */
ArrayJoin(this, sep := ",") {
	AssertTypes([this, sep], [Array, String])
	str := ""
	loop this.Length {
		val := this[A_Index]
		if (val is Object and val.HasMethod("ToString")) {
			val := val.ToString()
		}
		str .= val . sep
	}
	return SubStr(str, 1, -StrLen(sep))
}

/**
 * Reverses the order of items of an array.
 * @param {Array} this
 * @returns {Array} new array
 */
ArrayReverse(this) {
	AssertArrays(this)
	reversed := []
	i := this.Length
	while (i > 0) {
		reversed.Push(this[i--])
	}
	return reversed
}

/**
 * Removes an item from the start of an array.
 * @param {Array} this
 * @returns {Any} the item(s) removed
 */
ArrayShift(this) {
	AssertArrays(this)
	return this.RemoveAt(1)
}

/**
 * Pushes items to the start of an array.
 * @param {Array} this
 * @param {Any} vals*
 * @returns {Array} this
 */
ArrayUnshift(this, vals*) {
	AssertArrays(this)
	return this.InsertAt(1, vals*)
}

/**
 * Slices an array, up to and including the ending index.
 * @param {Array} this
 * @param {Number} [startIndex=1] - starting index; if non-positive, starts from an offset from the end of the array
 * @param {Number} [endIndex=0] - ending index; if non-positive, ends at an offset from the end of the array
 * @param {Number} [stride=1] - stepping size, cannot be zero or negative
 * @returns {Array} an array with the sliced contents
 */
ArraySlice(this, startIndex := 1, endIndex := 0, stride := 1) {
	AssertTypes([this, startIndex, endIndex, stride], [Array, Integer, Integer, Integer])
	len := this.Length
	if (len = 0) {
		return this
	}
	if (startIndex < 1) {
		startIndex := len - startIndex
	}
	startIndex := Min(startIndex, len)
	if (endIndex < 1) {
		endIndex := len - endIndex
	}
	endIndex := Min(endIndex, len)
	stride := Abs(stride)
	
	sliced := []
	if (stride > 0) {
		index := startIndex
		if (startIndex > endIndex) {
			while (index >= endIndex) {
				sliced.Push(this[index])
				index -= stride
			}
		} else {
			while (index <= endIndex) {
				sliced.Push(this[index])
				index += stride
			}
		}
	}
	return sliced
}

/**
 * Splices an array by removing and inserting elements in-place.
 * @param {Array} this
 * @param {Number} index - the index to remove elements from and insert elements into; if non-positive, starts at the offset from the end
 * @param {Number} [remove=0] - number of elements to remove from the array at the index
 * @param {Any[]} [...insertItems] - elements to insert into the array starting at the index
 * @returns {Array} this array
 */
ArraySplice(this, index := 1, remove := 0, insertItems*) {
	AssertTypes([this, index, remove], [Array, Integer, Integer])
	if (index < 1) {
		index := this.Length - index
	}
	index := Min(index, this.Length)
	remove := Min(Max(remove, 1), this.Length)
	if (remove) {
		this.RemoveAt(index, remove)
	}
	if (insertItems.Length) {
		this.InsertAt(index, insertItems*)
	}
	return this
}

/**
 * Combines multiple arrays into one array.
 * @param {Array} this
 * @param {Array[]} [...arrs]
 * @return {Array}
 */
ArrayConcat(this, arrs*) {
	AssertArrays(this, arrs*)
	concatenated := ArraySlice(this)
	loop arrs.Length {
		concatenated.Push(arrs[A_Index]*)
	}
	return concatenated
}

/**
 * Copies elements from target array to source array in-place.
 * @param {Array} this - array to copy elements into
 * @param {Array} src - array to copy elements from
 * @param {Number} [startIndex=1] - starting index to copy elements into the target array; if non-positive, starts at the offset from the end
 * @param {Number} [endIndex=0] - ending index to copy elements into the target array; if non-positive, ends at the offset from the end
 * @param {Number} [copyStartIndex=1] - starting index to copy elements from the source array; if non-positive, starts at the offset from the end
 * @param {Number} [copyEndIndex=0] - ending index to copy elements from the source array; if non-positive, ends at the offset from the end
 * @returns {Array} this array
 */
ArrayCopy(this, src, startIndex := 1, endIndex := 0, copyStartIndex := 1, copyEndIndex := 0) {
	AssertTypes([this, src, startIndex, endIndex, copyStartIndex, copyEndIndex], [Array, Array, Integer, Integer, Integer, Integer])
	if (startIndex < 1) {
		startIndex := this.Length - startIndex
	}
	if (endIndex < 1) {
		endIndex := this.Length - endIndex
	}
	if (copyStartIndex < 1) {
		copyStartIndex := src.Length - copyStartIndex
	}
	if (copyEndIndex < 1) {
		copyEndIndex := src.Length - copyEndIndex
	}
	startIndex := Min(startIndex, this.Length)
	endIndex := Min(endIndex, this.Length)
	copyStartIndex := Min(copyStartIndex, src.Length)
	copyEndIndex := Min(copyEndIndex, src.Length)
	copied := ArraySlice(src, copyStartIndex, copyEndIndex)
	return ArraySplice(this, startIndex, endIndex-startIndex+1, copied*)
}

/**
 * Flattens an array by concatenating nested arrays to the parent array, up to a specified depth.
 * @param {Array} this
 * @param {Number} [depth=-1] - number of nested levels to flatten
 * @returns {Array}
 */
ArrayFlat(this, depth := -1) {
	AssertTypes([this, depth], [Array, Integer])
	flattened := []
	loop this.Length {
		val := this[A_Index]
		if (val is Array and depth != 0) {
			flattened := ArrayConcat(flattened, ArrayFlat(val, depth-1))
		} else {
			flattened.Push(val)
		}
	}
	return flattened
}

/**
 * Searches the array for an item that satisfies the searcher function.
 * @param {Array} this
 * @param {Func} searcher
 * @returns {Number} the index of the first item found, or 0 if not found
 */
ArraySearch(this, searcher) {
	AssertTypes([this, searcher], [Array, Func])
	loop this.Length {
		if (searcher(this[A_Index],A_Index)) {
			return A_Index
		}
	}
	return 0
}

/**
 * Searches the array for the last item that satisfies the searcher function and returns its index.
 * @param {Array} this
 * @param {Func} searcher
 * @returns {NUmber} the index of the last item found, or 0 if not found
 */
ArraySearchLast(this, searcher) {
	AssertTypes([this, searcher], [Array, Func])
	len := this.Length
	loop this.Length {
		idx := len - (A_Index - 1)
		if (searcher(this[idx], idx, this)) {
			return idx
		}
	}
	return 0
}

/**
 * Maps the elements of an array to a new array.
 * @param {Array} this
 * @param {Func} map - accepts the value and index as arguments
 * @returns {Array}
 */
ArrayMap(this, map) {
	AssertTypes([this, map], [Array, Func])
	mapped := []
	loop this.Length {
		mapped.Push(map(this[A_Index], A_Index))
	}
	return mapped
}

/**
 * Filters the array by keeping items that satisfy the filter function.
 * @param {Array} this
 * @param {Func} [filter] - accepts the value and index as arguments
 * @returns {Array} items from the source array that passed the filter
 */
ArrayFilter(this, filter := 0) {
	if (filter = 0) {
		filter := __IdentityFunc
	}
	AssertTypes([this, filter], [Array, Func])
	filtered := []
	loop this.Length {
		val := this[A_Index]
		if (filter(val,A_Index)) {
			filtered.Push(val)
		}
	}
	return filtered
}

/**
 * Filters the array by keeping items that *don't* satisfy the filter function, excluding all else.
 * @param {Array} this
 * @param {Func} filter - accepts the value and index as arguments
 * @returns {Array} items from the source array that failed the filter
 */
ArrayExclude(this, filter := 0) {
	if (filter = 0) {
		filter := __IdentityFunc
	}
	AssertTypes([this, filter], [Array, Func])
	filtered := []
	loop this.Length {
		val := this[A_Index]
		if (not filter(val,A_Index)) {
			filtered.Push(val)
		}
	}
	return filtered
}

/**
 * Reduces an array to a single value by processing each item through a reducer function.
 * The default reducer function is a no-op that returns the initial value.
 * @param {Array} this
 * @param {Func} [reducer] - accepts the current state of the reduction, the array value, and array index, and returns the new state of the reduction
 * @param {?Any} [initialValue?] - starting value of the reduction state; if omitted, the reducer initializes to the first value in the array
 * @returns {Any}
 */
ArrayReduce(this, reducer := 0, initialValue?) {
	if (reducer = 0) {
		reducer := __IdentityFunc
	}
	AssertTypes([this, reducer], [Array, Func])
	initialValueNotSet := not IsSet(initialValue)
	reduced := initialValueNotSet ? this[1] : initialValue
	loop this.Length {
		if (A_Index = 1 and initialValueNotSet) {
			continue
		} else {
			reduced := reducer(reduced, this[A_Index], A_Index)
		}
	}
	return reduced
}

/**
 * Reduces an array to a single value by processing each item through a reducer function, starting from the end of the array.
 * The default reducer function is a no-op that returns the initial value.
 * @param {Array} this
 * @param {Func} [reducer] - accepts the current state of the reduction, the array value, and array index, and returns the new state of the reduction
 * @param {?Any} [initialValue?] - starting value of the reduction state; if omitted, the reducer initializes to the last value in the array
 * @returns {Any}
 */
ArrayReduceRight(this, reducer := 0, initialValue?) {
	if (reducer = 0) {
		reducer := __IdentityFunc
	}
	AssertTypes([this, reducer], [Array, Func])
	len := this.Length
	initialValueNotSet := not IsSet(initialValue)
	reduced := initialValueNotSet ? this[len] : initialValue
	loop len {
		if (A_Index = 1 and initialValueNotSet) {
			continue
		} else {
			idx := len - (A_Index - 1)
			reduced := reducer(reduced, this[idx], A_Index)
		}
	}
	return reduced
}

/**
 * Calls the callback function for each item in the array.
 * @param {Array} this
 * @param {Func} callback - accepts the value and index as arguments
 * @returns {Array} this
 */
ArrayForEach(this, callback) {
	AssertTypes([this, callback], [Array, Func])
	loop this.Length {
		callback(this[A_Index], A_Index)
	}
	return this
}

/**
 * Checks every item in the array for at least one to pass a criterion.
 * @param {Array} this
 * @param {Func} condition - accepts the value and index as arguments
 * @returns {Boolean}
 */
ArraySome(this, condition) {
	if (condition = 0) {
		condition := __IdentityFunc
	}
	AssertTypes([this, condition], [Array, Func])
	loop this.Length {
		val := this[A_Index]
		if (condition(val, A_Index)) {
			return true
		}
	}
	return false
}

/**
 * Checks that every item in the array passes a criterion.
 * @param {Array} this
 * @param {Func} condition - accepts the value and index as arguments
 * @returns {Boolean}
 */
ArrayEvery(this, condition := 0) {
	if (condition = 0) {
		condition := __IdentityFunc
	}
	AssertTypes([this, condition], [Array, Func])
	loop this.Length {
		val := this[A_Index]
		if (not condition(val,A_Index)) {
			return false
		}
	}
	return this.Length > 0
}

/**
 * Sorts an array.
 * @param {Array} this
 * @param {Func} [comparator] - compares two values in the array, returning -1 to place the first before the second, 1 to place after the second, or 0 to not move them
 * @returns {Array} new array
 */
ArraySort(this, comparator := 0) {
	if (comparator = 0) {
		comparator := __DefaultComparator
	}
	AssertTypes([this, comparator], [Array, Func])
	sorted := []
	len := 0
	for x in this {
		mid := len // 2
		len++
		if (mid) {
			switch (comparator(x, sorted[mid])) {
				case -1:
					loop {
						mid--
					} until (mid = 0 or comparator(x, sorted[mid]) > -1)
				case 1:
					loop {
						mid++
					} until (mid = len or comparator(x, sorted[mid]) < 1)
			}
		}
		sorted.InsertAt(mid, x)
	}
	return sorted
}

/**
 * Groups items in an array.
 * @param {Array} this
 * @param {String|Func} [grouper] - groups elements by a key or mapping function
 * @returns {Object<Array>} items grouped by key
 */
ArrayGroupBy(this, grouper := 0) {
	if (grouper = 0) {
		grouper := __IdentityFunc
	}
	Assert(this is Array, "Parameter 1 must be an Array")
	Assert(grouper is String or grouper is Func, "Parameter 2 must be a Function or String")
	groups := {}
	loop this.Length {
		x := this[A_Index]
		g := grouper is String ? x.%grouper% : grouper(x,A_Index)
		if (not groups.HasOwnProp(g)) {
			groups.%g% := []
		}
		groups.%g%.Push(x)
	}
	return groups
}

/**
 * Selects a random element in an array.
 * Empty array returns empty string.
 * @param {Array} this
 * @returns {Any}
 */
ArrayRandom(this) {
	AssertArrays(this)
	return this.Length > 0 ? this[Random(1, this.Length)] : ""
}

/**
 * Returns an array with only unique elements.
 * @param {Array} this
 * @returns {Array}
 */
ArrayUnique(this) {
	return ArrayReduce(this, (uniq,elem,*) => ArrayContains(uniq,elem) ? uniq : (uniq.Push(elem), uniq), [])
}

/**
 * Unionizes multiple arrays into one array containing unique elements from all arrays.
 * @param {Array[]} arrs*
 * @returns {Array}
 */
ArrayUnion(arrs*) {
	AssertArrays(arrs*)
	union := []
	loop arrs.Length {
		for x in arrs[A_Index] {
			if (not ArrayContains(union, x)) {
				union.Push(x)
			}
		}
	}
	return union
}

/**
 * Excludes elements from the first array if they are included in the other arrays.
 * @param {Array} this
 * @param {Array[]} arrs*
 * @returns {Array}
 */
ArrayDifference(this, arrs*) {
	return ArrayExclude(this, (elem,*) => ArraySome(arrs, (arr,*) => ArrayContains(arr,elem)))
}

/**
 * Includes elements from the first array only if they are included in all the other arrays.
 * @param {Array} this
 * @param {Array[]} arrs*
 * @returns {Array}
 */
ArrayIntersection(this, arrs*) {
	return ArrayFilter(this, (elem,*) => ArrayEvery(arrs, (arr,*) => ArrayContains(arr,elem)))
}

/**
 * Excludes elements that are found in both arrays, effectively being the union minus the intersection.
 * @param {Array} this
 * @param {Array} arr
 * @returns {Array}
 */
ArraySymmetricDifference(this, arr) {
	AssertArrays(this, arr)
	symdiff := []
	for x in this {
		if (not ArrayContains(arr, x)) {
			symdiff.Push(x)
		}
	}
	for x in arr {
		if (not ArrayContains(this, x)) {
			symdiff.Push(x)
		}
	}
	return symdiff
}

Array.IsArray := IsArray
Array.Comprehend := ArrayComprehend
Array.Range := ArrayRange
ArrayBase := [].Base
ArrayBase.Assert := ArrayAssert
ArrayBase.Contains := ArrayContains
ArrayBase.IndexOf := ArrayIndexOf
ArrayBase.LastIndexOf := ArrayLastIndexOf
ArrayBase.Clear := ArrayClear
ArrayBase.Fill := ArrayFill
ArrayBase.Join := ArrayJoin
ArrayBase.Reverse := ArrayReverse
ArrayBase.Shift := ArrayShift
ArrayBase.Unshift := ArrayUnshift
ArrayBase.Slice := ArraySlice
ArrayBase.Splice := ArraySplice
ArrayBase.Concat := ArrayConcat
ArrayBase.Copy := ArrayCopy
ArrayBase.Flat := ArrayFlat
ArrayBase.Search := ArraySearch
ArrayBase.SearchLast := ArraySearchLast
ArrayBase.Map := ArrayMap
ArrayBase.Filter := ArrayFilter
ArrayBase.Exclude := ArrayExclude
ArrayBase.Reduce := ArrayReduce
ArrayBase.ReduceRight := ArrayReduceRight
ArrayBase.ForEach := ArrayForEach
ArrayBase.Some := ArraySome
ArrayBase.Every := ArrayEvery
ArrayBase.Sort := ArraySort
ArrayBase.GroupBy := ArrayGroupBy
ArrayBase.Random := ArrayRandom
ArrayBase.Unique := ArrayUnique
ArrayBase.Union := ArrayUnion
ArrayBase.Difference := ArrayDifference
ArrayBase.Intersection := ArrayIntersection
ArrayBase.SymmetricDifference := ArraySymmetricDifference
