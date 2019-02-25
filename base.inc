include	windows.inc
include	D:\cracking\coding\masm32\macros\macros.asm
include ufmod.inc
includelib ufmod.lib

uselib	MACRO	libname
	include		libname.inc
	includelib	libname.lib
ENDM

uselib	user32
uselib	kernel32
uselib	shell32
uselib	advapi32
uselib	gdi32
uselib	comctl32
uselib	comdlg32
uselib	masm32
uselib	winmm

DlgProc					PROTO :DWORD,:DWORD,:DWORD,:DWORD
EditBoxProc				proto :DWORD,:DWORD,:DWORD,:DWORD
AboutProc 				proto :dword,:dword,:dword,:dword
UpdateScroller			proto
CreateTVBox 			proto :dword
UpdateTVBox 			proto
Random 					proto :dword
BallSize 				proto :dword,:dword
BallFpu 				proto

IDC_OK 			equ	1003
IDC_IDCANCEL 	equ	1004

.data
AboutFont	LOGFONT <14, 7, 0, 0, FW_BOLD, FALSE, FALSE, FALSE, ANSI_CHARSET, OUT_CHARACTER_PRECIS,CLIP_DEFAULT_PRECIS,PROOF_QUALITY,DEFAULT_PITCH,"courier new">

szAboutText db " tRUE Proudly Presents a keYgen for:",13
			db "DataBus KeygenMe #1",13,13,13,13
			db "Coded by: MiSSiNG iN ByTES",13
			db "Music: Unknown author",13,13,13
			db "Greetz to:",13
			db "MAXTREME",13
			db "h3x4",13
			db "kRio",13
			db "Blez",13
			db "shudder",13
			db "Encrypto",13,13,13
			db "----------------",13
			db "Team tRUE",13
			db "----------------",13,13,13
			db "Home Page:",13
			db "http://missinginbytes.hit.bg",0

			
nrandom_seed dd "O63."

buffer		db 1024 dup (00h)
szDash		db "-",0
szAlertShortUserName 	db "Username must be > 4 symbols.",0

.data?
hInstance		dd		?	;dd can be written as dword
szbla			dd 60 dup (?)

WX				equ 275
WY				equ 360
top				equ 0
left			equ 0

ppv				dd ?
srcdc			dd ?
hdcx			dd ?
thread			dd ?
threadID		dd ?
colorInc		byte ?
colorIncStep	dd ?
oldEditProc		dd ?
pWin			dd ?