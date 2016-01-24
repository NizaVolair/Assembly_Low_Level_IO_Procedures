TITLE LowLevel I/O Procedures     (NizaVolairLowLevel_IO_Procedures.asm)

; Name: Niza Volair
; Email: nizavolair@gmail.com
; Date: 12-06-15
; Description: Program that gets 10 valid integers from the user, stores the numeric values in an array, displays the integers, 
; their sum, and average. Converts integer values to sting and back.

INCLUDE Irvine32.inc

; getString should display a prompt, then get the user’s keyboard input into a memory location
getString	MACRO	val, prompt
	push		ecx						; Save registers
	push		edx

	mov			edx, prompt				; display prompt
	call		WriteString

	mov			edx,  val				; move tbe address of val to the edx
	mov			ecx, (TOTAL_CHAR)		; use the arbitrarily large constant to allow for 100 chars
	call		ReadString				; read in the value to the address of val

	pop			edx						; Restore registers
	pop			ecx

ENDM


; displayString should the string stored in a specified memory location(source: lecture 26)
displayString	MACRO	val
	push	edx							; save registers
	mov		edx, val					; move the address of val to the edx
	call	WriteString					; display value stored in val
	pop		edx							; Restore registers

ENDM

; constants  
TOTAL_CHAR = 25							; total number of chars which is arbitrarily bigger than valid input to allow user to enter invalid input 
TOTAL_NUMS = 10							; number array to store results
VALID_CHAR = 11							; total number of valid chars for return string

.data

introTxt		BYTE	"Low-level I/O procedures programmed by Niza Volair", 0ah, 0dh, 0ah, 0dh
				BYTE	"Please provide 10 unsigned decimal integers.", 0ah, 0dh
				BYTE	"Each number needs to be small enough to fit inside a 32 bit register.", 0ah, 0dh
				BYTE	"After you have finished inputting the raw numbers I will display a list", 0ah, 0dh
				BYTE	"of the integers, their sum, and their average value.", 0

instTxt			BYTE	"Please enter an unsigned number: ", 0

errorTxt		BYTE	"ERROR: You did not enter an unsigned number or your number was too big.", 0

numDisplayTxt	BYTE	"You entered the following numbers: ", 0

spaceTxt		BYTE	"   ", 0

numAverageTxt	BYTE	"The average is: ", 0

numSumTxt		BYTE	"The sum of these numbers is: ", 0

outroTxt		BYTE	"Thanks for playing!", 0

charArray		BYTE	TOTAL_CHAR DUP(?)

numArray		DWORD	TOTAL_NUMS DUP(?)

retCharArray	BYTE	11 DUP(" ")



.code
main PROC

; Introduce the program.
push	OFFSET introTxt
call	introduction


; Get use to input TOTAL_NUM integers within the MAX & MIN limits
	push	OFFSET numArray
	push	OFFSET errorTxt
	push	OFFSET instTxt
	push	OFFSET charArray
	call	readVal					

	; MACRO Test Code
		;getString		charArray
		;displayString	charArray
		;call			Crlf

	;Test code to ensure array returned correctly
		;mov		esi, OFFSET numArray
		;mov		ecx, 10
		ArrayTest:
			;mov		eax, [esi]
	 		;call	WriteDec
			;mov		edx, OFFSET spaceTxt
			;call	WriteString
			;add		esi, 4
			;loop	ArrayTest
			;call	Crlf

; Calculate and Display the average  of the numbers
	push	OFFSET numAverageTxt
	push	OFFSET numArray
	call	averageNums
	
; Calculate and Display the sum of the numbers
	push	OFFSET numSumTxt
	push	OFFSET numArray
	call	sumNums

; Convert array of integers back to strings
	push	OFFSET NumArray
	push	OFFSET retCharArray
	push	OFFSET spaceTxt
	push	OFFSET numDisplayTxt
	call	writeVal
		
; Display outro
	push	OFFSET outroTxt
	call	farewell

exit; exit to operating system
main ENDP


; Procedure to display introduction of program
; receives: intro(ref)
; returns: displays intro to screen
; preconditions: intro is initialized
; registers changed : ebp, esp(saved and restored)
introduction	PROC

; set up stackframe
	push	ebp
	mov		ebp, esp

; introduce the program
	displayString	[ebp + 8]
	call			Crlf
	call			Crlf

	pop		ebp
	ret 4

introduction	ENDP


; Procedure to invoke getString macro to get user’s string of digits, then convert the digit string to numeric, while validating the user’s input.
; receives: numArray, charArray, errorTxt, instTxt all pushed on stack by reference
; returns: printed messages to screen and an array of numbers
; preconditions:  all varaibles are initialized 
; registers changed: ebp, esp, edi, esi, ebx, eax, ecx (saved and restored)
readVal	PROC
; set up stackframe
	push	ebp
	mov		ebp, esp

	pushad

;loop to interate TOTAL_NUMS (10) times getting a string of numbers, validating it, converting it to numeric, and placing it in an array

mov		edi, [ebp + 20]
mov		ecx, TOTAL_NUMS
PutNumsInArray:	
			
	push	ecx

	jmp		NoErrors									; skip the error code unless it is specifically jumped to
			
			DisplayErrorPopEAX:
				pop		eax
			DisplayError:								; input included something that was not a digit or was too big, so display an error
				clc
				displayString[ebp + 16]
				call			Crlf
					
			NoErrors:
				mov				esi, [ebp + 8]			; pass charArray to getString through ESI register,
				getString		esi, [ebp + 12]			; pass instuction prompt from stack, stores charArray return in ESI

					; Test code to check if getString worked properly
						;displayString	esi 
						;call			Crlf
					
				cld										; clear the direction flag to move forward through the array

				mov		edx, eax						; the length of the string was stored in the EAX, so put in the EDX
				xor		eax, eax						; clear out EAX and EBX to use in loop
				xor		ebx, ebx						; ebx will act as the accumulator storing the most updated number as we convert from string to numeric
				mov		ecx, edx						; put the length of the string from the EDX into the ECX for the loop
			ConvertStringToNum:							; inner loop loads one byte, jumps out of loop if error, or finishes loop to have number stored in the outter loop
			
				lodsb									; load one byte
				sub		eax, 48							; subtract 48 to get to the decimal value from the char value
				cmp		eax, 0							; check against lower limit 0 and upper limit 9, if it is not a digit jump to error above and set up loop to try again
				jl		DisplayError
				cmp		eax, 9
				jg		DisplayError

				push	eax								; was a number, so push it in EAX so we can use EAX for the next calculations
	
				mov		eax, ebx						; mov the EBX accumulator to the EAX and multiply by 10 to shift the current number one space right
				mov		ebx, 10
				mul		ebx
				jc		DisplayErrorPopEAX				; check if multiplication set the carry flag and jump to special error which pops the EAX then displays normal error
				mov		ebx, eax						; store the result from the EAX in the EBX

				pop		eax								; now pop back the EAX value which is the valid digit 
	
				add		ebx, eax		                ; add this digit to the EBX which will now have the correct number so far in the loop
				jc		DisplayError					;check if addtion set the carry flag and jump to error if so

				; Test code to see the state of the number
					;mov	eax, ebx
					;call	WriteDec
					;call	Crlf

				xor		eax, eax

			loop	ConvertStringToNum			; loop back to get the next digit and either find an error or add it to the number accumulator in the EBX
				
	mov		eax, ebx							; Inner loop is finished without an error, so move the valid number from EBX to the EAX 
	stosd										; Store in the EDI (where NumArray was stored before PutNumsIn Array loop began)

	pop		ecx									; pop eax to return for outter PutNumsInArray loop

loop	PutNumsInArray							; go back up to the outter loop to request a new number string

	popad

	pop	ebp
	ret 16

readVal	ENDP

; Procedure to convert a numeric value to a string of digits, and invoke the displayString macro to produce the output
; receives: numArray, retCharArray, SpaceTxt, and DisplayTxt all passed by reference
; returns: displays list of numbers converted to strings to screen
; preconditions: variables are all initialized
; registers changed: ebp, esp, edi, esi, ebx, eax, ecx (saved and restored)
writeVal	PROC
; set up stackframe
push	ebp
mov		ebp, esp

pushad

displayString[ebp + 8]							; display string explaining procedure results
call	Crlf
mov		esi, [ebp + 20]							; numArray
mov		edi, [ebp + 16]							; retCharArray

cld
mov		ecx,TOTAL_NUMS

ConvertArrayOfNumsToStrings:

	ConvertNumToString:
		xor		edx, edx						; clear the edx

		mov		ebx, 10							; mov 10 to EBX for multiplication
		div		ebx								; div- EAX has quotient and EDX has remainder 
		add		edx, 48							; add 48 to the EDX, now it is converted to decimal 

		push	eax								; save the qoutient

		mov		eax, edx						; mov the remainder into EAX to save as a stringbyte 
		
		stosb									; store in the return string in the EDI
		
		;Testcode								; Test to see what was stored in the EDI
			;mov	edx, edi
			;call	WriteChar
	
		pop		eax								; resote the quotient in the EAX

		cmp		eax, 0							; if the quotient is 0 we are done with this DWORD, if not loop to the top to continue conversion
		je		Next
		jmp		ConvertNumToString

	Next:										; this number is converted, load a new DWORD, check and print STRING in displayString
		lodsd
		call	WriteDec
		displayString [ebp + 12]

loop	ConvertArrayOfNumsToStrings

call	Crlf

popad

pop	ebp

ret 16

writeVal	ENDP

; Procedure to display farewell of program
; receives: outro(ref)
; returns: displays outro to screen
; preconditions: outro is initialized
; registers changed : ebp, esp (saved and restored)
sumNums	PROC
; set up stackframe
	push	ebp
	mov		ebp, esp
	
	pushad
	
	displayString[ebp + 12]

	xor		eax, eax
	mov		esi, [ebp + 8]
	mov		ecx, TOTAL_NUMS
	AddNumsInArray:
		add		eax, [esi]
		add		esi, 4
	
	loop	AddNumsInArray

	call	WriteDec
	call	Crlf

	popad

	pop		ebp
	ret 8
sumNums	ENDP


; Procedure to display farewell of program
; receives: outro(ref)
; returns: displays outro to screen
; preconditions: outro is initialized
; registers changed : edx, ebp, esp
averageNums	PROC
	; set up stackframe
	push	ebp
	mov		ebp, esp

	pushad

	displayString[ebp + 12]

	xor		eax, eax
	xor		ebx, ebx
	xor		edx, edx
	mov		esi, [ebp + 8]
	mov		ecx, TOTAL_NUMS
AddNumsInArray:
		add		eax, [esi]
		add		esi, 4

	loop	AddNumsInArray

	mov		ebx, TOTAL_NUMS
	div		ebx

	call	WriteDec
	call	Crlf

	popad

	pop		ebp
	ret 8

averageNums	ENDP


; Procedure to display farewell of program
; receives: outro(ref)
; returns: displays outro to screen
; preconditions: outro is initialized
; registers changed : edx, ebp, esp
farewell	PROC

; set up stackframe
	push	ebp
	mov		ebp, esp

; display farewell 
	displayString	[ebp + 8]
	call			Crlf

	pop		ebp
	ret 4

farewell	ENDP


END main