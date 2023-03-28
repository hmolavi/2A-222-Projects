;*----------------------------------------------------------------------------
;* Name:    Lab_2_program.s 
;* Purpose: This code template is for Lab 2
;* Author: Eric Praetzel and Rasoul Keshavarzi 
;*----------------------------------------------------------------------------*/
		THUMB 		; Declare THUMB instruction set 
        AREA 		My_code, CODE, READONLY 	; 
        EXPORT 		__MAIN 		; Label __MAIN is used externally q
		ENTRY 
__MAIN
; The following lines are similar to Lab-1 but use an address, in r4, to make it easier.
; Note that one still needs to use the offsets of 0x20 and 0x40 to access the ports
;
; Turn off all LEDs 
		MOV 		R2, #0xC000
		MOV 		R3, #0xB0000000	
		MOV 		R4, #0x0
		MOVT 		R4, #0x2009
		ADD 		R4, R4, R2 		    ;0x2009C000 - the base address for dealing with the ports
		STR 		R3, [R4, #0x20]		; Turn off the three LEDs on port 1
		MOV 		R3, #0x0000007C
		STR 		R3, [R4, #0x40] 	; Turn off five LEDs on port 2 

ResetLUT
		LDR         R5, =InputLUT            ; assign R5 to the address at label LUT

; Start processing the characters

NextChar
        LDRB        R0, [R5]		    ; Read a character to convert to Morse Code
        ADD         R5, #1              ; point to next value for number of delays, jump by 1 byte
		TEQ         R0, #0              ; If we hit 0 (null at end of the string) then reset to the start of lookup table
		BNE		    ProcessChar	        ; If we have a character process it

		MOV		    R6, #0x0004         ; load the # of delays (4 dots) in R6 (3 dots already done after character completed)
		BL 		    HOLDON              ; branch and link to HOLDON subroutine
		BEQ         ResetLUT            ; restart process when finished

ProcessChar	BL		CHAR2MORSE	; convert ASCII to Morse pattern in R1		

;*************************************************************************************************************************************************
;*****************  These are alternate methods to read the bits in the Morse code LUT. You can use them or not **********************************
;************************************************************************************************************************************************* 

;	This is a different way to read the bits in the Morse Code LUT than is in the lab manual.
; 	Choose whichever one you like.
; 
;	First - loop until we have a 1 bit to send  (no code provided)
;
;	This is confusing as we're shifting a 32-bit value left, but the data is ONLY in the lowest 16 bits, so test starting at bit 15 for 1 or 0
;	Then loop thru all of the data bits:
;
;		MOV		R6, #0x8000	; Init R6 with the value for the bit, 15th, which we wish to test
;		LSL		R1, R1, #1	; shift R1 left by 1, store in R1
;		ANDS		R7, R1, R6	; R7 gets R1 AND R6, Zero bit gets set telling us if the bit is 0 or 1
;		BEQ		; branch somewhere it's zero
;		BNE		; branch somewhere - it's not zero
;
;		....  lots of code
;		B 		somewhere in your code! 	; This is the end of the main program 
;
; Alternate Method #2
; Shifting the data left - makes you walk thru it to the right.  You may find this confusing!
; Instead of shifting data - shift the masking pattern.  Consider this and you may find that
; there is a much easier way to detect that all data has been dealt with.
;
;		LSR		R6, #1		; shift the mask 1 bit to the right
;		ANDS		R7, R1, R6	; R7 gets R1 AND R6, Zero bit gets set telling us if the bit is 0 or 1
;
;
; Alternate Method #3
; All of the above methods do not use the shift operation properly.
; In the shift operation the bit which is being lost, or pushed off of the register,
; "falls" into the C flag - then one can BCC (Branch Carry Clear) or BCS (Branch Carry Set)
; This method works very well when coupled with an instruction which counts the number 
; of leading zeros (CLZ) and a shift left operation to remove those leading zeros.

;*************************************************************************************************************************************************
;
;
; Subroutines
;
;			convert ASCII character to Morse pattern
;			pass ASCII character in R0, output in R1
;			index into MorseLuT must be by steps of 2 bytes
CHAR2MORSE	STMFD		R13!,{R0, R8, R14}	    ; push R0, R8 and Link Register (return address) on stack
		    LDR 		R8, =MorseLUT           ; assign R8 to the address at label MorseLUT
		    SUB 		R0, #0x41;              ; subtract 41 from R0 (convert ASCII character into index)
		    LDRH		R1, [R8, R0, LSL #1]    ; lookup and store morse pattern in R1 (MorseLUT address + index offset)
		
		    BL			MORSEPATTERN            ; branch and link to MORSEPATTERN subroutine
		
		    LDMFD		R13!,{R0, R8, R15}      ; restore R0, R8, and LR to R15 the Program Counter to return

; Turn the LED on, but deal with the stack in a simpler way
; NOTE: This method of returning from subroutine (BX  LR) does NOT work if subroutines are nested!!
;
LED_ON 	   	STMFD	R13!,{R3}	; push R3 on stack
		    MOV		R3, #0x0000
		    MOVT	R3, #0xA000		; value 0xA0000000 turns on LED
		    STR		R3, [R4, #0x20]	; address 0x2009C000 + 0x20 corresponds to LED (P1.28)
		    LDMFD	R13!,{R3}	    ; restore R3
            BX 		LR		        ; branch to the address in the Link Register.

; Turn the LED off, but deal with the stack in the proper way
; the Link register gets pushed onto the stack so that subroutines can be nested
;
LED_OFF	   	STMFD		R13!,{R3}	    ; push R3 on stack
		    MOV		    R3, #0x0000
		    MOVT	    R3, #0xB000		; value 0xB0000000 turns off LED
		    STR		    R3, [R4, #0x20]	; address 0x2009C000 + 0x20 corresponds to LED (P1.28)
		    LDMFD		R13!,{R3}	    ; restore R3
            BX 		    LR		        ; branch to the address in the Link Register.
		
; Count down delays given the # of dots which is passed through R6
; decrement helper label branches back until counter hits 0
;         
HOLDON	    STMFD		R13!,{R7, R14}	    ; push R7 and Link Register (return address) on stack
			MOV 		R7, #0xFFFF 		; Initialize R7 lower word for countdown
			MOVT 		R7, #0x000C 		; Initialize R7 upper word for countdown (~0.5s delay)
			MUL			R7, R6              ; multiply R7 by the # of delays needed
					
decrement	SUBS 		R7, #1 				; Decrement R7 and set the N,Z,C status bits
			BNE 		decrement			; branch to 'decrement' if countdown hasnt reached 0
			LDMFD		R13!,{R7, R15}	    ; restore R7 and LR to R15 the Program Counter to return

;	Use the delay loop from Lab-1 but loop R0 times around
;
MORSEPATTERN		STMFD		R13!,{R6, R8, R14} ; push R6, R8 and Link Register (return address) on stack
					CLZ		    R8,	R1		; count leading zeros and store number in R8			
					LSL         R1, R8		; shift out the extra leading zeros from the morse pattern
loop				LSLS		R1, #1      ; left shift one bit in morse pattern and update condition flags
					BLCS		LED_ON      ; if C = '1', branch and link to LED_ON subroutine
					BLCC		LED_OFF     ; else if C = '0', branch and link to LED_OFF subroutine
					
					MOV		    R6, #0x0001 ; load the # of delays (1 dot) in R6
					BL			HOLDON      ; branch and link to HOLDON subroutine
MultipleDelay		TEQ			R1, #0		; test R1 to see if it's 0

					BNE 		loop        ; process next morse pattern bit if not 0
					BL		    LED_OFF     ; turn off led when flashing character completed
					
					MOV		    R6, #0x0003 ; load the # of delays (3 dot between characters) in R6  
					BL          HOLDON      ; branch and link to HOLDON subroutine
					
					BEQ			NextChar    ; process next character

exitDelay		    LDMFD		R13!,{R6, R8, R15} ; restore R6, R8, and LR to R15 the Program Counter to return

;
; Data used in the program
; DCB is Define Constant Byte size
; DCW is Define Constant Word (16-bit) size
; EQU is EQUate or assign a value.  This takes no memory but instead of typing the same address in many places one can just use an EQU
;
		ALIGN				; make sure things fall on word addresses

; One way to provide a data to convert to Morse code is to use a string in memory.
; Simply read bytes of the string until the NULL or "0" is hit.  This makes it very easy to loop until done.
;
InputLUT	DCB		"HMGKE", 0	; strings must be stored, and read, as BYTES
; 1010101 000 1110111 000 111011101 000 111010111 000 1 0000000

		ALIGN				    ; make sure things fall on word addresses
MorseLUT 
		DCW 	0x17, 0x1D5, 0x75D, 0x75 	; A, B, C, D
		DCW 	0x1, 0x15D, 0x1DD, 0x55 	; E, F, G, H
		DCW 	0x5, 0x1777, 0x1D7, 0x175 	; I, J, K, L
		DCW 	0x77, 0x1D, 0x777, 0x5DD 	; M, N, O, P
		DCW 	0x1DD7, 0x5D, 0x15, 0x7 	; Q, R, S, T
		DCW 	0x57, 0x157, 0x177, 0x757 	; U, V, W, X
		DCW 	0x1D77, 0x775 			; Y, Z

; One can also define an address using the EQUate directive
;
LED_PORT_ADR	EQU	0x2009c000	; Base address of the memory that controls I/O like LEDs

		END 