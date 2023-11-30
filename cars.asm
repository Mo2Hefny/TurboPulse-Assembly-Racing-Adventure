  EXTRN TIME_AUX:BYTE
  PUBLIC MOVE_CARS
  PUBLIC DRAW_CARS
.model small
.stack 64
.data
  ; Red Car
  img1 DB 184, 113, 113, 6, 137, 209, 185, 113, 6, 6, 137, 232, 185, 113, 6, 6, 137, 234, 244, 136, 41, 41, 138, 21, 244, 136, 41, 41, 138, 21, 170, 161, 137, 137, 23, 170, 19, 3, 75, 75 
       DB 74, 19, 185, 160, 25, 25, 163, 234, 112, 6, 6, 6, 6, 136, 184, 113, 6, 6, 137, 210, 185, 113, 113, 113, 113, 185
  ; Blue Car
  img2 DB 17, 222, 151, 150, 151, 223, 18, 128, 151, 150, 151, 223, 223, 128, 175, 175, 150, 246, 244, 150, 174, 174, 149, 244, 244, 150, 174, 174, 149, 244, 148, 148, 149, 149, 172, 148, 221, 3, 75, 75 
       DB 74, 221, 223, 148, 3, 3, 172, 246, 223, 150, 175, 175, 174, 151, 223, 151, 150, 150, 150, 223, 200, 223, 223, 223, 223, 200
       
  ; Constants
  CAR_WIDTH EQU 06h       ; The width of all cars
  CAR_HEIGHT EQU 0Bh      ; The height of all cars
  CAR_SPEED EQU 3
  ACCELERATION_INCREASE EQU 2
  ACCELERATION_DECREASE EQU 1
  MAX_ACCELERATION EQU 18
  GAME_BORDER_X EQU 320
  ;GAME_BORDER_Y EQU 00A0h
  GAME_BORDER_Y EQU 200
  UP EQU 0
  DOWN EQU 1
  RIGHT EQU 2
  LEFT EQU 3

  ; Variables
  OLD_TIME_AUX DB 0

  CAR1_X DW 0Ah           ; X position of the 1st player
  CAR1_Y DW 5Ah           ; Y position of the 1st player
  CAR1_IMG_DIR DB UP
  CAR1_MOVEMENT_DIR DB UP
  CAR1_ACCELERATION DW 0

  CAR2_X DW 2Fh             ; X position of the 2nd player
  CAR2_Y DW 5Ah             ; Y position of the 2nd player
  CAR2_IMG_DIR DB UP
  CAR2_MOVEMENT_DIR DB UP
  CAR2_ACCELERATION DW 0

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
MOVE_CARS proc far
  PUSH ES
  mov AX, @data
  mov ES, AX
  mov CX, 0
  call READ_BUFFER
  ;jz SKIP_INPUT_CHECK         ; ZF = 1 if no key is being pressed

  ; Player One
  lea DI, CAR1_KEYS
  lea BX, CAR1_IMG_DIR
  lea SI, CAR1_MOVEMENT_DIR
  call CHECK_INPUT            ; Stores status in CX
  lea DI, CAR1_ACCELERATION
  call HANDLE_ACCELERATION
  ; Move PLayer One
  mov AL, CAR1_IMG_DIR
  lea DI, CAR1_X
  lea SI, CAR1_Y
  call MOVE_CAR

  ; Key may be associated with player two
  cmp CX, 0                   ; Key didn't belong to player one
  jz SKIP_READ
  call READ_BUFFER
  jz EXIT_MOVE_CARS           ; ZF = 1 if no key is being pressed
  SKIP_READ:

  ; Player Two
  lea DI, CAR2_KEYS
  lea BX, CAR2_IMG_DIR
  lea SI, CAR2_MOVEMENT_DIR
  call CHECK_INPUT            ; Stores status in CX
  lea DI, CAR2_ACCELERATION
  call HANDLE_ACCELERATION
  ; Move PLayer Two
  mov AL, CAR2_IMG_DIR
  lea DI, CAR2_X
  lea SI, CAR2_Y
  call MOVE_CAR

  ; reset Keyboard Buffer
  mov AH, 0Ch
  int 21h

  EXIT_MOVE_CARS:
  POP ES
  mov AL, TIME_AUX
  mov OLD_TIME_AUX, AL
  ret
MOVE_CARS endp
;-------------------------------------------------------
CHECK_INPUT proc near         ; [DI]: CAR_KEYS_TO_CHECK, [BX]: IMG_DIR, [SI]: MOVEMENT_DIR
  MOV CX, 17              ; Number of car input keys
  repne SCASW             ; Search for AX in CAR_KEYS
  mov AL, [BX]
  mov AH, [SI]
  cmp CX, 0
  jz EXIT_CHECK_INPUT
  ; Horizontal Movement

  cmp CX, 4
  jg CHECK_IF_RIGHT
  ; MOVING LEFT
  mov AH, LEFT
  cmp AL, RIGHT
  jz  EXIT_CHECK_INPUT        ; Can't rotate from Right to Left directly
  mov AL, LEFT
  jmp EXIT_CHECK_INPUT

  CHECK_IF_RIGHT:
  cmp CX, 8
  jg CHECK_IF_DOWN
  ; MOVING RIGHT
  mov AH, RIGHT
  cmp AL, LEFT
  jz  EXIT_CHECK_INPUT        ; Can't rotate from Left to Right directly
  mov AL, RIGHT
  jmp EXIT_CHECK_INPUT

  CHECK_IF_DOWN:
  ; Vertical Movement
  cmp CX, 12
  jg CHECK_IF_UP
  ; MOVING DOWN
  mov AH, DOWN
  cmp AL, UP
  jz  EXIT_CHECK_INPUT        ; Can't rotate from Up to Down directly
  mov AL, DOWN
  jmp EXIT_CHECK_INPUT

  CHECK_IF_UP:
  ; MOVING UP
  mov AH, UP
  cmp AL, DOWN
  jz  EXIT_CHECK_INPUT        ; Can't rotate from DOWN to UP directly
  mov AL, UP

  EXIT_CHECK_INPUT:
  mov [BX], AL
  mov [SI], AH
  ret
CHECK_INPUT endp
;-------------------------------------------------------
HANDLE_ACCELERATION proc near           ; [DI]: CAR_ACCELERATION, [BX]: IMG_DIR, [SI]: MOVEMENT_DIR
  cmp CX, 0
  jz DECELERATE
  mov AL, [BX]
  mov AH, [SI]
  XOR AL, AH                            
  mov AX, ACCELERATION_INCREASE
  jnz NEG_ACCELERATION                  ; Car is reversing
  add [DI], AX
  jmp FIX_1
  NEG_ACCELERATION:
  sub [DI], AX
  jmp FIX_3

  DECELERATE:
  mov AL, 0
  cmp [DI], AL 
  mov AX, ACCELERATION_DECREASE
  jl NEG_DECELERATE
  sub [DI], AX
  js FIX_2
  jmp SKIP_ACC_CHECKS
  NEG_DECELERATE:
  add [DI], AX
  jns FIX_2
  jmp SKIP_ACC_CHECKS
  FIX_1:                      ; Acceleration > MAX_ACCELERATION
    xor AX, AX
    mov AL, MAX_ACCELERATION
    cmp [DI], AX
    jng SKIP_ACC_CHECKS
    mov [DI], AX
    jmp SKIP_ACC_CHECKS
  FIX_2:
    xor AX, AX                      ; |Acceleration| - DECELERATION < 0
    mov [DI], AX
    jmp SKIP_ACC_CHECKS
  FIX_3:                            ; Acceleration < NEG_MAX_ACCELERATION
    xor AX, AX
    mov AL, MAX_ACCELERATION * -1
    CBW
    cmp [DI], AX
    jnl SKIP_ACC_CHECKS
    mov [DI], AX
    jmp SKIP_ACC_CHECKS
  SKIP_ACC_CHECKS:
  ; Position = Position + (Velocity + Boost) * Acceleration
  ; DX = (Velocity + Boost) * Acceleration(DX) * delta(T)
  XOR AX, AX
  mov AL, [DI]
  mov DL, CAR_SPEED
  imul DL                      ; (Velocity + Boost) * Acceleration(DX)
  ;mov DL, TIME_AUX
  ;sub DL, OLD_TIME_AUX        ; delta(T) = New T - Old T
  ;mul DL                      ; (Velocity + Boost) * Acceleration(DX) * delta(T)
                              ; NOT WORKING XD
  mov CL, 3                            
  SAR AX, CL                  ; To make acceleration smaller
  mov DX, AX                  ; (Velocity + Boost) * Acceleration(DX)
  ret
HANDLE_ACCELERATION endp
;-------------------------------------------------------
MOVE_CAR proc near
  ; Move Car According To The Current Direction
  ;cmp CX, 0
  ;jz EXIT_MOVE_CAR
  ; Horizontal Movement
  cmp AL, LEFT
  jz MOVE_LEFT
  cmp AL, RIGHT
  jz MOVE_RIGHT
  ; Vertical Movement
  cmp AL, DOWN
  jz MOVE_DOWN
  jmp MOVE_UP
  MOVE_UP:
    call MOVE_UP_PROC
    jmp EXIT_MOVE_CAR

  MOVE_DOWN:
    call MOVE_DOWN_PROC
    jmp EXIT_MOVE_CAR

  MOVE_RIGHT:
    call MOVE_RIGHT_PROC
    jmp EXIT_MOVE_CAR

  MOVE_LEFT:
    call MOVE_LEFT_PROC
    jmp EXIT_MOVE_CAR

  EXIT_MOVE_CAR:
    ret
MOVE_CAR endp
;-------------------------------------------------------
MOVE_UP_PROC proc near        ; DX: Velocity, [BX]: Direction, [SI]: Car_Y
    cmp DX, [SI]              ; Point < Car_Y    
    jl SKIP_UP_FIX
      mov [SI], DX
    SKIP_UP_FIX:
    sub [SI], DX
    ret
MOVE_UP_PROC endp
;-------------------------------------------------------
MOVE_DOWN_PROC proc near      ; DX: Velocity, [BX]: Direction, [SI]: Car_Y
    add [SI], DX
    mov AX, GAME_BORDER_Y - 1 - CAR_HEIGHT
    cmp [SI], AX
    jng SKIP_DOWN_FIX
      mov [SI], AX
    SKIP_DOWN_FIX:
    ret
MOVE_DOWN_PROC endp
;-------------------------------------------------------
MOVE_RIGHT_PROC proc near     ; DX: Velocity, [BX]: Direction, [DI]: Car_X
    add [DI], DX              ; DI = CAR_X
    mov AX, GAME_BORDER_X - 1 - CAR_HEIGHT 
    cmp [DI], AX           
    jng SKIP_RIGHT_FIX
      mov [DI], AX
    SKIP_RIGHT_FIX:
    ret
MOVE_RIGHT_PROC endp
;-------------------------------------------------------
MOVE_LEFT_PROC proc near      ; DX: Velocity, [BX]: Direction, [DI]: Car_X
    cmp DX, [DI]              ; DI = CAR_X
    jl SKIP_LEFT_FIX
      mov [DI], DX
    SKIP_LEFT_FIX:
    sub [DI], DX
    ret
MOVE_LEFT_PROC endp
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
  mov BL, CAR1_IMG_DIR  ; Set Face Direction
  call DRAW_CAR

  mov CX, CAR2_X    ; Set initial column (X)
  mov DX, CAR2_Y    ; Set initial row (Y)
  lea si, img2      ;load image adress
  mov BL, CAR2_IMG_DIR  ; Set Face Direction
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