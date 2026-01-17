#INCLUDE json-fox.h

* Version 1.3.4

define class Stringify as jscustom
	tokens = .null.
	currentIndex = 0
	name = "Stringify"
	convertunicode   = .f.
	IsJsonLdObject = .f.    			&& Handle JSON-LD objects with @context and @type properties
	rdFoxprofix = "object_"				&& Prefix Json object for FoxPro object properties with "rd_"
	lAddEmptyTimeZoneTDate = .f.      	&& Add empty time zone to TDate values
	cIndentStep = ""					&& Indentation step
	cNewLine = ""						&& New line character
	nIndentLevel = 0					&& Indentation level

	* In JSON, the top-level structure can be an object, an array,
	* or a single value (such as a string, number, boolean, or null).
	* However, in most practical use cases, JSON data is typically structured as an object or an array
	* to represent more complex data.
	* In JSON, when serializing objects, each value is associated with a key.
	* However, when serializing arrays or single values, there are no keys associated with the values.
	* The StringifyValue function should handle these cases appropriately.
	* To handle indentation correctly, we need to ensure that the indentation level is properly managed
	* throughout the Stringify process.
	* Specifically, you should decrease the indentation level after Stringify nested structures and before closing braces or brackets.

	function Stringify(lvValue, tlBeautify)
		local lcJson,lcSavedDateSetValue,lcSavedHoursSetValue

		lcSavedDateSetValue = set("DATE")
		set date to YMD
		lcSavedHoursSetValue = set("HOURS")
		set hours to 24
		this.cIndentStep = iif(tlBeautify, "    ", "")
		this.cNewLine = iif(tlBeautify, CRLF, "")

		lcJson = this.stringifyValue(lvValue,0)

		set date to &lcSavedDateSetValue
		set hours to &lcSavedHoursSetValue

		return lcJson
	endfunc

	* This is the strating point of the JSON serialization
	* If your not confortable with the JSON format, you can use the JSONLint tool to validate your JSON string
	* Ready for function that handles nested objects and arrays recursively ;-)
	function StringifyValue(tvValue,tcKey)
		local lcJsonValue
		do case
			case vartype(tvValue) = "C"
				* We add quotes to format strings data
				if this.convertunicode 
					lcJsonValue = ["] + alltrim(this.escapeString(tvValue)) + ["]
				else
					lcJsonValue = ["] + alltrim(tvValue) + ["]
				endif
			case inlist(vartype(tvValue),"N","I")
				lcJsonValue = transform(tvValue)
			case vartype(tvValue) == "Q"
				* Handle VARBINARY values by encoding them in Base64
				lcJsonValue = tvValue													&& '"' + strconv(tvValue,13) + '"'
			case vartype(tvValue) == "Y"
				* Handle currency values by adding the currency symbol
				* We add quotes to format currency data
				lcJsonValue = '"' + transform(tvValue) + '"'
			case vartype(tvValue) == "D" or vartype(tvValue) == "T"
				* We add quotes to format date and datetime data
				lcJsonValue = '"' + this.FormatDateToISO8601(tvValue) + '"'
			case vartype(tvValue) = "L"
				lcJsonValue = iif(tvValue, "true", "false")
			case vartype(tvValue) = "O"
				if type("tvValue.Item[1]") <> "U"							&& tvValue is an array object
					* Array are encapsulated in a object with the "Item" array property
					lcJsonValue = this.stringifyArray(tvValue, tcKey)
				else
					lcJsonValue = this.stringifyObject(tvValue, tcKey)
				endif
			otherwise
				* Can't handle General
				lcJsonValue = "null"
		endcase

		return lcJsonValue
	endfunc

	function GetIndent()
		if this.nIndentLevel > 0
			lcIndent = replicate(this.cIndentStep, this.nIndentLevel)
		else
			lcIndent = ""
		endif
		return lcIndent
	endfunc

	function StringifyObject(loObject, tcKey)
		local lcJson, lcKey, lcValue, lcIndent

		if vartyp(loObject) <> "O"
			return "null"
		endif

		lcIndent = this.GetIndent()

		* Object start with an "{"
		lcJson = "{" + this.cNewLine
		this.nIndentLevel = this.nIndentLevel+1
		if pemstatus(loObject,"BaseClass",5) and loObject.baseclass = "Collection"
			* Object collection
			lcJson = lcJson + this.stringifyCollection(loObject)
		else
			* Object members
			lcJson = lcJson + this.stringifyObjectMembers(loObject)
		endif
		* Object end with an "}"
		lcJson = lcJson + lcIndent + "}"
		this.nIndentLevel = this.nIndentLevel-1

		return lcJson
	endfunc

	function stringifyObjectMembers(toObject)

		local lnI,lcJson,laMembers,lcIndent,lcKeyname
		lcJson = ""
		dimension lamembers[1]
		lcIndent = this.GetIndent()

		* "+GU" loop for "U"ser properties and("+") only "G"lobal ( public )
		amembers(laMembers, toObject, 1, "+GU")

		* A members has 2 columns first is the name
		for lnI = 1 to alen(laMembers,1)
			lcKey = lower(laMembers[lnI, 1])
			if this.IsJsonLdObject
				* Check if the key is formatted as this.rdFoxprofix + "context" or this.rdFoxprofix + "type" etc..
				if left(lcKey, len(this.rdFoxprofix)) = this.rdFoxprofix
					lcKeyname = "@" + substr(lcKey, len(this.rdFoxprofix) + 1)
				else
					lcKeyname = lckey
				endif
			else
				lcKeyname = lckey
			endif
			lcJson = lcJson + lcIndent + ["] + lcKeyname + [":] + this.StringifyValue(toObject.&lcKey)
			if lnI <  alen(laMembers,1)
				lcJson = lcJson + ","
			endif
			lcJson = lcJson + this.cNewLine
		endfor

		return lcJson

	endfunc

	function stringifyCollection(toCollection)

		local lnI,lvValue,lcJson
		lcJson = ""

		lcIndent = this.GetIndent()

		* "+GU" loop for "U"ser properties and("+") only "G"lobal ( public )
		for lnI = 1 to toCollection.count
			lvValue = evaluate("toCollection.Item(" + transform(lnI) + ")")
			lcJson = lcJson + lcIndent + this.StringifyValue(lvValue)
			if lnI < toCollection.count
				lcJson = lcJson + ","
			endif
			lcJson = lcJson + this.cNewLine
		endfor

		return lcJson

	endfunc

	function stringifyArray(toArray, tcKey)
		local lcJson, lnRows, lnCols, lnI, lnII, lvValue, lcIndent

		if vartype(toArray) <> "O"
			return "null"
		endif

		lcIndent = this.GetIndent()
		if !empty(tcKey)
			tcKey = '"' + tcKey + '":'
		else
			tcKey = ""
		endif
		lcJson = tcKEy + "[" + this.cNewLine
		lnRows = alen(toArray.item, 1)
		lnCols = alen(toArray.item, 2)

		for lnI = 1 to lnCols
			if lnCols > 1
				lcJson = lcJson + this.cIndentStep + "["
				* we Have a Two Dimension array
				*[
				*	[xx,xx,xx]
				*	[xx,xx,xx]
				*]
			else
				* we Have a One Dimension array
				* [xx,xx,xx]
			endif
			for lnII = 1 to lnRows
				lvValue = toArray.item[lnII, lnI]
				lcJson = lcJson + lcIndent + this.cIndentStep + this.StringifyValue(lvValue)
				if lnII < lnRows
					lcJson = lcJson + "," + this.cNewLine
				endif
			endfor
			lcJson = lcJson + "]"
			if lnI < lnCols
				lcJson = lcJson + "," + this.cNewLine
			endif
		endfor
		if lnCols > 1
			lcJson = lcJson + this.cNewLine + lcIndent + "]"
		endif
		return lcJson
	endfunc

	function escapeString(tcValue)
		local lcEscaped, lnPos, lcChar, lnCharCode

		lcEscaped = ""
		for lnPos = 1 to len(tcValue)
			lcChar = substr(tcValue, lnPos, 1)
			lcNextChar = substr(tcValue, lnPos+1, 1)
			lnCharCode = asc(lcChar)
			do case
				case lcChar = '"'
					lcEscaped = lcEscaped + '\"'
				case lcChar = "\"
					lcEscaped = lcEscaped + "\\"
				case lcChar = "/"
					lcEscaped = lcEscaped + "\/"
				case lnCharCode = 8
					lcEscaped = lcEscaped + "\b"
				case lnCharCode = 12
					lcEscaped = lcEscaped + "\f"
				case lnCharCode = 10
					lcEscaped = lcEscaped + "\n"
				case lnCharCode = 13
					lcEscaped = lcEscaped + "\r"
				case lnCharCode = 9
					lcEscaped = lcEscaped + "\t"
*				case lnCharCode < 32 .or. lnCharCode > 126
					* Put on the end of do case le let priority to \b \f etc ... 
					* Handle Unicode escape sequence for characters outside the ASCII range
					* We use the \uXXXX format to represent Unicode characters
					* where XXXX is the hexadecimal representation of the character code
*					lcEscaped = lcEscaped + "\u" + RIGHT(TRANSFORM(lnCharCode, "@0"),4)
				CASE lcChar + lcNextChar == "0x"
					lcEscaped = lcEscaped + "\u" + substr(tcValue, lnPos+2, 4)
					lnPos = lnPos + 5
				otherwise
					lcEscaped = lcEscaped + lcChar
			endcase
		endfor

		return lcEscaped
	endfunc

	function saveToFile(lcFileName, loObject, tlBeautify)
		if vartype(loObject) <> T_OBJECT
			return .f.
		endif
		local lcJson
		lcJson = this.stringify(loObject, tlBeautify)
		strtofile(lcJson, lcFileName)
	endfunc

	function FormatDateToISO8601(tdDateTime)
		local lcDate,lcDateTime
		if empty(tdDateTime)
			return "null"
		endif
		if vartype(tdDateTime) == "D"
			lcDate = dtoc(tdDateTime, 1)
			if this.lAddEmptyTimeZoneTDate
				return left(lcDate, 4) + "-" + substr(lcDate, 5, 2) + "-" + right(lcDate, 2) + "T00:00:00Z"
			else
				return left(lcDate, 4) + "-" + substr(lcDate, 5, 2) + "-" + right(lcDate, 2)
			endif
		else
			if vartype(tdDateTime) == "T"
				lcDateTime = ttoc(tdDateTime, 1)
				return left(lcDateTime, 4) + "-" + substr(lcDateTime, 5, 2) + "-" + substr(lcDateTime,7, 2) + "T" + ttoc(tdDateTime, 2) + "Z"
			endif
		endif
		return ""
	endfunc

	function todolater

		if this.isunicode
			* We add quotes to format strings data
			lcJsonValue = '"' + alltrim(this.escapeString(tvValue)) + '"'
		else
			lcJsonValue = '"' + alltrim(tvValue) + '"'
		endif

		if this.IsJsonLdObject
			* Handle JSON-LD objects with @context and @type properties
			lcKey = lower(laMembers[lnI, 1])
			* THe key is formatted as this.rdFoxprofix + "context" or this.rdFoxprofix + "type" etc..
			if left(lcKey, len(this.rdFoxprofix)) = this.rdFoxprofix
				lcKey = substr(lcKey, len(this.rdFoxprofix) + 1)
				lcValue = evaluate("toObject." + this.rdFoxprofix + lcKey)
				lcKey = "@" + lcKey
			else
				lcValue = evaluate("toObject." + lcKey)
			endif
		else

			lcValue = evaluate("toObject." + lcKey)
		endif
	endfunc


enddefine
