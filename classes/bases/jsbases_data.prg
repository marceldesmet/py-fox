
DEFINE CLASS AllFieldTypes AS  jsCursor

    * C  Character field
    * N  Numeric field
    * F  Float field
    * Y  Currency field     && Not tested strange because the automatic $ x 
    * D  Date field
    * T  DateTime field
    * L  Logical field
    * M  Memo field
    * G  General field
    * B  Blob field
    * Q  Varbinary field    && Not tested strange because the automatic conv of fox 
    * I  Integer field
    * B  Double field
    
    * This model can't be go in a collection always create a new 
    lUnPersistentModel = .F. 
    
    cAlias = "AllFieldTypes"
    cSchema = "cString C(50), ;
		    nNumber N(10,2), ;
		    lBoolean L, ;
		    dDate D, ;
		    tDateTime T, ;
		    mMemo M, ;
		    gGeneral G, ;
		    bBlob B, ;
		    iInteger I, ;
		    fFloat F, ;
		    dDouble B, ;
		    vVarchar V(50)"
    
    
	PROTECTED function InsertSampleData()
			 
		LOCAL lcAlias 
		lcAlias = THIS.cAlias 	    
		* Insert sample data into the cursor
		INSERT INTO &lcAlias. (cString, nNumber, lBoolean, dDate, tDateTime, mMemo, iInteger, fFloat, dDouble, vVarchar) ;
		VALUES ("Sample String", 123.45, .T., DATE(), DATETIME(), "Sample Memo", 123, 123.45, 123.45, "Sample Varchar")

	ENDFUNC 


enddefine 
