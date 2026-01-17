#INCLUDE json-fox.h

* Version 1.3.4

lparameters tcRole,tvParm1,tvParm2,tvParm3

tcRole = iif(vartype(tcRole)="C",tcRole,"main")

if application.startmode = 4
	_screen.visible = .f.
endif

public desk,dep

* Load
dep = createobject("dependencies")

* Start here desktop or server
desk = createobject("htmldata")

do case
	case lower(tcRole) = "test"
		* Load libs is done in test procedure
		* to indentify using of each prg
		TestProg(tvParm1,tvParm2,tvParm3)
	case lower(tcRole) = "distrib"
		* Copy to the distrib repertory when new release
		DistribProg()
	case lower(tcRole) = "loaddep"
		* Used for debuging
		on error do ErrorHandler with ;
			.null., message( ), error(), program( ), lineno( )
	case lower(tcRole) = "main"
		* load libs only

	otherwise
		desk.main(tcRole,tvParm1,tvParm2,tvParm3)
endcase

return

************* Start your application here

define class jsdependencies as custom

	function load_librarys
		*-* do webmove\j_classes_dependencies.prg

	endfunc

	function GetDependencies(tlAddLocalMain)

		loFiles = createobject("collection")

		loFiles.add('classes\bases\jsbases_desk_application.prg')

		* Add for debug purpose local main
		if tlAddLocalMain
			loFiles.add('htmldata_main.prg')
		endif

		return loFiles

	endfunc

	function init()

		* Load all root dependencies
		* Generaly configurated in childs
		this.load_librarys()

		* Current project dependencies
		local loDependencies, lnI, lcFile
		loDependencies = this.GetDependencies(.t.)
		for lnI = 1 to loDependencies.count
			lcFile = loDependencies.item(lnI)
			set procedure to (lcFile) additive
		endfor

	endfunc

	function testprog

	endfunc

enddefine
