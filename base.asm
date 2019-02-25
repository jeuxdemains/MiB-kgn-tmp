.486
.model	flat, stdcall
option	casemap :none   ; case sensitive

include		base.inc

.code
include music.asm

divisor:
dd 700.000
dd 85.00000 ;25.00000
dd 435.000
dd 22.00000 ;22.00000
dd 480.000
dd 42.00000 ;42.00000
dd 412.000
dd 22.00000
dd 450.000
dd 25.00000
dd 435.000
dd 41.00000
dd 410.000
dd 65.00000
dd 475.000
dd 21.00000

position:
dd WX/2
dd WX/5
dd WY
dd WX/4
dd WX/2 
dd WX/6
dd WX/2 
dd WX/5

start:
	invoke	GetModuleHandle, NULL
	mov	hInstance, eax
	invoke	DialogBoxParam, hInstance, 101, 0, ADDR DlgProc, 0
	invoke	ExitProcess, eax
; -----------------------------------------------------------------------
DlgProc	proc	hWin	:DWORD,
		uMsg	:DWORD,
		wParam	:DWORD,
		lParam	:DWORD

	.if uMsg == WM_INITDIALOG
		push hWin
		pop pWin
		;invoke GetDlgItem,hWin,1011
		;invoke SetWindowLong,eax, GWL_WNDPROC, addr EditBoxProc
		;mov oldEditProc, eax
		
	.elseif	uMsg == WM_COMMAND
		.if	wParam == 1007
			invoke DialogBoxParam,hInstance,1008,hWin,addr AboutProc,WM_INITDIALOG
        .elseif	wParam == IDC_IDCANCEL
			invoke EndDialog,hWin,0
		.elseif wParam== 1014
			call GenerateSerial
		.endif
	.elseif	uMsg == WM_CLOSE
		invoke	EndDialog,hWin,0
	.endif

	xor	eax,eax
	ret
DlgProc	endp

GenerateSerial proc
	local userName[1024]:BYTE
	local serial[1024]:BYTE
	local userLn:DWORD
	local magicNum:DWORD
	local bfr1:DWORD
	
	invoke GetDlgItemText,pWin,1011,addr userName,1024
	
	invoke lstrlen,addr userName
	.if eax < 5
		invoke MessageBox,pWin, addr szAlertShortUserName, NULL,MB_OK
		ret
	.endif
	mov userLn, eax
	xor ecx, ecx
	.while eax > 0
		movzx esi, byte ptr [userName+eax-1]
		add ecx, esi
		add ecx, eax
		dec eax
	.endw
	mov magicNum, ecx
	
	mov eax, magicNum
	add eax, 0ddccbbaah
	mov bfr1, eax
	mov ecx, 2
	cdq
	mul ecx
	invoke dw2hex, eax, addr buffer
	invoke dw2hex, bfr1, addr serial
	invoke lstrcat,addr serial, addr szDash
	invoke lstrcat,addr serial, addr buffer
	invoke SetDlgItemText,pWin,1012,addr serial
	Ret
GenerateSerial endp

EditBoxProc proc hwnd:dword,message:dword,wparam:dword,lparam:dword
	local bfr[1024]:BYTE
	
	mov eax,message
	.if eax==WM_CHAR
		invoke GetDlgItemText,pWin,1011,addr buffer, 1024
		invoke lstrcat,addr buffer, addr wparam
		invoke SetDlgItemText,pWin,1012,addr buffer
	.else
		invoke CallWindowProc,oldEditProc, hwnd,message,wparam, lparam
		ret
	.endif
	invoke CallWindowProc,oldEditProc, hwnd,message,wparam, lparam
	xor eax,eax
	ret 	                         
EditBoxProc endp


align 4
AboutProc proc uses ebx esi edi hwnd:dword,message:dword,wparam:dword,lparam:dword
	local rect:RECT
	mov eax,message
	.if eax==WM_INITDIALOG
		invoke CreateTVBox,hwnd
		invoke uFMOD_PlaySong,OFFSET xm,xm_length,XM_MEMORY
		
	.elseif eax==WM_COMMAND

	.elseif eax == WM_LBUTTONDOWN
		invoke  SendMessage,hwnd,WM_CLOSE,0,0

	.elseif eax==WM_CLOSE
		invoke TerminateThread,threadID,0
		invoke DeleteDC,srcdc
		invoke uFMOD_PlaySong,0,0,0
		invoke EndDialog,hwnd,0
	.endif
	xor eax,eax
	ret 	                         
AboutProc endp



align 4
UpdateScroller proc 
	local rect:RECT
	local int_position:dword
	local local_match:dword

	mov int_position, WY
	mov local_match,2

	@@:

    invoke UpdateTVBox
	invoke SetRect,addr rect, left,  int_position, WX, WY
	invoke lstrlen,addr szAboutText
	mov edi,eax
	invoke DrawText,srcdc,addr szAboutText,edi,addr rect,DT_CENTER or DT_TOP
	invoke  BitBlt, hdcx, left, top, WX, WY, srcdc, 0, 0, SRCCOPY

    .if int_position == -0190h
		mov int_position, WY
	.endif

	dec local_match

	 .if local_match == 1
	dec int_position
	mov local_match,4
	.endif

	invoke Sleep,10

	jmp @B
	ret
UpdateScroller endp

align 4
CreateTVBox proc hwnd:dword
	local bmpi:BITMAPINFO

	invoke GetWindowDC,hwnd
	mov hdcx,eax
	invoke CreateCompatibleDC, eax
	mov srcdc, eax
	invoke RtlZeroMemory,addr bmpi, sizeof BITMAPINFO
	mov bmpi.bmiHeader.biSize, sizeof bmpi.bmiHeader
	mov bmpi.bmiHeader.biBitCount, 32
	mov eax,WX
	imul eax,eax,5
	imul eax,eax,WY
	mov bmpi.bmiHeader.biSizeImage, eax
	mov bmpi.bmiHeader.biPlanes, 1
	mov bmpi.bmiHeader.biWidth, WX
	mov bmpi.bmiHeader.biHeight, WY
 	invoke  CreateDIBSection, srcdc, addr bmpi, DIB_RGB_COLORS, addr ppv, 0, 0
	invoke  SelectObject, srcdc, eax
	invoke  CreateFontIndirect,addr AboutFont
	invoke  SelectObject, srcdc, eax
	invoke  SetBkMode, srcdc, TRANSPARENT
	invoke  SetTextColor, srcdc, 0FEFEFEh
	invoke CreateThread,0,0,offset UpdateScroller,0,0,addr thread
	mov threadID,eax
	invoke SetThreadPriority,eax,THREAD_PRIORITY_LOWEST
	ret
CreateTVBox endp

align 4
UpdateTVBox proc uses edi esi ebx

	mov edi,ppv
    xor ecx,ecx
	xor esi,esi
	
	.if colorIncStep != 1
		inc colorInc
		.if colorInc > 233
			mov colorIncStep, 1
		.endif
	.else
		dec colorInc
		.if colorInc < 2
			mov colorIncStep, 0
		.endif
	.endif
	
	.while ecx != WX*WY

		.if ebx  == 1 && esi  == 0  &&  ebx == WX-1 && esi == WY-1
			xor eax, eax
		.else
			push ecx
			invoke Random, 180
			add al, 9
			mov ah, colorInc
			shl eax, 8
			mov al, ah
			pop ecx
		.endif
		stosd
		inc ebx
		.if ebx == WX
			xor ebx, ebx
			inc esi
		.endif
		inc ecx
	.endw

	invoke BallFpu
	mov edi,ppv
	xor  ecx, ecx
	xor ebx,ebx
	xor esi,esi

	.while ecx != WX*WY

		inc ebx

		.if ebx == WX
			xor ebx,ebx
			inc esi
		.endif

		.if ebx  > 1 && esi  > 0  &&  ebx < WX-1 && esi < WY-1

		push ecx
		invoke BallSize,ebx,esi

		.if eax > 500

		mov eax,dword ptr [edi]
		and eax, 0FEAEFEh ;0FEFEFEh
		shr eax,1
		mov dword ptr [edi],eax

		.else

		.if eax > 400

		mov eax,dword ptr [edi]
		and eax,1
		add eax,1
		shr eax,3
		mov dword ptr [edi],eax

		.endif
		.endif

		pop ecx

		.endif

		add edi,4
		inc ecx
	.endw
	ret
UpdateTVBox endp

align 4
Random proc uses edx ecx, base:dword

	mov eax, nrandom_seed
	xor edx, edx
	mov ecx, 127773
	div ecx
	mov ecx, eax
	mov eax, 16807
	mul edx
	mov edx, ecx
	mov ecx, eax
	mov eax, 2836
	mul edx
	sub ecx, eax
	xor edx, edx
	mov eax, ecx
	mov nrandom_seed, ecx
	div base
	mov eax, edx
	ret
Random endp

align 4
BallFpu proc
	local local_match:dword
	local local_result:dword

	invoke GetTickCount
	mov local_match,eax
	mov local_result,0
	xor edi,edi
	xor edx,edx
       
	.while edi != 16
		fild local_match
		fdiv dword ptr [divisor+edi*4]
		fcos
		inc edi	
		fmul dword ptr [divisor+edi*4]
		fistp local_result
		push local_result
		pop dword ptr [szbla+edx*4]
		mov eax,dword ptr [position+edx*4]
		add dword ptr [szbla+edx*4],eax
		fild local_match
		inc edi
		fdiv  dword ptr [divisor+edi*4]
		fsin
		inc edi
		fmul  dword ptr [divisor+edi*4]
		fistp local_result
		push local_result
		inc edx
		pop dword ptr [szbla+edx*4]
		mov eax,dword ptr [position+edx*4]
		add dword ptr [szbla+edx*4],eax
		inc edi
		inc edx
	.endw

	ret

BallFpu endp

align 4
BallSize proc uses esi edi ebx a:dword,b:dword

	mov esi,offset szbla
	xor edi,edi
	xor ebx,ebx

	.while edi != 6
		mov eax,dword ptr [esi]
		add eax, 80 ;the X
		sub eax,a
		cdq
		mul eax
		mov ecx,eax
		mov eax,dword ptr [esi+4]
		add eax, 100	;the Y
		sub eax,b
		cdq
		mul eax
		add eax,ecx

		.if !eax
		mov eax,-1
		ret
		.endif
		xor edx,edx
		mov ecx,eax
		mov eax,0AF5C0h	;the size of the balls
		div ecx
		add ebx,eax
		add esi,10
		inc edi
	.endw
	mov eax,ebx
	ret
BallSize endp

end start
