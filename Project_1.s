;*----------------------------------------------------------------------------
;* Name:    Lab_1_program.s 
;* Purpose: This code flashes one LED at approximately 1 Hz frequency 
;* Author: 	Rasoul Keshavarzi 
;*----------------------------------------------------------------------------*/
	THUMB		; Declare THUMB instruction set 
	AREA		My_code, CODE, READONLY 	; 
	EXPORT		__MAIN 		; Label __MAIN is used externally q
	ENTRY 
__MAIN
; The following operations can be done in simpler methods. They are done in this 
; way to practice different memory addressing methods. 
; MOV moves into the lower word (16 bits) and clears the upper word
; MOVT moves into the upper word
; show several ways to create an address using a fixed offset and register as offset
;   and several examples are used below
; NOTE MOV can move ANY 16-bit, and only SOME >16-bit, constants into a register
; BNE and BEQ can be used to branch on the last operation being Not Equal or EQual to zero
;
	MOV 		R2, #0xC000		; move 0xC000 into R2
	MOV 		R4, #0x0		; init R4 register to 0 to build address
	MOVT 		R4, #0x2009		; assign 0x20090000 into R4
	ADD 		R4, R4, R2 		; add 0xC000 to R4 to get 0x2009C000 

	MOV 		R3, #0x0000007C	; move initial value for port P2 into R3 
	STR 		R3, [R4, #0x40] 	; Turn off five LEDs on port 2 

	MOV 		R3, #0xB0000000	; move initial value for port P1 into R3
	STR 		R3, [R4, #0x20]	; Turn off three LEDs on Port 1 using an offset

	MOV 		R2, #0x20		; put Port 1 offset into R2 for user later
count
	MOV 		R0, #0xFFFF 		; Initialize R0 lower word for countdown
	MOVT 		R0, #0x000A 		; Initialize R0 upper word for countdown (~0.5s delay)
loop
	SUBS 		R0, #1 			; Decrement r0 and set the N,Z,C status bits
	
	BNE 		loop			; branch to 'loop' if countdown hasnt reached 0
	EOR 		R3, #0x10000000	; toggle bit 28

	STR 		R3, [R4, R2] 	; write R3 port 1, YOU NEED to toggle bit 28 first

	B 			count			; branch to 'count' to initialize counter
	
	; ADD R4, R4, R2 = 1110 00 0 0100 0 0100 0100 000000000010 (HAND ASSEMBLY FOR LAB REPORT)

 	END 
