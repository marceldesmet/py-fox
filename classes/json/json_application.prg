#INCLUDE json-fox.h

* Version 1.3.4

define class JsonHandler as jsApplication olepublic

	cMsg	= "JSonfoxMessages"
	ldebugmode = .t.
	cErrorMsg = ""
	nError = 0
	IsJsonLdObject = .f.
	rdFoxprofix = "object_"
	convertunicode  = .f.

	dimension dependencies[1,2]

	function FormatJson(tcJson,roJson)
		local loJson,lcJson
		lcJson = iif(vartype(tcJson)="C",tcJson,"")
		if empty(lcJson)
			msg.add("empty json error")
			return "null"
		endif
		loJson = this.deserialize(lcJson)
		if vartype(loJson)="O"
			roJson = loJson
		else
			roJson = .null.
			msg.add("deserialize error")
			return "null"
		endif
		tcFormattedJson = this.Serialize(loJson,.t.)
		return tcFormattedJson
	endfunc


	function serialize(loObject,tlBeautify)
		local loStringify, lcJson
		loStringify = createobject("Stringify")
		with loStringify
			.IsJsonLdObject = this.IsJsonLdObject
			.rdFoxprofix = this.rdFoxprofix
			.convertunicode  = this.convertunicode 
		endwith

		lcJson = loStringify.stringify(loObject,tlBeautify)

		if loStringify.nError = JS_FATAL_ERROR
			this.cErrorMsg = loStringify.cErrorMsg
			this.nError = JS_FATAL_ERROR
			msg.add(this.cErrorMsg)
			return .null.
		endif

		return lcJson
	endfunc

	function deserialize(tcJson)
		local loParser, loObject,lcJson
		lcJson = iif(vartype(tcJson)="C",tcJson,"")
		loParser = createobject("Parser")
		with loParser
			.IsJsonLdObject = this.IsJsonLdObject
			.rdFoxprofix = this.rdFoxprofix
			.convertunicode  = this.convertunicode 
		endwith

		loObject = loParser.parseJson(lcJson)

		if loParser.nError = JS_FATAL_ERROR
			this.cErrorMsg = loParser.cErrorMsg
			this.nError = JS_FATAL_ERROR
			msg.add(this.cErrorMsg)
			return .null.
		endif

		return loObject
	endfunc

	function GetDependencies
		return @this.dependencies
	endfunc

	function Initialize_MVC()

		release oFactory
		public oFactory
		oFactory = createobject("jsfactory")

	endfunc

	function dumpTokensToFile(tvTokens,tcDumpFile)

		local loTokenizer,loTokens
		loTokenizer =createobject("tokenizer")
		if vartype(tvTokens)="C"
			loTokens = loTokenizer.tokenize(tvTokens)
		else
			if vartype(tvTokens)="O"
				loTokens = tvTokens
			else
				return "Wrong parameters "
			endif
		endif
		if vartype(tcDumpFile)="C"
			loTokenizer.dumpTokensToFile(loTokens,tcDumpFile)
		else
			return loTokenizer.dumpTokensToFile(loTokens)
		endif
	endfunc

enddefine

