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
.code
;-------------------------------------------------------
; (Send to CAR file)
MOVE_CARS proc far
  ; Player One
  ; Check if any key is being pressed (if not exit)
  mov AH, 1
  int 16h
  jz  MOVE_CAR_2         ; ZF = 0 if no key is being pressed

  ; Get the pressed keys
  mov AH, 0
  int 16h                 ; AL = key ascii code
  PUSH AX
  mov AH, 0Ch
  int 21h
  POP AX
  ; If key is UP ARROW to move up
  cmp AX, 4800h           ; Normal
  jz MOVE_UP
  cmp AX, 4838h           ; Shifted 
  jz MOVE_UP
  cmp AX, 8D00h           ; w/CTRL 
  jz MOVE_UP
  cmp AX, 9800h           ; w/Alt 
  jz MOVE_UP
  ; If key is DOWN ARROW to move down
  cmp AX, 5000h           ; Normal
  jz MOVE_DOWN
  cmp AX, 5032h           ; Shifted 
  jz MOVE_DOWN
  cmp AX, 9100h           ; w/CTRL 
  jz MOVE_DOWN
  cmp AX, 0A000h          ; w/Alt 
  jz MOVE_DOWN
  jmp CHECK_CAR_2
  MOVE_UP:
    mov AX, CAR1_VELOCITY_Y
    sub CAR1_Y, AX
    jmp MOVE_CAR_2

  MOVE_DOWN:
    mov AX, CAR1_VELOCITY_Y
    add CAR1_Y, AX
    jmp MOVE_CAR_2

  MOVE_CAR_2:
  ; Check if any key is being pressed (if not exit)
  mov AH, 1
  int 16h
  jz  EXIT_PROC           ; ZF = 0 if no key is being pressed

  ; Get the pressed keys
  mov AH, 0
  int 16h                 ; AL = key ascii code
  PUSH AX
  mov AH, 0Ch
  int 21h
  POP AX
  CHECK_CAR_2:
  ; If key is 'w' or 'W' move up
  cmp AX, 1177h           ; Normal
  jz MOVE_CAR2_UP
  cmp AX, 1157h           ; Shifted 
  jz MOVE_CAR2_UP
  cmp AX, 1117h           ; w/CTRL 
  jz MOVE_CAR2_UP
  cmp AX, 1100h           ; w/Alt 
  jz MOVE_CAR2_UP
  ; If key is 's' or 'S' move down
  cmp AX, 1F73h           ; Normal
  jz MOVE_CAR2_DOWN
  cmp AX, 1F53h           ; Shifted 
  jz MOVE_CAR2_DOWN
  cmp AX, 1F13h           ; w/CTRL 
  jz MOVE_CAR2_DOWN
  cmp AX, 1F00h           ; w/Alt 
  jz MOVE_CAR2_DOWN
  jmp EXIT_PROC
  MOVE_CAR2_UP:
    mov AX, CAR2_VELOCITY_Y
    sub CAR2_Y, AX
    jmp EXIT_PROC

  MOVE_CAR2_DOWN:
    mov AX, CAR2_VELOCITY_Y
    add CAR2_Y, AX
    jmp EXIT_PROC
  EXIT_PROC:
    ret
MOVE_CARS endp
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
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DRAW_row proc near
    mov cx,5 ;size of all pixels
    rep movsb
    ret
DRAW_row endp
end