PUBLIC MOVE_CARS
  PUBLIC DRAW_CARS
.model small
.stack 64
.data
  img DB 184, 113, 6, 137, 233, 184, 113, 6, 137, 136, 235, 6, 41, 137, 21, 235, 6, 41, 137, 21, 170, 161, 138, 163, 170, 244, 27, 75, 74, 20, 113, 137, 163, 138, 137, 112, 4, 6, 6, 136 
      DB 185, 113, 113, 111, 209
  TIME_AUX  DB 0          ; Used when checking if time has changed

  CAR_WIDTH EQU 03h       ; The width of all cars
  CAR_HEIGHT EQU 07h      ; The height of all cars
  CAR1_X DW 0Ah           ; X position of the 1st player
  CAR1_Y DW 0Ah           ; Y position of the 1st player
  CAR1_VELOCITY_X  DW 2
  CAR1_VELOCITY_Y  DW 2
  CAR1_ACCELERATION_X DB 1
  CAR1_ACCELERATION_Y DB 1
  CAR2_X DW 0AAh           ; X position of the 1st player
  CAR2_Y DW 0AAh           ; Y position of the 1st player
  CAR2_VELOCITY_X  DW 2
  CAR2_VELOCITY_Y  DW 2
  CAR2_ACCELERATION_X DB 1
  CAR2_ACCELERATION_Y DB 1

             ; Normal Shift  CTRL   ALT
  CAR1_KEYS DW 4800h, 4838h, 8D00h, 9800h       ; UP ARROW
            DW 5000h, 5032h, 9100h, 0A000h      ; DOWN ARROW
            DW 4D00h, 4D36h, 7400h, 9D00h       ; RIGHT ARROW
            DW 4B00h, 4B34h, 7300h, 9B00h       ; LEFT ARROW
            DW 0000h    ; NONE

             ; Normal Shift  CTRL   ALT
  CAR2_KEYS DW 1177h, 1157h, 1117h, 1100h       ; W
            DW 1F73h, 1F53h, 1F13h, 1F00h       ; S
            DW 2064h, 2044h, 2004h, 2000h       ; D
            DW 1E61h, 1E41h, 1E01h, 1E00h       ; A
            DW 0000h    ; NONE
.code
;-------------------------------------------------------
; (Send to CAR file)
MOVE_CARS proc far
  PUSH ES
  mov AX, @data
  mov ES, AX
  call READ_BUFFER
  jz EXIT                 ; ZF = 1 if no key is being pressed
  ; Player One
  call MOVE_CAR_1
  cmp CX, 0               ; Key may be associated with player two
  jz SKIP_READ
  call READ_BUFFER
  jz EXIT                 ; ZF = 1 if no key is being pressed
  SKIP_READ:
  ; Player Two
  call MOVE_CAR_2

  ; reset Keyboard Buffer
  mov AH, 0Ch
  int 21h

  EXIT:
  POP ES
    ret
MOVE_CARS endp
;-------------------------------------------------------
MOVE_CAR_1 proc near
  ; Check if key is wanted
  lea DI, CAR1_KEYS
  MOV CX, 17              ; Number of car1 keys
  repne SCASW             ; Search for AX in CAR1_KEYS

  cmp CX, 0
  jz EXIT_1
  cmp CX, 4
  jng MOVE_LEFT_1
  cmp CX, 8
  jng MOVE_RIGHT_1
  cmp CX, 12
  jng MOVE_DOWN_1
  jmp MOVE_UP_1
  MOVE_UP_1:
    mov AX, CAR1_VELOCITY_Y
    sub CAR1_Y, AX
    jmp EXIT_1

  MOVE_DOWN_1:
    mov AX, CAR1_VELOCITY_Y
    add CAR1_Y, AX
    jmp EXIT_1

  MOVE_RIGHT_1:
    mov AX, CAR1_VELOCITY_X
    add CAR1_X, AX
    jmp EXIT_1

  MOVE_LEFT_1:
    mov AX, CAR1_VELOCITY_X
    sub CAR1_X, AX
    jmp EXIT_1

  EXIT_1:
    ret
MOVE_CAR_1 endp
;-------------------------------------------------------
MOVE_CAR_2 proc near
  ;Check if key is wanted
  lea DI, CAR2_KEYS
  MOV CX, 17              ; Number of car1 keys
  repne SCASW             ; Search for AX in CAR1_KEYS
  cmp CX, 0
  jz EXIT_2
  cmp CX, 4
  jng MOVE_LEFT_2
  cmp CX, 8
  jng MOVE_RIGHT_2
  cmp CX, 12
  jng MOVE_DOWN_2
  jmp MOVE_UP_2
  MOVE_UP_2:
    mov AX, CAR2_VELOCITY_Y
    sub CAR2_Y, AX
    jmp EXIT_2

  MOVE_DOWN_2:
    mov AX, CAR2_VELOCITY_Y
    add CAR2_Y, AX
    jmp EXIT_2

  MOVE_RIGHT_2:
    mov AX, CAR2_VELOCITY_X
    add CAR2_X, AX
    jmp EXIT_2

  MOVE_LEFT_2:
    mov AX, CAR2_VELOCITY_X
    sub CAR2_X, AX
    jmp EXIT_2

  EXIT_2:
    ret
MOVE_CAR_2 endp
;-------------------------------------------------------
READ_BUFFER proc near
  ; Check if any key is being pressed (if not exit)
  mov AH, 1
  int 16h
  jz  BUFFER_EMPTY        ; ZF = 1 if no key is being pressed
  ; Get the pressed keys
  mov AH, 0
  int 16h
  BUFFER_EMPTY:
    ret
READ_BUFFER endp
;-------------------------------------------------------
DRAW_CARS proc far
  mov CX, CAR1_X    ; Set initial column (X)
  mov DX, CAR1_Y    ; Set initial row (Y)
  call DRAW_CAR

  mov CX, CAR2_X    ; Set initial column (X)
  mov DX, CAR2_Y    ; Set initial row (Y)
  call DRAW_CAR
  ret
DRAW_CARS endp
;-------------------------------------------------------
DRAW_CAR proc near
    lea si,img  ;load image adress
    mov AX, DX
    mov BX, 320
    mul BX
    add AX, CX
    mov di, AX   ;load adress  (CX + DX * 320)
    mov bx, 9 ;number of rows 
cols:
    call DRAW_row
    add di,315
    dec bx ;check if end condition
    cmp bx,0
    jnz cols

    ret
DRAW_CAR endp
;-------------------------------------------------------;
DRAW_row proc near
    mov cx,5 ;size of all pixels
    rep movsb
    ret
DRAW_row endp
end