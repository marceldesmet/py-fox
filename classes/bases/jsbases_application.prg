#INCLUDE json-fox.h

* Version 1.3.4

define class jsApplication as jscustom

    cFactory = "jsFactory"

    function GetAppDirectory

        local lcProgram, ;
            lcPath, ;
            lcFilename, ;
            lnBytes

        lcProgram = sys(16, 0)

        do case

                * In-process DLL server or Active Document.

            case atc('.VFD',upper(lcProgram)) > 0 or application.startmode = 3
                lcPath = home()

                * Out-of-process EXE server.

            case application.startmode = 2
                declare integer GetModuleFileName ;
                    in Win32API ;
                    integer hInst,;
                    string @lpszFileName,;
                    integer @cbFileName
                lcFilename = space(256)
                lnBytes    = 255
                GetModuleFileName(0, @lcFilename, @lnBytes)
                lnBytes    = at(chr(0), lcFilename)
                lcFilename = iif(lnBytes > 1, substr(lcFilename, 1, lnBytes - 1), '')
                lcPath     = justpath(lcFilename)

                * Standalone EXE or VFP development.

            otherwise

                lcPath = justpath(lcProgram)

        endcase

        return addbs(upper(lcPath))

    endfunc

    function Initialize_MVC()

        release oMeta,oModels,oview,ocontroller

        public oMetaModels, oModels, oview, ocontroller

    ENDFUNC

ENDDEFINE 
