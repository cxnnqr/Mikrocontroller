;
; Mikro.asm
;
; Created: 09/05/2025 13:41:14
; Author : JDuec
;

; Coding for 7 segment:
; 1 => light up
; order: top -> clockwise around -> middle -> decimal point
; order: lsb -> msb
.equ symbol_0 = 0x3f
.equ symbol_1 = 0x06
.equ symbol_2 = 0x5b
.equ symbol_3 = 0x4f
.equ symbol_4 = 0x66
.equ symbol_5 = 0x6d
.equ symbol_6 = 0x7d
.equ symbol_7 = 0x07
.equ symbol_8 = 0x7f
.equ symbol_9 = 0x6f
.equ symbol_A = 0x77
.equ symbol_b = 0x7c
.equ symbol_C = 0x39
.equ symbol_d = 0x5e
.equ symbol_E = 0x79
.equ symbol_F = 0x71
.equ symbol_point = 0x80

; brightness starts at 0x88 -> 0
; 0x89 -> 1, ...
; all the way up to 7
.equ brightness_base = 0x88 
.equ brightness = brightness_base + 7
.equ CLK = 2
.equ DIO = 3
.equ ADDR_FIXED = 0x44
.equ ADDR_AUTO = 0x40
.equ ADDR_START = 0xc0

; Initialize the stack pointer (SP) to top of SRAM
init_stack:
	ldi r16, high(RAMEND)    ; RAMEND is 0x08FF
	out SPH, r16             ; High byte of stack pointer
	ldi r16, low(RAMEND)
	out SPL, r16             ; Low byte of stack pointer

init_registers:
	; initislize start value (2seconds)
	ldi r24, 0x1
	ldi r25, 0x0


; inititalizes the 4 digit display
init_display:
	sbi DDRD, CLK
	sbi DDRD, DIO
	rcall display_clear

ldi r20, 0 ; initialize seed
initialize_seed:
	sbic PIND, 4
	rjmp button_pressed
	inc r20
	rjmp initialize_seed

button_idle:
	sbic PIND, 4
	rjmp button_pressed
	rjmp button_idle

button_pressed:
	rcall next
	rcall display_circle
	push r24
	push r25
	push r20

	; set wait time
	ldi r24, 0b11010000
	ldi r25, 0b00000111

	loop_and_add:
		adiw r25:r24, 12
		dec r20
		brne loop_and_add
	
	rcall wait
	rcall display_clear
	pop r20
	pop r25
	pop r24

; make sure the user hasn't released the button early
button_wait_for_prerelease:
	sbis PIND, 4
	rjmp button_idle


; initialize time counters
ldi r28, 0
ldi r29, 0
ldi r30, 0
ldi r31, 0

; wait for button to be released
button_wait_for_release:
	sbis PIND, 4
	rjmp show_time ; jump to finish
	rcall wait ; wait for 1ms
	rcall increment_time ; increment time
	rjmp button_wait_for_release

show_time:
	push r17
	push r18

	ldi r18, 3
	mov r28, r16
	rcall write_7_segment_code
	rcall transmit_digit

	ldi r18, 2
	mov r29, r16
	rcall write_7_segment_code
	rcall transmit_digit

	ldi r18, 1
	mov r30, r16
	rcall write_7_segment_code
	rcall transmit_digit

	ldi r18, 0
	mov r31, r16
	rcall write_7_segment_code
	rcall transmit_digit

	pop r18
	pop r17
	rjmp button_idle



increment_time:
	inc r28
	cpi r28, 10
	brne end
	ldi r28, 0

	inc r29
	cpi r29, 10
	brne end
	ldi r29, 0

	inc r20
	cpi r30, 10
	brne end
	ldi r30, 0

	inc r31
	cpi r31, 10
	brne end
	dec r31

	end:
		ret

; put the desired digit in r16
; modifies r17 globally
write_7_segment_code:
	push r16

	cpi r16, 0
	breq digit_0

	cpi r16, 1
	breq digit_1

	cpi r16, 2
	breq digit_2

	cpi r16, 3
	breq digit_3

	cpi r16, 4
	breq digit_4

	cpi r16, 5
	breq digit_5

	cpi r16, 6
	breq digit_6

	cpi r16, 7
	breq digit_7

	cpi r16, 8
	breq digit_8

	cpi r16, 9
	breq digit_9

	digit_0:
		ldi r17, symbol_0
		ret

	digit_1: 
		ldi r17, symbol_1
		ret

	digit_2: 
		ldi r17, symbol_2
		ret

	digit_3:
		ldi r17, symbol_3
		ret

	digit_4:
		ldi r17, symbol_4
		ret

	digit_5:
		ldi r17, symbol_5
		ret

	digit_6:
		ldi r17, symbol_6
		ret

	digit_7:
		ldi r17, symbol_7
		ret

	digit_8:
		ldi r17, symbol_8
		ret

	digit_9:
		ldi r17, symbol_9
		ret

display_clear:
	push r17
	push r18
	ldi r17, 0b00000000
	ldi r18, 0
	rcall transmit_digit
	ldi r17, 0b00000000
	ldi r18, 1
	rcall transmit_digit
	ldi r17, 0b00000000
	ldi r18, 2
	rcall transmit_digit
	ldi r17, 0b00000000
	ldi r18, 3
	rcall transmit_digit
	pop r18
	pop r17
	ret

; displays a circle on the display
display_circle:
	push r17
	push r18
	ldi r17, 0b00111001
	ldi r18, 0
	rcall transmit_digit
	ldi r17, 0b00001001
	ldi r18, 1
	rcall transmit_digit
	ldi r17, 0b00001001
	ldi r18, 2
	rcall transmit_digit
	ldi r17, 0b00001111
	ldi r18, 3
	rcall transmit_digit
	pop r18
	pop r17
	ret


; needs exactly 16 cycles with return and call
prescaler0:
	push r16
	pop r16
	push r16
	pop r16
	cp r16, r17
	ret


; exactly 160 cycles with return and call
prescaler1:
	rcall prescaler0
	rcall prescaler0
	rcall prescaler0
	rcall prescaler0
	rcall prescaler0
	rcall prescaler0
	rcall prescaler0
	rcall prescaler0
	rcall prescaler0
	push r16
	pop r16
	push r16
	pop r16
	cp r16, r17
	ret

; exactly 1607 cycles
prescaler2: 
	rcall prescaler1
	rcall prescaler1
	rcall prescaler1
	rcall prescaler1
	rcall prescaler1
	rcall prescaler1
	rcall prescaler1
	rcall prescaler1
	rcall prescaler1
	rcall prescaler1
	ret

; exactly 16.077 cycles
; exactly 1ms
prescaler3:
	rcall prescaler2
	rcall prescaler2
	rcall prescaler2
	rcall prescaler2
	rcall prescaler2
	rcall prescaler2
	rcall prescaler2
	rcall prescaler2
	rcall prescaler2
	rcall prescaler2
	ret

; pauses a predefined amount of milliseconds
; r24 holds low byte
; r25 holds high byte
; r24 and r25 have to be set to the amount of desired milliseconds
; that wait should pause for
; so you can wait up to 0xffff milliseconds which is 65535ms - about 1 minute
wait:
	push r16
	push r24
	push r25
	ldi r16, 0
	loop2:
		rcall prescaler3
		sbiw r25:r24, 1
		cp r24, r16
		cpc r25, r16
		brne loop2
	pop r25
	pop r24
	pop r16
	ret

; ------------------------- Random Number Helper Methods-------------
; takes the seed/random number in r20 and creates the next one
; with xorshift algorithm inside r20
; so you can obtain the new random number from r20
next:
	push r16

	mov r16, r20 ; move seed into r16
	lsl r16 ; shift left 7
	lsl r16
	lsl r16
	lsl r16
	lsl r16
	lsl r16
	lsl r16
	eor r20, r26

	mov r16, r20 ; move  seed into r16
	lsr r16
	lsr r16
	lsr r16
	lsr r16
	lsr r16
	eor r20, r16

	mov r16, r20 ; move seed into r16
	lsl r16
	lsl r16
	lsl r16
	eor r20, r16

	pop r16
	ret



; ----------------------Display Handling Helper Routinen----------------------

; sends a sequence to 4 digit display
; to signify the start of transmitting one byte
transmit_start:
	sbi PORTD, CLK
	sbi PORTD, DIO
	cbi PORTD, DIO
	cbi PORTD, CLK
	ret

; sends a sequence to 4 digit display
; to signify the end of transmitting one byte
transmit_stop:
	cbi PORTD, CLK
	cbi PORTD, DIO
	sbi PORTD, CLK
	sbi PORTD, DIO
	ret

; transmits the byte stored in r16
transmit_byte:
	;------------transmit bit 0 -----------------------------
	cbi PORTD, CLK ; clk cleared before transmit of every bit

	; send data
	; clear dio if bit 0 in r16 is cleared
	sbrs r16, 0
	cbi PORTD, DIO

	; set dio if bit 0 in r16 is set
	sbrc r16, 0
	sbi PORTD, DIO

	sbi PORTD, CLK ; clk high -> display reads bit here
	;------------transmit bit 0------------------------------

	
	;------------transmit bit 1 -----------------------------
	cbi PORTD, CLK ; clk cleared before transmit of every bit

	; send data
	; clear dio if bit 0 in r16 is cleared
	sbrs r16, 1
	cbi PORTD, DIO

	; set dio if bit 0 in r16 is set
	sbrc r16, 1
	sbi PORTD, DIO

	sbi PORTD, CLK ; clk high -> display reads bit here
	;------------transmit bit 1------------------------------


	;------------transmit bit 2 -----------------------------
	cbi PORTD, CLK ; clk cleared before transmit of every bit

	; send data
	; clear dio if bit 0 in r16 is cleared
	sbrs r16, 2
	cbi PORTD, DIO

	; set dio if bit 0 in r16 is set
	sbrc r16, 2
	sbi PORTD, DIO

	sbi PORTD, CLK ; clk high -> display reads bit here
	;------------transmit bit 2------------------------------


	;------------transmit bit 3 -----------------------------
	cbi PORTD, CLK ; clk cleared before transmit of every bit

	; send data
	; clear dio if bit 0 in r16 is cleared
	sbrs r16, 3
	cbi PORTD, DIO

	; set dio if bit 0 in r16 is set
	sbrc r16, 3
	sbi PORTD, DIO

	sbi PORTD, CLK ; clk high -> display reads bit here
	;------------transmit bit 3------------------------------


	;------------transmit bit 4 -----------------------------
	cbi PORTD, CLK ; clk cleared before transmit of every bit

	; send data
	; clear dio if bit 0 in r16 is cleared
	sbrs r16, 4
	cbi PORTD, DIO

	; set dio if bit 0 in r16 is set
	sbrc r16, 4
	sbi PORTD, DIO

	sbi PORTD, CLK ; clk high -> display reads bit here
	;------------transmit bit 4------------------------------


	;------------transmit bit 5 -----------------------------
	cbi PORTD, CLK ; clk cleared before transmit of every bit

	; send data
	; clear dio if bit 0 in r16 is cleared
	sbrs r16, 5
	cbi PORTD, DIO

	; set dio if bit 0 in r16 is set
	sbrc r16, 5
	sbi PORTD, DIO

	sbi PORTD, CLK ; clk high -> display reads bit here
	;------------transmit bit 5------------------------------


	;------------transmit bit 6 -----------------------------
	cbi PORTD, CLK ; clk cleared before transmit of every bit

	; send data
	; clear dio if bit 0 in r16 is cleared
	sbrs r16, 6
	cbi PORTD, DIO

	; set dio if bit 0 in r16 is set
	sbrc r16, 6
	sbi PORTD, DIO

	sbi PORTD, CLK ; clk high -> display reads bit here
	;------------transmit bit 6------------------------------


	;------------transmit bit 7------------------------------
	cbi PORTD, CLK ; clk cleared before transmit of every bit

	; send data
	; clear dio if bit 0 in r16 is cleared
	sbrs r16, 7
	cbi PORTD, DIO

	; set dio if bit 0 in r16 is set
	sbrc r16, 7
	sbi PORTD, DIO

	sbi PORTD, CLK ; clk high -> display reads bit here
	;------------transmit bit 7------------------------------


	; Acknowledge Handling
	cbi PORTD, CLK
	sbi PORTD, DIO
	sbi PORTD, CLK

	push r16
	push r17
	ldi r16, 0
	ldi r17, 200
	loop: ; wait for DIO bit to drop back to 0 (max 200 iterations)
		cbi DDRD, DIO ; set DIO back to input to receive ack
		inc r16

		; exit loop if dio dropped to 0
		sbis PORTD, DIO
		rjmp finish

		; finish loop if 200 iterations are done
		cp r16, r17
		brne loop
		sbi DDRD, DIO ; set DIO to output
		cbi PORTD, DIO ; send 0
		;cbi DDRD, DIO ; set DIO back to input to receive ack maybe needed not sure

	finish:
		sbi DDRD, DIO ; set DIO back to output
		pop r17
		pop r16
		ret

; transmits the digit stored in r17
; to 4 digit display at the nth position
; n can be set in r18
transmit_digit:
	push r16

	; select address mode
	rcall transmit_start
	ldi r16, ADDR_FIXED
	rcall transmit_byte
	rcall transmit_stop

	; send digit address and digit data
	rcall transmit_start
	; send digit address
	ldi r16, ADDR_START
	add r16, r18 ; set address
	rcall transmit_byte
	; send digit data
	mov r16, r17
	rcall transmit_byte
	rcall transmit_stop

	; select brightness
	rcall transmit_start
	ldi r16, brightness
	rcall transmit_byte
	rcall transmit_stop

	pop r16
	ret
