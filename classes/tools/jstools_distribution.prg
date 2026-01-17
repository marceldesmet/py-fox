#INCLUDE json-fox.h

* Version 1.3.4

DEFINE CLASS Distribution AS jsCustom
    FUNCTION CreateDirectory(tcDirectory)
        IF !DIRECTORY(tcDirectory)
            MKDIR(tcDirectory)
            IF !DIRECTORY(tcDirectory)
                RETURN .F. && Failed to create directory
            ENDIF
        ENDIF
        RETURN .T. && Directory created or already exists
    ENDFUNC

    FUNCTION CopyFile(tcSource, tcDestination)
        IF !FILE(tcSource)
            RETURN .F. && Source file does not exist
        ENDIF

        COPY FILE (tcSource) TO (tcDestination)
        IF !FILE(tcDestination)
            RETURN .F. && Failed to copy file
        ENDIF

        RETURN .T. && File copied successfully
    ENDFUNC

    FUNCTION Distribute(tcSourceDir, tcDestDir)
        LOCAL lnFiles, lcFile, lcSourceFile, lcDestFile

        * Create destination directory if it doesn't exist
        IF !THIS.CreateDirectory(tcDestDir)
            RETURN .F. && Failed to create destination directory
        ENDIF

        * Get list of .prg files in source directory
        lnFiles = ADIR(laFiles, tcSourceDir + "\*.prg")

        FOR lnI = 1 TO lnFiles
            lcFile = laFiles[lnI, 1]
            lcSourceFile = tcSourceDir + "\" + lcFile
            lcDestFile = tcDestDir + "\" + lcFile

            * Copy .prg file to destination directory
            IF !THIS.CopyFile(lcSourceFile, lcDestFile)
                RETURN .F. && Failed to copy file
            ENDIF
        ENDFOR

        RETURN .T. && All .prg files copied successfully
    ENDFUNC
ENDDEFINE