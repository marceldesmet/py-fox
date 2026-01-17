* Clear screen 
CLEAR 
* Setup lirarys 
DO pyfox_libs.prg

LOCAL loPy
loPy = CREATEOBJECT("PythonHost")
loPy.LoadPythonDLL()

* Example JSON strings
lcJsonDict = '{"name": "Alice", "age": 30, "friends": ["Bob", "Charlie"], "meta": {"score": 85.6, "active": true}}'
lcJsonList = '["apple", "banana", 3, {"nested": "obj"}]'

? '--- Test: Python json.loads() -> wrapper object -> _PyFoxNative/_PyFoxGetVal'
LOCAL loPyJsonObj, loNative
loPyJsonObj = loPy.PythonFunctionCall('json', 'loads', CREATEOBJECT('PythonTuple', lcJsonDict))
? 'pyjson type:' , VARTYPE(loPyJsonObj)
? 'pyjson repr:' , loPyJsonObj.repr()

loNative = _PyFoxNative(loPyJsonObj)
? 'Converted (Py->VFP) type:', VARTYPE(loNative)
IF VARTYPE(loNative) == 'O'
	? 'Collection count:', loNative.Count
	? 'Value for name (via GetPairValue):', _PyFoxGetPairValue(loNative, 'name')
	? 'Value for age (via GetPairValue):', _PyFoxGetPairValue(loNative, 'age')
	? 'Value for friends (via GetPairValue) - repr:'
	loFriends = _PyFoxGetPairValue(loNative, 'friends')
	IF VARTYPE(loFriends) == 'O'
		FOR EACH item IN loFriends
			? ' -', item
		ENDFOR
	ENDIF
ENDIF

? '--- Test: Python json.loads() returns list wrapper' 
loPyJsonList = loPy.PythonFunctionCall('json', 'loads', CREATEOBJECT('PythonTuple', lcJsonList))
? 'list repr: ', loPyJsonList.repr()
loNativeList = _PyFoxNative(loPyJsonList)
IF VARTYPE(loNativeList) == 'O'
	? 'Converted list count:', loNativeList.Count
	FOR EACH itm IN loNativeList
		? 'list item -> ' , VARTYPE(itm), itm
	ENDFOR
ENDIF

? '--- Test: _PyFoxGetVal on already native / wrapped values'
LOCAL lsName, lnAge
lsName = _PyFoxGetVal(_PyFoxGetPairValue(loNative, 'name'))
lnAge = _PyFoxGetVal(_PyFoxGetPairValue(loNative, 'age'))
? 'name (native):', lsName
? 'age (native):', lnAge

* Optionally test json-fox parser (native VFP parsing) if available
? '--- json-fox parser: try creating parser object and parsing with dot-notation or fallbacks'
TRY
	LOCAL loParser, loParsed
	loParser = .NULL.
	* Try to create the parser object first (class name may vary in json-fox)
	IF TYPE('Parser') != 'F'
		* If a class named Parser exists as a VFP class
		loParser = CREATEOBJECT('Parser')
	ENDIF
	IF VARTYPE(loParser) = 'O'
		* If not available, try common free functions as a fallback
		loParsed = loParser.parseJson(lcJsonDict)
	ENDIF

	IF VARTYPE(loParsed) == 'O'
		? 'json-fox parsed object/collection type:' , VARTYPE(loParsed)
		* Try to access dot-notation values (preferred)
		IF PEMSTATUS(loParsed, 'name', 5)
			? 'name (property):', loParsed.name
		ELSE
			* fallback: if collection-of-pairs, use GetPairValue
			? 'name (fallback via GetPairValue):', _PyFoxGetVal(_PyFoxGetPairValue(loParsed, 'name'))
		ENDIF

		IF PEMSTATUS(loParsed, 'age', 5)
			? 'age (property):', loParsed.age
		ELSE
			? 'age (fallback via GetPairValue):', _PyFoxGetVal(_PyFoxGetPairValue(loParsed, 'age'))
		ENDIF

		* Friends: inspect as a collection or print fallback
		IF PEMSTATUS(loParsed, 'friends', 5) AND VARTYPE(loParsed.friends) == 'O'
			? 'Friends count:', loParsed.friends.Count
			FOR lnI = 1 TO loParsed.friends.Count
				? ' -', loParsed.friends.Item(lnI)
			ENDFOR
		ELSE
			loFriends = _PyFoxGetPairValue(loParsed, 'friends')
			IF VARTYPE(loFriends) == 'O'
				FOR EACH f IN loFriends
					? ' - (fallback) ', f
				ENDFOR
			ENDIF
		ENDIF

		* Meta: property or fallback
		IF PEMSTATUS(loParsed, 'meta', 5) AND VARTYPE(loParsed.meta) == 'O'
			? 'meta.score:', loParsed.meta.score
			? 'meta.active:', loParsed.meta.active
		ELSE
			loMeta = _PyFoxGetPairValue(loParsed, 'meta')
			IF VARTYPE(loMeta) == 'O'
				? 'meta.score (fallback):', _PyFoxGetPairValue(loMeta, 'score')
				? 'meta.active (fallback):', _PyFoxGetPairValue(loMeta, 'active')
			ENDIF
		ENDIF
	ELSE
		? 'json-fox parse result (native):', loParsed
	ENDIF
CATCH TO oerr
	? 'json-fox parser not available or parse failed: ' + oerr.Message
ENDTRY

? '--- End of pyfox_helpers JSON tests'

