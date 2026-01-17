#INCLUDE json-fox.h

* Version 1.3.4

define class JsonTranslateUnicode as jsCustom

	function DecodeUnicode(tcInput)
		local lcOutput, lnPos, lcChar, lcUnicode

		lcOutput = ""
		lnPos = 1

		do while lnPos <= len(tcInput)
			lcChar = substr(tcInput, lnPos, 1)
			if lcChar = "\" .and. substr(tcInput, lnPos + 1, 1) = "u"
				lcUnicode = substr(tcInput, lnPos + 2, 4)
				lcOutput = lcOutput + chr(eval("0x" + lcUnicode))
				lnPos = lnPos + 6
			else
				lcOutput = lcOutput + lcChar
				lnPos = lnPos + 1
			endif
		enddo

		return lcOutput
	endfunc

	function DecodeUnicodeInObject(toObject)
		local lcKey, lcValue

		for each lcKey in toObject
			lcValue = toObject.Item(lcKey)
			if vartype(lcValue) = JS_STRING
				toObject.Item(lcKey) = this.DecodeUnicode(lcValue)
			else
				if vartype(lcValue) = JS_OBJECT
					toObject.Item(lcKey) = this.DecodeUnicodeInObject(lcValue)
				endif
			endif
		next

		return toObject
	endfunc

enddefine
