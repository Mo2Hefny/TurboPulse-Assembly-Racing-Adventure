  PUBLIC RECEIVE_INPUT
  PUBLIC WAIT_TILL_RECEIVE
  PUBLIC RECIEVE_WORD
  PUBLIC WAIT_TILL_RECEIVE_WORD
  PUBLIC RECEIVED
.model compact
.stack 64
.data
RECEIVED db -1
.code
RECEIVE_INPUT proc far          ; ZF = 1 if nothing RECEIVED, 0 otherwise
  push DX
  push AX
  ;Check that Data Ready
	mov dx , 3FDH		; Line Status Register
	in al , dx 
  AND al , 1
  JZ EXIT_RECEIVE_DATA

  ;If Ready read the VALUE in Receive data register
  mov dx , 03F8H
  in al , dx 
  mov RECEIVED , al
  MOV AL, 0
  ADD AL, 1
  EXIT_RECEIVE_DATA:
  pop AX
  pop DX
  ret
RECEIVE_INPUT endp
;----------------------------------------------------------
WAIT_TILL_RECEIVE proc far
  DIDNT_RECEIVE:
  call RECEIVE_INPUT
  jz DIDNT_RECEIVE
  ret
WAIT_TILL_RECEIVE endp
;----------------------------------------------------------
RECIEVE_WORD proc far
  call RECEIVE_INPUT
  jz EXIT_RECIEVE_WORD
  mov AL, RECEIVED
  call WAIT_TILL_RECEIVE
  mov AH, RECEIVED
  EXIT_RECIEVE_WORD:
  ret
RECIEVE_WORD endp
;----------------------------------------------------------
WAIT_TILL_RECEIVE_WORD proc far
  DIDNT_RECEIVE_WORD:
  call RECIEVE_WORD
  jz DIDNT_RECEIVE_WORD
  ret
WAIT_TILL_RECEIVE_WORD endp
;----------------------------------------------------------
end