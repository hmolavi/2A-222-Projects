;*-------------------------------------------------------------------
;* Name:    	lab_4_program.s 
;* Purpose: 	A sample style for lab-4
;* Term:		Winter 2013
;*-------------------------------------------------------------------
				THUMB 								; Declare THUMB instruction set 
				AREA 	My_code, CODE, READONLY 	; 
				EXPORT 		__MAIN 					; Label __MAIN is used externally 
				EXPORT		EINT3_IRQHandler
				ENTRY 

__MAIN

; The following lines are similar to previous labs.
; They just turn off all LEDs 
				MOV 	R6, #0

				LDR		R0, =ISER0		; set the EINT3 enable bit
				LDR		R1, [R0]
				MOV 	R2, #0x200000	; bit 21
				ORR 	R1, R1, R2
				STR		R1, [R0]

				LDR		R0, =IO2IntEnf	; enable P.210 to interrupt for falling edge
				LDR		R1, [R0]
				MOV 	R2, #0x0400		; bit 11
				ORR		R1, R1, R2
				STR		R1, [R0]
				

				LDR		R10, =LED_BASE_ADR	; R10 is a  pointer to the base address for the LEDs
				MOV 	R3, #0xB0000000		; Turn off three LEDs on port 1  
				STR 	R3, [R10, #0x20]
				MOV 	R3, #0x0000007C
				STR 	R3, [R10, #0x40] 	; Turn off five LEDs on port 2 

; This line is very important in your main program
; Initializes R11 to a 16-bit non-zero value and NOTHING else can write to R11 !!
				MOV		R11, #0xABCD		; Init the random number generator with a non-zero number
LOOP 			BL 		RNG  
				
FLASH_LEDS		MOV		R3, #0x4000000	; Turn on three LEDs on port 1 
				STR 	R3, [R10, #0x20]
				MOV		R3, #0x00000080	; Turn on five LEDs on port 2 
				STR 	R3, [R10, #0x40]
				
				MOV		R0, #0x0005			; LED's Flash at 2 Hertz
				BL 		DELAY
				
				MOV 	R3, #0xB0000000		; Turn off three LEDs on port 1  
				STR 	R3, [R10, #0x20]
				MOV 	R3, #0x0000007C
				STR 	R3, [R10, #0x40] 	; Turn off five LEDs on port 2 
				
				MOV		R0, #0x0005			; LED's Flash at 2 Hertz
				BL 		DELAY
				
				TEQ		R6, #0				; Loop back as along as R6 is zero
				BEQ		LOOP
				
HELLO			MOV		R3, R6				; Copy random number in R6 to R3 for displaying
				BL		DISPLAY_NUM		
				
				MOV		R0, #10				; Using 1 second delays
				BL 		DELAY
				
				SUB		R6, #10				; Count the random number in R6 10 at a time
				
				CMP		R6, #0				; Continue until count is <= 0
				BGT		HELLO
				MOV		R6, #0				; Otherwise start flashing LEDs again
				BLT		LOOP
				
				
				
;*------------------------------------------------------------------- 
; Subroutine RNG ... Generates a pseudo-Random Number in R11 
;*------------------------------------------------------------------- 
; R11 holds a random number as per the Linear feedback shift register (Fibonacci) on WikiPedia
; R11 MUST be initialized to a non-zero 16-bit value at the start of the program
; R11 can be read anywhere in the code but must only be written to by this subroutine
RNG 			STMFD		R13!,{R1-R3, R14} 	; Random Number Generator 
				AND			R1, R11, #0x8000
				AND			R2, R11, #0x2000
				LSL			R2, #2
				EOR			R3, R1, R2
				AND			R1, R11, #0x1000
				LSL			R1, #3
				EOR			R3, R3, R1
				AND			R1, R11, #0x0400
				LSL			R1, #5
				EOR			R3, R3, R1			; The new bit to go into the LSB is present
				LSR			R3, #15
				LSL			R11, #1
				ORR			R11, R11, R3
				LDMFD		R13!,{R1-R3, R15}
				
DISPLAY_NUM		STMFD		R13!,{R1, R2, R3, R4, R14}

				EOR			R3, #0xFFFFFFFF			; complement all bits (active low)
				
				MOV 		R4,	#0x0				; intialize R4 to 0
				BFI			R4, R3, #0, #5			; store lower 5 bits of R3 into R4 (port 2 leds)
				RBIT		R4,	R4
				LSR			R4, #27
				LSR 		R3, #5					; shift out the port 2 bits as no longer needed
				LSL			R4,	#2					; left shift to properly align bits on pins P2.6 --> P2.2
				
				STR 		R4, [R10, #0x40]		; display num on five LEDs on port 2
						
				RBIT		R3, R3					; reverse the bit order
				AND			R4, R3, #0x80000000		; store bit for P1.31 in R4
				LSL			R3, #1					; left shift out P1.31 bit as no longer needed
				LSR			R3, #2					; right shift to properly align bits to end on P1.28
				ORR			R3, R3, R4				; place P1.31 bit back in the correct position
				
				STR			R3, [R10, #0x20]		; display num of three LEDs on port 1
					
				LDMFD		R13!,{R1, R2, R3, R4, R15}

;*------------------------------------------------------------------- 
; Subroutine DELAY ... Causes a delay of 1ms * R0 times
;*------------------------------------------------------------------- 
; 		aim for better than 10% accuracy
DELAY			STMFD		R13!,{R2, R14}

initialize		MOV32 		R2, #0x208D5		 ; Initialize R2 lower word for countdown (0.1 s)
					
decrement		SUBS 		R2, #1 				; Decrement R2 and set the N,Z,C status bits
				BNE 		decrement			; branch to 'decrement' if countdown hasnt reached 0
				
				SUBS		R0,	#1
				BNE			initialize
				
exitDelay		LDMFD		R13!,{R2, R15}		; restore R2 and LR to R15 the Program Counter to return

; The Interrupt Service Routine MUST be in the startup file for simulation 
;   to work correctly.  Add it where there is the label "EINT3_IRQHandler
;
;*------------------------------------------------------------------- 
; Interrupt Service Routine (ISR) for EINT3_IRQHandler 
;*------------------------------------------------------------------- 
; This ISR handles the interrupt triggered when the INT0 push-button is pressed 
; with the assumption that the interrupt activation is done in the main program
EINT3_IRQHandler 	
				STMFD 		R13!, {R0, R1, R2, R3, R4} ; Use this command if you need it  
					
				MOV			R3, #0				; Intialize register
				
				BFI			R3, R11, #0, #7		; copy lower 7 bits (MAX 128) of random num into R3
				
				MOV			R4, #156			; scaling code to get a number between 50 and 250
				MUL			R3, R4				; current range: 0 --> 19968
				
				MOV			R4, #100			
				UDIV		R3, R3, R4			; current range: 0 --> 199.68
				
				ADD 		R3, R3, #50			; current range: 50 --> 249.68
				
				MOV			R6, R3				; Store scaled random number into R6

				LDR			R0, =IO2IntClr		; Clear the cause of interrupt
				MOV			R2, #0x0400			; Reset value
				STR			R2, [R0]			

				LDMFD 		R13!, {R0, R1, R2, R3, R4} ; Use this command if you used STMFD (otherwise use BX LR) 
				
				BX 			LR
				

;*-------------------------------------------------------------------
; Below is a list of useful registers with their respective memory addresses.
;*------------------------------------------------------------------- 
LED_BASE_ADR	EQU 	0x2009c000 		; Base address of the memory that controls the LEDs 
PINSEL3			EQU 	0x4002C00C 		; Pin Select Register 3 for P1[31:16]
PINSEL4			EQU 	0x4002C010 		; Pin Select Register 4 for P2[15:0]
FIO1DIR			EQU		0x2009C020 		; Fast Input Output Direction Register for Port 1 
FIO2DIR			EQU		0x2009C040 		; Fast Input Output Direction Register for Port 2 
FIO1SET			EQU		0x2009C038 		; Fast Input Output Set Register for Port 1 
FIO2SET			EQU		0x2009C058 		; Fast Input Output Set Register for Port 2 
FIO1CLR			EQU		0x2009C03C 		; Fast Input Output Clear Register for Port 1 
FIO2CLR			EQU		0x2009C05C 		; Fast Input Output Clear Register for Port 2 
IO2IntEnf		EQU		0x400280B4		; GPIO Interrupt Enable for port 2 Falling Edge 
ISER0			EQU		0xE000E100		; Interrupt Set-Enable Register 0 
IO2IntClr		EQU		0x400280AC		; GPIO Interrupt Clear for port 2

				ALIGN 

				END 
