
define class jsCursor as  jsCustom

	cAlias = ""
	cSchema = "cCharField C(50)"

	lUnPersistentModel = .f.

	* Function : Select the cursor
	*           The alias can be passed as a parameter or use the cAlias property
	* Parameter: tcAlias - The alias of the cursor to open
	* Return   : Logical
	function open(tcAlias)
		tcAlias =iif(vartype(tcAlias) == "C", tcAlias, this.cAlias)
		if used(tcAlias)
			sele (tcAlias)
		else
			if this.CreateCursor(tcAlias, this.cSchema)
				if used(tcAlias)
					sele (tcAlias)
					return .t.
				else
					return .f.
				endif
			else
				return .f.
			endif
		endif
	endfunc

	*
	function BuildBlankDataObject() as object
		local lodata
		if this.open()
			if reccount() > 0
				scatter name lodata memo blank
			else

			endif
			return loData
		else
			return .null.
		endif
	endfunc

	function BuildSampleRecord()   as LOGICAL
		local lodata
		if this.open()
			this.insertsampledata()
		else
			return .null.
		endif
		scatter name lodata memo
		return lodata
	endfunc



	* Function : Create a cursor from the cAlias and cSchema propertie
	* Parameter: None
	* Return   : Logical
	* Example  : CreateCursor("MyCursor","MySchema") create mycursor from mySchema
	*           By default use this.alias and this.schema
	function CreateCursor(tcAlias, tcSchema) as LOGICAL
		local lcAlias, lcSchema
		lcAlias = iif(vartype(tcAlias) == "C", tcAlias, this.cAlias)
		lcSchema = iif(vartype(tcSchema) == "C", tcSchema, this.cSchema)

		if used(lcAlias)
			use in (lcAlias)
		endif
		lcBuildCursor = lcAlias  + " (" +lcSchema + ")"
		create cursor &lcBuildCursor.
		if used(lcAlias)
			return .t.
		else
			return .f.
		endif
	endfunc

enddefine
