; ECE-222 Lab ... Winter 2013 term 
; Lab 3 sample code 
				THUMB 		; Thumb instruction set 
                AREA 		My_code, CODE, READONLY
                EXPORT 		__MAIN
				ENTRY  
__MAIN

; The following lines are similar to Lab-1 but use a defined address to make it easier.
; They just turn off all LEDs 
				LDR			R10, =LED_BASE_ADR		; R10 is a permenant pointer to the base address for the LEDs, offset of 0x20 and 0x40 for the ports

				MOV 		R3, #0xB0000000		; Turn off three LEDs on port 1  
				STR 		R3, [R10, #0x20]
				MOV 		R3, #0x0000007C
				STR 		R3, [R10, #0x40] 	; Turn off five LEDs on port 2 
				
				;BL			SIMPLE_COUNTER		; uncomment to test the simple counter
				
				MOV 		R0, #0x00000000		; intialize all registers as needed
				MOV 		R1, #0x00000000
				MOV 		R2, #0x00000000
				MOV 		R3, #0x90000000
				MOV 		R4, #0x00000000
				MOV 		R5, #0x00000000
				MOV 		R6, #0x00000000
				MOV 		R7, #0x00000000
				MOV			R8, #0x00004E20		; 20000
				

; This line is very important in your main program
; Initializes R11 to a 16-bit non-zero value and NOTHING else can write to R11 !!
				MOV			R11, #0xABCD		; Init the random number generator with a non-zero number
loop 			BL 			RandomNum 	
				
				CMP			R11, R8				; check random value is above 20000
				BLT			loop
				
				MOV32		R8, #0x186A0		; 100000
				
				CMP			R11, R8				; check random value is below 100000			
				BGT			loop
				
				MOV			R0,	R11 			; copy random value into R0
				BL 			DELAY				; delay for the specified random value
				
				STR 		R3, [R10, #0x20]	; turn one LED (P1.29) on	

				B 			BTNPOLL				; branch to polling loop

;
; Display the number in R3 onto the 8 LEDs
; Useful commands:  RBIT (reverse bits), BFC (bit field clear), LSR & LSL to shift bits left and right, ORR & AND and EOR for bitwise operations
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
				
BTNPOLL			MOV			R0,	#1					; intialize # of delays to 1
				BL 			DELAY					; delay for 0.1mS
				ADD			R7, #0x1				; increment R7 register value (counter)

				LDR			R5, =FIO2PIN0			; store address of FIO2PIN in R5
				LDR			R6,	[R5]				; load the contents of memory pointed to by R5 into R6
				LSR			R6, #10					; put the 10th bit corresponding to the push-button (INT0) in the LSB
				MOV			R4,	#0					
				BFI			R4, R6, #0, #1			; copy LSB bit into R4	
				
				TEQ			R4, #0x1				; test whether the button is pressed (value is 0)
					
				BEQ			BTNPOLL					; if not, poll
				
				MOV 		R3, #0xB0000000			; Turn off three LEDs on port 1  
				
				STR 		R3, [R10, #0x20]		
				
RESULTS			MOV			R1, R7					; store a copy of the counter in R1

NEXTBITS		MOV			R6,	#0	
REDO			MOV			R3, #0					; loop counter					
				BFI			R3, R1, #0, #8			; copy adajcent 8 bits starting at position 0 from R1 into R3	
				LSR			R1, #8					; shift out the 8 bits we just copied as no longer needed
				BL 			DISPLAY_NUM				; display the corresponding number on LED's
				MOV			R0, #0x4E20				; ~2s delay
				BL 			DELAY
				ADD			R6, #1					
				
				TEQ			R6, #4					; 4 passes to display all 32 bits since 32/8 = 4
				BNE			REDO					; if not 4, process next 8 bits
				
				MOV			R0, #0x7530				; ~3s delay
				BL 			DELAY				
				
				BEQ			RESULTS					; branch to 'RESULTS' to display bits again	
				
;
; R11 holds a 16-bit random number via a pseudo-random sequence as per the Linear feedback shift register (Fibonacci) on WikiPedia
; R11 holds a non-zero 16-bit number.  If a zero is fed in the pseudo-random sequence will stay stuck at 0
; Take as many bits of R11 as you need.  If you take the lowest 4 bits then you get a number between 1 and 15.
;   If you take bits 5..1 you'll get a number between 0 and 15 (assuming you right shift by 1 bit).
;
; R11 MUST be initialized to a non-zero 16-bit value at the start of the program OR ELSE!
; R11 can be read anywhere in the code but must only be written to by this subroutine
RandomNum		STMFD		R13!,{R1, R2, R3, R14}

				AND			R1, R11, #0x8000
				AND			R2, R11, #0x2000
				LSL			R2, #2
				EOR			R3, R1, R2
				AND			R1, R11, #0x1000
				LSL			R1, #3
				EOR			R3, R3, R1
				AND			R1, R11, #0x0400
				LSL			R1, #5
				EOR			R3, R3, R1		; the new bit to go into the LSB is present
				LSR			R3, #15
				LSL			R11, #1
				ORR			R11, R11, R3
				
				
				LDMFD		R13!,{R1, R2, R3, R15}

;
;		Delay 0.1ms (100us) * R0 times
; 		aim for better than 10% accuracy
DELAY			STMFD		R13!,{R2, R14}

initialize		MOV 		R2, #0x0085		 	; Initialize R2 lower word for countdown (0.1 mS)
				;MOVT 		R2, #0x0002			; 0x208D5 for simple counter, 0x85 for polling 
					
decrement		SUBS 		R2, #1 				; Decrement R2 and set the N,Z,C status bits
				BNE 		decrement			; branch to 'decrement' if countdown hasnt reached 0
				
				SUBS		R0,	#1
				BNE			initialize
				
exitDelay		LDMFD		R13!,{R2, R15}		; restore R2 and LR to R15 the Program Counter to return



SIMPLE_COUNTER	STMFD		R13!,{R3, R14}

restart			MOV 		R3, #0x0			; intialize counter to 0x0
				
increment		BL			DISPLAY_NUM			; branch and link to 'DISPLAY_NUM' subroutine
				MOV			R0,	#1
				BL			DELAY
				ADD 		R3, #1 				; increment R3 and set the N,Z,C status bits
				TEQ			R3, #0xFF			; test if R3 has reached 0xFF (255)
				BNE 		increment			; branch to 'increment' if countdown hasnt reached 0
				BEQ			restart				; branch to 'restart' if counter has reached 255
				
				LDMFD		R13!,{R3, R15}
				

FIO2PIN0		EQU		0x2009C054		
LED_BASE_ADR	EQU 	0x2009C000 		; Base address of the memory that controls the LEDs 
PINSEL3			EQU 	0x4002C00C 		; Address of Pin Select Register 3 for P1[31:16]
PINSEL4			EQU 	0x4002C010 		; Address of Pin Select Register 4 for P2[15:0]

;	Usefull GPIO Registers
;	FIODIR  - register to set individual pins as input or output
;	FIOPIN  - register to read and write pins
;	FIOSET  - register to set I/O pins to 1 by writing a 1
;	FIOCLR  - register to clr I/O pins to 0 by writing a 1

; POST-LAB 
; Q1	
; 8 bits = 0.0255 seconds
; 16 bits = 6.5536 seconds
; 24 bits = 1677.7215 seconds
; 32 bits --> 429496.7295 seconds
;
; Q2
; According to a simple google search, the typical human reaction time lies somewhere in the range 150ms - 300ms. It could be possible to use 8 bits, but 
; to accommodate for the higher end of the spectrum, it would be safe and best to use 16 bits for this task.

; Q3 - Prove time delay meets 2 to 10s
; We used the approach of continously calling the RandomNum subroutine until the value in R11 is within the range of 20000-100000 (line 36), thus meeting
; specified requirement,

				ALIGN 

				END 
