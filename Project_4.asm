;*******************************************************************************
;  Student Name	    : Keshav Jeewanlall			            
;  Student Number   : 213508238	                                                
;  Date		    : 26 / 09 / 2017                                    
;    
;  Description:
;    
;  This code processes an analogue input from a LM35 chip and displays the 
;  result on two multiplexed SSDs. There are two push buttons. One for  
;  incrementing the threshold and the other for decrementing it. Holding either   
;  button down for 2s will enter the "Set Threshold" mode. Set Threshold mode     
;  will exit after 3s if no button ispressed. An alarm of 440Hz is sounded
;  when the temperature exceeds the threshold value. This alarm sounds on and    
;  and off in 1s intervals.						       								       
;*******************************************************************************
    
    List p=16f690
    #include <p16F690.inc>

    errorlevel  -302             ;Configuration bits setup
    __CONFIG   _CP_OFF & _CPD_OFF & _BOR_OFF & _MCLRE_ON & _WDT_OFF & _PWRTE_OFF & _INTRC_OSC_NOCLKOUT & _FCMEN_OFF & _IESO_OFF 
    
;************************VARIABLE DEFINITIONS & VECTORS*************************  
 GPR_VAR UDATA
tens		RES 1		;;stores tens digit
units		RES 1		;stores units digit
temperature	RES 1		;store current temperature value
threshold	RES 1		;stores threshold value
buzzer_state	RES 1		;used to control duty cycle of the buzzer
count		RES 1		;used to control Timer0
eeprom_address	RES 1		;stores the EEPROM address for threshold value 
temp	        RES 1
temp2	        RES 1	

 EXTERN Binary_To_BCD	    ;library to convert binary to BCD
 
RESET ORG 0x00
    GOTO Setup
    
;*****************************SETUP OF PIC16F690*******************************
Setup
    
			    ;Use Bank 0
    BCF STATUS,5
    BCF STATUS,6
     
    CLRF PORTA		    ;Initialise Port A
    CLRF PORTB		    ;Initialise Port B
    CLRF PORTC		    ;Initialise Port C
    
    MOVLW b'01001101'
    MOVWF ADCON0	    ;Load 01001101 into ADCONO to Adjust left, 
			    ;use external Vref, enable AN3 and enable ADC
     
    BSF T1CON,4
    BSF T1CON,5		    ;Set T1CKPS1 & T1CKPS0 bits for 1:8 Prescaler
    
    BCF PIR1,1
    CLRF T2CON

    
    MOVLW 0x02
    MOVWF eeprom_address    ;Use address 0x02 to store Threshold value in EEPROM
                        
			    ;Use Bank 1
    BSF STATUS,5
    
    BCF OSCCON,6
    BSF OSCCON,5		
    BSF OSCCON,4	    ;Set IRCF1 & IRCF0 to select 500kHz FOSC
    
    CLRF TRISC		    ;Set PORTC as output
    
    MOVLW b'00010111'		
    MOVWF TRISA		    ;set RA0 for as input for decrement button
			    ;Set RA1 as input. Used to read Vref
			    ;Set RA2 as input for increment button
			    ;Set RA4 as input for the LM35
				
    BCF TRISB,4		    ;RB4 used to sound alarm
    
    CLRF ADCON1		    ;Conversion cloack set at FOSC/2
    
    MOVLW b'00000111'
    MOVWF OPTION_REG	    ;Timer0 used in Timer mode with Prescaler 1:256 
    
			    ;Use Bank 2
    BCF STATUS,5
    BSF STATUS,6		
    
    CLRF ANSEL		    ;Initialize all ports as digital I/O
    CLRF ANSELH
    BSF ANSEL,3		    ;Set RA4/AN3 to be analog input
    BSF ANSEL,1		    ;Set Vref to be analog input
     
    BANKSEL EEADR	    
    MOVFW eeprom_address	
    MOVWF EEADR		    ;Load address to EEADR
    
			    ;Use Bank 3
    BSF STATUS,5
    BSF STATUS,6
    
    BANKSEL EECON1
    BCF EECON1,7	    ;Clear EEPGD bit to Access Data memory
    BSF EECON1,0	    ;Set RD bit to read from EEPROM
    
			    ;Use Bank 2
    BCF STATUS,5
    
    MOVFW EEDAT		    ;Move the data from EEPROM to WREG
    
			    ;Use Bank 0
    BCF STATUS,6
    
    MOVWF threshold	    ;Move WREG to Threshold register 
    CLRF temperature	    ;Clear variables
    CLRF buzzer_state
    CLRF count
    
    MOVLW 0x0B		    ;Initial value for Timer0, will run for 500ms
    MOVWF TMR0
    BCF INTCON,2	    ;Start Timer0
        
    GOTO Main_Loop
     
;********************************MAIN LOOP*************************************
    CODE 
Main_Loop
    CALL Get_Temperature    ;Sample the Temperature and Display it
   
    BTFSS PORTA,0	    ;Check if Decrement button is pressed
    CALL One_Second_Delay   ;If yes, wait for 1 second
    BTFSS PORTA,0	    ;Check if Decrement button is still pressed
    CALL One_Second_Delay   ;If yes, wait another second.
    BTFSS PORTA,0	    ;Check if button is still pressed after 2 seconds
    CALL Set_Threshold	    ;If yes, call Set_Threshold
    
    BTFSS PORTA,2	    ;Check if Increment button is pressed
    CALL One_Second_Delay   ;If yes, wait for 1 seconds
    BTFSS PORTA,2	    ;Check if Increment button is still pressed
    CALL One_Second_Delay   ;If yes, wait another second.
    BTFSS PORTA,2	    ;Check if button is pressed after 2 seconds
    CALL Set_Threshold	    ;If yes, call Set_Threshold
    
    BTFSC INTCON,2	    ;Check if 500ms reached by checking timer overflow
    CALL Timer0_Control	    ;If set, call Timer0_Control
    
    MOVFW threshold
    SUBWF temperature,0	    ;temp = temperature - threshold
    MOVWF temp		    ;If threshold > temperature, negative occurs, 
			    ;bit 7 will be set
    BTFSS temp,7	    ;If bit 7 set, don't sound alarm because temperature 
			    ;is under the threshold
    CALL Trigger_Alarm  
    
    GOTO Main_Loop
    
;***************************CODE FOR SOUNDING ALARM*****************************
    
Trigger_Alarm			
 

    
 BSF OSCCON,6		;For a frequency of 440Hz, the period is 2.27ms. Toggling PORTB<4> after each half
    BCF OSCCON,5		;period (1.135ms) will generate the 440Hz frequency needed. Therefore 1126 * 1/1MHz = 1.126ms
    BCF OSCCON,4		;By setting FOSC to 1MHz, the output frequency will equal 444Hz.
    
    BTFSS buzzer_state,0	;Used to control active state of speaker (When bit 0 is 1, the speaker is off)
    BSF PORTB,4
    CALL Get_Temperature	;Calling Get_Temperature. This will act as a Delay
    BCF PORTB,4
    CALL Get_Temperature
 
    BCF OSCCON,6
    BSF OSCCON,5		;Setting back to FOSC = 500kHz
    BSF OSCCON,4
    RETURN
   

    RETURN

;**********************CODE TO GET TEMPERATURE FROM LM35************************
     
Get_Temperature
			    ;Conversion is initiated by setting the GO/DONE 
			    ;bit ADCON0<1>
			    
    BSF ADCON0,1	    ;Start ADC conversion
    
Wait_Loop
    BTFSC ADCON0,1	    ;Checks if conversion done, if so, exit loop
    GOTO Wait_Loop	    
    MOVFW ADRESH	    ;Move conversion result to WREG
    MOVWF temperature
    CALL Display	    ;Displays the Temperature
    RETURN
    
;************************CODE FOR DISPLAYING ON SSDs****************************
    
Display
    
    CALL Convert_to_BCD	    ;subroutine to convert count to BCD
    CALL SSD_Table	    ;gets code for displaying the number (Tens)
    ADDLW 0x80		    ;setting the MSB (Bit 7) will enable the Tens SSD
    MOVWF PORTC		    ;display Tens value
    CALL Multiplexing_Delay ;delay for multiplexing SSDs
    BCF PORTC,7		    ;Set pin RA4 to enable units SSD
    MOVFW units		    
    CALL SSD_Table	    ;gets code for displaying the number (Units)
    BSF PORTA,5		    ;Set PORTA<5> to enable units SSD
    MOVWF PORTC		    ;displays units value
    CALL Multiplexing_Delay
    BCF PORTA,5		    ;Disable the Units SSD
    RETURN
    
Convert_to_BCD		  ;converts count to BCD
    Call Binary_To_BCD	  ;uses library subroutine to get BCD value of number
    MOVWF tens
    ANDLW 0x0F		  ;b'00001111 , clears upper nibble of BCD number
    MOVWF units		  ;stores the value as the units
    SWAPF tens,1	  ;swaps the nibbles of the BCD number
    MOVFW tens		  
    ANDLW 0x0F		  ;b'00001111, clears the high nibble to get tens value
    MOVWF tens		  ;stores value in tens register
    RETURN
    
;This code adds the value that is in the W register to the Program Counter, 
;PC will skip to whichever code is needed and returns the code in the WREG.
    
SSD_Table
			  ;These HEX values are required because common anode SSDs
			  ;are being used
    ADDWF PCL,1
    RETLW 0x40		  ;displays number 0 on SSD
    RETLW 0x79		  ;displays number 1 on SSD    
    RETLW 0x24		  ;displays number 2 on SSD
    RETLW 0x30		  ;displays number 3 on SSD
    RETLW 0x19		  ;displays number 4 on SSD
    RETLW 0x12		  ;displays number 5 on SSD
    RETLW 0x02		  ;displays number 6 on SSD
    RETLW 0x78		  ;displays number 7 on SSD
    RETLW 0x00		  ;displays number 8 on SSD
    RETLW 0x10		  ;displays number 9 on SSD
 
;***********************CODE FOR SETTING THRESHOLD VALUE************************
Set_Threshold
    CALL Three_Second_Delay ;Calls routine to start Timer1 to run for 3s
Set_Threshold_Loop
    MOVFW threshold
    CALL Display	    ;Displays the Threshold value
    CALL Flash_SSD	    ;This flashes the SSDs off and on
    BCF PORTA,5		    ;Disables Units SSD
    ;CALL Flash_SSD
    BCF PORTC,7		    ;Disables Tens SSD
    
    BTFSS PORTA,2	    ;Checks if Increment button pressed
    CALL Increase_Threshold  ;If so, call Increae_Threshold
    BTFSS PORTA,0	    ;Checks if Decrement button pressed
    CALL Decrease_Threshold ;If so, call Decrease_Threshold
    
    BTFSS PIR1,0	    ;If 3 seconds occured, exit routine
    GOTO Set_Threshold_Loop
    CALL Write_To_EEPROM    ;Subroutine to write to EEPROM
    BCF PIR1,0		    ;Re-enable the timer flag
    BCF T1CON,0		    ;Stop Timer1
    
    RETURN
    
Increase_Threshold
    INCF threshold,1	    ;Increment the Threshold value
    MOVLW 0x1C		    ;adds 28 to threshold
    ADDWF threshold,0	    ;if threshold is 128 or greater, bit 7 will set
    MOVWF temp		    
    BTFSC temp,7	    ;if bit 7 is clear, number is under 100
    CLRF threshold	    ;reset the threshold
Wait_For_Increase
    MOVFW threshold
    CALL Display	    ;Displays the Threshold value while waiting
    BTFSS PORTA,2	    ;Waits till button released
    GOTO Wait_For_Increase
    CALL Three_Second_Delay ;Starts Timer1 again. Configure to run for 3s.
    RETURN
    
Decrease_Threshold
    DECF threshold,1	    ;Decrement Threshold value
    BTFSS threshold,7	    ;If -1 occurs(0xFF), bit 7 will be set. Reset to 99
    GOTO Wait_For_Decrease  ;else skip
    MOVLW 0x63
    MOVWF threshold
Wait_For_Decrease
    MOVFW threshold
    CALL Display	    ;Displays the Threshold value while waiting
    BTFSS PORTA,0	    ;Waits till button released
    GOTO Wait_For_Decrease
    CALL Three_Second_Delay ;Run 3s delay.
    RETURN

 ;***********************CODE FOR WRITTING TO EEPROM****************************
 
Write_To_EEPROM
    BANKSEL EEADR		
    MOVFW eeprom_address	    
    MOVWF EEADR		    ;Data memory address to write
    BANKSEL 0x00
    MOVFW threshold	    ;Load threshold value to be written to EEPROM
    BANKSEL EEDAT
    MOVWF EEDAT		    ;Data memory value to write
    BANKSEL EECON1
    BCF EECON1,7	    ;Clear EEPGD bit to Access Data memory
    BSF EECON1,2	    ;Set WREN to allow write cycle
    
    MOVLW 0x55		    
    MOVWF EECON2    
    MOVLW 0xAA		    
    MOVWF EECON2 
    BSF EECON1,1	    ;Initiate write to EEPROM
    BCF EECON1,2	    ;Clear WREN to disable write to EEPROM
    BANKSEL 0x00
    RETURN
 
;*************************CODE FOR ALL DELAYS REQUIRED**************************
    
Multiplexing_Delay	  
			  
			  		    
    
    MOVLW 0xFF		  ;Loads a value of 255 and stores it in temp
    MOVWF temp
Multiplexing_Delay_Loop
    DECFSZ temp,1	  ;When temp = 0, exit loop
    GOTO Multiplexing_Delay_Loop
   
    RETURN
    
    
Flash_SSD		  ;This delay is used to flash the SSDs off and on during 
			  ;Set_Threshold mode. 
			  
    MOVLW 0x0C		  
   MOVWF temp2
    MOVWF temp
Wait_Flash
    DECFSZ temp
    GOTO Wait_Flash
    DECFSZ temp2
    GOTO Wait_Flash
    RETURN

One_Second_Delay	    ;Uses Timer1 for a 1 second Delay
    MOVLW 0xF6
    MOVWF TMR1L
    MOVLW 0xC2
    MOVWF TMR1H		    ;Initial value loaded to TMR1H:TMR1L
			    ;to allow a 1sec overflow
    BSF T1CON,0		    ;Start Timer1   
One_Second_Loop
    CALL Get_Temperature    ;Displays Temperature while waiting for overflow flag
    BTFSS PIR1,0	    ;If flag not set, loop again
    GOTO One_Second_Loop
    BCF PIR1,0		    ;Clear Timer1 interrupt flag
    BCF T1CON,0		    ;Stop Timer1
   RETURN
    
Three_Second_Delay
    BCF PIR1,0		    ;Re-enable the timer flag
    BCF T1CON,0		    ;Stops Timer1
    MOVLW 0xE4
    MOVWF TMR1L
    MOVLW 0x48
    MOVWF TMR1H		    ;Initial value loaded to TMR1H:TMR1L to allow a 
			    ;3s overflow
    BSF T1CON,0		    ;Start Timer1
    RETURN
    
;*****************************CODE FOR TIMER0 CONTROL***************************    
Timer0_Control			
;Timer0 set up for 500ms. When timer flag is set twice, it means 1s has reached.
    
    INCF count		    ;Increment count each time 500ms reached. 
    
			    ;Check if count = 2. Done by moving this to temp
			    ;and decrementing temp twice.
    MOVFW count		    
    MOVWF temp		    
    DECF temp,1 
    DECFSZ temp,1	    ;If temp = 2, zero should occur here
    GOTO Reset_Timer0	    ;If not true, reset Timer0
    INCF buzzer_state,1	    ;Everytime 1s occurs, buzzer_state is incremented. 
			    ;This means every second, Bit 0 is changing value,
			    ;therefore the buzzer is activated for 1 second and 
			    ;then deactivated for the next.
    CLRF count		    ;Resets the count
Reset_Timer0
    BCF INTCON,2	    ;Clear Timer0 overflow flag
    MOVLW 0x0B		    ;Initiate Timer0 for 500ms
    MOVWF TMR0    
    RETURN
 
 
 
    END


