  EXTRN TIME_AUX:BYTE
  PUBLIC MOVE_CARS
  PUBLIC DRAW_CARS
.model small
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
  GAME_BORDER_X_MIN EQU 0
  GAME_BORDER_X_MAX EQU 320
  ;GAME_BORDER_Y EQU 00A0h
  GAME_BORDER_Y_MIN EQU 0
  GAME_BORDER_Y_MAX EQU 200
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
  mov AX, @data
  mov ES, AX
  mov CX, 0
  call READ_BUFFER

  ; Player One
  lea DI, CAR1_KEYS
  lea BX, CAR1_IMG_DIR
  lea SI, CAR1_MOVEMENT_DIR
  call CHECK_INPUT                      ; Stores status in CX
  ; Simulate acceleration for player one
  lea DI, CAR1_ACCELERATION
  call HANDLE_ACCELERATION              ; Stores in DX Position to be added, Position = Position + DX
  ; Move PLayer One
  mov AL, CAR1_IMG_DIR
  lea DI, CAR1_X
  lea SI, CAR1_Y
  call MOVE_CAR
  ; RESET DIRECTION IF CAR IS AT REST
  mov AL, CAR1_IMG_DIR
  lea SI, CAR1_MOVEMENT_DIR
  call CAR_AT_REST

  ; Key may be associated with player two
  cmp CX, 0                             ; Key didn't belong to player one
  jz SKIP_READ
  call READ_BUFFER
  SKIP_READ:

  ; Player Two
  lea DI, CAR2_KEYS
  lea BX, CAR2_IMG_DIR
  lea SI, CAR2_MOVEMENT_DIR
  call CHECK_INPUT                      ; Stores status in CX
  ; Simulate acceleration for player two
  lea DI, CAR2_ACCELERATION
  call HANDLE_ACCELERATION              ; Stores in DX Position to be added, Position = Position + DX
  ; Move PLayer Two
  mov AL, CAR2_IMG_DIR
  lea DI, CAR2_X
  lea SI, CAR2_Y
  call MOVE_CAR
  ; RESET DIRECTION IF CAR IS AT REST
  mov AL, CAR2_IMG_DIR
  lea SI, CAR2_MOVEMENT_DIR
  call CAR_AT_REST

  ; reset Keyboard Buffer
  mov AH, 0Ch
  int 21h

  EXIT_MOVE_CARS:
  mov AL, TIME_AUX
  mov OLD_TIME_AUX, AL
  ret
MOVE_CARS endp
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
CHECK_INPUT proc near                   ; [DI]: CAR_KEYS_TO_CHECK, [BX]: IMG_DIR, [SI]: MOVEMENT_DIR
  MOV CX, 17                            ; Number of car input keys
  repne SCASW                           ; Search for AX in CAR_KEYS
  mov AL, [BX]
  mov AH, [SI]
  cmp CX, 0
  jz EXIT_CHECK_INPUT
  ; Horizontal Movement
  ; LEFT
  cmp CX, 4
  jng MOVEMENT_LEFT
  ; RIGHT
  cmp CX, 8
  jng MOVEMENT_RIGHT
  ; Vertical Movement
  ; DOWN
  cmp CX, 12
  jng MOVEMENT_DOWN
  ; UP
  jmp MOVEMENT_UP

  MOVEMENT_LEFT:
  mov DH, LEFT
  mov DL, RIGHT
  call CHANGE_DIRECTION
  jmp EXIT_CHECK_INPUT

  MOVEMENT_RIGHT:
  mov DH, RIGHT
  mov DL, LEFT
  call CHANGE_DIRECTION
  jmp EXIT_CHECK_INPUT

  MOVEMENT_DOWN:
  mov DH, DOWN
  mov DL, UP
  call CHANGE_DIRECTION
  jmp EXIT_CHECK_INPUT

  MOVEMENT_UP:
  mov DH, UP
  mov DL, DOWN
  call CHANGE_DIRECTION

  EXIT_CHECK_INPUT:
  mov [BX], AL
  mov [SI], AH
  ret
CHECK_INPUT endp
;-------------------------------------------------------
CHANGE_DIRECTION proc near              ; AH: MOVEMENT_DIR, AL: IMG_DIR, DH: NEW_DIR, DL: Opposite_DIR, AH: 0 if normal
  cmp AH, AL                            ; (CURR_IMG != CURR_MOVEMENT)
  jz NOT_BACK_ROTATION
  cmp AH, DH                            ; NEW_MOVEMENT != CURR_IMG or CURR_MOVEMENT
  jz NOT_BACK_ROTATION
  cmp AL, DH                            ; NEW_MOVEMENT != CURR_IMG or CURR_MOVEMENT
  jz NOT_BACK_ROTATION
  mov AL, DL                            ; The Car is steering while reversing   
  jmp EXIT_CHANGE_DIRECTION
  NOT_BACK_ROTATION:
  cmp AL, DL                            ; CURR_IMG == OPPOSITE_MOVEMENT, So the Car is in REVERSE
  jz  EXIT_CHANGE_DIRECTION             ; Can't rotate 180deg directly
  mov AL, DH
  EXIT_CHANGE_DIRECTION:
  mov AH, DH
  ret
CHANGE_DIRECTION endp
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
  FIX_1:                                ; Acceleration > MAX_ACCELERATION
    xor AX, AX
    mov AL, MAX_ACCELERATION
    cmp [DI], AX
    jng SKIP_ACC_CHECKS
    mov [DI], AX
    jmp SKIP_ACC_CHECKS
  FIX_2:
    xor AX, AX                          ; |Acceleration| - DECELERATION < 0
    mov [DI], AX
    jmp SKIP_ACC_CHECKS
  FIX_3:                                ; Acceleration < NEG_MAX_ACCELERATION
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
MOVE_CAR proc near                      ; AL: CAR_IMG_DIR, [DI]: CAR_X, [SI]: CAR_Y, DX: Velocity
  ; Move Car According To The Current Direction
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
  call FIX_BOUNDARIES_CONDITION
    ret
MOVE_CAR endp
;-------------------------------------------------------
MOVE_UP_PROC proc near                  ; DX: Velocity, [BX]: Direction, [SI]: Car_Y
    sub [SI], DX
    ret
MOVE_UP_PROC endp
;-------------------------------------------------------
MOVE_DOWN_PROC proc near                ; DX: Velocity, [BX]: Direction, [SI]: Car_Y
    add [SI], DX
    ret
MOVE_DOWN_PROC endp
;-------------------------------------------------------
MOVE_RIGHT_PROC proc near               ; DX: Velocity, [BX]: Direction, [DI]: Car_X
    add [DI], DX              ; DI = CAR_X
    ret
MOVE_RIGHT_PROC endp
;-------------------------------------------------------
MOVE_LEFT_PROC proc near                ; DX: Velocity, [BX]: Direction, [DI]: Car_X
    sub [DI], DX
    ret
MOVE_LEFT_PROC endp
;-------------------------------------------------------
FIX_BOUNDARIES_CONDITION proc near      ; [DI]: CAR_X, [SI]: CAR_Y
  ; X < 0
  mov AX, GAME_BORDER_X_MIN
  cmp [DI], AX
  jl FIX_X
  ; X > X_Limit
  mov AX, GAME_BORDER_X_MAX - 1 - CAR_HEIGHT
  cmp [DI], AX
  jg FIX_X
  jmp SKIP_FIX_X
  FIX_X:
  mov [DI], AX
  SKIP_FIX_X:
  ; Y < 0
  mov AX, GAME_BORDER_Y_MIN
  cmp [SI], AX
  jl FIX_Y
  ; Y > Y_Limit
  mov AX, GAME_BORDER_Y_MAX - 1 - CAR_HEIGHT
  cmp [SI], AX
  jg FIX_Y
  jmp SKIP_FIX_Y
  FIX_Y:
  mov [SI], AX
  SKIP_FIX_Y:
  ret
FIX_BOUNDARIES_CONDITION endp
;-------------------------------------------------------
CAR_AT_REST proc near                   ; DX: Velocity, AL: CAR_IMG_DIR, [SI]: MOVEMENT_DIR
  cmp DX, 0
  jnz EXIT_CAR_AT_REST
    mov [SI], AL
  EXIT_CAR_AT_REST:
  ret
CAR_AT_REST endp
;-------------------------------------------------------
;-------------------------------------------------------
DRAW_CARS proc far
  mov CX, CAR1_X                        ; Set initial column (X)
  mov DX, CAR1_Y                        ; Set initial row (Y)
  lea SI, img1                          ; Load image adress
  mov BL, CAR1_IMG_DIR                  ; Set Face Direction
  call DRAW_CAR

  mov CX, CAR2_X                        ; Set initial column (X)
  mov DX, CAR2_Y                        ; Set initial row (Y)
  lea SI, img2                          ; Load image adress
  mov BL, CAR2_IMG_DIR                  ; Set Face Direction
  call DRAW_CAR
  ret
DRAW_CARS endp
;-------------------------------------------------------
DRAW_CAR proc near                      ; CX: CAR_X, DX: CAR_Y, [SI]: CAR_IMG, BL: IMG_DIR
    mov AX, 320
    cmp BL, DOWN                           
    jng  SKIP_DX_ADDITION               ; SKIP IF VERTICAL
    add DX, CAR_WIDTH                   ; IF IMG_DIR > (DOWN | UP)
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
        cmp BL, DOWN             
        jz SKIP_SUBBING     ; Facing Down
        cmp BL, RIGHT            
        jz SKIP_SUBBING     ; Facing Right
        sub SI, 2
        SKIP_SUBBING:
        loop TRANSFER
    ; Go to next Row
    add DI, 320 - CAR_WIDTH
    cmp BL, DOWN
    jng  NEXT_BAR         ; SKIP IF VERTICAL
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