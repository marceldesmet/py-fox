#INCLUDE json-fox.h

* Version 1.3.4
define class jsArray as jscustom

	name = "jsArray"

	dimension item[1,1]
	item[1,1] = .f.

	nRow = 1
	nCol = 1

	* The current push row level in a column
	* To handle recursion and nested structures correctly, the size of the aPushLevel array should match the number of columns in the main array. This ensures
	* that each column can track its own depth level independently.
	dimension aPushLevel[1]
	aPushLevel[1] = 1

	*  col1 [ row1 row2 row3 ]
	*  col2 [ row1 row2 row3 ]
	*  col3 [ row1 row2 row3 ]

	procedure IsArray()
		return type("This.item[1]") != T_UNDEFINED
	endproc

	function push(tvItem)
		* Set the current row to the last row in the column
		this.nRow = this.aPushLevel[THIS.nCol]
		if vartype(this.item[THIS.nRow,THIS.nCol])=T_OBJECT
			this.nRow = this.nRow + 1
		endif
		if empty(this.item[THIS.nRow,THIS.nCol])
			this.item[THIS.nRow,THIS.nCol] = tvItem
			this.aPushLevel[THIS.nCol] = this.nRow
			return
		endif
		this.nRow = this.nRow + 1
		this.item[THIS.nRow,THIS.nCol] = tvItem
		this.aPushLevel[THIS.nCol] = this.nRow
	endfunc

	function nRow_assign(tnRow)
		local lnRows,lnCols
		lnRows = alen(this.item,1)
		if tnRow > lnRows
			lnCols = alen(this.item,2)
			dimension this.item[ tnRow, lnCols]
		endif
		this.nRow = tnRow
	endfunc

	function GetArray(roArray)
		acopy(this.item,roArray.item)
	endfunc

	function add(tvItem)
		this.push(tvItem)
	endfunc

	* InsertCols Method - Add columns to the array (re-size it larger)
	*   Parameters: n
	*   Returns: The new number of columns in the array
	*   Note: All elements in the new columns are initialized to .NULL.
	function ncol_assign(tnCol)

		* Check for valid parameters
		assert pcount() = 1 and tnCol > 0

		* Only incremental
		if tnCol > this.nCol

			local lnNewCols,lnI,lnII,laTemp,lnRows,lnCols

			lnRows = alen(this.item,1)
			lnCols = alen(this.item,2)

			dimension laTemp[ lnRows, lnCols]

			* Copy the current array to laTemp[]
			= acopy( this.item, laTemp )

			* Re-dimension our array
			dimension this.item[ lnRows, tnCol]

			* Initialize new columns to .NULL.
			for lnI = 1 to lnRows
				for lnII = lnCols + 1 to tnCol
					this.item[lnI, lnII] = .f.			&& Foxpro don't ccept null value in arrays
				endfor
			endfor

			* Copy everything from the temporary array into the new array
			for lnI = 1 to lnRows
				for lnII = 1 to lnCols
					this.item[lnI, lnII] = laTemp[lnI, lnII]
				endfor
			endfor

			* Set colum to the current / new column count
			this.nCol = alen(this.item,2)
			this.nRow = 1
			dimension this.aPushLevel[tnCol]
			this.aPushLevel[tnCol] = 1
		else
			this.nCol = tnCol
		endif
	endproc

	* Method to convert array to text
	FUNCTION ArrayToText()
		LOCAL lcText, lnRows, lnCols, lnI, lnII, lcRow
		lcText = ""
		lnRows = ALEN(this.item, 1)
		lnCols = ALEN(this.item, 2)

		FOR lnI = 1 TO lnRows
			lcRow = ""
			FOR lnII = 1 TO lnCols
				lcRow = lcRow + TRANSFORM(this.item[lnI, lnII])
				IF lnII < lnCols
					lcRow = lcRow + ","
				ENDIF
			ENDFOR
			lcText = lcText + lcRow + CRLF 
		ENDFOR

		RETURN lcText
	ENDFUNC

enddefine

define class jsdata as jsParseArray
	hidden add
	
	hidden push
	hidden nRow
	hidden nCol
	hidden aPushLevel
	
enddefine

* Jsdata is array wrapepr for json-fox
* It is used to store data in array format
* and then convert it to json
* There are a lot of hidden properties and methods
* because the serialization is done by json-fox
* See "+GA" in json-fox stringify method
define class jsParseArray as jsArray

	* exposed property
	dimension item[1,1]

	protected push
	protected nRow
	protected aPushLevel

	* hidden properties
	hidden name
	hidden classlibrary
	hidden addobject
	hidden baseclass
	hidden class
	hidden addproperty
	hidden writemethod
	hidden writeexpression
	hidden width
	hidden whatsthishelpid
	hidden tag
	hidden showwhatsthis
	hidden saveasclass
	hidden resettodefault
	hidden removeobject
	hidden readmethod
	hidden readexpression
	hidden picture
	hidden parentclass
	hidden parent
	hidden objects
	hidden newobject
	hidden init
	hidden helpcontextid
	hidden height
	hidden error
	hidden destroy
	hidden controls
	hidden controlcount
	hidden comment
	hidden cloneobject
	hidden top
	hidden left
	hidden lSendError
	hidden oSendError
	hidden nError
	hidden lError
	hidden cErrorMsg
	hidden cErrorMethod
	hidden getarray
	hidden isarray
	hidden cName

enddefine

