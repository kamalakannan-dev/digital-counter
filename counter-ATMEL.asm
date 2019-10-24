;==================================================================================================================================
;										IDUSTRIAL DIGITAL COUNTER WITH CONTROLLED BATCH COUNTING
;==================================================================================================================================
; This programm is made for ATMEL series of 8051 arch ICs.  ATMEL 89 C/S 51/52.  Plan is to use only one timer is used (Timer-0).  The codes 
; written inside Timer-1 ISR has been changed and migrated to Timer-0.  Since the timer-0 timing is double times slower than timer-1, 
; only half value has been choosen in each couting byte of timer-1 to achiev the same time delay.  The changes are mentioned here under.
; 20MS delay call: Byte D20MS (14H -> AH) @ T20MSDELAY Call; (0AH -> 05H) @ External Interrupt-0 ISR
; 5S delay call: Byte D5S_1 (88H | C4H) @ STR5SDELAY Call 
;				 Byte D5S_2 (14H | 05H) @ STR5SDELAY Call 
; Buzzer 0.2S (200ms) Call: But actually it is made to blow 30ms since 200ms is a long duration
;				 Byte BUZ02S_1 (30 | 15) @ T02SBUZZER Call
; Buzzer 1S Call: Byte BUZ1S_1 (E8H | F4H) @ T1BUZZER Call
; 				  Byte BUZ1S_2 (04H | 02H) @ T1BUZZER Call
;===============================================Interrupt vector table=============================================================
				ORG 0000H
				SJMP MAIN			; Jumping to the main program code
				ORG 0003H
				LJMP EXINT0			; Jumping to the External Interrupt 0 ISR code
				ORG 000BH
				LJMP TIMER0			; Jumping to the Timer 0 Interrupt ISR code
;================================================Main program code=================================================================
				ORG 30H
MAIN:			MOV TMOD, #11H		; Enabling both timers Timer-0 and Timer-1 at 16-Bit timer mode.  But we dont need timer-1 acutally.		
				SETB TCON.0			; Edge Triggering the External Interrupt-0
				MOV 0A8H, #10000011B	; IE register (0A8H) is set to enable interrupt for External-0 & Timer-0 interrupt
				MOV 0B8H, #00000010B	; IP register (0B8H) is set so as the Timer-0 has to top priority among all interrupts
;				SETB IP.1			; Alternatively you can set the Timer-0 bit (but yet to be confirmed)
;============================Assigning various pins of controller and RAM locations to corresponding BIT directives================
				BA BIT P2.7			; Internal Buzzer bit to blow the buzzer
				BB BIT 08H			; 0.2 second buzzer bit flag bit
				BC BIT 09H			; 1 second buzzer bit flag bit
				BD BIT P2.6			; External buzzer bit
				BE BIT 10H			; 20 milli second delay flag bit (ON/OFF)
				BF BIT 11H			; 5 second time delay flag bit
				BG BIT 12H			; Target blink switch flag bit (ON/OFF)
				BHH BIT 13H			; Target blink toggle flag bit
				BI BIT 14H			; 0.5 second delay flag bit (ON/OFF)
				BJ BIT 15H			; 0.5 second delay flag bit (flag)
				BK BIT 16H			; After 5 second blink (ON/OFF) bit
				BLL BIT 17H			; After 1 second target blink (ON/OFF) bit				
				TB BIT PSW.5		; True bit, confirms the true interrupt has been made
				NB BIT PSW.1		; New bit, confirms the value has been changed to new
				S1 BIT P2.0			; Round Button - Common 
				S2 BIT P2.1			; Enter button - @ the Center 
				S3 BIT P2.2			; Up arrow button - @ the right side 
				BM BIT P2.5			; Busy LED bit
				BN BIT P2.3			; Arithmetic LED bit. Bicolor LED should be used to indicate the operation
				BO BIT P2.4			; Batch count enable indication LED
				BPP BIT 0AH			; Bit used to switch ON/OFF the preceeding zero etching process at DCC call
				T0C BIT 0BH			; Timer-0 Carry backup bit location
				T1C BIT 0CH			; Timer-1 Carry backup bit location
;				INT0 BIT P3.2		; Interrupt-0 at the pin number P3.2
;==========Assinging various RAM  byte locations to corresponding byte directives===================================================
				ArBEN EQU 20H		; ArBEN byte used to store the value which directs arithmetic operations and batch count operations
				BUZ02S_1 EQU 36H	; 0.2 second lasting buzzer byte
;				BUZ02S_2 EQU 37H	; Not needed
				BUZ1S_1 EQU 38H		; 1 second lasting buzzer byte-1
				BUZ1S_2 EQU 39H		; 1 second lasting buzzer byte-2
				D20MS EQU 3AH		; 20 millisecond delay byte
				D5S_1 EQU 3BH		; 5 second delay byte-1
				D5S_2 EQU 3CH		; 5 second delay byte-2
				TBLNK_1 EQU 3DH		; Target blnking byte-1
;				TBLNK_2 EQU 3EH		; Target blnking byte-2
				D05S EQU 3FH		; 0.5 second time delay byte
				AF1STBLK EQU 4CH	; After 1 second target blink byte
				TMR0RS_1 EQU 4DH	; While calling Timer-0 ISR, the register values at the register R0 through R7 are stored in a 
				TMR0RS_2 EQU 4EH	; RAM memory locations temporarily.  Those mem locations are assigned names to which it is designated.
				TMR0RS_3 EQU 4FH	; i.e. TMR0RS_1 will be used to store the value of accumulator and TMR0RS_2 is used for R1 register
				TMR0RS_4 EQU 50H	; -and so on.
				TMR0RS_5 EQU 51H
				TMR0RS_6 EQU 52H
				TMR0RS_7 EQU 53H
				TMR0RS_8 EQU 54H
				TMR0RS_9 EQU 55H
				TMR1RS_1 EQU 56H	; While calling Timer-1 ISR, the register values at the register R0 through R7 are stored in a 
				TMR1RS_2 EQU 57H	; RAM memory locations temporarily.  Those mem locations are assigned names to which it is designated.
				TMR1RS_3 EQU 58H	; i.e. TMR1RS_1 will be used to store the value of accumulator and TMR1RS_2 is used for R1 register
				TMR1RS_4 EQU 59H	; and so on.
				TMR1RS_5 EQU 5AH
				TMR1RS_6 EQU 5BH	; This setup is made because if it is not used, the ISR that raised in the middle of main program execution
				TMR1RS_7 EQU 5CH	; will change the values in the registers A, R1, R2 ... R7 created by the main program. So on exiting the ISR
				TMR1RS_8 EQU 5DH	; the values in the registers are not true values of main program and changed by ISRs. But this set up will 
				TMR1RS_9 EQU 5EH	; ensure that each programs (main, ISRs) can have their values undistrubed even while sharing same registers
				DDISPLAY EQU 5FH	; Digit Display byte used to store the starting address of series of memory reg(s). [Left nybble(Addrs)|Right nybble(data)]
				GEN_1 EQU 60H		; General purpose register used in the portion of count input validation code
				AF1STBLK_ EQU 61H	; Additional byte to establish 1 second time duration
				;===================For introducing delay while writing RAM=============================
;				RAMDLY_1 EQU 62H	; RAM delay byte-1. To count 500, these 2 bytes are used
;				RAMDLY_2 EQU 63H	; RAM delay byte-2. (500)d = (1F4)h
;==================The important bits & bytes are stored with initial value(s) before the start of the program=================================                				
				SETB BN				; Setting the arithmetic LED bit to "ADD" mode by default
				SETB S1				; Making switches S1 thourgh S3 as input by setting it.
				SETB S2
				SETB S3
				SETB P3.2			; P3.2 = External Interrupt-0. Setting it to make it as input pin
				SETB P3.6			; EXRAM active low write enable control pin is set. DISABLE WRITE ENABLE
				SETB P3.7			; EXRAM active low read enable control pin is also set. DISABLE READ ENABLE
				SETB P3.5			; EXRAM active low Chip select control pin is too set. Disable Chipselect and IC too.
				CLR BA				; Clearing all bit directives to ensure that all calls and related sub-routines are switched OFF at the code
				CLR BB				; startup.
				CLR TB
				CLR NB
				CLR BC
				CLR BD
				CLR BE
				CLR BF
				CLR BG
				CLR BHH
				CLR BI
				CLR BJ
				CLR BK
				CLR BLL
				CLR BM
				CLR BO
				CLR BPP
				MOV DDISPLAY, #40H	; The display value(s) to the BCD-7 segment driver is stored in RAM locations starting from 40H
;===========================================================================================================================================				
;======================================Start of the code: Loading timer values and starting it==============================================				
				MOV TH0, #0F8H		; Timer-0 16 bit register is stored values so as to repeat at each 2.083ms.  (780)H=(1920)d counts will do
				MOV TL0, #80H		; for each roll over.  1920 x 1.085us = 2083us i.e. 2.083ms.  A couple of micro seconds error isn't a big deal
				MOV TH1, #0FCH		; Timer-1 is stored with value of FC66 (FFFF-FC66=399)H.  Which is equal to 921.  So this timer-1 ISR will repeat at 
				MOV TL1, #66H		; each 921 x 1.085us = 999.285us ~ 1ms
				SETB TR0			; starting the Timer-0
				SETB TR1			; starting the Timer-1
				ACALL BUSY			; No external interrupts could processed with out errors if control is Reading and displaying. So INT0 is masked
				LCALL DISPLAY_CHECK	; Long calling display check call
				LCALL EXRAM_READ	; Long calling External RAM value read call
				ACALL DCC			; Display calcuation call that suppress preceeding zeros and fill the registers arrays (40H - 4BH) for digit display values
				LCALL T20MSDELAY	; To avoid data loss at the EX-RAM, it has been again written to the EX-RAM.
				LCALL EXRAM_WRITE	; Just for saftey.
				ACALL FREE
MAINL_1:		JNB S1, FUNCTION	; S1=0 if it is pressed. Then the program control will be switched to Function XYZ computing part of code.
				JNB	S2,	VALUE_SET		; S2, S3 switches are meant to set the target value by the user.  Hence the program control will go to that part of code
				JNB S3, VALUE_SET		; Since all conditional jumps are short, the control is first taken to a code address within the range.
				JNB TB, MAINL_1		; If TB is not set means, no True bit found yet and the control has to revolve here scanning S1, S2, S3 and TB.
				SJMP ADD_FN
FUNCTION:		LJMP FUNCTION_XYZ				
ADD_FN:			ACALL BUSY			; If TB found, a valid count input has been made. Calling busy to mask the External interrupt 0
				CLR TB				; Clearing the true bit and new bit.
				CLR NB
				JNB ArBEN.4, SUBTRT_BRANCH	; If no bit found at D4 to D7 bits in ArBEN byte, it is assumed to do subtraction.  
				JNB ArBEN.6, SUBTRT_BRANCH	; Bits D4 and D7 are checked and if found, the program control will jump to subtraction part of code.
				ACALL ADDITION		; If bits D4 and D7 @ ArBEN are found set, calling addition call
				MOV R4, 32H			; Bytes 32H and 33H contains the target or buzzer value and 34H, 35H contains the running value.
				MOV R5, 33H			; To compare 32H value with 34H and 33H value with 35H value, these are moved to registers R4 thourgh R7
				MOV R6, 34H
				MOV R7, 35H
				MOV A, R4			; Here the running value is checked for whether it reaches the target value after each addtion call.
				CJNE A, 6, MOUT_1	; Comparing 'A' with R6 (i.e 32H <--> 34H)to check does it met the target value? If found not equal, the control will quit.
				MOV A, R5			; Placing next reference value at 'A' register (A=33H)
				CJNE A, 7, MOUT_1	; Comparing 'A' with R7 (i.e 33H <--> 35H). If found not equal, the control will quit.
				CLR C				; If both comparision found equal means the running value reaches the target value. Soclear carry first.
				MOV A, #00H			; Have to blow buzzer and reset the running value. But first clear 'A' register and registers R4 throught R7.
				MOV R4, #00H
				MOV R5, #00H
				MOV R6, #00H
				MOV R7, #00H
				MOV 34H, #00H		; It is addition count. So the starting value in the running display is 00H. 
				MOV 35H, #00H		; Registers 34H, 35H that contains the running value are cleared.
				LJMP ARITH_END		; Jumping to the end of arithmetic process coding to end arithmetic operation.
SUBTRT_BRANCH:	ACALL SUBTRACTION	; If bits D4 and D7 @ ArBEN are found reset, calling subtration call.
				MOV R6, 34H			; Bringing down the running values to R6, R7 registers.
				MOV R7, 35H			; Here we are checking running value whether it reaches '0000H' after each subtraction call.
				MOV A, R6			; Placing value to compare with 00H since it is a subtraction count. So overflow will occur at zero.
				CJNE A, #00H, MOUT_1	; Comparing 'A' with value 00H. If found not equal, the control will quit.
				MOV A, R7			; Moving next value to compare.
				CJNE A, #00H, MOUT_1 
				CLR C				; Assumes that running value over flooded. So have to blow buzzer but first clear the carry.
				MOV A, #00H			; Clearing 'A' register.
				MOV R6, 32H			; Remember, it is subtraction count. So the starting value of running display is target value. So load it.
				MOV R7, 33H			; Further couple of codes moves the value from memory locations 32H, 33H to 34H, 35H respectively.
				MOV 34H, R6
				MOV 35H, R7
				MOV R6, #00H
				MOV R7, #00H
ARITH_END:		ACALL BATCH_COUNT	; This code is common for each (add/sub) processes while running value is saturated. Calling batch count call.
				ACALL DCC			; Calling display calculation call to fill the display register arrays that light the LEDs.
				LCALL T1SBUZZER		; Calling 1 second duration buzzer call.  
				SJMP MTERM_1		; Jumping to EX-RAM write call and end the process.
MOUT_1:			ACALL DCC			; This code is common for each (add/sub) processes. Calling DCC call.
				LCALL T02SBUZZER	; 0.2 second time duration buzzer will be blowed with this call.
MTERM_1:		LCALL EXRAM_WRITE	; Values at the RAM locations 30H through 35H and 20H are written in to the External RAM to save data.
				ACALL FREE			; Calling FREE call will unmask the External interrupt 0. Now the control will listen new interrupts to count.
				SJMP MAINL_1		; Unconditionally jumping back to the scanning of switches S1, S2, S3 and True bit.
				;=================
				; VALUE_SET_S = Selection process; VALUE_SET_I = Incrementing process (S2 = Selection key; S3 = Incrementing key)
VALUE_SET:		ACALL BUSY							; T02SBUZZER
				LCALL T20MSDELAY	; Is t(S2 or S3=0)>= 20ms?
				JNB S2, VALUE_SELECT	; Is S2=0?
				JB S3, VALUE_EXIT_F		; If S3 fails to last 20ms time duration, just jump to main scan loop
				LCALL T02SBUZZER		; If S2 last 20ms, blow 0.2S buzzer to initimate a true input has been detected
				LCALL STRAF5SBLNK		; Start after 5S blink display blink call
VS3:			JNB S3, VS3				; Making sure that S3 has been released
				SJMP VALUE_EXIT_T		; True input for setting value has been found and jump to value setting process
VALUE_SELECT:	LCALL T02SBUZZER		; Check for (S2=0)>=20ms
				LCALL STRAF5SBLNK		; If yes, start after 5S display blink to make user to release S3
VS2:			JNB S2, VS2				; Making sure S2=1
VALUE_EXIT_T:	LJMP VALUE_VALID		; Jumping to process value increment input
VALUE_EXIT_F:	ACALL FREE				; False input has been identified, so the controll made Ext.Int-0 free and exit main scan loop
				LJMP MAINL_1
;==========================================================================================================================================
;=============================Codes for various calls used in Arithmetic processes==========================================================
BUSY:			CLR 0A8H			; This will disable the External interrupt 0 (IE.0) Ref: Page no 108
				SETB BM				; Lighting the BUSY LED (BM=P2.5 where BUSY LED is connected)
				RET					; Returning the call
;==========================================================================================================================================				
FREE:			CLR BM				; Switching OFF BUSY LED
				SETB 0A8H			; This will enable the External interrupt 0 (IE.0)
				RET					; Returning the call
;==========================================================================================================================================				
ADDITION:		MOV R6, 34H			; Bringing the running value from RAM locations to work bench (i.e. registers R6, R7)
				MOV R7, 35H			 
				CLR C				; Clearing carry first
				ACALL ADD_1			; This call will add #1 to R6 (lower 2 digit). If found carry, add one more #1 with R7 (upper 2 digit)
				MOV 34H, R6			; After addition, values are restored back to its RAM memory locations.
				MOV 35H, R7
				MOV R6, #00H		; Clearing R6, R7, A, and carry for next use
				MOV R7, #00H
				MOV A, #00H
				CLR C
				RET					; Returning the addition call
;==========================================================================================================================================
BATCH_COUNT:	JNB ArBEN.0, BATCH_OUT	; ArBEN bits D0 to D3 are reserver to denote batch count option is enabled or disabled			
				JNB ArBEN.3, BATCH_OUT	; If either of these bits are set means perform batch count. If not, just complete the call with out counting.
				MOV R6, 30H			; Bringing batch values to the work bench. Register 30H, 31H contains the lower and upper 2 digits of batch count value.
				MOV R7, 31H			
				CLR C				; Clearing carry
				ACALL ADD_1			; Benefit of this call is, it'll just add #1 to R6, R7 registers 
				MOV 30H, R6			; and treat as single 4 digit number is stored in these 2 regs. Here the values are moved back to its RAM locations
				MOV 31H, R7
				CLR C				; Clearing Carry, A, R6 and R7 for next use
				MOV R6, #00H
				MOV R7, #00H
				MOV A, #00H
BATCH_OUT:		RET					; Returning the Batch count call
;==========================================================================================================================================
SUBTRACTION:	MOV R6, 34H			; Bringing the running value to work bench to perform subtraction
				MOV R7, 35H			; Now R6 has Lower 2 digits (tens:ones)
				CLR C				; Clearing carry to avoid confusion
				MOV A, R6			
				ADD A, #0FFH		; Adding #0FFH means subtracting #1 from it
				JNC SUB_L1			; If carry not found it is not normal. It'll happen when A=#00H. After adding #FFH will yield false result.
				ACALL SDAA			; Assumes carry found. This call will decimal adjust the Accumulator 
				MOV R6, A			; The decimal adjusted value is in R6 (contains no Hex value in it)
				SJMP SUB_L2			; Unconditionally jump to said location to conclude the subtraction call.
SUB_L1:			ACALL SDAA			; @ C=0, first adjust the accumulator value to contain no Hex value (i.e. #FFH will be changed to #99H)
				MOV R6, A			; Moving the hex free 'A' value to R6
				MOV A, R7			; To process upper 2 digit (thousands:hundreds) load it in to accumulator
				ADD A, #0FFH		; Since C=0, lower 2 digits is rolling over from 00 to 99. So subtract #1 from upper 2 digits
				ACALL SDAA			; Again decimal adjusting the accumulator
				MOV R7, A			; Now R7 has Hex free upper 2 digits
SUB_L2:			MOV 34H, R6			; After the successfull subtraction, the upper and lower digits are stored back from where these are taken
				MOV 35H, R7			
				CLR C				; Clearing Carry, A, R0, R1, R6, R7 for next use
				MOV A, #00H
				MOV R0, #00H
				MOV R1, #00H
				MOV R6, #00H
				MOV R7, #00H
				RET					; Returning the subtraction interrupt
;==========================================================================================================================================				
DCC:			MOV R0, 30H			; DCC - Display calculation call. The Batch count value, Buzzer/Target value and Runnig value are in 
				MOV R2, 31H			; the register locations 30H to 35H as BCD form. This is not suitable to show in the 7-segment LED display
				JNB BPP, DCC_L1		; This particular call will fetch those values and add their display digit addresses with them. The  
				CLR BPP				; address added byte will have address on its left nybble and data on its right nybble. So the 6 byte data
				ACALL CALC_CALL		; becomes 12 byte content when it is ready to feed to the LEDs. This operation is achieved in this call. And the
				SETB BPP			; call CALC_CALL will etch the preceeding zeros. i.e. if you want to show no: 40 in a four digit display,
				SJMP DCC_L2			; | | |4|0| will be good to human to read and should not be look like |0|0|4|0|. So the preceeding zeros are identified
DCC_L1:			ACALL CALC_CALL		; and filled with value 'F'. By selecing the appropriate 7 segment LED driver, you can switch off the 
DCC_L2:			ORL 00H, #10H		; output when the input comes in Hex range.  And also this etching option can be switched OFF/ON by setting/resetting 
				ORL 01H, #20H		; the bit BPP. So the process of etching is achieved at CALC_CALL.  But while settings target value, the user 
				ORL 02H, #30H		; should be shown zeros in all 4 digits. So the Batch count value and running value display codes are made so as
				ORL 03H, #40H		; to etch preceeding zeros at any conditions unlike targe value display. Hence, even if etching is disabled, 
				MOV 40H, R0			; still Batch & Running values are etched if found any preceeding zeros. The target display only 
				MOV 41H, R1			; shows the un etched zeros when preceeding zero etching is switched OFF.
				MOV 42H, R2			
				MOV 43H, R3
				;====================
				MOV R0, 32H			; Taking the target value to work bench. Memory addresses 32H, 33H contains target values. So here we simply call 
				MOV R2, 33H			; CALC_CALL with out clearing bit BPP if it is enabled. Clearing BPP bit and calling CALC_CALL and again 
				ACALL CALC_CALL		; setting BPP done in both Batch count value and Running value display calls. Please refer above and below this.
				ORL 00H, #50H		; 
				ORL 01H, #60H		; After calling this call, the decimal weights one, ten, hundred & thousand are in the right side nybble of the 
				ORL 02H, #70H		; register R0, R1, R2, R3 repectively with left side nybble cleared. Here the empty left side nybbles are 
				ORL 03H, #80H		; filled with their display digit addresses.
				MOV 44H, R0			; The completed registers are further moved to its RAM location of display arrays where the control will come and 
				MOV 45H, R1			; fetch to feed display LEDs.
				MOV 46H, R2
				MOV 47H, R3
				;=====================
				MOV R0, 34H
				MOV R2, 35H
				JNB BPP, DCC_L3
				CLR BPP
				ACALL CALC_CALL
				SETB BPP
				SJMP DCC_L4
DCC_L3:			ACALL CALC_CALL
DCC_L4:			ORL 00H, #90H
				ORL 01H, #0A0H
				ORL 02H, #0B0H
				ORL 03H, #0C0H
				MOV 48H, R0
				MOV 49H, R1
				MOV 4AH, R2
				MOV 4BH, R3
				ACALL LED_DISPLAY
				RET
;=================================================================================================================================				
ADD_1:			MOV A, R6			; Now accumulator has the lower 2 digits. (Note: These values are BCD and contains no Hex value)
				ADD A, #01H			; Adding #1 with it.
				DA A				; Decimal adjusting it to make sure that there is no hex value exist.
				MOV R6, A			; Moving the value back to the register R6.
				JNC ADD_END			; Check whether carry exists. If not found, just complete the call.
				MOV A, R7			; If found, have add one more #1 with upper 2 digits. So bring that value to 'A'.
				ADD A, #01H			; Adding it.
				DA A				; Decimal adjust it to ensure BCD.
				CLR C				; Clear carry unconditinally.
				MOV R7, A			; Moving that value back to its register.
ADD_END:		RET					; Completing the call.
;===========================================================================================================================================
SDAA:			CLR C				; Subtraction Decimal Adjust the Accumulator call that works with the value in accumulator. First clears the carry
				MOV R0, A			; Copying to R0 (Remember, Acc. will have 'tens/thousands' in left side nybble and 'ones/hundreds' in right side nybble).
				SWAP A				; Interchanging the nybbles in Acc.
				ANL A, #0FH			; Etching the left side nybble.  So the right side of Acc. nybble has the 'tens/thousands'
				MOV R1, A			; Copying it to R1
				MOV A, R0			; Bring R0 value to Acc. for Etching!
				ANL A, #0FH			; Etching left side nybble. So right side nybbles has the 'ones/hundreds'
				MOV R0, A			; Copying to R0.  (R0 has lower nybble or 'ones/hundreds' and R1 has upper nybble or 'tens/thousands').
				CJNE R0, #0AH, SDA_L1	; Whether R0 >= #10? By checking carry we can find it out. So, just proceed with carry checking.
SDA_L1:			JC SDA_R0			; If C=0 then R0 could be equal to 10('A' in hex) or greater than 10 (reg page no. 129, 132 @ mazidi).
				MOV A, R0			; If C=0 then bring the value to work register i.e. Acc. We need these value to be in the range '0-9'
				ADD A, #0FAH		; While rolling back, after '0', '9' has to come and not 'F'. If any, subtract 6 from it. (i.e. '-6' is equal to FA in hex). 
				ANL A, #0FH			; Etching the left side nybble.
				CLR C				; Clearing the carry to aviod confusion.
				MOV R0, A			; Saving back to R0
SDA_R0:			CJNE R1, #0AH, SDA_L2	; Whether R0 >= '10'? if or not, just proceed with carry checking.
SDA_L2:			JC SDA_R1			; If C=0 then R1 could be equal to 10 or greater than 10 
				MOV A, R1			; If no carry then bring the value to work register i.e. Acc.
				ADD A, #0FAH		; Subtract 6 from it
				ANL A, #0FH			; Etching
				CLR C				; Clearing carry
				MOV R1, A			; Saving back to R1
SDA_R1:			MOV A, R1			; Bring back to Acc. to combine the lower and upper nybble in to one register
				SWAP A				; Interchanging the nybbles. Now Acc. right side nybble has 'tens'
				ORL A, R0			; R0 right side nybble has 'ones' that is copied to Acc.  So Acc. has 'tens' in upper nybble and 'ones' in lower
				RET					; Return of SDAA call.  The final value is still in the accumulator but adjusted to BCD.
;======================================================================================================================				
CALC_CALL:		MOV 1, 0			; While calling this call R0 has tens and ones in their left and right nybbles respectively.
				MOV 3, 2			; Similarly R2 has thousands and hundreds in their left and right nybbles. Further couple of codes
				MOV A, R1			; will make R0=ten:one; R1=one:ten; R2=thous:hund; R3=hund:thous. And then left nybbles in all bytes are
				SWAP A				; cleared. e.g. R0=zero:one; R1=zero:ten; R2=zero:hunds; R3=zero:thous. If BPP bit is cleared then the preceeding
				MOV R1, A			; zeros are etched form the order thous --> one. If BPP is set, the call will not perfom preceeding zero etch.
				MOV A, R3
				SWAP A
				MOV R3, A
				ANL 00H, #0FH		; Clearing left side nybbles in all registers R0 thourgh R3
				ANL 01H, #0FH
				ANL 02H, #0FH
				ANL 03H, #0FH
				JB BPP, CALC_L1		; Checking the BPP bit to perform preceeding zero etching. If it is not set, the etching will be performed
				CLR C
				CJNE R3, #00H, CALC_L1	; Performing etching if the bit is not set
				ORL 03H, #0FH
				CJNE R2, #00H, CALC_L1
				ORL 02H, #0FH
				CJNE R1, #00H, CALC_L1
				ORL 01H, #0FH
CALC_L1:		CLR C
				RET					; Returning the call
;======================================================================================================================
LED_DISPLAY:	JNB ArBEN.0, NO_BTCH
				SETB P2.4 			; P2.4 - Batch count Enable/Disable indication LED
				SJMP ARITH_BTCH
NO_BTCH:		CLR P2.4
ARITH_BTCH:		JNB ArBEN.4, SUB_EN
				SETB BN				; P2.3 - Arithmetic LED indication
				SJMP BTCH_END
SUB_EN:			CLR BN
BTCH_END:		RET
;=======================================================================================================================
DISPLAY_CHECK:	MOV R1, #30H		; Here, data arrays 30H to 35H are filled with value 88H. Becasue this value will light
DISPLAY_L1:		MOV @R1, #88H		; all 7 segment LEDs when it is shown. So the user can examine the light defects in LEDs
				INC R1				; if any while glowing. And also arithmetic indicating LEDs like Addition, Subtraction are also
				CJNE R1, #36H, DISPLAY_L1	; made to glow. Each LEDs will glow up to 1 second time period along with buzzer sound.
				MOV R1, #00H		; The Batch count enable LED is also made to glow 2 second time period with buzzer. So
				MOV ArBEN, #0FH		; the user can examine 7-segment LEDs, Arithmetic LED, Batch LED and buzzer for defections
				ACALL DCC			; and faults. Before calling DCC, 30H to 35H RAM addresses is stored value 88H and ArBEN=0FH.
				ACALL T1SBUZZER		; Calling 1 second time duration buzzer to check the buzzer connection also.
DISPLAY_L2:		JB BC, DISPLAY_L2	; Waiting to complete the 1 second buzzer call
				MOV ArBEN, #0FFH	; Before this call ArBEN was 0FH. i.e. Arith=sub; Batch=Enable, now its FFH i.e. Arith=Add; Batch=EN
				ACALL LED_DISPLAY	; Just rewrite the LEDs only according to the revised ArBEN data value.
				ACALL T1SBUZZER		; Again calling 1 second buzzer call to constitute another 1 second buzzer blow
DISPLAY_L3:		JB BC, DISPLAY_L3	
				RET
;=============================================================================================================================================				
EXRAM_READ:		MOV R1, #30H		; Storing starting address in the regiser R1
				MOV P1, #0FFH		; Making port-1 as input
				SETB P3.6			; Initially the Write enable is disabled
				SETB P3.7			; and Read enable is also disabled
				SETB P3.5			; The chip is disabled by deactivating CE (Chip enable) pin
				;================	
				ACALL RAM_ADDR001
				ACALL EXRAM_RSUB	; This call will fetch the data from the port P1 which is connected to EX-RAM and move it to RAM address
				ACALL RAM_ADDR010	; -stored in the register R1. At present R1 = 30H. i.e. the date @ 001 RAM address is now in 30H
				ACALL EXRAM_RSUB	; Now R1 is incremented. So R1=31H and now data @ExRAM.addr.(010)=@31H
				ACALL RAM_ADDR011
				ACALL EXRAM_RSUB	; Now R1=32H; data @ExRAM.addr(011)=@32H
				ACALL RAM_ADDR100
				ACALL EXRAM_RSUB	; R1=33H; data @ExRAM.addr(100)=@33H
				ACALL RAM_ADDR101
				ACALL EXRAM_RSUB	; R1=34H; data @ExRAM.addr(101)=@34H
				ACALL RAM_ADDR110
				ACALL EXRAM_RSUB	; R1=35H; data @ExRAM.addr(110)=@35H
				ACALL RAM_ADDR111
				MOV R1, #20H		; Note: Now R1 = 20H i.e. the ArBEN byte
				ACALL EXRAM_RSUB	; R1=20H; data @ExRAM.addr(111)=@20H
				MOV R1, #00H 		; Clearing R1
				RET
;=================================================================================================================================================
EXRAM_WRITE:	MOV R1, #30H		; Storing starting address in the regiser R1
				SETB P3.6			; Initially the Write enable is disabled
				SETB P3.7			; and Read enable is also disabled
				SETB P3.5			; The chip is disabled by deactivating CE (Chip enable) pin
				;================
				ACALL RAM_ADDR001	; Address lines are given address value 001
				ACALL EXRAM_WSUB	; Now R1=30H, so the value in 30H is moved to the Ex-RAM address 001 location through port-1 and R1 is incremented
				ACALL RAM_ADDR010	; Now the address line for Ex-RAM is 010
				ACALL EXRAM_WSUB	; Now R1=31H. Data @31H is moved to 010@Ex-RAM. R1 incremented
				ACALL RAM_ADDR011	; Ex-RAM address = 011
				ACALL EXRAM_WSUB	; R1=32H. Data @32H - moved - 011@Ex-RAM. R1 incremented
				ACALL RAM_ADDR100	; Ex-RAM address = 100
				ACALL EXRAM_WSUB	; R1=33H. Data @33H - moved - 100@Ex-RAM. R1 incremented
				ACALL RAM_ADDR101	; Ex-RAM address = 101
				ACALL EXRAM_WSUB	; R1=34H. Data @34H - moved - 101@Ex-RAM. R1 incremented
				ACALL RAM_ADDR110	; Ex-RAM address = 110
				ACALL EXRAM_WSUB	; R1=35H. Data @35H - moved - 110@Ex-RAM. R1 incremented
				ACALL RAM_ADDR111	; Ex-RAM address = 111
				MOV R1, #20H		; R1 = 20, ArBEN byte address
				ACALL EXRAM_WSUB	; R1=20H. Data @20H - moved - 111@Ex-RAM. R1 incremented
				MOV R1, #00H 		; R1 Cleared
				RET
;=================================================================================================================================================
RAM_ADDR001:	SETB P3.0			; Placing the address on the address lines 
				CLR P3.1			; P3.4	 |	P3.1	|	P3.0	Port pin numbers...
				CLR P3.4			; A2 (0) |	A1 (0)	|	A0 (1)	Address lines with its value i.e. RAM Address = 001
				RET
RAM_ADDR010:	CLR P3.0			; Now the second address is 010			
				SETB P3.1			
				RET
RAM_ADDR011:	SETB P3.0			; Third address 011			
				RET
RAM_ADDR100:	CLR P3.1			; Fourth address 100
				CLR P3.0
				SETB P3.4			
				RET
RAM_ADDR101:	SETB P3.0			; Fifth address = 101			
				RET
RAM_ADDR110:	CLR P3.0			; Sixth address = 110
				SETB P3.1			
				RET
RAM_ADDR111:	SETB P3.0			; Seventh address = 111			
				RET
;=================================================================================================================================================				
EXRAM_RSUB:		MOV P1, #0FFH		; Making the Port-1 as input port
				CLR P3.7			; Enabling Read Enable control line
				CLR P3.5			; Enabling the chip (CE active low)
				;======= A short delay call =========
;				MOV RAMDLY_1, #0FFH
;RAMDLY1:		DJNZ RAMDLY_1, RAMDLY1
				;====================================
				MOV @R1, P1			; Move the data at port-1 to the location stored at R1 for time being
				INC R1				; Increment the R1
				SETB P3.7			; Disabling the Read Enable control 
				SETB P3.5			; Disabling the chip
				RET					; Returning the call
;=================================================================================================================================================
EXRAM_WSUB:		MOV P1, @R1			; The data of the addresse location stored in R1 is moved to port-1
				CLR P3.5			; Enabling the chip (CE active low)
				CLR P3.6			; Enabling Write Enable control line
;				MOV P1, #00H		; The registers of EX-RAM has been written '00'(this is to avoid wrong value, i guess)
				;======= A short delay call =========
;				MOV RAMDLY_1, #0FFH
;RAMDLY2:		DJNZ RAMDLY_1, RAMDLY2
				;====================================
				;======= A short delay call =========
;				MOV RAMDLY_1, #0FFH
;RAMDLY3:		DJNZ RAMDLY_1, RAMDLY3
				;====================================
				INC R1				; Incrementing R1
				SETB P3.6			; Disabling the Write enable control
				SETB P3.5			; Disabling the chip
				RET					; Returning the call
;=================================================================================================================================================				
T1SBUZZER:		SETB BC				; Sets the two bits BC, BD. BC is the 1s buzzer flag bit that sets both the internal/external buzzers.
				SETB BD				; Bit BD directly sets the external buzzer pin. This call will start the buzzer automatically.
				MOV BUZ1S_1, #0F4H	; Buzzer timer code is in Timer 0 ISR which runs at every 2 milisecond(approx). Buzzer code has 2 bytes in it. 
				MOV BUZ1S_2, #02H	; So (500)d = (1F4)H will constitute 1000ms = 1 second time period. After completion of counting,
				RET					; -the buzzer is stopped. [To achive count 01F4H, we have to store 02F4H. Ref. Timer 1 ISR]
;=================================================================================================================================================				
T02SBUZZER:		SETB BB				; Bit BB is 0.2 second buzzer flag and also it blows the internal buzzer for that time period.
				MOV BUZ02S_1, #15	; Since 200ms is felt long the buzzer 0.2 second byte is made to count 15 (i.e. 15 X 2 = 30ms)
				RET					
;=================================================================================================================================================								
;=============================================================FUNCTION XYZ CODE PART==============================================================
FUNCTION_XYZ:	LCALL BUSY			; FUNCTION Z, clears all data. i.e. Batch count, Buzzer value & Running value(s) are cleared once & for all.				
				ACALL T20MSDELAY	; The Arithmetic mode is set to 'Add' and Batch count mode is set to ON. T20MSDELAY is a 20 milisecond delay
				JB S1, EXIT_Z		; -that hold the contol up to 20ms time period in its call. Hence at exiting this call, S1 must be '0'. 
				ACALL S1REPEAT		; Otherwise it is a false one and program will exit to EXIT_Z. If S1=0?, S1 repeat code is called to confirm 
Z_LOOP1:		JNB BF, EXIT_Z_ERR	; -each press of S1.  This 'BF' bit is reset by 5S time delay call. The control will exit if there is no 
				JNB S3, FUNCTION_Y	; -interrupt found within this 5S time period. If S3 is pressed, i.e. S3=0. control skip to process FUNCTION Y
				JNB S2, FUNCTION_X	; If S2=0, control will skip to FUNCTION X (FUNCTION Y = Set Up/Down count; FUNCTION X = Batch count En/Dis)
				JB S1, Z_LOOP1		; If S1=1, i.e. repeat loop to check for another interrupt from S/Ws or for delay flag reset.
				ACALL T20MSDELAY	; If S1=0, confirming it lasts more than 20ms time delay with this call. (This call holds the control for 20ms)
				JB S1, Z_LOOP1		; Checking S1 for '0'. If S1=0, means the interrupt was false and made by some electrical spikes
				ACALL S1REPEAT		; Means S1=0 and calling to confirm the second interrupt was by same S1.
Z_LOOP2:		JNB BF, EXIT_Z_ERR	; Three press of S1 clears all data and set Add/Batch-EN mode.  Already 2 presses made, so the last one should
				JNB S2, EXIT_Z_ERR	; -be S1 and other switch presses and delay flag reset will be assumed as false try or time out, so the 
				JNB S3, EXIT_Z_ERR	; -control will exit if found any. Hence keep rolling the control here until S1 is pressed and until time out flag 
				JB S1, Z_LOOP2		; -is reset. 
				ACALL T20MSDELAY	; Now S1 is pressed again, so make sure it lasts more than 20ms so as to assume that it is made by human.
				JB S1, Z_LOOP2		; If it doesn't last 20ms, it is a false interrupt and switch back to its immediate loop.
				ACALL S1REPEAT		; Confirming the second press.
				MOV R1, #30H		; Moving initial address value to R1 where all data are used to store (30H to 35H & 20H are to be cleared)
Z_CLR:			MOV @R1, #00H		; Clearing RAM location stored @ R1 and increments R1 and again clearing it until R1 reaches 36H
				INC R1
				CJNE R1, #36H, Z_CLR	; If R1=36H, control will exit this loop to alter 20H (ArBEN)
				MOV R1, #00H		; Clears R1 for next use.
				MOV 20H, #0FFH		; ArBEN is stored value of FF. i.e. Arithmetic mode = Addition; Batch count mode = Enable
EXIT_NOR:		ACALL EXRAM_WRITE	; The new data are immediately written to External RAM to protect from data loss due to power loss.
				LCALL DCC			; Take data, process it and filling the display array ready to glow the 7 Segment LEDs.
				ACALL T02SBUZZER	; Blow 0.2 second time buzzer to signal user that the task has completed. It is propably interanl buzzer
T02SBZ_RPT:		JB BB, T02SBZ_RPT	; Wait until 0.2 second buzzer blowing is OFF				
				SJMP EXIT_Z			
EXIT_Z_ERR:		ACALL T1SBUZZER		; Error exit that blow 1 second buzzer to warn user that the task exits due to false interrupt
T1SBUZ_RPT:		JB BC, T1SBUZ_RPT	; Wait until 1 second buzzer blowing is OFF				
EXIT_Z:			ACALL STP5SDELAY	; Stoping the 5 second time delay call which clears the bit/flag 'BF'.
				LCALL FREE			; Un mask the External interrupt-0 to accept further count input.
				LJMP MAINL_1		; Jumping back to main loop
;==================================================================================================================================================				
FUNCTION_X:		ACALL T20MSDELAY	; FUNCTION X enable/disable the batch count mode. Confirming S2=0 lasts upto 20ms time period.
				JB S2, Z_LOOP1		; If S2=1, it is a false interrupt & jump back to its immediate primary loop
				ACALL S2REPEAT		; Confirming the relese of S2 switch press.
X_LOOP1:		JNB BF, EXIT_Z_ERR	; Loop waiting to another press of S2.  If other switches pressed or time up (5S time period) the control
				JNB S1, EXIT_Z_ERR	; has to exit with a error warning.
				JNB S3, EXIT_Z_ERR
				JB S2, X_LOOP1		; Loop here until S2 is pressed or 5S time up flag is reset.
				ACALL T20MSDELAY	; If S2 is pressed (i.e. S2=0), check its lasting period meets 20ms
				JB S2, X_LOOP1		; Still if S2=0, the interrupt is a good one. Otherwise jump back to its immediate primary loop.
				ACALL S2REPEAT		; S2=0. Cofirm its been released.
				ACALL STP5SDELAY	; Stoping the time up 5S time delay call.
				MOV A, #00H			; Clearing the accumulator [FUNCTION X will simply complement the batch nybble in the ArBEN byte]
				MOV R0, #00H		; Clearing the register R0
				MOV A, 20H			; Move the data of ArBEN byte
				CPL A				; Complementing the accumulator
				ANL A, #0FH			; Etching the left side nybble (Arithmetic)
				MOV R0, A			; Storing that in the R0
				MOV A, 20H			; Again move the ArBEN data to A
				ANL A, #0F0H		; Etching the right side nybble (Batch)
				ORL A, R0			; OR-ing A with R0. i.e. OR-ing complemented right(Batch) nybble(@R0) with uncomplemented left(Arith) nybble(@A)
				MOV 20H, A			; Now A has complemented Batch value and uncomplemented Arithmetic value in its byte.
				MOV A, #00H			; Clearing A & R0 for the next use
				MOV R0, #00H
				SJMP EXIT_NOR		; Exiting normally		
;==================================================================================================================================================				
Z_LOOP_J:		LJMP Z_LOOP1
FUNCTION_Y:		ACALL T20MSDELAY	; FUNCTION Y enable/disable the Arithmetic mode. Confirming S3=0 lasts upto 20ms time period.
				JB S3, Z_LOOP_J		; If S3=1, it is a false interrupt & jump back to its immediate primary loop.
				ACALL S3REPEAT		; i.e. S3=0, so making sure that S3 is released for the next press
Y_LOOP1:		JNB BF, EXIT_Z_ERR	; Here S1 is pressed and S3 is pressed. So further interrupt should be S3 and others are false. So wait here
				JNB S1, EXIT_Z_ERR	; until S3 is pressed and 5S time up flag is reset.
				JNB S2, EXIT_Z_ERR
				JB S3, Y_LOOP1		
				LCALL T20MSDELAY	; Means S3 is pressed and checking its time duration exeeds 20ms time period
				JB S3, Y_LOOP1		; If it fails to make 20ms time delay send it back to loop
				ACALL S3REPEAT		; If it last more than 20ms, make sure the S3 switch is released
				ACALL STP5SDELAY	; If S3=1, stoping the 5S time delay call
				MOV A, 20H			; FUNCTION Y will simply complement the Arithmetic nybble in the ArBEN byte
				MOV R0, #00H		; Clearing R0 and moving ArBEN data to A
				CPL A				; Complementing the A
				ANL A, #0F0H		; Etching rith side nybble(Batch)
				MOV R0, A			; Storing it to R0 temporarily
				MOV A, 20H			; Againg taking ArBEN data to A
				ANL A, #0FH			; Now etch the left side nybble(Arithmetic)
				ORL A, R0			; Now combine the left(complemented) and right(uncomplemented) side nybble
				MOV 20H, A			; Storing it back to ArBEN byte
				MOV A, #00H			; Clearing A & R0
				MOV R0, #00H
;				JNB NB, EXIT_NOR1	; Checks the True bit. If TB=0, exits normally. If found, have to load null value to running 
				JB ArBEN.5, AR_ADD	; -count for Arithmetic mode and load target value to running count for Subtraction mode. 
				MOV 34H, 32H		; Hence, check the ArBEN byte. Loading target value to running count since it is SUB mode (ArBEN.5=0)
				MOV 35H, 33H
				LJMP EXIT_NOR		; Exit normally
AR_ADD:			MOV 34H, #00H		; Loading null value to the running count since it is ADD mode (ArBEN.5=1)
				MOV 35H, #00H
EXIT_NOR1:		LJMP EXIT_NOR		; Exit normally
;==================================================================================================================================================
;==============================================VARIOUS CALLS USED IN FUNCTION XYZ CODE PART=======================================================
S1REPEAT:		ACALL STP5SDELAY	; Stoping the 5S time delay call since it is confirmed that the interrupt was made by human. Now, it has to
				ACALL STRAF5SBLNK	; -confirm the release of existing press of interrupt so as to identify the next press. Here calling AFTER
				ACALL T02SBUZZER	; A gentle sound warning says that the switch is pressed
S1RPT:			JNB S1, S1RPT		; -5S BLINK call. This bliks the total display if it is not stoped within 5S. Just checking S1 for '1'
				ACALL STPAF5SBLNK	; If S1=1, stops the AFTER 5S BLINK call.
				ACALL STR5SDELAY	; Start the time out call. Because, if user didn't do anything to complete the process even after made 
				RET					; -useful interrupts, the control shouldn't waste time in waiting for long time and must exit.
;==================================================================================================================================================
S2REPEAT:		ACALL STP5SDELAY	; Stop the 5S time up call
				ACALL STRAF5SBLNK	; This call will blink the whole display after 5S time period if it is not stopped
				ACALL T02SBUZZER	; A gentle sound warning says that the switch is pressed
S2RPT:			JNB S2, S2RPT		; Checking S2 for released. Wait here until it is released (i.e. S2=1)
				ACALL STPAF5SBLNK	; Means S2 is released (S2=1) and stop the After 5S display blink call
				ACALL STR5SDELAY	; Again start the 5S time up call 
				RET
;==================================================================================================================================================				
S3REPEAT:		ACALL STP5SDELAY	; Similar to S1REPEAT and S2REPEAT calls.
				ACALL STRAF5SBLNK
				ACALL T02SBUZZER	; A gentle sound warning warns the switch is pressed
S3RPT:			JNB S3, S3RPT
				ACALL STPAF5SBLNK
				ACALL STR5SDELAY
				RET
;==================================================================================================================================================				
T20MSDELAY:		MOV D20MS, #0AH		; (0A)h = (10)d. Because 10x2=20ms. Loading 20ms byte
				SETB BE				; Setting 20ms flag bit
D20MSL:			JB BE, D20MSL		; Stay here until the bit BE has been reset by its sub routine run at timer 1 ISR
				RET					; Return when found bit BE=0
;==================================================================================================================================================				
STR5SDELAY:		MOV D5S_1, #0C4H		; Load 5 second delay bytes with 9C4H [To achive count 9C4H, we have to store AC4H. Ref. Timer 1 ISR]
				MOV D5S_2, #0AH		; (9C4)h = (2500)d X 2 = 5000 [since this call will be counted on timer-0 (~2ms) we have mux by 2]
				SETB BF				; Simply setting the 5 second delay flag bit to start its 5S delay sub routine at timer 1 ISR
				RET					; Just leave the call without waiting
;==================================================================================================================================================
STP5SDELAY: 	CLR BF				; Clearing bit BF will stop the 5S delay sub routine
				MOV D5S_1, #01H		; Load null value to the bytes [To store/achive null we have to store 0101H. Ref. Timer 1 ISR]
				MOV D5S_2, #01H				
				RET					; Returing. No waiting
;==================================================================================================================================================
STRAF5SBLNK:	CLR BF				; Stop the 5S delay sub routine
				CLR BHH				; 5S toggle bit also stopped
				CLR BJ				; 0.5S delay sub routine toggle flag also disabled
				ACALL STR5SDELAY
				SETB BK				; After 5S display blink call sub routine is enabled
				SETB BI				; 0.5S delay sub routine flag is set
				RET
;==================================================================================================================================================
STPAF5SBLNK:	CLR BF				; Stop the 5S delay sub routine
				CLR BI				; 0.5S delay sub routine flag is reset
				CLR BK				; After 5S display blink call sub routine is enabled
				MOV D5S_1, #01H		; Clearing the bytes
				MOV D5S_2, #01H		; [To store/achive null we have to store 0101H. Ref. Timer 1 ISR]
				LCALL DCC
				RET
;==================================================================================================================================================				
;========================================================CALL TO SET THE TARGET VALUE=============================================================
VALUE_VALID:	ACALL STPAF5SBLNK	; Valid interrupt found from S1 or S2. So stop the after 5 second blink call
				MOV TBLNK_1, #01H	; TBLNK_1 byte data address is 3D. Chose the first digit to blink by loading value #1 to the TBLNK_1 byte 
				LCALL STR_TBLNK		; Now start the Target blink call. So the selected target digit will start to blink
				ACALL STR5SDELAY	; Also start general purpose 5 second delay call to enable time out escape.
VALUE_LP:		JNB BF, VALUE_BF	; Checking 5 second flag to exit loop if time limit has exeeded.
				JNB S1, VALUE_S1	; S1 switch pressed means, the process of value setting should stop and exit to main scan				
				JNB S3, VALUE_S3	; S3 switch is to increment the target value at selected digit.
				JB S2, VALUE_LP		; If neither of switches are presessed or time out flag has not been reset, again scan from the begining.
				ACALL T20MSDELAY	; If S2=0, check for it lasts 20ms time period [S2 meant to select the digits of target display to increment it]
				JB S2, VALUE_LP		; If it fails to last 20ms, just again jump to scan switches and time out flag bit				
				LCALL T02SBUZZER	; If t(S2=0)>=20ms, blow 0.2s buzzer to intimate that a valid input has been received
				ACALL STP5SDELAY	; Stoping the 5 second delay bit
				INC 3DH				; Incrementing the target blink byte thus selecting the next left digit which is below 5
				LCALL STR_TBLNK		; Make the selected target digit blink so that the user can view which digit is selected for increment now
				ACALL STRAF5SBLNK	; Making sure the press of switch S2 has been released.
VSLS2:			JNB S2, VSLS2		; If the user holds the S2 switch more than 5 second the whole display will start to blink to warn user
				ACALL STPAF5SBLNK	; After the switch S2 has been released, stop the after 5S blink call
				LCALL STR_TBLNK		; Because the previous instruction will stop all blink related calls. So this will make sure the blinking.
				MOV R1, #3DH		; Since CJNE does not works with labels we are checking TBLNK_1 through R1
				CJNE @R1, #05H, V_JMP1	; Check the target digit selector bit value for #5. If it meets, the call should complete the process
				SJMP V_JMP_A		; The call is exiting since it is equals to 5
V_JMP1:			ACALL STR5SDELAY	; If not equals to 5, again start the 5S delay call and jump back to scan another input
				SJMP VALUE_LP		; Jumping back
				;=================
V_JMP_A:		ACALL STP5SDELAY	; It is a proper exit way that each process of scanning calls should go through to get out. Stop 5S delay call
				ACALL STP_TBLNK		; Stoping the Target blink call.
				JNB NB, V_JMP2		; Checking the new bit. If NB=0 just jump out otherwise clear the batch value and load running value w.r.t ArBEN
				MOV 30H, #00H		; Clearing the Batch count display values
				MOV 31H, #00H		
				JNB ArBEN.5, V_JMP4	; Checking Arithmetic mode
				MOV 34H, #00H		; If Arith mode is 'add' clear the running value to start from null
				MOV 35H, #00H		
				SJMP V_JMP3			; Jumping to the end of the exit process
V_JMP4:			MOV 34H, 32H		; If Arith mode is 'sub' load the target value to running register to start from the top value and de-count it
				MOV 35H, 33H				
V_JMP3:			LCALL EXRAM_WRITE	; Saving the newly changed value to the external RAM
				LCALL DCC			; Filling the display array		
V_JMP2:			LCALL FREE			; Calling free call
				LJMP MAINL_1		
				;==============
VALUE_BF:		LCALL T1SBUZZER		; 1 second long buzzer to warn the user that the process is completed and exits due to time up
VBF:			JB BC, VBF			; Wait until 1S buzzer bit BC has been reset
				SJMP V_JMP_A		; Jumping to formal value setting exit call/process/code
				;==============
VALUE_S1:		ACALL T20MSDELAY	; In value setting process, S1 is inapropriate. So the control assumes that the user wants the call to force exit
				JB S1, VALUE_LP		; So checking the t(S1=0)>=20ms. If it is not, it is a false one and jump back to previous scan loop
				LCALL T02SBUZZER	; If it is, blow the 20ms buzzer as a gentle idication of a valid interrupt identification
				ACALL STP5SDELAY	; Stoping 5S delay call since it has no further use after S1 interrupt is processed
				ACALL STP_TBLNK		; Stoping the target blink call since value setting process is done
				ACALL STRAF5SBLNK	; Confirming the user releases the press of S1
V_JMP5:			JNB S1, V_JMP5		
				ACALL STPAF5SBLNK	; Stoping after 5S blink call once S1 is released
				SJMP V_JMP_A		; Jumping to exit 
				;================
VALUE_S3:		ACALL T20MSDELAY	; Checking t(S3=0)>=20ms [S3 is meant to increment the selected digit of target display]
				JB S3, VALUE_LP		; If not, considering this as false interrupt and jump back to its parent loop
				LCALL T02SBUZZER	; It it is, blow 0.2S buzzer to say that a valid interrupt has been indentified
				ACALL STP5SDELAY	; Stoping 5S delay call
				ACALL STP_TBLNK		; Stops the blinking of selected digit at target display and enable preceeding zero etching to all displays
				ACALL TAR_INC		; Calling Target increment call. This will increment the selected digit value @ target display
				SETB BPP			; This will disable zero etching on the target display which will be useful while setting the target value
				LCALL DCC			; Filling the ready to display array
				ACALL STRAF5SBLNK	; Starting after 5S display blink call to confirm the release of pressed S3
V_JMP6:			JNB S3, V_JMP6		; Stay here until S3=1
				ACALL STPAF5SBLNK	; Stops the call at S3=1
				ACALL STR5SDELAY	; Again starts the 5S delay call that enable time out exit of next scan loop
				ACALL STRAF1S_TBLNK	; Starts After 1S target blink call, enables users to view the incremented digit without blinking for a while
				LJMP VALUE_LP		; Jump again to continue the scanning
;================================================================================================================================================				
;====================================CALLS USED IN VALUE SETTING PROCESS AND OTHER PROCESSES=====================================================				
TAR_INC:		MOV R7, #00H		; Clearing A, R0 & R7
				MOV R0, #00H		; Byte value @ TBLNK_1 			: 04       | 03      | 02  | 01
				MOV A, #00H			; Corresponding decimal weight	: Thousand | Hundred | Ten | One
				MOV R1, #3DH		; Since CJNE not works with lables the address is stored in R1 as value and used indirectly [TBLNK_1 addr=3D]
				CJNE @R1, #01H, TAR_2		; Check the target byte for 1. If then that digit will be incremented
				SJMP TAR_DIG_1					; i.e. TBLNK_1=1. So the first (rightmost) digit is selected
TAR_2:			CJNE @R1, #02H, TAR_3		; TBLNK_1 = 2?
				SJMP TAR_DIG_2					; Now the second digit from right will be incremented
TAR_3:			CJNE @R1, #03H, TAR_4		; TBLNK_1 = 3?
				SJMP TAR_DIG_3					; Now third
TAR_4:			CJNE @R1, #04H, TAR_INC_RET	; This means the byte TBLNK_1 meets neither of the said values
				; TAR_DIG_4			
				MOV R7, 33H			; Digit 4 has been selected. Taking higher 2 digits (thous:hundrs) of target value to work bench
				ACALL TAR_LD		; Increment only thousands
				MOV 33H, R7			; Storing back
				MOV R7, #00H		; Clearing R7
				SJMP TAR_INC_END	; Finishing the call
TAR_DIG_1:		MOV R7, 32H			; Digit 1 is selected. Taking lower 2 digits (tens:ones) of the target value to work bench
				ACALL TAR_RD		; Increment the ones
				MOV 32H, R7			; Storing back
				MOV R7, #00H		; Clear the R7
				SJMP TAR_INC_END	; Finishing
TAR_DIG_2:		MOV R7, 32H			; Digit 2 is selected. Taking lower 2 digits (tens:ones) of the target value to work bench
				ACALL TAR_LD		; Increment the tens
				MOV 32H, R7			; Storing back
				SJMP TAR_INC_END
TAR_DIG_3:		MOV R7, 33H			; Digit 4 has been selected. Taking higher 2 digits (thous:hundrs) of target value to work bench
				ACALL TAR_RD		; Increments the hundred
				MOV 33H, R7			; Storing back
				MOV R7, #00H		
TAR_INC_END: 	LCALL EXRAM_WRITE	; Immediately save the value to External RAM
				SETB NB				; Setting the new bit to denote, a new value has been entered
TAR_INC_RET:	RET			
				;=================
TAR_RD:			MOV A, R7			; This call increments only right nybble without disturbing the left nybble. And the value doesn't contain Hex
				ADD A, #01H			; Moving it to accumulator.  And adding one to it
				DA A				; Decimal adjusting it to make sure it doesn't contain hex value
				ANL A, #0FH			; Etching the left nybble. Because it may be disturbed
				MOV R0, A			; Storing it at R0 temporarily
				MOV A, R7			; Again take the original value from R7
				ANL A, #0F0H		; Etching the right side. So the left side nybble is original.
				ORL A, R0			; The original left nybble is ORed with right nybble
				MOV R7, A			; Moving back to R7
				MOV R0, #00H 		; Clear the R0 & A
				MOV A, #00H			;
				RET
				;================
TAR_LD:			MOV A, R7			; This call increment left nybble without distrubing the right side nybble
				SWAP A				; The value from R7 taken to A and has been swaped
				ADD A, #01H			; Adding 1 to A
				DA A				; Correcting it if hex value found any
				SWAP A				; Now (left = Tens/thous ; right = hunds/ones)
				ANL A, #0F0H		; Etching the right nybble
				MOV R0, A			; Storing it temporarily at R0
				MOV A, R7			; Taking original from R7 to A
				ANL A, #0FH			; Etching the left nybble
				ORL A, R0			; OR ing A with R0. Now (left = Tens/thous+ ; right hunds/ones). + = Incremented
				MOV R7, A			; Moving back to R7
				MOV R0, #00H		; Clearing the used
				MOV A, #00H
				RET				
;================================================================================================================================================
STR_TBLNK:		SETB BG				; This call will make the target digit to blik so that the user can identify which digit he is updating
				CLR BHH				; Toggling bit that toggles at every 500ms or 0.5S. If this bit is set, the selected digit is shown blank
				SETB BI				; Enabling 0.5S triggering call
				SETB BJ				; Will moniter 500ms time period and raise at each. Very useful, reduce unnecessary execution and thus time
				SETB BPP			; Special bit avoid preceding zero etching for target bit while setting target value
				RET					; Returining the call
;================================================================================================================================================
STP_TBLNK:		CLR BG
				CLR BHH
				CLR BI
				CLR BJ
				CLR BLL
				CLR BPP
				LCALL DCC			; Stops everything and make sure that 
				RET
;================================================================================================================================================				
STRAF1S_TBLNK:	SETB BLL			; This will call target blink call after 1 second time period
				MOV AF1STBLK, #0E0H	; When using 2 bytes with DJNZ instruction to decrement count, we have to add '1' to the upper byte if the 
				MOV AF1STBLK_, #02H	; lower byte is not '00'. So (1E0)H => (01)H lower; (E0)H upper. Adding '1' = (02)H; (E0)H. i.e. (2E0)H
				RET					; The time duration is calculated as (1E0)H = (480)D => 480 x 2.083ms = 999.84ms ~ 1 S
;================================================================================================================================================				
;===================================INTERRUPT SERVICE ROUTINES OF TIMER 0, TIMER 1 & EXTERNAL INTERRUPT 0========================================				
EXINT0:			MOV GEN_1, #02H			; Moving initial value (2) to general register GEN_1
INT0_STRT:		MOV D20MS, #05H			; Loading delay register D20MS. 5 X 2 X 2 will make 20ms time period. TD20MS will be decounted in Timer-0
				SETB BE					; Enabling the delay process by setting BE bit
INT0LP_1:		JB BE, INT0LP_1			; Wait untill bit BE is cleared by timer ISR call after the delay is achieved
				JB P3.2, INT0_GUT		; Check the Ext.Int.0 pin P3.2 is still down? Just getout if not(i.e. P3.2 is checked at each 10ms period)
				DJNZ GEN_1, INT0_STRT	; If P3.2 is down decrementing GEN1 register until it becomes zero. So this will loop 5 times.
				SETB TB					; If GEN1 is zero for 30ms then we found a true interrupt, so set true bit TB
INT0_GUT:		RETI					; Returning the interrupt
;================================================================================================================================================				
TIMER0:			CLR TR0					; Stoping the timer-0 [THIS TIMER ISR WILL REPEAT EVERY 2.083ms]
				MOV TH0, #0F8H			; This value constituting 780H counts to set TR0 i.e. 1920 counts. 1920 x 1.085us = 2083.3us ~ 2.083ms
				MOV TL0, #80H			; This speed will help us to constitute 40 frames per second scanning display
				SETB TR0				; Again starting the timer
				JNC TMR0_NCY			; Along with saving of data from registers A, R0 ... R7 carry is also saved in a seperate bit called TR0
				SETB T0C				; Before it is contaminated by timer-0
				SJMP TMR0_CY
TMR0_NCY:		CLR T0C
TMR0_CY:		MOV 4DH, 00H			; Saving data from regitsters A, R0, R1, R2... R7 to another RAM location before running timer-0 ISR
				MOV 4EH, 01H			; This is important because this timer-0 ISR will raise with out leting the main program to save its data
				MOV 4FH, 02H			; So the data in the said location will be lost if timer-0 ISR is raised and used the said registers.
				MOV 50H, 03H			; Hence to avoid data loss and colision, the data values from the said registers are safely taken in to
				MOV 51H, 04H			; an another RAM location.  After completing the job by timer-0 ISR all data that are saved are fetched 
				MOV 52H, 05H			; again from the saved location and moved back to its native registers from where it was taken.
				MOV 53H, 06H			; Instead doing this we can use switching of register banks to avoid data loss/colision by ISR with main
				MOV 54H, 07H			; programs. But again we have to deal the situation carefully because of the register bank usage of stack-
				MOV 55H, A				; pointers. Since there are many call in calls are used in this program, we have to give more space to stack-
				;===================	; pointers. So I left that method and choosed this one.
				;====Af 5s Blink=====
				JNB BK, AF5SB_RET		; Main flag for after 5S blink should be set to run further
				JB BF, AF5SB_RET		; 5S delay flag will be set until 5S time duration has been completed. So it shouldn't be set
				JNB BJ, AF5SB_RET		; Used to make display blink at every 0.5 second time duration
				JNB BHH, AF5SB_RETB		; Determines the value should be blocked or emitted
				MOV R0, #40H			; Display arrays addresses are 40H to 4DH. Load the first address value to R0 to access from there
AF5SB_LP:		MOV A, @R0				; Indirectly access the display array data values and move it to A
				ORL A, #0FH				; Making data value 'F' so that the driver driving LEDs block the hex value from displaying it
				MOV @R0, A				; Again store it back to its display array address
				INC R0					; Increment R0 to access next address 
				CJNE R0, #4CH, AF5SB_LP	; Check the R0, does it reach 4C which next to the last display address 4D? If not, loop again until it reaches
				MOV A, #00H				; If found, clear the accumulator
				SJMP AF5SB_RET			; Complete the call
AF5SB_RETB:		LCALL DCC				; If BHH bit isn't set, call DCC call
AF5SB_RET:		CLR C					; Since CJNE instruction is used we need to clear carry
				MOV R0, #00H			; Clear the R0
				;=======After 1S Trgt. Blnk========
				JNB BLL, AF1STB_RET		; Main flag to do after 1S target digit blink
				DJNZ AF1STBLK, AF1STB_RET	; Decrement its byte and check for zero. If not just complete the process
				DJNZ AF1STBLK_, AF1STB_RET
				ACALL STR_TBLNK			; If found, call the target digit blink call to start that process
				CLR BLL					; Clear its flag denoting the completion of the task		
				;=====0.5S delay call======
AF1STB_RET:		JNB BI, TMR05D_RET		; 0.5S flag bit. If it is not set the call will not execute any thing
				JNB BJ, TMR0_J3			; 0.5S duration monitor flag that raises each completion of 0.5S time duration
				MOV D05S, #0F0H			; Once BJ raised the corresponding byte is loaded #0F0H to count 240. i.e. 240 x 2.083ms = 499.92ms ~ 0.5S
				CLR BJ					; Clearing it for next raise
TMR0_J3:		DJNZ D05S, TMR05D_RET	; Decrement a unit and check it for zero. If not, just complete the call
				SETB BJ					; If found zero, set BJ to denote a 0.5S duration has complete.
				CPL BHH					; Complementing this bit will determine  the selected target digit is to be shown or hidden.
				;=====Timer-1 migrated codes======
TMR05D_RET:		JNB BE, TMR120MS_RET		; 20ms delay flag bit. If not set just exit
				DJNZ D20MS, TMR120MS_RET	; If set, decrement its byte and check for zero. If not, just exit
				CLR BE						; If the byte found zero after decrementing it, clears it own flag denoting the task is done
				;======5S Delay call======
TMR120MS_RET:	JNB BF, TMR5S_RET			; With the instruction DJNZ we can code to decount 2 bytes to zero with out
				DJNZ D5S_1, TMR5S_RET		; having any complexity.  But we have to store some derived values in to the byte which are
				DJNZ D5S_2, TMR5S_RET		; used to be decounted. We cannot store the actual value(s) in to the DJNZ instruction working
				CLR BF						; bytes. So we have to do some calculations and store the result in to that bytes. 
				;=====BUZZER 0.2S=========
TMR5S_RET:		JNB BB, B02S_RET			; CALCULATION: W.r.t 5S delay program DJNZ is working with byte(s) labled "D5S_1", "D5S_2". D5S_1 is 
				DJNZ BUZ02S_1, B02S_RET		; the first byte and D5S_2 is the second byte. i.e. each unit de-count is made at D5S_1. 
				CLR BB						; Now the calculation is as follows... 
				;====BUZZER 1S============		
B02S_RET:		JB BC, B1SCOUNT				; CASE 1: Check for the last two digit of the target count for "00". If found, just store the hex value
				JB BD, B1SCOUNT				; as it is. e.g. 1200H ---> #12H = D5S_2 ; #00H = D5S_1 (or) 100H ---> #01H = D5S_2 ; #00H = D5S_1
				SJMP B1S_RET				
B1SCOUNT:		DJNZ BUZ1S_1, B1S_RET		; CASE 2: If found any value other than "00" in the last two digit of the target count value, just add '1'
				DJNZ BUZ1S_2, B1S_RET		; with the first two digit(s) e.g. 1112H ---> #12H = D5S_2 ; #12H = D5S_1 (first two digit 11 is added with 1
				CLR BC						; and it becomes 12), 101H ---> #02H = D5S_2 ; #01H = D5S_1
				CLR BD
				;===BIT BB & BC OR-ing=====
B1S_RET:		JB BB, SET_BA				; Bits BB and BC are the bits used to blow the internal and external buzzers. Bit BA is assigned to 
				JB BC, SET_BA				; External buzzer. If either of these bits BB or BC is set, the bit BA should be set to blow the inter-
				CLR BA						; nal buzzer. If both the bits aren't set, just exit the program by clearing BA
				SJMP BB_BC_OR_END
SET_BA:			SETB BA						; Setting the bit BA since bits BA or BC is set
				;=====Target Blink Call============
BB_BC_OR_END:	JNB BG, TMR0TB_RET		; Target blink flag bit. The control will go out if this flag is not set
				JNB BJ, TMR0TB_RET		; Duration monitoring flag bit also need to be set to avoid time loss
				JNB BHH, TMR0TB_RETB	; If both flags are set, BHH must be set to block the selected digit. Otherwise exit
				CLR C					; Since the further codes uses CJNE, first clears the carry
				MOV R0, #3DH			; Lable "TBLNK_1" register RAM address is 3D.
				CJNE @R0, #01H, TMR0TB_2	; Is the data in 3D is equal to 01H?
				MOV A, 44H				; 44H is the RAM address where the first digit of the target value is stored
				ORL A, #0FH				; Make the [left-addr|right-data] data to be shown at display as 'F' so that the display driver block it
				MOV 44H, A				; Moving back again to its native place
				SJMP TMR0TB_CLR			; Completing the target digit blink call and exit
TMR0TB_2:		CJNE @R0, #02H, TMR0TB_3
				MOV A, 45H
				ORL A, #0FH				; Same operation done at 45H if TBLNK_1 (3DH) = 02H
				MOV 45H, A
				SJMP TMR0TB_CLR
TMR0TB_3:		CJNE @R0, #03H, TMR0TB_4
				MOV A, 46H
				ORL A, #0FH				; Same operation done at 46H if TBLNK_1 (3DH) = 03H
				MOV 46H, A
				SJMP TMR0TB_CLR
TMR0TB_4:		CJNE @R0, #04H, TMR0TB_CLR
				MOV A, 47H
				ORL A, #0FH				; Same operation done at 47H if TBLNK_1 (3DH) = 04H
				MOV 47H, A
TMR0TB_CLR:		CLR C			
				SJMP TMR0TB_RET
TMR0TB_RETB:	LCALL DCC				; If BHH bit isn't set, just call DCC to revert changes made by the target blink call
TMR0TB_RET:		MOV R0, #00H			; Clears R0				
				;=======Displaying value from array==========				
				MOV R0, DDISPLAY		; DDISPLAY where the display array address is stored to display the value for current interrupt raise
				MOV P0, @R0				; Indirectly acces that address and move it port-0 where display drivers are physically connected
				CJNE R0, #4BH, TMR0_J1	; Check for it reaches 4B (Last addres of the display array) If not, just exit with increment DDISPLAY
				MOV DDISPLAY, #40H		; If it reaches 4B, just move 40H (First address of display array) to restart the process again for next run
				SJMP TMR0_J2			; Completing the call
TMR0_J1:		INC DDISPLAY			; Incrementing DDISPLAY for next run
				;================20ms Delay call=============
TMR0_J2:		CLR C
				MOV R0, #00H			; Clearing R0
				JNB T0C, TMR0_CYR		
				SETB C					; Write back carry bit
TMR0_CYR:		MOV 00H, 4DH
				MOV 01H, 4EH
				MOV 02H, 4FH 
				MOV 03H, 50H
				MOV 04H, 51H
				MOV 05H, 52H
				MOV 06H, 53H
				MOV 07H, 54H
				MOV A, 55H
				RETI
;================================================================================================================================================				
;TIMER1:			CLR TR1						; [THIS TIMER ISR WILL RAISE EVERY 1ms]. Stop the Timer-1
;				MOV TH1, #0FCH				; FC66H --> 0000H will constitute 922 counts to roll over. 922 x 1.085us = 1000us ~ 1ms
;				MOV TL1, #66H
;				SETB TR1					; Start the timer to avoid waste of time
;				JNC TMR1_NCY				; Along with saving of data from registers A, R0 ... R7 carry is also saved in a seperate bit called TR0
;				SETB T1C					; before it is been contaminated by timer-1
;				SJMP TMR1_CY
;TMR1_NCY:		CLR T1C
;TMR1_CY:		MOV 56H, 00H				; Storing the data in the registers like A, R0, R1, .... R7 in to another RAM locations to avoid
;				MOV 57H, 01H				; data loss due to raise of timer-1 when main program is accessing these registers. After completion of
;				MOV 58H, 02H				; timer-1 ISR, the values of these registers are again put back from where there were taken
;				MOV 59H, 03H
;				MOV 5AH, 04H
;				MOV 5BH, 05H
;				MOV 5CH, 06H
;				MOV 5DH, 07H
;				MOV 5EH, A
;				;=====20ms Delay call=====
;				JNB BE, TMR120MS_RET		; 20ms delay flag bit. If not set just exit
;				DJNZ D20MS, TMR120MS_RET	; If set, decrement its byte and check for zero. If not, just exit
;				CLR BE						; If the byte found zero after decrementing it, clears it own flag denoting the task is done
;				;======5S Delay call======
;TMR120MS_RET:	JNB BF, TMR5S_RET			; With the instruction DJNZ we can code to decount 2 bytes to zero with out
;				DJNZ D5S_1, TMR5S_RET		; having any complexity.  But we have to store some derived values in to the byte which are
;				DJNZ D5S_2, TMR5S_RET		; used to be decounted. We cannot store the actual value(s) in to the DJNZ instruction working
;				CLR BF						; bytes. So we have to do some calculations and store the result in to that bytes. 
;				;=====BUZZER 0.2S=========
;TMR5S_RET:		JNB BB, B02S_RET			; CALCULATION: W.r.t 5S delay program DJNZ is working with byte(s) labled "D5S_1", "D5S_2". D5S_1 is 
;				DJNZ BUZ02S_1, B02S_RET		; the first byte and D5S_2 is the second byte. i.e. each unit de-count is made at D5S_1. 
;				CLR BB						; Now the calculation is as follows... 
;;				;====BUZZER 1S============		
;B02S_RET:		JB BC, B1SCOUNT				; CASE 1: Check for the last two digit of the target count for "00". If found, just store the hex value
;				JB BD, B1SCOUNT				; as it is. e.g. 1200H ---> #12H = D5S_2 ; #00H = D5S_1 (or) 100H ---> #01H = D5S_2 ; #00H = D5S_1
;				SJMP B1S_RET				
;B1SCOUNT:		DJNZ BUZ1S_1, B1S_RET		; CASE 2: If found any value other than "00" in the last two digit of the target count value, just add '1'
;				DJNZ BUZ1S_2, B1S_RET		; with the first two digit(s) e.g. 1112H ---> #12H = D5S_2 ; #12H = D5S_1 (first two digit 11 is added with 1
;				CLR BC						; and it becomes 12), 101H ---> #02H = D5S_2 ; #01H = D5S_1
;				CLR BD
;				;===BIT BB & BC ORing=====
;B1S_RET:		JB BB, SET_BA				; Bits BB and BC are the bits used to blow the internal and external buzzers. Bit BA is assigned to 
;				JB BC, SET_BA				; External buzzer. If either of these bits BB or BC is set, the bit BA should be set to blow the inter-
;				CLR BA						; nal buzzer. If both the bits aren't set, just exit the program by clearing BA
;				SJMP BB_BC_OR_END
;SET_BA:		SETB BA						; Setting the bit BA since bits BA or BC is set
;BB_BC_OR_END:	CLR C
;				JNB T1C, TMR1_CYR
;				SETB C						; Write back carry bit
;TMR1_CYR:		MOV 00H, 56H 
;				MOV 01H, 57H
;				MOV 02H, 58H
;				MOV 03H, 59H
;				MOV 04H, 5AH
;				MOV 05H, 5BH
;				MOV 06H, 5CH
;				MOV 07H, 5DH
;				MOV A, 5EH
;				RETI
;================================================================================================================================================
				END
;================================================================================================================================================
; Code by: M Kamalakannan
; Coding started: 27-7-2013 @ 10:30pm
; Coding finished: 27-8-2013 @ 10:53pm
; Error(s) corrected & Compiled: 1-9-2013 @ 11:50am
; Kit finished: 9-9-2013 @ 8:40pm
; Fused: 9-9-2013
; Project Completed: 3 prototypes were developed. For developing prototype it took another 3 to 4 months that includes PCB design and fabrication.
; Conclusion: Project dropped due to lack of support & attitude less confidence less team mates.  Never trust peoples who always promises everything.
;
;=================================================================================================================================================
