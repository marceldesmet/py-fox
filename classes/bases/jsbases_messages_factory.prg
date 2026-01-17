#INCLUDE json-fox.h

* Version 1.3.4

define class jsmessagefactory AS jsfactory 

	lAddObjecttoCollection = .f.

	procedure make_message(tcCateg)
		LOCAL loMessage
		loMessage = CREATEOBJECT("EMPTY")
		ADDPROPERTY(loMessage,"category",tcCateg)
		ADDPROPERTY(loMessage,"message","")
		RETURN loMessage
	endproc	

enddefine
