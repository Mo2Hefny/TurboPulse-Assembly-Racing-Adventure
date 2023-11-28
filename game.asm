.model small
.stack 64
.data
  TIME_AUX  DB 0          ; Used when checking if time has changed

  CAR_WIDTH EQU 03h       ; The width of all cars
  CAR_HEIGHT EQU 07h      ; The height of all cars
  CAR1_X DW 0Ah           ; X position of the 1st player
  CAR1_Y DW 0Ah           ; Y position of the 1st player
  CAR1_VELOCITY_X  DW 2
  CAR1_VELOCITY_Y  DW 2
.code
main proc far

  mov AX, @data
  mov DS, AX

  ; Initialize Video Mode
  mov AX, 0013h           ; Select 320x200, 256 color graphics
  int 10h
  
  

  ; Get the systen time
  CHECK_TIME:
    mov AH, 2Ch
    int 21h                 ; CH = hour CL = minute DH - second DL = 1/100 seconds
    cmp DL, TIME_AUX        ; fps = 100
    je  CHECK_TIME          ; repeat till time frame changes
  ; Else draw the new frame
  call RESET_BACKGROUND
  ; Draw Cars
  call MOVE_CARS
  call DRAW_CARS
  
  ; Repeat the process
  jmp CHECK_TIME

  ; Terminate Program
  mov ah, 9
  int 21h

main endp
;-------------------------------------------------------
RESET_BACKGROUND proc near
  ; (Send to TRACK file)
  ; Set background color to WHITE
  mov AH, 06h             ; Scroll up function
  xor AL, AL              ; Clear entire screen
  xor CX, CX              ; Upper left corner CH=row, CL=column
  mov DX, 184Fh           ; lower right corner DH=row, DL=column 
  mov BH, 1Eh             ; YellowOnBlue
  int 10h
  ret
RESET_BACKGROUND endp
;-------------------------------------------------------
MOVE_CARS proc near
  ; Player One
  ; Check if any key is being pressed (if not exit)
  mov AH, 1
  int 16h
  jz  EXIT_PROC           ; ZF = 0 if no key is being pressed

  ; Get the pressed keys
  mov AH, 0
  int 16h                 ; AL = key ascii code

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
  jz CHECK_CAR_2
  MOVE_UP:
    mov AX, CAR1_VELOCITY_Y
    sub CAR1_Y, AX
    jmp CHECK_CAR_2

  MOVE_DOWN:
    mov AX, CAR1_VELOCITY_Y
    add CAR1_Y, AX
    jmp CHECK_CAR_2

  CHECK_CAR_2:
  EXIT_PROC:
    ret
MOVE_CARS endp
;-------------------------------------------------------
; (Send to CAR file)
DRAW_CARS proc near
  mov CX, CAR1_X    ; Set initial column (X)
  mov DX, CAR1_Y    ; Set initial row (Y)
  DRAW_CARS_VERTICAL:
    mov AH, 0Ch           ; Set the configuration to writing a pixel
    mov AL, 00h           ; Choose Black as color
    mov BH, 00h           ; Set the page number
    int 10h
    inc DX
    ; Check if DX - CAR1_Y > CAR_HEIGHT
    mov AX, DX
    sub AX, CAR1_Y
    cmp AX, CAR_HEIGHT
    jng DRAW_CARS_VERTICAL
  
  mov DX, CAR1_Y    ; Reset to the initial row (Y)
  inc CX            ; Go to the next column
  ; Check if CX - CAR1_X > CAR_WIDTH
  mov AX, CX
  sub AX, CAR1_X
  cmp AX, CAR_WIDTH
  jng DRAW_CARS_VERTICAL
  ret
DRAW_CARS endp
;-------------------------------------------------------
end main