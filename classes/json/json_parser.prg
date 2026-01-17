#INCLUDE json-fox.h

* Version 1.3.4
* ResetError(THIS) is a function THIS.ResetError() is osolete

define class Parser as jscustom
	tokens = .null.
	currentIndex = 0
	name = "Parser"
	convertunicode  = .f. 				&& Set to .T. to decode Unicode escape sequences in the parsed object
	IsJsonLdObject = .f.    			&& Handle JSON-LD objects with @context and @type properties
	rdFoxprofix = "object_"				&& Prefix Json object for FoxPro object properties with "rd_"
	HandleComments = .f. 				&& Set to .T. to remove comments from the JSON string
	lIs2DArray = .f.					&& Set to .T. to parse a 2D array
	
	MakeObjectCursor = .f.		    	&& Set to .T. to add the parsed object to a cursor
	cCursorName = "JsonObjectCursor"

	function parseJson(tcInput)

		local loTokenizer, loObject, loUnicodeObject,lcSavedDateSetValue,lcSavedHoursSetValue

		lcSavedDateSetValue = set("DATE")
		set date to YMD
		lcSavedHoursSetValue = set("HOURS")
		set hours to 24

		if vartype(tcInput)<> T_CHARACTER .or. empty(tcInput)
			SetError(this,"Wrong input string",JS_FATAL_ERROR)
			return .null.
		endif

		if this.HandleComments = .t.
			* Remove comments
			tcInput = this.removeComments(tcInput)
		endif

		* lcDateSet = set('Date')
		* set date ymd

		* Clear some special characters
		tcInput = chrtran(tcInput, chr(9),'')			&& Tab
		tcInput = chrtran(tcInput, chr(10),'')			&& Linefeed
		tcInput = chrtran(tcInput, chr(13),'')			&& Carriage return
		* We don't remove space because they are part of the JSON string


		loTokenizer = createobject("Tokenizer")
		loTokenizer.convertunicode = this.convertunicode
		this.tokens = loTokenizer.tokenize(tcInput)

		if loTokenizer.nError = JS_FATAL_ERROR .or. vartype(this.tokens) <> T_OBJECT
			SetError(this,loTokenizer.cerrormsg,JS_FATAL_ERROR)
			return .null.
		endif

		* Setup for parsing
		this.currentIndex = 1
		* this.nArrayLevel = 0    #TODO Implement support for multi-dimensional arrays
		ResetError(this)

		loObject = this.parseObject()

		* Reset to previous VFP settings
		* set date &lcDateSet

		if this.nError = JS_FATAL_ERROR
			SetError(this,this.cerrormsg,JS_FATAL_ERROR)
			return .null.
		endif

		set date to &lcSavedDateSetValue.
		set hours to &lcSavedHoursSetValue

		return loObject

	endfunc

	function parseObject()

		local loObject, lcToken, lcKey, lvValue, lcType, lcProperty, lcValuetype

		* Check where we are in the token list
		lcToken = this.tokens.item(this.currentIndex)

		* '{' token begins a object
		if lcToken != JS_LBRACE
			SetError(this,"Expected a '{' at current index " + transform(this.currentIndex),JS_FATAL_ERROR)
			return .null.
		endif

		* Create an empty object
		loObject = createobject("Empty")

		* Check for empty object
		if this.tokens.item(this.currentIndex+1) == JS_RBRACE
			this.currentIndex = this.currentIndex + 2  && Skip '{' and '}'
			return loObject
		endif

		this.currentIndex = this.currentIndex + 1  && Skip '{'

		do while this.currentIndex <= this.tokens.count .and. this.tokens.item(this.currentIndex) != JS_RBRACE
			llIsArray = .f.
			* Next token is a string property name
			lcType = this.tokens.item(this.currentIndex)
			if lcType != JS_STRING
				SetError(this,"Expected a string property name",JS_FATAL_ERROR)
				exit
			else
				this.currentIndex = this.currentIndex + 1  		&& Skip type token set for properties and values
				lcProperty = this.tokens.item(this.currentIndex)
				this.currentIndex = this.currentIndex + 1  		&& Next token is a colon
			endif
			if this.tokens.item(this.currentIndex) == JS_COLON
				this.currentIndex = this.currentIndex + 1  		 && Skip ':'
			else
				SetError(this,"Expected a colon ':' at current index " + transform(this.currentIndex),JS_FATAL_ERROR)
				exit
			endif

			lcToken = this.tokens.item(this.currentIndex)
			* Don't skip the currentindex for recursive call to parseObject() or parseArray()

			do case
				case lcToken == JS_LBRACE
					lvValue = this.parseObject()
				case lcToken == JS_LBRACKET       && Not == top include 2D array
					lvValue = this.parseArray(.null.)
					llIsArray = .t.				  && force to recopy the array to a jsdata object class
				case lcToken == JS_LBRACKET_2DIM
					THIS.lIs2DArray = .T.
					lvValue = this.parseArray(.null.)  && .t. for 2D array
					llIsArray = .t.				 && force to recopy the array to a jsdata object class
				otherwise
					* Value of the property is not a array or object we now expect a valuetype
					lcValuetype = lcToken
					this.currentIndex = this.currentIndex + 1  && Skip the valuetype token

					do case
						case lcValuetype == JS_BOOLEAN
							lvValue = this.tokens.item(this.currentIndex)
							if lower(lvValue) == "true"
								lvValue = .t.
							else
								lvValue = .f.
							endif
						case lcValuetype == JS_DATE
							lvValue = this.parseDate(this.tokens.item(this.currentIndex))
						case lcValuetype == JS_NULL
							lvValue = .null.
						case lcValuetype == JS_NUMERIC
							lvValue = val(this.tokens.item(this.currentIndex))
						case lcValuetype == JS_STRING
							lvValue = this.tokens.item(this.currentIndex)
						otherwise
							SetError(this,"Expected a valuetype not " + lcValuetype ,JS_FATAL_ERROR)
							exit
					endcase
					* Skip the value token
					this.currentIndex = this.currentIndex + 1

			endcase

			if this.MakeObjectCursor 

				this.AddObjectToCursor(lcProperty, @lvValue,llIsArray)

			else 
				* Add the property and value to the object
				if this.IsJsonLdObject
					this.HandleJsonLDobject(@loObject, lcProperty, lvValue)
				else
					if llIsArray
						this.AddArray(@loObject, lcProperty, @lvValue)
					else
						addproperty(loObject, lcProperty, lvValue)
					endif
				endif
			endif 

			lcToken = this.tokens.item(this.currentIndex)

			if lctoken == JS_COMMA && Skip ',' for next property
				this.currentIndex = this.currentIndex + 1
			else
				* Here we have reached the end of the object
				if lctoken != JS_RBRACE
					SetError(this,"Expected a '}' at current index " + transform(this.currentIndex),JS_FATAL_ERROR)
				endif
			endif

		enddo

		this.currentIndex = this.currentIndex + 1  	&& Skip '}'

		return loObject

	endfunc

	function AddArray(roObject, lcProperty, toArray)
		if vartype(toArray) <> "O"
			* Add the array object to the object
			local loArray
			* jsData is a custom class to handle arrays having hidden properties
			loArray = createobject("jsParseArray")
			* toArray contains the array
			toArray.GetArray(@loArray)
			addproperty(roObject, lcProperty,loArray)
		else
			addproperty(roObject, lcProperty,toArray)
		endif
	endfunc

	function parseArray(loArray)

		* #TODO Implement support native VFP arrays and multi-dimensional arrays
		* Track the array level for error checking

		local loArray, lcToken, lvValue, llIs2DArray,lnCols

		lcToken = this.tokens.item(this.currentIndex)

		if lcToken != JS_LBRACKET
			SetError(this,"Expected a '[' at current index " + transform(this.currentIndex),JS_FATAL_ERROR)
			return .null.
		endif

		if vartype(loArray) <> "O"
			* Create an empty array object
			* Default array dimension is  a[1,1]
			loArray = createobject("jsParseArray")
			lnCols = 0
		endif

		* Check for empty array
		if this.tokens.item(this.currentIndex+1) == JS_RBRACKET
			this.currentIndex = this.currentIndex + 2  && Skip '[' and ']'
			return loArray
		endif

		* Ok skip '[' we have a array with values
		this.currentIndex = this.currentIndex + 1  && Skip '['

		do while this.currentIndex <= this.tokens.count .and. this.tokens.item(this.currentIndex) != JS_RBRACKET

			lcToken = this.tokens.item(this.currentIndex)
			lvValue = .null.

			do case
				case lcToken == JS_LBRACE
					lvValue = this.parseObject()
				case lcToken == JS_LBRACKET
					IF VARTYPE(lnCols) = "N" .AND. THIS.lIs2DArray = .T.
						lnCols = lnCols + 1
						loArray.nCol = lnCols 
					endif 
					this.parseArray(@loArray)
				otherwise
					this.currentIndex = this.currentIndex + 1  && ready  to get the value
					do case
						case lcToken == JS_BOOLEAN
							lvValue = this.tokens.item(this.currentIndex)
							if lower(lcValue) == "true"
								lcValue = .t.
							else
								lcValue = .f.
							endif
						case lcToken == JS_DATE
							lvValue = this.parseDate(this.tokens.item(this.currentIndex))
						case lcToken == JS_NULL
							lvValue = .null.
						case lcToken == JS_NUMERIC
							lvValue = val(this.tokens.item(this.currentIndex))
						case lcToken == JS_STRING
							lvValue = this.tokens.item(this.currentIndex)
						otherwise
							lvValue = lcToken
					endcase
					this.currentIndex = this.currentIndex + 1  && ready  to get the comma
			endcase

			if !isnull(lvValue)
				* Add the value to the array
				loArray.add(lvValue)
			endif

			* Skip comma
			if this.tokens.item(this.currentIndex) == JS_COMMA
				this.currentIndex = this.currentIndex + 1
			else
				* Here we have reached the end of the array
				if this.tokens.item(this.currentIndex) != JS_RBRACKET
					SetError(this,"Expected a ']' at current index " + transform(this.currentIndex),JS_FATAL_ERROR)
				else 
					* We have reached the end of the array
				endif
			endif

		enddo

		this.currentIndex = this.currentIndex + 1 		&& Skip ']'

		if this.tokens.item(this.currentIndex) == JS_RBRACKET
			* This is the end of the add of colums
			* Array is ready to be returned
		endif

		return loArray

	endfunc

	function parseDate(lcDateString)
		local lnYear, lnMonth, lnDay, lnHour, lnMinute, lnSecond, lcDatePart, lcTimePart, lcTimeZonePart

		if lower(lcDateString) = "null"
			return {}
		endif

		* Initialize default values
		lnYear = 0
		lnMonth = 0
		lnDay = 0
		lnHour = 0
		lnMinute = 0
		lnSecond = 0

		* Split the date string into date and time parts
		lcDatePart = left(lcDateString, 10)
		lcTimePart = ""
		lcTimeZonePart = ""

		if len(lcDateString) > 10
			lcTimePart = substr(lcDateString, 12, 8)
			if len(lcDateString) > 19
				lcTimeZonePart = substr(lcDateString, 20)
			endif
		endif

		* Parse the date part
		* Json format 2023-05-15"
		lnYear = val(substr(lcDatePart, 1, 4))
		lnMonth = val(substr(lcDatePart, 6, 2))
		lnDay = val(substr(lcDatePart, 9, 2))

		* Parse the time part
		if not empty(lcTimePart)
			lnHour = val(substr(lcTimePart, 1, 2))
			lnMinute = val(substr(lcTimePart, 4, 2))
			lnSecond = val(substr(lcTimePart, 7, 2))
		endif

		* Return DATETIME() if time part is present, otherwise return DATE()
		if not empty(lcTimePart)
			return datetime(lnYear, lnMonth, lnDay, lnHour, lnMinute, lnSecond)
		else
			return date(lnYear, lnMonth, lnDay)
		endif
	endfunc

	function removeComments(tcInput)
		local lcOutput, lnPos, lcChar, lcNextChar, lnLength, lbInString

		lcOutput = ""
		lnPos = 1
		lnLength = len(tcInput)
		lbInString = .f.

		do while lnPos <= lnLength
			lcChar = substr(tcInput, lnPos, 1)
			lcNextChar = iif(lnPos < lnLength, substr(tcInput, lnPos + 1, 1), "")

			if lcChar = '"' .and. (lnPos = 1 .or. substr(tcInput, lnPos - 1, 1) # "\")
				lbInString = !lbInString
			endif

			if !lbInString
				if lcChar = "/" .and. lcNextChar = "/"
					* Single-line comment
					do while lnPos <= lnLength .and. substr(tcInput, lnPos, 1) # chr(10)
						lnPos = lnPos + 1
					enddo
				else
					if lcChar = "/" .and. lcNextChar = "*"
						* Multi-line comment
						lnPos = lnPos + 2
						do while lnPos <= lnLength - 1 .and. (substr(tcInput, lnPos, 2) # "*/")
							lnPos = lnPos + 1
						enddo
						lnPos = lnPos + 1
					else
						lcOutput = lcOutput + lcChar
					endif
				endif
			else
				lcOutput = lcOutput + lcChar
			endif

			lnPos = lnPos + 1
		enddo

		return lcOutput

	endfunc

	* Handle JSON-LD objects with @context and @type @id properties
	function HandleJsonLDobject(roObject, tcProperty, tvValue)
		if left(tcProperty, 1) == "@"
			* Handle JSON-LD keywords by storing them in a special property
			lcProperty = this.rdFoxprofix + substr(tcProperty,2)
		else
			lcProperty = tcProperty
		endif
		addproperty(roObject, lcProperty, tvValue)
	endfunc

	function isbinary(tcValue)
		* Check if the value contains non-printable characters
		local lnIndex, lnLength, lcChar
		lnLength = len(tcValue)
		for lnIndex = 1 to lnLength
			lcChar = substr(tcValue, lnIndex, 1)
			if asc(lcChar) < 32 or asc(lcChar) > 126
				return .t.
			endif
		endfor
		return .f.
	endfunc

	
	FUNCTION AddObjectToCursor(lcProperty, rvValue, llIsArray)
		LOCAL lcCursorName, lcPropertyValue
	
		* Define the cursor name
		lcCursorName = THIS.cCursorName
	
		* Check if the cursor already exists, if not, create it
		IF NOT USED(lcCursorName)
			CREATE CURSOR (lcCursorName) (cProperty C(50), mMemo M)
		ENDIF
	
		* Convert the value to a string representation
		DO CASE
			CASE TYPE("rvValue") == "C"
				lcPropertyValue = rvValue
			CASE TYPE("rvValue") == "N"
				lcPropertyValue = TRANSFORM(rvValue)
			CASE TYPE("rvValue") == "L"
				lcPropertyValue = IIF(rvValue, "true", "false")
			CASE TYPE("rvValue") == "D"
				lcPropertyValue = DTOC(rvValue)
			CASE TYPE("rvValue") == "T"
				lcPropertyValue = TTOC(rvValue)
			CASE TYPE("rvValue") == "O"
				lcPropertyValue = "Object"
			CASE llIsArray
				lcPropertyValue = rvValue.ArrayToText()
			OTHERWISE
				lcPropertyValue = "Unknown"
		ENDCASE
	
		* Insert the property and value into the cursor
		INSERT INTO (lcCursorName) (cProperty, mMemo) VALUES (lcProperty, lcPropertyValue)
	
	ENDFUNC


enddefine
