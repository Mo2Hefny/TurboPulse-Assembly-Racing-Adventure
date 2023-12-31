  PUBLIC CONFIG_PORT
  PUBLIC SEND_INPUT
  PUBLIC WAIT_TILL_SEND
  PUBLIC SEND_WORD
  PUBLIC WAIT_TILL_SEND_WORD
  PUBLIC SERIAL_STATUS
  PUBLIC SEND
.model compact
.stack 64
.data
EXIT equ 1bh
TIME_AUX db 0
buffer db 2, ?, 2 dup('$')
msg db 2, ?, 2 dup('$')
UPDATED db 0
LEAVE db 0
SERIAL_STATUS  DB 0                                           ; 00000001[waiting to send]
SEND           DB -1
;UPDATED2 db 0
X db 1, 41
Y db 1, 1
.code
;----------------------------------------------------------
CONFIG_PORT proc far
  ;Set Divisor Latch Access Bit
  mov dx,3fbh 			; Line Control Register
  mov al,10000000b		;Set Divisor Latch Access Bit
  out dx,al			;Out it
  ;Set LSB byte of the Baud Rate Divisor Latch register.
  mov dx,3f8h			
  mov al,0ch			
  out dx,al
  ;Set MSB byte of the Baud Rate Divisor Latch register.
  mov dx,3f9h
  mov al,00h
  out dx,al
  ;Set port configuration
  mov dx,3fbh
  mov al,00011011b
  ; 0:Access to Receiver buffer, Transmitter buffer
  ; 0:Set Break disabled
  ; 011:Even Parity
  ; 0:One Stop Bit
  ; 11:8bits
  out dx,al
  ret
CONFIG_PORT endp
;----------------------------------------------------------
SEND_INPUT proc far             ; ZF = 1 if nothing RECEIVED, 0 otherwise
  push DX
  push AX
  ;Check that Transmitter Holding Register is Empty
	mov dx, 3FDH		; Line Status Register
  In al , dx 			;Read Line Status
  AND al , 00100000b
  JZ EXIT_SEND_INPUT

  ;If empty put the VALUE in Transmit data register
  mov dx , 3F8H		; Transmit data register
  mov al ,SEND
  out dx , al
  MOV AL, 0
  ADD AL, 1
  EXIT_SEND_INPUT:
  pop AX
  pop DX
  ret 
SEND_INPUT endp
;----------------------------------------------------------
WAIT_TILL_SEND proc far
  DIDNT_SEND:
  call SEND_INPUT
  jz DIDNT_SEND
  ret
WAIT_TILL_SEND endp
;----------------------------------------------------------
SEND_WORD proc far
  mov SEND, AL
  call SEND_INPUT
  jz EXIT_SEND_WORD
  mov SEND, AH
  call WAIT_TILL_SEND
  EXIT_SEND_WORD:
  ret
SEND_WORD endp
;----------------------------------------------------------
WAIT_TILL_SEND_WORD proc far
  DIDNT_SEND_WORD:
  call SEND_WORD
  jz DIDNT_SEND_WORD
  ret
WAIT_TILL_SEND_WORD endp
;----------------------------------------------------------
end