;------------------------------------------------------------------------------
;Archivo: Lab5
;Microcontrolador: PIC16F887
;Autor: Andy Bonilla
;Programa: Displys multiplexados con contadores0
;Descripcion: contadores con despliegue en LEDS y displyas multiplexados
;Hardware: 
;------------------------------------------------------------------------------

;---------libreras a emplementar-----------------------------------------------
PROCESSOR 16F887
#include <xc.inc>
;------configuration word 1----------------------------------------------------
CONFIG  FOSC=INTRC_NOCLKOUT ;se declara osc interno
CONFIG  WDTE=OFF            ; Watchdog Timer apagado
CONFIG  PWRTE=ON            ; Power-up Timer prendido
CONFIG  MCLRE=OFF           ; MCLRE apagado
CONFIG  CP=OFF              ; Code Protection bit apagado
CONFIG  CPD=OFF             ; Data Code Protection bit apagado

CONFIG  BOREN=OFF           ; Brown Out Reset apagado
CONFIG  IESO=OFF            ; Internal External Switchover bit apagado
CONFIG  FCMEN=OFF           ; Fail-Safe Clock Monitor Enabled bit apagado
CONFIG  LVP=ON		    ; low voltaje programming prendido

;----------configuration word 2-------------------------------------------------
CONFIG BOR4V=BOR40V	    ;configuraciÃ³n de brown out reset
CONFIG WRT = OFF	    ;apagado de auto escritura de cÃƒÂ³digo

;---------------------------macros -------------------------------------------
reset_timer	macro	    ; lo que anteriormente fue subrutina, se hizo macro
    movlw	40	    ; dada la configuración del prescaler
    movwf	TMR0	    ; se guarda en timer0
    bcf		T0IF	    ; bandera cuando no hay overflow
    endm     
    
;-------------------------variables x --------------------------------------- -
GLOBAL W_TEMP, STATUS_TEMP, cont, var, banderas, nibble, display_var, dis3, dis4, dis5
    PSECT	udata_bank0
    cont:	    DS 2 ; variable de contador sencillo
    backup:	    DS 2 ; variable de respaldo de contador
    dis3:	    DS 1 ; resultado de centenas
    dis4:	    DS 1 ; resultado de decenas
    dis5:	    DS 1 ; resultado de unidades
    var:	    DS 1
    banderas:	    DS 1
    nibble:	    DS 2 ; me lleva la cuenta de los displays
    display_var:    DS 2
    
;-------------- variables de interrupcion -------------------------------------
PSECT udata_shr	    
 W_TEMP:	DS 1
 STATUS_TEMP:	DS 1
 
;-----------------vect reset --------------------------------------------------
PSECT resVect, class=CODE, abs, delta=2 ;
 ORG 00h
 PAGESEL main
 goto	 main

;------------------------ interrupt vector ------------------------------------
PSECT	intVect, class=code, abs, delta=2 
ORG 04h
push:
    movwf	W_TEMP	    ; variable se almacena en f
    swapf	STATUS, W   ; se dan vuelta nibble
    movwf	STATUS_TEMP ; se almacena en status_temp	
isr:
    btfsc	T0IF		; se revisa si está activada la bandera
    call	sumaresta_int
    call	int_timer0	; se usa subrutina
pop:
    swapf	STATUS_TEMP	; se da vuelta a cantidad
    movwf	STATUS		; se almacena en status
    swapf	W_TEMP, F	; se da vuelta otra vez
    swapf	W_TEMP, W	; se vuelve a dar vuelta y se almacena en w
    retfie
;---------------------subrutinas de interrupt ---------------------------------
sumaresta_int:
    btfsc	PORTB,0
    incf	PORTA
    
    btfsc	PORTB,1
    decf	PORTA
    return

int_timer0:
    reset_timer			; se reinicia el timer0
    clrf	PORTD		; PSM limpio el PortD
    btfsc	banderas,0	; si se si ese bit es 0
    goto	display1	; info se madna a sub-subrutina
    
display0:    
    clrf	PORTD		; PSM se limpia PortD
    movf	display_var, W	; se mueve el de alla abajoa 
    movwf	PORTC		; se mueve al portc multiplezado
    bsf		PORTD, 0	; se prende transistor que este anclado
    goto	siguiente_display 
       
display1:    
    clrf	PORTD		; PSM se limpia PortD
    movf	display_var+1, W    ; se mueve el de alla abajoa 
    movwf	PORTC		    ; se mueve al portc multiplezado
    bsf		PORTD, 1	    ; se prende transistor que este anclado
    
    goto	siguiente_display
  
; el display 2 lo dejé en blanco para que no se confundiera, y todo lo
; relacionado con estas subrutinas tienen el mismo salto 1->3
    
display3:    
    clrf	PORTD		    ; PSM se limpia PortD
    movf	display_var+2, W    ; se toma valor almacenado de centenas
    movwf	PORTC		    ; se mueve al PortC
    bsf		PORTD, 3	    ; se prende transistor que este anclado
    goto	siguiente_display
	
display4:    
    clrf	PORTD
    movf	display_var+3, W 
    clrf	PORTC
    movwf	PORTC
    bsf		PORTD, 4
    goto	siguiente_display 
	
display5:    
    clrf	PORTD
    movf	display_var+4, W 
    clrf	PORTC
    movwf	PORTC
    bsf		PORTD, 5
    goto	siguiente_display


siguiente_display: ; <----- hay que encontrar la forma de hacer esto, practicamente hacer alternar los tranaistores
    bcf		CARRY
    btfsc	PORTD, 5
    goto	$-3
    movlw	01h
    movwf	banderas
    rlf		banderas, F
    return
    
   /* 
    movlw	1	    
    xorwf	banderas, F
    return
    */
;-------------------- código principal ---------------------------------------
PSECT code, delta=2, abs
ORG 100h
 
tabla:
    clrf    PCLATH	    ; asegurarase de estar en secciÃ³n
    bsf	    PCLATH, 0 	    ; 
    andlw   0xff	    ; 
    addwf   PCL, F	    ; se guarda en F
    retlw   00111111B	    ; 0
    retlw   00000110B	    ; 1
    retlw   01011011B	    ; 2
    retlw   01001111B	    ; 3
    retlw   01100110B	    ; 4
    retlw   01101101B	    ; 5 
    retlw   01111101B	    ; 6
    retlw   00000111B	    ; 7
    retlw   01111111B	    ; 8
    retlw   01101111B	    ; 9
    retlw   01110111B	    ; A
    retlw   01111100B	    ; B
    retlw   00111001B	    ; C
    retlw   01011110B	    ; D
    retlw   01111001B	    ; E
    retlw   01110001B	    ; F
    
;--------------------------configuraciones ------------------------------------
main:
    call	io_config
    call	reloj_config
    call	timer0_config
    banksel	PORTA
;------------------------ loop de programa ------------------------------------    
loop:
    movlw	0x01; aqui pego los contadores de la tabla
    movwf	var ; contador por acá
    ;contador
    call    	separar_nibbles
    call	variables_displays
    
;    btfsc	PORTB, 0	; incf    
;    call	suma		;
;    btfsc	PORTB, 1	;
;    call	resta
    ;call	decimal
    ;bcf		banderas ;, displayValue
    goto	loop

;------------------------ subrutinas regulares --------------------------------
io_config:
    banksel	ANSEL
    clrf	ANSEL	    ; aseguramos que sea digital
    clrf	ANSELH	    ; configuraciÃ³n de pin analÃ³gico
    
    banksel	TRISA
    clrf	TRISA	    ; PortA como salida
    bsf		TRISB, 0    ; PortB0 como entrada
    bsf		TRISB, 1    ; PortB1 como entrada
    clrf	TRISC	    ; PortC como salida	
    clrf	TRISD	    ; POrtD como salida
    
    banksel	PORTA	    
    clrf	PORTA	    ; PortA como salida
    bsf		PORTB, 0    ; PortB0 como entrada
    bsf		PORTB, 1    ; PortB1 como entrada
    clrf	PORTC	    ; PortC como salida
    clrf	PORTD	    ; PortD como salida
    
    bsf		OPTION_REG, 7
    bsf		WPUB, 0
    bsf		WPUB, 1
   
    return
    
reloj_config:
    banksel	OSCCON
    bcf		IRCF2	    ; clear, se pone Freq de 500KHz -> 010
    bsf		IRCF1	    ; set, ; se pone Freq de 500KHz -> 010
    bcf		IRCF0	    ; clear, ; se pone Freq de 500KHz -> 010
    bsf		SCS
    return
 
timer0_config:
    banksel	TRISA
    bcf		T0CS
    bcf		PSA	    ; se configura preescaler
    bsf		PS2	    ; set,
    bsf		PS1	    ; set
    bsf		PS0	    ; set
    banksel	PORTA
    reset_timer
    bsf		GIE	    ; se prender bits de interrupciones
    bsf		T0IE	    ; interrupt enabel
    bcf		T0IF	    ; interrupt flag
    return

;suma:
;    btfsc	PORTB, 0
;    goto	$-1	    ; regresar una linea en codigo
;    incf	PORTA
;    incf	cont, F	    ; antes estaba 
;    ;incf	backup, F
;    ;call	centenas
;    return
;
;resta:
;    btfsc	PORTB, 1
;    goto	$-1	    ; regresar una linea en codigo
;    decf	PORTA  
;    decf	cont, F
;    ;decf	backup, F
;    ;call	centenas
;    return

separar_nibbles:
    movf	PORTA, w    ; separo los nibbles del display0
    andlw	0x0f	    ; limite de LSB
    movwf	nibble	    ; muevo nibble a f
    
    swapf	PORTA, W	    ; separo los nibbles del display1
    andlw	0x0f	    ; limite de LSB
    movwf	nibble+1    ; muevo nibble+1 a f

    return
    
variables_displays:
    movf	nibble, W	; display bit1 contador hex
    call	tabla		; llamo al valor de la tabla
    movwf	display_var	; muevo variable display_var a f

    movf	nibble+1, W	; display bit0 contador hex
    call	tabla		; llamo al valor de la tabla
    movwf	display_var+1	; muevo variable display_var+1 a f
    
    movf	dis3, W		; display bit0 contador hex
    call	tabla		; llamo al valor de la tabla
    movwf	display_var+2	; muevo variable display_var+1 a f
    
    movf	dis4, W		; display bit0 contador hex
    call	tabla		; llamo al valor de la tabla
    movwf	display_var+3	; muevo variable display_var+1 a f
    
    movf	dis5, W		; display bit0 contador hex
    call	tabla		; llamo al valor de la tabla
    movwf	display_var+4	; muevo variable display_var+1 a f
    
    return
    ; nibble tiene el valor de PortA
    ; display_var tiene el binario de la tabla del PortA
    ; evaluar valor de PortA -100
  

centena:
    clrf	dis3	    ; se limpia nueva variable
    bcf		CARRY	    ; se limpia bit carry
    movf	PORTA, W    ; se toma valor del PortA
    movwf	var	    ; se mueve a var
    movlw	100	    ; se agrega a W 100
    subwf	var, F	    ; resta el POrtA y 100
    incf	dis3	    ; se suma el número de restas
    btfsc	CARRY	    ; se ve si dio 0 o no
    goto	$-3	    ; se regresa instruccion hasta que de 0
    decf	dis3	    ; se resta una vez	
    addwf	var	    ; se agrega el resultado a var
    movf	dis3, W	    ; se mueve a dis3 -> centenas
    call	tabla	    ; se llama ese valor de la tabla para el 7seg
    movwf	display_var+3	; se mueve a valor multiplezado
    movwf	PORTC		; se mueve al PortC
    goto	decena		; se pasa a siguiente subrutina
    
decena:
    clrf	dis4	    ; se limpia nueva variable
    bcf		CARRY	    ; se limpia bit carry
    movlw	10	    ; se toma valor del PortA
    subwf	var	    ; se mueve a var
    incf	dis4	     ; se agrega a W 100
    goto	$-3	    ; resta el POrtA y 100
    decf	dis4	    ; se suma el número de restas
    addwf	var	    ; se ve si dio 0 o no
    movwf	dis4, W	    ; se regresa instruccion hasta que de 0
    call	tabla	    ; se resta una vez	
    movwf	display_var+4	    ; se mueve a valor multiplezado
    ;movwf	PORTC		    ; se mueve al PortC
    goto	unidad		    ; se pasa a siguiente subrutina
    return
    
unidad:
    movf	var, W		; se toma el residuo y se manda a Q
    call	tabla		; se llama ese valor de la tabla    
    movwf	display_var+5	; se guarda en valor multiplexado
    return
  
END