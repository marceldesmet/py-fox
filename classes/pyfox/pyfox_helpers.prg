* Prefix _PyFox for helpers to avoid name clashes

FUNCTION _PyFoxNative(pyobj, ldDictToObject)

	IF PCOUNT() < 2
		ldDictToObject = .F.
	ENDIF
	* _PyFoxNative: Convert Python wrapper objects and native values to VFP
	* native types recursively.
	* - pyobj: VFP wrapper object (PythonObjectImpl or PythonObject), or a native value.
	* Returns:
	* - Scalars (strings, numbers, bool); VFP datatypes (DATE/DATETIME);
	* - Collections for sequences (Python list/tuple -> VFP Collection of converted elements)
	* - Collection-of-pairs for dicts (2-element arrays: [key, value])
	* - .NULL. for Python None
	* - String repr() for complex/unhandled objects
	LOCAL loVal, loColl, loObj, loItem, loOut, lnI, laPair, loKeysColl, loKeys, lcKey
	* Native type: return as-is
	IF VARTYPE(pyobj) != 'O'
		RETURN pyobj
	ENDIF

	* If it's a wrapper, try to get a native value (getval)
	loVal = pyobj.getval()
	IF VARTYPE(loVal) != 'O'
		RETURN loVal
	ENDIF

	* IMPORTANT: Check for dict-like objects FIRST before trying .Iter
	* because Python dicts are iterable (yield keys only), which would lose values!
	TRY
		loKeys = pyobj.CallMethodRetObj('keys', _PyEmptyTuple, .NULL.)
	CATCH TO oerr2
		loKeys = .NULL.
	ENDTRY
	
	* If we have keys(), extract key-value pairs and convert values recursively
	IF VARTYPE(loKeys) == 'O'
		loKeysColl = loKeys.Iter
		IF ldDictToObject
			loOut = CREATEOBJECT('Empty')
		ELSE
			loOut = CREATEOBJECT('jsArray')
		ENDIF
		FOR EACH lcKey IN loKeysColl
			LOCAL loV
			IF VARTYPE(lcKey) == 'O'
				lcKey = lcKey.getval()
			ENDIF
			loV = pyobj.GetItem(lcKey)
			IF VARTYPE(loV) == 'O'
				loV = _PyFoxNative(loV, ldDictToObject)
			ENDIF
			IF ldDictToObject
				* Add as named property so dot-notation works (loOut.key)
				ADDPROPERTY(loOut, lcKey, loV)
			ELSE
				* Use jsArray.pushpair() to store key-value pairs (VFP arrays can't be added to Collections by value)
				loOut.pushpair(lcKey, loV)
			ENDIF
		ENDFOR
		RETURN loOut
	ENDIF

	* If not dict-like, try to iterate it (list/tuple/iterable)
	TRY
		loColl = pyobj.Iter
	CATCH TO oerr
		loColl = .NULL.
	ENDTRY

	IF VARTYPE(loColl) == 'O'
		* Convert elements recursively
		loOut = CREATEOBJECT('Collection')
		FOR EACH loItem IN loColl
			* Pass ldDictToObject through so list items are converted consistently
			* (dicts become Empty objects when .T., arrays stay as jsArray when appropriate)
			loOut.ADD(_PyFoxNative(loItem, ldDictToObject))
		ENDFOR
		RETURN loOut
	ENDIF

	* If we reach here, return the wrapper's repr() to assist debugging
	RETURN pyobj.REPR()
ENDFUNC

FUNCTION _PyFoxGetPairValue(toColl, pairKey)
	* Extract value from a VFP Collection by checking if it has the key as a named property.
	* If toColl was built using collection.ADD(value, 'keyname'), the key is accessible as a property.
	IF VARTYPE(toColl) != 'O'
		RETURN .NULL.
	ENDIF
	IF PEMSTATUS(toColl, pairKey, 5)
		RETURN _PyFoxGetVal(EVALUATE("toColl." + pairKey))
	ENDIF
	RETURN .NULL.
ENDFUNC

FUNCTION _PyFoxGetVal(obj)
	* Return native value if object is a Python wrapper (has .obj() or .getval). Safe to call for ANY value.
	LOCAL lnVal
	IF VARTYPE(obj) != 'O'
		RETURN obj
	ENDIF
	TRY
		lnVal = obj.getval()
	CATCH TO oerr
		lnVal = obj
	ENDTRY
	* If we get a string that looks like a Python repr of a list (e.g. ['a','b']), try to parse it
	IF VARTYPE(lnVal) == 'C' AND LEFT(ALLTRIM(lnVal),1) == '[' AND RIGHT(ALLTRIM(lnVal),1) == ']'
		LOCAL loParsed
		loParsed = _PxFoxParseReprList(lnVal)
		IF VARTYPE(loParsed) == 'O' AND loParsed.COUNT == 1
			RETURN loParsed.Item[1]
		ELSE
			IF VARTYPE(loParsed) == 'O' AND loParsed.COUNT > 1
				RETURN loParsed
			ENDIF
		ENDIF
	ENDIF
	RETURN lnVal
ENDFUNC

FUNCTION _PxFoxStripQuotes(lcStr)
	* Remove surrounding single or double quotes from a string if present.
	* ['xxxx']  or ['xxxx','xxxx','xxxx'] -> xxxx  or xxxx,xxxx,xxxx
	IF VARTYPE(lcStr) != 'C' OR EMPTY(lcStr)
		RETURN lcStr
	ENDIF
	LOCAL lcFirst, lcLast, lnLen
	lnLen = LEN(ALLTRIM(lcStr))
	IF lnLen <= 1
		RETURN lcStr
	ENDIF
	lcFirst = LEFT(ALLTRIM(lcStr), 1)
	lcLast = RIGHT(ALLTRIM(lcStr), 1)
	IF (lcFirst == '[' AND lcLast == ']') .OR. (lcFirst == "'" AND lcLast == "'") .OR. (lcFirst == '"' AND lcLast == '"')
		lcString = SUBSTR(ALLTRIM(lcStr), 2, lnLen - 2)
		* Check for multiple items: use a simple comma check and parse into a collection
		IF AT(',', lcString) > 0
			RETURN _PxFoxParseReprList('[' + lcString + ']')
		ELSE
			RETURN _PxFoxStripQuotes(lcString)
		ENDIF
	ENDIF
	RETURN lcStr
ENDFUNC

* Backwards compatibility alias
FUNCTION GetPairValue(toColl, pairKey)
	RETURN _PyFoxGetPairValue(toColl, pairKey)
ENDFUNC

FUNCTION _PxFoxParseReprList(lcStr)
	* Parse a Python-style list string repr (e.g. ['a','b']) to a VFP Collection.
	LOCAL loColl, lcInner, lcRem, lnPos, lcToken, lcQuote
	loColl = CREATEOBJECT('Collection')
	IF VARTYPE(lcStr) != 'C' OR EMPTY(lcStr)
		RETURN loColl
	ENDIF
	lcInner = SUBSTR(ALLTRIM(lcStr), 2, LEN(ALLTRIM(lcStr)) - 2)
	lcRem = ALLTRIM(lcInner)
	DO WHILE LEN(ALLTRIM(lcRem)) > 0
		lcRem = LTRIM(lcRem)
		IF LEFT(lcRem,1) == "'" OR LEFT(lcRem,1) == '"'
			lcQuote = LEFT(lcRem,1)
			lnPos = AT(lcQuote, lcRem, 2)
			IF lnPos == 0
				EXIT
			ENDIF
			lcToken = SUBSTR(lcRem, 2, lnPos - 2)
			loColl.ADD(_PyFoxGetVal(lcToken))
			lcRem = LTRIM(SUBSTR(lcRem, lnPos + 1))
			IF LEFT(lcRem,1) == ','
				lcRem = SUBSTR(lcRem, 2)
			ENDIF
		ELSE
			lnPos = AT(',', lcRem)
			IF lnPos == 0
				lcToken = ALLTRIM(lcRem)
				loColl.ADD(_PyFoxGetVal(lcToken))
				lcRem = ''
			ELSE
				lcToken = ALLTRIM(SUBSTR(lcRem, 1, lnPos - 1))
				loColl.ADD(_PyFoxGetVal(lcToken))
				lcRem = SUBSTR(lcRem, lnPos + 1)
			ENDIF
		ENDIF
	ENDDO
	RETURN loColl
ENDFUNC

FUNCTION _PyFoxToCollection(pyobj)
	* Convert a python wrapper or native value to a VFP Collection.
	* If pyobj is a Python object wrapper, call Iter to convert an
	* iterable into a Collection. If it's a native value, return a collection
	* with a single element containing the value for uniform handling.
	LOCAL loVfpCollection, tmpColl, ITEM
	loVfpCollection = CREATEOBJECT('collection')

	* Python wrappers -> call Iter_Access (returns a VFP collection of items)
	IF VARTYPE(pyobj) == 'O'
		TRY
			tmpColl = pyobj.Iter
		CATCH TO oerr
			tmpColl = .NULL.
		ENDTRY
		IF VARTYPE(tmpColl) == 'O'
			FOR EACH ITEM IN tmpColl
				loVfpCollection.ADD(_PyFoxNative(ITEM, .T.))
			ENDFOR
			RETURN loVfpCollection
		ENDIF
		* Not iterable via Python protocol: return the native value for this wrapper
		loVfpCollection.ADD(_PyFoxNative(pyobj))
		RETURN loVfpCollection
	ENDIF

	* Non-object scalar -> wrap as single native item
	loVfpCollection.ADD(_PyFoxNative(pyobj))
	RETURN loVfpCollection
ENDFUNC



FUNCTION _PyFoxError()
	* Normalize local variable naming for clarity and consistency with VFP style
	LOCAL lnErr, lnPyType, lnPyValue, lnPyTraceback
	LOCAL loPyType, loPyValue, loPyTraceback, loValueTuple, loExcInfo, lcErrorMessage

	lnErr = PyErr_Occurred()
	IF lnErr == 0
		RETURN ''
	ENDIF

	lnPyType = 0
	lnPyValue = 0
	lnPyTraceback = 0

	PyErr_Fetch(@lnPyType, @lnPyValue, @lnPyTraceback)
	PyErr_NormalizeException(@lnPyType, @lnPyValue, @lnPyTraceback)
	IF lnPyType != 0
		loPyType = CREATEOBJECT('PythonObjectImpl', lnPyType)
		Py_IncRef(loPyType.obj())
	ELSE
		loPyType = _PyNone
	ENDIF
	IF lnPyValue != 0
		loPyValue = CREATEOBJECT('PythonObjectImpl', lnPyValue)
	ELSE
		loPyValue = _PyNone
	ENDIF
	IF lnPyTraceback != 0
		loPyTraceback = CREATEOBJECT('PythonObjectImpl', lnPyTraceback)
		Py_IncRef(loPyTraceback.obj())
	ELSE
		loPyTraceback = _PyNone
	ENDIF

	loValueTuple = CREATEOBJECT('pythontuple', loPyValue)
	loExcInfo = CREATEOBJECT('pythontuple', loPyType, loPyValue, loPyTraceback)
	_pylogger.callmethod('error', loValueTuple, CREATEOBJECT('PythonDictionary', CREATEOBJECT('PythonTuple', CREATEOBJECT('PythonTuple', 'exc_info', loExcInfo))))
	lcErrorMessage = loPyType.getattr('__name__') + ': ' + _PyStrType.CALL(loValueTuple)
	RETURN lcErrorMessage
ENDFUNC



