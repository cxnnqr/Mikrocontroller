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


sbi DDRD, 3
start:
	sbi PORTD, 3
	rcall wait
	cbi PORTD, 3
	rcall wait
	rjmp start
	

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

wait:
	push r16
	push r24
	push r25
	ldi r16, 0
	ldi r24, 0xff
	ldi r25, 0xff
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










init_display:
	sbi DDRD, CLK
	sbi DDRD, DIO

start2:
	ldi r17, symbol_8
	ldi r18, 0
	rcall transmit_digit
	ldi r17, symbol_8
	ldi r18, 1
	rcall transmit_digit
	ldi r17, symbol_8
	ldi r18, 2
	rcall transmit_digit
	ldi r17, symbol_8
	ldi r18, 3
	rcall transmit_digit
	rjmp start



; ------------------------- Random Number Helper Methods-------------
static uint8_t y8 = 1;

uint8_t xorshift8(void) {
    y8 ^= (y8 << 7);
    y8 ^= (y8 >> 5);
    return y8 ^= (y8 << 3);
}
; seed is always in r20
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
	push r16
	push r17
    ldi r17, 8
	loop_for_8:
		cbi PORTD, CLK ; clk cleared before transmit of every bit

		; send data
		; clear dio if bit 0 in r16 is cleared
		sbrs r16, 0
		cbi PORTD, DIO

		; set dio if bit 0 in r16 is set
		sbrc r16, 0
		sbi PORTD, DIO

		sbi PORTD, CLK ; clk high -> display reads bit here

		; loop handling
		lsr r16
		dec r17
		brne loop_for_8
	
	; Acknowledge Handling
	cbi PORTD, CLK
	sbi PORTD, DIO
	sbi PORTD, CLK

	ldi r16, 0
	ldi r17, 200
	loop: ; wait for DIO bit to drop back to 0 (max 200 iterations)
		cbi DDRD, DIO ; set DIO back to input to receive ack

		; exit loop if dio dropped to 0
		sbis PORTD, DIO
		rjmp finish


		; finish loop if 200 iterations are done
		dec r17
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
