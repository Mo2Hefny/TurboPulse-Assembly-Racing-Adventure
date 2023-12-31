  PUBLIC RECEIVE_INPUT
  PUBLIC WAIT_TILL_RECEIVE
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
  JZ EXIT_Receive_DATA

  ;If Ready read the VALUE in Receive data register
  mov dx , 03F8H
  in al , dx 
  mov RECEIVED , al
  MOV AL, 0
  ADD AL, 1
  EXIT_Receive_DATA:
  pop AX
  pop DX
  ret
RECEIVE_INPUT endp
;----------------------------------------------------------
WAIT_TILL_RECEIVE proc far
  DIDNT_Receive:
  call RECEIVE_INPUT
  jz DIDNT_Receive
  ret
WAIT_TILL_RECEIVE endp
;----------------------------------------------------------
end