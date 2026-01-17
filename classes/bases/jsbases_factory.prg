#INCLUDE json-fox.h

* Version 1.3.4

define class jsfactory as jscollection

	lAddObjecttoCollection = .t.


	* Usage model.users == make_model("users")
	procedure make(tcName,tcClassName,tvParms,tlNewInstance)

		local loObject,;
			lcClass

		loObject = .null.

		do case
			case vartype(tcName) = "C"
				if tlNewInstance .or. this.getkey(lower(tcName)) = 0
					loObject =  this.create(tcName,tcClassName,tvParms)
					if vartype(loObject)="O"
						* Save the factory name to create new instance of the same model
						if this.lAddObjecttoCollection .and. !loObject.lUnPersistentModel
							this.add(loObject,lower(tcName))
						endif
						return loObject
					else
						return .null.
					endif
				else
					loObject =  this.create(tcName,tcClassName,tvParms)
					return loObject
				endif

		endcase
		return .null.

	endproc

	procedure create(tcName,tcClassName,tvParms)
		*-* To do parse Json and return the object
		if empty(tcClassName)
			tcClassName = tcName
		endif
		if !empty(tvParms)

			loObject = createobject(tcClassName,tvParms)

		else

			loObject = createobject(tcClassName)

		endif
		loObject.cName = tcName
		return loObject
	endproc

	procedure make_message(tcCateg)
		LOCAL loMessage
		loMessage = CREATEOBJECT("EMPTY")
		ADDPROPERTY(loMessage,"category",tcCateg)
		ADDPROPERTY(loMessage,"message","")
		RETURN loMessage
	endproc	

enddefine
