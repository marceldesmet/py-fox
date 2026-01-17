#INCLUDE json-fox.h

* Version 1.3.4

* This component breaks the input JSON string into tokens.
* Each token represents a meaningful string element
* Such as special characters
*
*   {} for Object delimiters
*   [] for Array delimiters
*   : for key-value separator
*   , for value separator
*
*   White space and new lines are skipped
*
*   String values   : "value"
*   Numeric values  : 123 or -123 or 123.45
*   Boolean values  : true, false
*   Null values     : null
*   Date values     : "2025-01-15T13:45:30Z"
*                     "2025-01-15T13:45:30"
*                     "2025-01-15"
*                     "2025-01-15T13:45:30+02:00"
*
define class Tokenizer as jscustom
	tokens = .null.
	currentIndex = 0
	name = "Tokenizer"
	convertunicode = .f.

	function tokenize(tcInput)

		local lcCurrentChar, lcString, i, lcValue
		lcValue = ""
		this.tokens = createobject("Collection")
		i = 1

		do while i <= len(tcInput)
			lcCurrentChar = substr(tcInput, i, 1)

			do case
				case empty(lcCurrentChar)
					* Skip whitespace
					i = i + 1
					loop
				case inlist(lcCurrentChar,CR,LF)
					* Skip new line
					i = i + 1
					loop
				case lcCurrentChar == '{'
					this.tokens.add(JS_LBRACE)
				case lcCurrentChar == '}'
					this.tokens.add(JS_RBRACE)
				case lcCurrentChar == '['
					lnBracket = this.isMultiDimArray(lcCurrentChar, tcInput, @i)
					if lnBracket = 1
						this.tokens.add(JS_LBRACKET)
					else
						if lnBracket = 2
							this.tokens.add(JS_LBRACKET_2DIM)
						else
							* 3D array not supported yet
							SetError(this,"3D arrays are not supported by VFP",JS_FATAL_ERROR)
						endif
					endif
				case lcCurrentChar == ']'
					this.tokens.add(JS_RBRACKET)
				case lcCurrentChar == ':'
					this.tokens.add(JS_COLON)
				case lcCurrentChar == ','
					this.tokens.add(JS_COMMA)
				case lcCurrentChar == '\'
					* Handle comments ?
				case lcCurrentChar == '"'
					this.isString(lcCurrentchar, tcInput, @i, @lcValue)
					this.tokens.add(lcValue)
				case this.isBoolean(lcCurrentChar, tcInput, @i, @lcValue)
					this.tokens.add(JS_BOOLEAN)
					this.tokens.add(lcValue)
				case this.isNumeric(lcCurrentChar, tcInput, @i, @lcValue)
					this.tokens.add(JS_NUMERIC)
					this.tokens.add(lcValue)
				case this.isnull(lcCurrentChar, tcInput, @i, @lcValue)
					this.tokens.add(JS_NULL)
					this.tokens.add(lcValue)
				otherwise
					this.tokens.add(lcCurrentChar)
			endcase
			i = i + 1
		enddo

		if this.lError
			return .null.
		else
			return this.tokens
		endif

	endfunc

	* There are only " values without quotes in JSON
	* Boolean, Numeric and Null values are not enclosed in quotes
	* So we need to check if the current character is part of a boolean, numeric or null value
	function isString(char, tcInput, rnI, rcValue)
		rcValue = ""
		if this.isDate(char, tcInput, @rni)
			this.tokens.add(JS_DATE)
		else
			this.tokens.add(JS_STRING)
		endif
		rni = rni + 1
		lcCurrentChar = substr(tcInput, rni, 1)
		do while lcCurrentChar != '"' and rni <= len(tcInput)
			if lcCurrentChar == '\'
				* Handle escape character
				rni = rni + 1
				* Can use lcCurrentChar because next token could be equal to "
				* and end the do while ...
				lcInCurrentChar = substr(tcInput, rni, 1)
				do case
					case lcInCurrentChar == "n"
						rcValue = rcValue + chr(10)
					case lcInCurrentChar == "t"
						rcValue = rcValue + chr(9)
					case lcInCurrentChar == "r"
						rcValue = rcValue + chr(13)
					case lcInCurrentChar == "b"
						rcValue = rcValue + chr(8)
					case lcInCurrentChar == "f"
						rcValue = rcValue + chr(10)
					case lcInCurrentChar == "u"
						IF This.convertunicode
							* Handle Unicode escape sequence
							LOCAL lcUnicodeHex, lnUnicodeChar
							lcUnicodeHex = SUBSTR(tcInput, rni + 1, 4)
							* lnUnicodeChar = EVALUATE("0x" + lcUnicodeHex)
							* rcValue = rcValue + STRCONV(BINTOC(lnUnicodeChar, "4RS"), 6)
							rcValue = rcValue + "0x" + lcUnicodeHex	
							rni = rni + 4
						endif 
					otherwise
						rcValue = rcValue + lcInCurrentChar
				endcase
			else
				rcValue = rcValue + lcCurrentChar
			endif
			rni = rni + 1
			lcCurrentChar = substr(tcInput, rni, 1)
		enddo

	endfunc

	function isBoolean(char, tcInput, rnI, rcValue)
		do case
			case upper(char) == "T"
				rcValue = substr(tcInput, rnI, 4)
				if upper(rcValue) = "TRUE"
					rnI = rnI + 3
					return .t.
				else
					return .f.
				endif
			case upper(char) == "F"
				rcValue = substr(tcInput, rnI, 5)
				if upper(rcValue) = "FALSE"
					rnI = rnI + 4
					return .t.
				else
					return .f.
				endif
			otherwise
				return .f.
		endcase
	endfunc

	function isNumeric(char, tcInput, rnI, rcValue)
		if isdigit(char)
			local lcNumber, lcNextChar
			lcNumber = ""
			do while rnI <= len(tcInput) and (isdigit(substr(tcInput, rnI, 1)) or substr(tcInput, rnI, 1) == '.' or substr(tcInput, rnI, 1) == '-')
				lcNumber = lcNumber + substr(tcInput, rnI, 1)
				rnI = rnI + 1
			enddo
			* Check if the next character is a separator
			lcNextChar = substr(tcInput, rnI, 1)
			if inlist(lcNextChar, ",", "}", "]")
				* The next character is a separator
				* Move the index back by one
				rnI = rnI - 1
			endif
			rcValue = lcNumber
			return .t.
		else
			return .f.
		endif
	endfunc

	function isnull(char, tcInput, rnI, rcValue)
		* Implement logic to check if char is part of a null
		if upper(char) == "N" .and. upper(substr(tcInput, rnI, 4)) == "NULL"
			rnI =  rnI + 3
			rcValue = "null"
			return .t.
		else
			return .f.
		endif
	endfunc

	function isDate(char, tcInput, rnI)
		if isdigit(substr(tcInput, rnI+1, 1)) .and. substr(tcInput, rnI+5, 1)="-"
			return .t.
		else
			return .f.
		endif
	endfunc

	* Check if the current character is part of a multi-dimensional array
	function isMultiDimArray(char, tcInput, rnI)
		local lnBracketCount, lcCurrentChar, lnI
		if char == '['
			lnBracketCount = 1
			lnI = rnI + 1
		else
			return .f.
		endif
		do while lnI <= len(tcInput)
			lcCurrentChar = substr(tcInput, lnI, 1)
			if lcCurrentChar == '['
				lnBracketCount = lnBracketCount + 1
			else
				do case
					case lcCurrentChar == ']'
						lnBracketCount = lnBracketCount - 1
						exit
					case empty(lcCurrentChar)
						* Continue with next character
					otherwise
						exit
				endcase
			endif
			lnI = lnI + 1
		enddo
		return lnBracketCount
	endfunc

	function dumpTokensToFile(toTokens,tcDumpFile)
		local lnI, lcToken, lcValue, lnTokenCount, lcOutput

		lcOutput = ""

		if vartype(toTokens) <> "O" .or. toTokens.count = 0
			if vartype(this.oTokens) <> "O" .or. this.oTokens.count = 0
				lcOutput = "Empty tokens, tokens.count = 0 "
			else
				toTokens = this.oTokens
			endif
		endif

		for lnI = 1 to toTokens.count
			lcToken = toTokens.item(lnI)
			if lcToken = ","
				llNelwLine = .t.
			else
				llNelwLine = .f.
			endif
			lcOutput = lcOutput + " - " + transform(lni) + ":" + lcToken  + iif(llNelwLine,chr(10),"*")
		endfor
		if vartype(tcDumpFile) = T_CHARACTER .and. !empty(tcDumpFile)
			strtofile(lcOutput, tcDumpfile)
		else
			return lcOutput
		endif
		return .t.
	endfunc

enddefine

