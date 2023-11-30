  PUBLIC MOVE_CARS
  PUBLIC DRAW_CARS
.model small
.stack 64
.data
  img1 DB 184, 113, 113, 6, 137, 209, 185, 113, 6, 6, 137, 232, 185, 113, 6, 6, 137, 234, 244, 136, 41, 41, 138, 21, 244, 136, 41, 41, 138, 21, 170, 161, 137, 137, 23, 170, 19, 3, 75, 75 
       DB 74, 19, 185, 160, 25, 25, 163, 234, 112, 6, 6, 6, 6, 136, 184, 113, 6, 6, 137, 210, 185, 113, 113, 113, 113, 185
  
  img2 DB 17, 222, 151, 150, 151, 223, 18, 128, 151, 150, 151, 223, 223, 128, 175, 175, 150, 246, 244, 150, 174, 174, 149, 244, 244, 150, 174, 174, 149, 244, 148, 148, 149, 149, 172, 148, 221, 3, 75, 75 
       DB 74, 221, 223, 148, 3, 3, 172, 246, 223, 150, 175, 175, 174, 151, 223, 151, 150, 150, 150, 223, 200, 223, 223, 223, 223, 200
       


  CAR_WIDTH EQU 06h       ; The width of all cars
  CAR_HEIGHT EQU 0Bh      ; The height of all cars
  CAR_SPEED EQU 5
  ACCELERATION_INCREASE EQU 3
  ACCELERATION_DECREASE EQU 3
  MAX_ACCELERATION EQU 10
  GAME_BORDER_X EQU 320
  GAME_BORDER_Y EQU 00A0h
  CAR1_X DW 0Ah           ; X position of the 1st player
  CAR1_Y DW 0Ah           ; Y position of the 1st player
  CAR1_DIR DB 0           ; 0 UP, 1 DOWN, 2 RIGHT, 3 LEFT
  CAR1_VELOCITY_X  DW CAR_SPEED
  CAR1_VELOCITY_Y  DW CAR_SPEED
  CAR1_ACCELERATION_X DW 0
  CAR1_ACCELERATION_Y DW 0
  CAR2_X DW 0             ; X position of the 1st player
  CAR2_Y DW 0             ; Y position of the 1st player
  CAR2_DIR DB 0           ; 0 UP, 1 DOWN, 2 RIGHT, 3 LEFT
  CAR2_VELOCITY_X  DW CAR_SPEED
  CAR2_VELOCITY_Y  DW CAR_SPEED
  CAR2_ACCELERATION_X DW 0
  CAR2_ACCELERATION_Y DW 0

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
  ; Horizontal Movement
  mov DX, CAR1_VELOCITY_X
  lea BX, CAR1_DIR
  lea DI, CAR1_X
  jng MOVE_LEFT_1
  cmp CX, 8
  jng MOVE_RIGHT_1
  ; Vertical Movement
  mov DX, CAR1_VELOCITY_Y
  lea BX, CAR1_DIR
  lea DI, CAR1_Y
  cmp CX, 12
  jng MOVE_DOWN_1
  jmp MOVE_UP_1
  MOVE_UP_1:
    call MOVE_UP
    jmp EXIT_1

  MOVE_DOWN_1:
    call MOVE_DOWN
    jmp EXIT_1

  MOVE_RIGHT_1:
    call MOVE_RIGHT
    jmp EXIT_1

  MOVE_LEFT_1:
    call MOVE_LEFT
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
  ; Horizontal Movement
  mov DX, CAR2_VELOCITY_X
  lea BX, CAR2_DIR
  lea DI, CAR2_X
  cmp CX, 4
  jng MOVE_LEFT_2
  cmp CX, 8
  jng MOVE_RIGHT_2
  ; Vertical Movement
  mov DX, CAR2_VELOCITY_Y
  lea BX, CAR2_DIR
  lea DI, CAR2_Y
  cmp CX, 12
  jng MOVE_DOWN_2
  jmp MOVE_UP_2
  MOVE_UP_2:
    call MOVE_UP
    jmp EXIT_2

  MOVE_DOWN_2:
    call MOVE_DOWN
    jmp EXIT_2

  MOVE_RIGHT_2:
    call MOVE_RIGHT
    jmp EXIT_2

  MOVE_LEFT_2:
    call MOVE_LEFT
    jmp EXIT_2

  EXIT_2:
    ret
MOVE_CAR_2 endp
;-------------------------------------------------------
MOVE_UP proc near             ; DX: Velocity, [BX]: Direction, [DI]: Car_Y
    ; Position = Position + (Velocity + Boost) * Acceleration
    ; Add = (Velocity + Boost) * Acceleration
    mov AL, 0                 ; Store Car Direction
    mov [BX], AL              ; Store Car Direction
    cmp DX, [DI]              ; Point < Car_Y    
    jl SKIP_UP_FIX
      mov [DI], DX
    SKIP_UP_FIX:
    sub [DI], DX
    ret
MOVE_UP endp
;-------------------------------------------------------
MOVE_DOWN proc near           ; DX: Velocity, [BX]: Direction, [DI]: Car_Y
    add [DI], DX
    mov AL, 1
    mov [BX], AL
    mov AX, GAME_BORDER_Y - 1 - CAR_HEIGHT
    cmp [DI], AX
    jng SKIP_DOWN_FIX
      mov [DI], AX
    SKIP_DOWN_FIX:
    ret
MOVE_DOWN endp
;-------------------------------------------------------
MOVE_RIGHT proc near          ; DX: Velocity, [BX]: Direction, [DI]: Car_X
    add [DI], DX              ; DI = CAR_X
    mov AL, 2                 ; Store Car Direction
    mov [BX], AL              ; Store Car Direction
    mov AX, GAME_BORDER_X - 1 - CAR_HEIGHT 
    cmp [DI], AX           
    jng SKIP_RIGHT_FIX
      mov [DI], AX
    SKIP_RIGHT_FIX:
    ret
MOVE_RIGHT endp
;-------------------------------------------------------
MOVE_LEFT proc near           ; DX: Velocity, [BX]: Direction, [DI]: Car_X
    mov AL, 3                 ; Store Car Direction
    mov [BX], AL              ; Store Car Direction
    cmp DX, [DI]              ; DI = CAR_X
    jl SKIP_LEFT_FIX
      mov [DI], DX
    SKIP_LEFT_FIX:
    sub [DI], DX
    ret
MOVE_LEFT endp
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
  lea si, img1      ;load image adress
  mov BL, CAR1_DIR  ; Set Face Direction
  call DRAW_CAR

  mov CX, CAR2_X    ; Set initial column (X)
  mov DX, CAR2_Y    ; Set initial row (Y)
  lea si, img2      ;load image adress
  mov BL, CAR2_DIR  ; Set Face Direction
  call DRAW_CAR
  ret
DRAW_CARS endp
;-------------------------------------------------------
DRAW_CAR proc near
    mov AX, 320
    cmp BL, 1
    jng  SKIP_DX_ADDITION ; Horizontal
    add DX, CAR_WIDTH
    SKIP_DX_ADDITION:
    mul DX
    add AX, CX
    mov DI, AX            ; load adress  (CX + DX * 320)
    mov DX, CAR_HEIGHT    ; number of rows
    cmp BL, 1             
    jz SKIP_REVERSING     ; Facing Down
    cmp BL, 2             
    jz SKIP_REVERSING     ; Facing Right
    add SI, CAR_HEIGHT * CAR_WIDTH - 1
    SKIP_REVERSING:
DRAW_HEIGHT:
    ; Draw Width
    mov CX, CAR_WIDTH     ; size of Width
    TRANSFER:
        ;cmp SI, 0         ; Pixel is Transparent
        ;jz  TRANSPARENT
        MOVSB
        cmp BL, 1
        jng  SKIP_DI_ADDITION   ; Horizontal
        sub DI, 321
        SKIP_DI_ADDITION:
        ;TRANSPARENT:
        cmp BL, 1             
        jz SKIP_SUBBING     ; Facing Down
        cmp BL, 2            
        jz SKIP_SUBBING     ; Facing Right
        sub SI, 2
        SKIP_SUBBING:
        loop TRANSFER
    ; Go to next Row
    add DI, 314
    cmp BL, 1
    jng  NEXT_BAR   ; Horizontal
    inc AX
    mov DI, AX
    NEXT_BAR:
    dec DX                ; check if end condition
    cmp DX, 0
    jnz DRAW_HEIGHT

    ret
DRAW_CAR endp
;-------------------------------------------------------;
end