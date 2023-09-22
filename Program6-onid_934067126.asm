TITLE LoLevel Prgramming     (Program6-onid_934067126.asm)

; Author: Dan Allen
; Last Modified: 3/11/2020
; Email address: danieljallen86@gmail.com
; Course number/section: CS 271-400
; Project Number: 6                Due Date: 3/15/2020
; Description:  The program uses a programmer created readVal and writeVal procedure to generate the
;				sum of 10 user provided signed integers

INCLUDE Irvine32.inc


;===========================================================================================;
displayString MACRO	string																	;
; Macro displays the passed string (using it's offset)										;
; Credit: Modeled after the myWriteString macro in Irvine chapter 10						;
; Receives: The offset of the string to be printed											;
; Returns: nothing																			;
; Preconditions: string must be an offset of a string										;
; Registers changed: EDX																	;
;===========================================================================================;	
	push	edx
	mov		edx, string
	call	WriteString
	pop		edx

ENDM


;===========================================================================================;
getString MACRO	prompt, string																;
; Macro displays a prompt and gets a user entered string									;
; Credit: modeled after the mReadString macro in Irvine chapter 10							;
; Receives: The OFFSET of the prompt and the empty string to store the entered value		;
; Returns: User string in the array and the number of charachters entered in EAX			;
; Preconditions: both arguments must be OFFSETs												;
; Registers changed: EAX, EDX, ECX															;
;===========================================================================================;
	push	edx
	push	ecx

	displayString prompt

	mov		edx, string
	mov		ecx, 99
	call	ReadString


	pop		ecx
	pop		edx

ENDM


LOWER_LIMIT = -2147483648				; not used in program, but used as reference when testing
UPPER_LIMIT = 2147483647				; not used in program, but used as reference when testing
ARRAYSIZE = 10

.data
; variable data
num_sum			DWORD	0
num_ave			DWORD	0
str_num			BYTE	100 DUP(0)
entered_num		DWORD	0
num_array		DWORD	ARRAYSIZE DUP(?)
array_index		DWORD	0

; prompt data
header_info		BYTE	"How Low Can You Go (or program)?", 13,10,
						"Answered by Dan Allen",13,10,
						"EC: Values are summed after each user integer",0
user_instruct	BYTE	"Please provide 10 signed decimal integers.",13,10,
						"Each number needs to be small enough to fit inside a 32 bit register",13,10,
						"As you input the raw numbers, I will display the running total.",13,10,
						"Afterwards, I will display a list of the integers,",13,10,
						"the total sum, and their average value.",13,10,13,10,
						"I know you're excited so let's get this party started",0
num_prompt		BYTE	"Please enter a signed integer: ",0
error_msg		BYTE	"ERROR: Your number was either too large or not a signed integer.",13,10,
						"Try again, but with feeling this time: ",0
current_sum		BYTE	"The sum of your numbers is currently: ",0
your_nums		BYTE	13, 10, "You entered the following ten numbers:",13,10,0
your_sum		BYTE	"The sum of these numbers is: ",0
your_ave		BYTE	"The rounded average is: ",0
sign_off		BYTE	13, 10, "Well, it's been fun, but I've got to run!",13,10,
						"(I'm a poet and I didn't even know it)",0
comma_space		BYTE	", ",0


.code
main PROC

; introduce the program and provide instructions on what the user will be asked to do
	push	OFFSET user_instruct
	push	OFFSET header_info
	call	introduction

	mov		ecx, 10					; loop to get 10 integers

user_inputs:
; Get user values
	push	OFFSET entered_num
	push	LENGTHOF str_num - 1
	push	OFFSET str_num
	push	OFFSET error_msg
	push	OFFSET num_prompt
	call	ReadVal

; Store the value in the array
	push	entered_num
	push	OFFSET array_index
	push	OFFSET num_array
	call	fillArray

; Calculate sum
	push	OFFSET num_sum
	push	entered_num
	call	findSum

; Display the sum
	push	OFFSET str_num
	push	num_sum
	push	OFFSET current_sum
	call	showResults

loop	user_inputs						; loop until 10 values are collected

; Display the arrray
	push	OFFSET comma_space
	push	OFFSET str_num
	push	OFFSET your_nums
	push	array_index
	push	OFFSET num_array
	call	showArray

; Display the sum
	push	OFFSET str_num
	push	num_sum
	push	OFFSET your_sum
	call	showResults

; Cacluate the average
	push	OFFSET num_ave
	push	array_index
	push	num_sum
	call	getAverage

; Display the average
	push	OFFSET str_num
	push	num_ave
	push	OFFSET your_ave
	call	showResults

; Say goodbye
	push	OFFSET sign_off
	call	goodbye

	exit	; exit to operating system
main ENDP


;===========================================================================================;
introduction PROC																			;
; Procedure welcomes the user to the program, describes what will happen (including EC for	;
;		project) and gives instructions														;
; Receives: The offsets of the introduction block and the directsion on the system stack	;
; Returns: None																				;
; Preconditions: Procedure arguments are passed on the systeme stack in the following order	;
;				 then header information.													;
;																							;
;		push	OFFSET user_instruct														;
;		push	OFFSET header_info															;
;		call	introduction																;
;																							;
; Registers changed: EDX																	;
;===========================================================================================;
	pushad
	mov		ebp, esp

	displayString	[ebp+36]		; Introduction
	call	Crlf
	call	Crlf

	displayString	[ebp+40]		; Directions	
	call	Crlf
	call	Crlf

	popad
	ret		8
introduction ENDP


;===========================================================================================;
readVal PROC																				;
; Procedure uses MACRO getString to get a user defined number as a string and then			;
;   translates that to a signed integer														;
; Receives: location of entered_num, str_num, LENGTHOF str_num - 1, num_prompt, and			;
;			and erro_msg passed on the stack												;
; Returns: The valid signed integer into the variable entered_num							;
; Preconditions: Procedure arguments are passed on the systeme stack in the following order	;
;																							;
;		push	OFFSET entered_num															;
;		push	LENGTHOF str_num - 1														;
;		push	OFFSET str_num																;
;		push	OFFSET error_msg															;
;		push	OFFSET num_prompt															;
;		call	ReadVal																		;
;																							;
; Registers changed: eax ebx ecx edx edi esi												;
;===========================================================================================;
	pushad
	mov		ebp, esp

; ensure entered num is 0 before getting another value
	mov		edi, [ebp+52]
	mov		eax, 0
	mov		[edi], eax

	mov		edx, [ebp+36]			;  OFFSET num_prompt
	cld

getNum:
	getString edx, [ebp+44]			; prompt, OFFSET str_num

	mov		esi, [ebp+44]			; OFFSET str_num
	cmp		eax, 11					; If more digits entered than largest value
	ja		noGood					; able to fit in 32 bits, no good

	mov		ecx, eax				; length of entered num
	mov		ebx, 0					; keep track of where in the string

becomeNum:
	lodsb
	cmp		ebx, 0
	jne		digits					; if not the first element of the string only numbers are valid
	cmp		eax, 43					; check for sign 
	je		sign					; and procede to next number if a sign
	cmp		eax, 45
	je		sign
	jmp		digits

sign:
	inc		ebx
	loop	becomeNum

digits:
	cmp		eax, 48					; if not an ascii code for number
	jb		noGood					; have user try again
	cmp		eax, 57
	ja		noGood
	
	sub		eax, 48
	mov		edx, [edi]
	imul	edx, 10
	add		eax, edx
	jo		overflow				; if overflow occurs, check that value is valid
	mov		[edi], eax
	mov		eax, 0					; clear eax

	inc		ebx						; advance counter
	loop	becomeNum

	mov		esi, [ebp+44]			; OFFSET str_num
	lodsb
	cmp		eax, 45					; check if negative
	jne		done
	mov		eax, [edi]
	neg		eax						; if so, negate the value
	mov		[edi], eax				; and store it
	jmp		done

overflow:
	mov		[edi], eax				; move value to entered_num for comparison

	push	esi
	mov		esi, [ebp+44]			; OFFSET str_num
	lodsb
	pop		esi
	cmp		al, 45					; if not negative, the number is too big
	jne		noGood

	mov		eax, -2147483648		; if negative, check against lower limit
	cmp		[edi], eax
	jl		noGood

	loop	becomeNum				; otherwise keep looping or continue to done
	jmp		done		

noGood:
	mov		eax, 0
	mov		[edi], eax				; clear anything out of the number
	mov		edx, [ebp+40]			; error prompt
	jmp		getNum

done:
; reset the string number to empty
	mov		ecx, 99
	mov		edi, [ebp+44]
	mov		eax, 0
	cld

clear:
	stosb
	loop	clear

	popad
	ret		20
readVal ENDP


;===========================================================================================;
findSum PROC																				;
; Procedure takes user input and adds it to the total sum									;
; Receives: The value of the user number and offset of the total sum variable				;
; Returns: The updated sum in the total sum variable										;
; Preconditions: Procedure arguments are passed on the systeme stack in the following order	;
;																							;
;		push	OFFSET num_sum																;
;		push	entered_num																	;
;		call	findSum																		;
;																							;
; Registers changed: EAX																	;
;===========================================================================================;
	pushad
	mov		ebp, esp

	mov		esi, [ebp+40]			; location of sum
	mov		eax, [esi]
	mov		ebx, [ebp+36]			; user entered number
	add		eax, ebx

	mov		[esi], eax				; store in num_sum

	popad
	ret 4
findSum ENDP

;===========================================================================================;
writeVal PROC																				;
; Procedure takes a signed integer value and prints the value to the output					;
; Receives: The number, and a string of empty bytes, and the length of the empty string on	;
;			on the stack																	;
; Preconditions: Procedure arguments are passed on the systeme stack in the following order	;
;																							;
;		push	LENGTHOF number_string														;
;		push	str_number																	;
;		push	number																		;
;		call	writeVal																	;
;																							;
; Registers changed: EAX, EBX, ECX, EDX, EDI												;
;===========================================================================================;
	pushad
	mov		ebp, esp
	
	mov		edi, [ebp+40]			; str_number

	mov		ebx, 1000000000			; largest divisor possible
	mov		eax, [ebp+36]			; number to print
	cmp		eax, 0
	
	jl		neg_sign				; if negative, store the '-' character
	jne		beginning_div			; if not 0, proceed
	add		eax, 48					; else store 0 character and finish
	stosb
	jmp		finished

; if negative, move '-' into the string
neg_sign:
	push	eax
	mov		eax, 45
	stosb
	pop		eax

; find the first divisor
beginning_div:
	mov		edx, 0
	cdq
	idiv	ebx

	cmp		eax, 0					; if dividing by ebx is not 0, the divisor is reached
	jne		makeNumStr

	mov		eax, ebx				; otherwise divide by 10 and try again
	mov		ebx, 10
	push	edx
	mov		edx, 0
	cdq
	idiv	ebx
	mov		ebx, eax
	pop		eax						; move saved remainder to eax

	jmp		beginning_div

makeNumStr:
	cmp		eax, 0
	jnl		positive
	neg		eax						; if negative, make positive

positive:
	add		eax, 48					; translate number to ASCII character
	stosb
	cmp		ebx, 1
	je		finished


; get the next divisor
next_div:
	push	edx
	mov		eax, ebx				; divisor to translate next position in number string
	mov		ebx, 10
	mov		edx, 0
	cdq
	idiv	ebx
	mov		ebx, eax

; next digit in the number
	pop		eax						; move saved remainder to eax
	mov		edx, 0
	cdq
	idiv	ebx	
	
	jmp		makeNumStr

; When done, print the number and clear the string
finished:

displayString [ebp+40]

; empty the string for future use
	mov		ecx, 11					; the most digits possible for a 32 bit integer
	mov		edi, [ebp+40]			; number as a string
	mov		eax, 0
	cld

clear:
	stosd
	loop clear

	popad
	ret		12
writeVal ENDP


;===========================================================================================;
getAverage PROC																				;
; Receives: Uniitialized variable for the average, the sum of the integers, and the size	;
;			of the array (number of values collected)										;
; Returns: the average in the num_ave variable												;
; Preconditions: Procedure arguments are passed on the systeme stack in the following order	;
;																							;
;		push	OFFSET num_ave																;
;		push	array_index																	;
;		push	num_sum																		;
;		call	getAverage																	;
;																							;
; Registers changed: EAX, EBX, EDX															;
;===========================================================================================;
	pushad
	mov		ebp, esp

	mov		eax, [ebp+36]		; sum of integers
	mov		edx, 0
	mov		ebx, [ebp+40]		; number of integers gathered
	cdq
	idiv	ebx
	mov		edx, [ebp+44]		; store value in num_ave
	mov		[edx], eax			; store rounded average in as num_ave

	popad
	ret		12
getAverage ENDP


;===========================================================================================;
showResults PROC																			;
; Procedure prints out a label and an integer generated from calculations					;
; Receives: The number to be printed, offset of the label, and the offset of the string to	;
;			by writeVal																		;
; Preconditions: Procedure arguments are passed on the systeme stack in the following order	;
;																							;
;		push	OFFSET str_num																;
;		push	num_ave																		;
;		push	OFFSET number label															;
;		call	showResults																	;
;																							;
; Registers changed: EDX, EBP																;
;===========================================================================================;
	pushad
	mov		ebp, esp

	displayString	[ebp+36]
	push	11
	push	[ebp+44]
	push	[ebp+40]
	call	writeVal
	call	Crlf

	popad
	ret		12
showResults ENDP


;===========================================================================================;
fillArray PROC	USES eax ebx edi ebp														;
; Procedure takes a value and places it into an array at the next open element				;
; Receives: The number to store, the index of the next open location in the array, and the	;
;			location of the array.															;
; Returns: The value stored in the array and the index is incrimented						;
; Preconditions: Procedure arguments are passed on the systeme stack in the following order	;
;																							;
;		push	entered_num																	;
;		push	OFFSET array_index															;
;		push	OFFSET num_array															;
;		call	fillArray																	;
;																							;
; Registers changed: EAX, EBX, EDI															;
;===========================================================================================;
	mov		ebp, esp

	mov		edi, [ebp+20]				; array location
	mov		ebx, [ebp+24]				; index
	mov		eax, [ebx]
	mov		ebx, 4
	mul		ebx
	add		edi, eax					; pointing at array location

	mov		eax, [ebp+28]				; user input
	stosd
	
	mov		ebx, [ebp+24]				; index
	mov		eax, [ebx]
	inc		eax
	mov		[ebx], eax

	ret		12
fillArray ENDP


;===========================================================================================;
showArray PROC																				;
; Procedure displays an array to the output window with a label indicating what the array	;
;	contains																				;
; Receives: The location of the array, how many objects are in the array, the label for the ;
;			array, an empty string used to convert numbers to strings printable to the		;
;			window, and ', ' to be printed between each array value							;
; Returns: None																				;
; Preconditions: Procedure arguments are passed on the systeme stack in the following order	;
;																							;
;		push	OFFSET comma_space															;
;		push	OFFSET str_num																;
;		push	OFFSET your_nums															;
;		push	array_index																	;
;		push	OFFSET num_array															;
;		call	showArray																	;
;																							;
; Registers changed: ECX, ESI, EBP															;
;===========================================================================================;
	pushad
	mov		ebp, esp

	displayString [ebp+44]			; print label
	
	mov		ecx, [ebp+40]			; array_index
	dec		ecx
	mov		esi, [ebp+36]			; OFFSET num_array

showElements:
	push	11
	push	[ebp+48]				; OFFSET str_num 
	push	[esi]					; value at array location
	call	writeVal

	displayString [ebp+52]

	add		esi, 4
	loop	showElements 
	
	push	11
	push	[ebp+48]				; OFFSET str_num 
	push	[esi]					; value at array location
	call	writeVal

	call	Crlf

	popad
	ret		20
showArray ENDP


;===========================================================================================;
goodbye PROC USES edx ebp																	;
; Procedure Prints strings to the terminal saying goodbye to to the user.					;
; Receives: The offset of the goodbye message on the system stack							;
; Returns: None																				;
; Preconditions: The offset of the message must be pushed on the stack before calling		;
;																							;
;		push	OFFSET sign_off																;
;		call	goodbye																		;
;																							;
; Registers changed: EDX, EBP																;
;===========================================================================================;
	mov		ebp, esp

	displayString [ebp+12]			; goodbye message
	call	Crlf
	call	Crlf

	ret		4
goodbye ENDP

END main
