# VC++ 6 Makefile

CC=		cl
LN=		link
RC=		rc

!IF "$(DEBUG)" == "1"
LDEBUG=		/DEBUG
CDEBUG=		-Zi
!ELSE
LDEBUG=		/RELEASE
!ENDIF

!IF "$(ENCODING)" == ""
ENCODING=	ISO8859
!ENDIF

CFLAGS=		-I. -Isqlite -Gs -GX -D_WIN32 -D_DLL -nologo $(CDEBUG)
CFLAGSEXE=	-I. -Gs -GX -D_WIN32 -nologo $(CDEBUG)
DLLLFLAGS=	/NODEFAULTLIB $(LDEBUG) /NOLOGO /MACHINE:IX86 \
		/SUBSYSTEM:WINDOWS /DLL
DLLLIBS=	msvcrt.lib odbccp32.lib kernel32.lib \
		user32.lib comdlg32.lib sqlite\libsqlite.lib

!IF "$(ENCODING)" == "UTF8"
DRVDLL=		sqliteodbcu.dll
!ELSE
DRVDLL=		sqliteodbc.dll
!ENDIF

OBJECTS=	sqliteodbc.obj

.c.obj:
		$(CC) $(CFLAGS) /c $<

all:		$(DRVDLL) inst.exe uninst.exe

clean:
		del *.obj
		del *.res
		del *.exp
		del *.ilk
		del *.pdb
		del *.res
		del resource.h
		del *.exe
		cd sqlite
		nmake -f ..\sqlite.mak clean
		cd ..

uninst.exe:	inst.exe
		copy inst.exe uninst.exe

inst.exe:	inst.c
		$(CC) $(CFLAGSEXE) inst.c odbc32.lib odbccp32.lib \
		kernel32.lib user32.lib

fixup.exe:	fixup.c
		$(CC) $(CFLAGSEXE) fixup.c

mkopc.exe:	mkopc.c
		$(CC) $(CFLAGSEXE) mkopc.c

sqliteodbc.c:	resource.h

sqliteodbc.res:	sqliteodbc.rc resource.h
		$(RC) -I. -Isqlite -fo sqliteodbc.res -r sqliteodbc.rc

sqliteodbc.dll:		sqlite\libsqlite.lib $(OBJECTS) sqliteodbc.res
		$(LN) $(DLLLFLAGS) $(OBJECTS) sqliteodbc.res \
		-def:sqliteodbc.def -out:$@ $(DLLLIBS)

sqliteodbcu.dll:	sqlite\libsqlite.lib $(OBJECTS) sqliteodbc.res
		$(LN) $(DLLLFLAGS) $(OBJECTS) sqliteodbc.res \
		-def:sqliteodbcu.def -out:$@ $(DLLLIBS)

resource.h:	resource.h.in fixup.exe
		.\fixup < resource.h.in > resource.h \
		    --VERS-- @VERSION

sqlite\libsqlite.lib:	fixup.exe mkopc.exe
		cd sqlite
		nmake -f ..\sqlite.mak ENCODING=$(ENCODING)
		cd ..
