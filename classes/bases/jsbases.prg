#INCLUDE json-fox.h

* Version 1.3.4

* The baseCustom class is a custom class in Visual FoxPro designed to handle error management and reporting.
* It includes properties and methods to manage errors that occur within the class or its subclasses.
define class jsCustom as custom 			    && relation is a lightware object for custom building but we need custom for

	cName = "jsCustom"

	* Common error handling routine ->

	* These properties and methods are to add to all non child of this classes
	* Properties for error handling
	lSendError = .t.                            && Flag to determine if errors should be sent
	oSendError = .null.
	nError = 0                                  && Numeric code of the last error

	lError = .f.                                && Flag to indicate if an error has occurred
	cErrorMsg = "Message unknow"                && Stores the last error message
	cErrorMethod = ""

	* Error handling procedure
	procedure error(nError, cMethod, nLine)
		ErrorHandler(this,message(),nError, cMethod, nLine)
	endproc

	* End of <- Common error handling routine

enddefine

* The baseCollection class is a collection class in Visual FoxPro designed to handle error management and reporting.
* It includes properties and methods to manage errors that occur within the class or its subclasses.
define class jsCollection as collection

	cName = "jsCollection"

	* Common error handling routine ->

	* These properties and methods are to add to all non child of this classes
	* Properties for error handling
	lSendError = .t.                            && Flag to determine if errors should be sent
	oSendError = .null.

	nError = 0                                  && Numeric code of the last error
	lError = .f.                                && Flag to indicate if an error has occurred
	cErrorMsg = "Message unknow"                && Stores the last error message
	cErrorMethod = ""

	* Error handling procedure
	procedure error(nError, cMethod, nLine)
		ErrorHandler(this,message(),nError, cMethod, nLine)
	endproc

	* End of <- Common error handling routine

enddefine





