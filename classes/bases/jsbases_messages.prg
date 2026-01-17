#INCLUDE json-fox.h

* Version 1.3.4.
* Missing function ResetError() 

FUNCTION ErrorHandler(toCallingObject, tcMessage, tnError, tcMethod, tnLine)

    LOCAL lnError,lcMethod,lnLine,lcMessage 

    * This procedure handles errors that occur in the class.
    * Parameters:
    *   nError  - Numeric error code
    *   cMethod - Name of the method where the error occurred
    *   nLine   - Line number where the error occurred
    lnError = IIF(VARTYPE(tnError)==T_NUMERIC,tnError,0)
    lcMethod = IIF(VARTYPE(tcMethod)==T_CHARACTER,tcMethod,"")
    lnLine = IIF(VARTYPE(tnLine)==T_NUMERIC,tnLine,0)
	lcMessage = IIF(VARTYPE(tcMessage)==T_CHARACTER .AND. !EMPTY(tcMessage),tcMessage,MESSAGE())

    IF VARTYPE(goApp) = T_OBJECT 
    	IF PEMSTATUS(goApp,"ldebugmode",5) .AND. goApp.ldebugmode
        	SET STEP ON 
    	ENDIF 
	ENDIF 
	
	IF VARTYPE(toCallingObject) = T_OBJECT
		WITH toCallingObject
			.nError = lnError
			.lError = .T.
			.cErrorMsg = lcMessage
			.cErrorMethod = tcMethod
		ENDWITH 
		IF VARTYPE(toCallingObject.Name) = T_CHARACTER
			lcMethod = toCallingObject.Name + "." + lcMethod + "()"
		ENDIF
	ENDIF 
	
	IF VARTYPE(REQUEST)="O" .AND. PEMSTATUS(REQUEST,'GetRequestId',5)
	    * If REQUEST is an object, include the request ID in the error message
	    lcMessage = "Request id : "  + TRANSFORM(REQUEST.GetRequestId()) + " - " 
	ELSE 
		lcMessage = ""
	ENDIF 
    
	lcMessage = lcMessage + "Error "+ TRANSFORM(lnError) +" in "+ lcMethod + " at line " + TRANSFORM(lnLine) + " - Last Message() "+  + lcMessage

	logm(lcMessage)

ENDFUNC

FUNCTION Logm(tcMessage,tcLogFile)

    IF VARTYPE(msg) = T_OBJECT  .AND. PEMSTATUS(msg,"llogmode",5) .AND. msg.llogmode
       	msg.Add(tcMessage)
	ENDIF 

	LOCAL lcMessage,lcLogFile	
	lcMessage = IIF(VARTYPE(tcMessage)==T_CHARACTER,tcMessage,"Unknow message")
	lcLogFile = IIF(!EMPTY(tcLogFile),tcLogFile,"error.log")
    SET TEXTMERGE OFF   && IN case there is a recursive call error within TEXTMERGE 
    SET TEXTMERGE TO (lcLogFile) ADDITIVE NOSHOW
    SET TEXTMERGE DELIMITERS TO "<<",">>"
    SET TEXTMERGE ON
    _PRETEXT = ''
    \<<TRANSFORM(DATETIME()) + " - " + lcMessage>>
    SET TEXTMERGE TO
    SET TEXTMERGE OFF

ENDFUNC 

FUNCTION SetError(toCallingObject,tcErrorMsg, tnError)
	
	LOCAL lnError,lcErrorMsg

    lnError = IIF(VARTYPE(tnError)==T_NUMERIC,tnError,0)
	lcErrorMsg = IIF(VARTYPE(tcErrorMsg)==T_CHARACTER,tcErrorMsg,"Unknow message")

	IF lnError = JS_FATAL_ERROR
		* Publish the error
		Logm(lcErrorMsg)
	ELSE 
		* Unpublished method to set the error properties of the object only
	ENDIF 
	
	IF VARTYPE(toCallingObject)=T_OBJECT
		        
	    IF PCOUNT() = 1                 && If only one parameter is passed reset the error flag
	        WITH toCallingObject
	        	.cerrormsg = ""
	        	.lerror = .F.
	        	.nError = 0
	        ENDWITH
			RETURN
	    ENDIF
	    
	    WITH toCallingObject
	    	.cerrormsg = lcErrorMsg
	    	.lerror = .T.
	        .nError = lnError		
		ENDWITH 
		
	ENDIF
	
ENDFUNC 

FUNCTION ResetError(toCallingObject)
	RETURN SetError(toCallingObject)
ENDFUNC 