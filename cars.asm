  ; GAME.asm
  EXTRN TIME_AUX:BYTE
  EXTRN TIME_SEC:BYTE
  ; PATHGEN.asm
  EXTRN xstart:WORD
  EXTRN ystart:WORD
  EXTRN CLEAR_ENTITY:FAR
  EXTRN CHECK_CAR_ON_PATH:FAR
  ; OBSTACLES.asm
  EXTRN ADD_OBSTACLE:FAR
  EXTRN CHECK_COLLISION:FAR
  ; PUBLIC
  PUBLIC CHECK_INPUT_UPDATES
  PUBLIC PRINT_TEST
  PUBLIC LOAD_CARS
  PUBLIC MOVE_CARS
  PUBLIC DRAW_CARS
  PUBLIC CAR_X
  PUBLIC CAR_Y
  moveCursor macro x, y
    mov dl, x
    mov dh, y
    mov ah, 2H
    int 10h  
endm
.model small
.data
  ; Red Car
  img1  DB 184, 113, 6, 137, 233, 184, 113, 6, 137, 136, 235, 6, 41, 137, 21, 235, 6, 41, 137, 21, 170, 161, 138, 163, 170, 244, 27, 75, 74, 20, 113, 137, 163, 138, 137, 112, 4, 6, 6, 136 
        DB 185, 113, 113, 111, 209

  ; Blue Car
  img2  DB 200, 128, 150, 151, 247, 200, 128, 150, 151, 246, 151, 150, 174, 175, 150, 150, 150, 174, 175, 150, 148, 148, 173, 172, 148, 220, 78, 75, 78, 150, 222, 173, 172, 173, 151, 222, 150, 175, 175, 151 
        DB 200, 222, 222, 222, 200
  
 ; Constants
  CAR_WIDTH             EQU 05h               ; The width of all cars
  CAR_HEIGHT            EQU 09h               ; The height of all cars
  CAR_SPEED             EQU 2
  ACCELERATION_INCREASE EQU 1
  ACCELERATION_DECREASE EQU 1
  MAX_ACCELERATION      EQU 8
  
  GAME_BORDER_X_MIN     EQU 0                ; track boundries
  GAME_BORDER_X_MAX     EQU 320
  GAME_BORDER_Y_MIN     EQU 0
  GAME_BORDER_Y_MAX     EQU 180
  SCREEN_WIDTH          EQU 320
  SCREEN_HEIGHT         EQU 200
  BLOCK_WIDTH           EQU 20
  BLOCK_HEIGHT          EQU 20
  WHITE_STRIP_WIDTH     EQU 1
  WHITE_STRIP_HEIGHT    EQU 4
  GREY                  EQU 08h
  GREEN                 EQU 02h
  RED                   EQU 0Ch
  UP EQU 0
  DOWN EQU 1
  RIGHT EQU 2
  LEFT EQU 3
  UP_RIGHT EQU 4
  DOWN_LEFT EQU 5
  UP_LEFT EQU 6
  DOWN_RIGHT EQU 7
  BOOST EQU 2
  SLOW EQU 1
  POWERUP_TIME EQU 5
  POWERUPS_COUNT EQU 4

  ; Variables
  OLD_TIME_AUX DB 0
  OLD_TIME_SEC DB 0
  CURRENT_KEY DW 0000h
  CURRENT_CAR DB ?
  CURRENT_VELOCITY DW ?

  CAR_X DW 0Ah, 2Ah                                   ; CenterX position of player1, player2
  CAR_Y DW 3Ah, 3Ah                                   ; CenterY position of player1, player2
  CAR_IMG_DIR DB UP, UP                 ; IMG Direction of player1, player2
  CAR_MOVEMENT_DIR DB DOWN, DOWN        ; Movement Direction of player1, player2
  CAR_ACCELERATION DW 0, 0                         ; Acceleration Value of player1, player2
  CAR_COLLISION DB 0, 0                         ; Acceleration Value of player1, player2
  CAR_POWER DB 0, 0

          ; Release Press
  CAR1_KEYS DB  25h, 25h                            ; K : 10, 9
            DB 0C8h, 48h                            ; UP : 8, 7
            DB 0D0h, 50h                            ; DOWN : 6, 5
            DB 0CDh, 4Dh                            ; RIGHT : 4, 3
            DB 0CBh, 4Bh                            ; LEFT : 2, 1
            DB 00h    ; NONE : 0

  CAR1_KEYS_STATUS DB 0, 0, 0, 0, 0                   ; UP, DOWN, RIGHT, LEFT
  CAR1_POWERS_TIME DB 0, 0, 0, 0

          ; Release Press
  CAR2_KEYS DB  39h, 39h                            ; SPACE : 10, 9
            DB  91h, 11h                            ; W : 8, 7        [BX] + 0
            DB  9Fh, 1Fh                            ; S : 6, 5        [BX] + 1
            DB 0A0h, 20h                            ; D : 4, 3        [BX] + 2
            DB  9Eh, 1Eh                            ; A : 2, 1        [BX] + 3
            DB 00h    ; NONE : 0

  CAR2_KEYS_STATUS DB 0, 0, 0, 0, 0                   ; W, S, D, A
  CAR2_POWERS_TIME DB 0, 0, 0, 0
.code
;-------------------------------------------------------
MOVE_CARS proc far
  mov AX, @data
  mov ES, AX
  mov CX, 0
  ; Player One
  mov AL, 0
  mov CURRENT_CAR, AL
  call UPDATE_CAR
  ; Player Two
  mov AL, 2
  mov CURRENT_CAR, AL
  call UPDATE_CAR

  call UPDATE_POWERUPS
  EXIT_MOVE_CARS:
  mov AL, TIME_AUX
  mov OLD_TIME_AUX, AL
  ret
MOVE_CARS endp
;-------------------------------------------------------
UPDATE_CAR proc near
  call CHECK_INPUT
  ; Simulate acceleration for player one
  call HANDLE_ACCELERATION              ; Stores in DX Position to be added, Position = Position + DX
  ; Move PLayer
  xor BX, BX
  mov BL, CURRENT_CAR
  mov CX, [CAR_X + BX]
  mov DX, [CAR_Y + BX]
  mov BL, CAR_HEIGHT
  call CLEAR_ENTITY
  call MOVE_CAR
  ; RESET DIRECTION IF CAR IS AT REST
  call CAR_AT_REST
  ; Check For Collision
  call CHECK_ENTITY_COLLISION
  call CHECK_PATH_COLLISION
  call DROP_OBSTACLE
  EXIT_UPDATE_CAR:
  ret
UPDATE_CAR endp
;-------------------------------------------------------
CHECK_INPUT_UPDATES proc far
  push AX
  push BX
  push CX
  push DX
  push SI
  push DI
  push DS
  push ES
  in al, 60h ; read scan code
  cmp AL, 0
  jz EXIT_CHECK_INPUT_UPDATES
  lea DI, CAR1_KEYS
  lea BX, CAR1_KEYS_STATUS
  lea SI, CAR1_POWERS_TIME
  mov AH, 0
  mov CURRENT_CAR, AH
  call READ_BUFFER
  lea DI, CAR2_KEYS
  lea BX, CAR2_KEYS_STATUS
  lea SI, CAR2_POWERS_TIME
  mov AH, 2
  mov CURRENT_CAR, AH
  call READ_BUFFER
  EXIT_CHECK_INPUT_UPDATES:
  mov al,20h
  out 20h,al
  pop ES
  pop DS
  pop DI
  pop SI
  pop DX
  pop CX
  pop BX
  pop AX
  iret
CHECK_INPUT_UPDATES endp
;-------------------------------------------------------
READ_BUFFER proc near                   ; [DI]: CAR_KEYS_TO_CHECK, [BX]: CAR_KEYS_STATUS
  ; Check Selected Car Input
  MOV CX, 11
  repne SCASB                           ; Search for AX in CAR_KEYS
  cmp CX, 0
  jz EXIT_READ_KEYBOARD
  cmp CX, 8
  jng MOVEMENT_KEY
  call USE_POWERUP
  jmp EXIT_READ_KEYBOARD
  MOVEMENT_KEY:
  mov DX, 8
  sub DL, CL
  sar Dl, 1
  
  and CL, 1
  cmp CL, 1
  jnz SKIP_RESETING
  mov ch, 0
  mov [BX], ch
  mov [BX + 1], ch
  mov [BX + 2], ch
  mov [BX + 3], ch
  SKIP_RESETING:
  add BX, DX
  mov [BX], CL
  ;cmp CL, 0
  ;jz EXIT_READ_KEYBOARD
  ;sub BX, DX
  ;xor DX, 1
  ;add BX, DX
  ;mov [BX], CH
  EXIT_READ_KEYBOARD:
    ret
READ_BUFFER endp
;-------------------------------------------------------
CHECK_INPUT proc near                   ; [DI]: CAR_KEYS_TO_CHECK, [DX]: IMG_DIR, [SI]: MOVEMENT_DIR
  ; Load Car Info Depending on BX: Car_Number
  mov BX, 0
  mov BL, CURRENT_CAR
  lea DI, CAR1_KEYS_STATUS
  cmp BX, 2
  jnz CHECK_CAR1_KEYS
  lea DI, CAR2_KEYS_STATUS
  CHECK_CAR1_KEYS:
  shr BX, 1
  lea SI, [CAR_MOVEMENT_DIR + BX]
  mov AL, [CAR_IMG_DIR + BX]
  mov AH, [SI]
  mov BX, DI
  ; Check Selected Car Input
  mov CX, 1
  cmp CL, [DI]
  jz MOVEMENT_UP
  inc DI
  cmp CL, [DI]
  jz MOVEMENT_DOWN
  inc DI
  cmp CL, [DI]
  jz MOVEMENT_RIGHT
  inc DI
  cmp CL, [DI]
  jz MOVEMENT_LEFT
  mov CX, 0
  jmp EXIT_CHECK_INPUT

  MOVEMENT_UP:
  cmp CL, [DI] + 2     
  jz MOVEMENT_UP_RIGHT                  ; Up and Right are Pressed
  cmp CL, [DI] + 3                      
  jz MOVEMENT_UP_LEFT                   ; Up and Left are Pressed
  mov DH, UP
  mov DL, DOWN
  call CHANGE_DIRECTION
  jmp EXIT_CHECK_INPUT

  MOVEMENT_UP_RIGHT:
  mov DH, UP_RIGHT
  mov DL, DOWN_LEFT
  call CHANGE_DIRECTION
  jmp EXIT_CHECK_INPUT

  MOVEMENT_UP_LEFT:
  mov DH, UP_LEFT
  mov DL, DOWN_RIGHT
  call CHANGE_DIRECTION
  jmp EXIT_CHECK_INPUT

  MOVEMENT_DOWN:
  cmp CL, [DI] + 1     
  jz MOVEMENT_DOWN_RIGHT                ; Down and Right are Pressed
  cmp CL, [DI] + 2                      
  jz MOVEMENT_DOWN_LEFT                 ; Down and Left are Pressed
  mov DH, DOWN
  mov DL, UP
  call CHANGE_DIRECTION
  jmp EXIT_CHECK_INPUT

  MOVEMENT_DOWN_RIGHT:
  mov DH, DOWN_RIGHT
  mov DL, UP_LEFT
  call CHANGE_DIRECTION
  jmp EXIT_CHECK_INPUT

  MOVEMENT_DOWN_LEFT:
  mov DH, DOWN_LEFT
  mov DL, UP_RIGHT
  call CHANGE_DIRECTION
  jmp EXIT_CHECK_INPUT

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

  EXIT_CHECK_INPUT:
  mov [SI], AH
  xor BX, BX
  mov BL, CURRENT_CAR
  shr BX, 1
  lea SI, [CAR_IMG_DIR + BX]
  mov [SI], AL
  ret
CHECK_INPUT endp;-------------------------------------------------------
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
HANDLE_ACCELERATION proc near           ; [DI]: CAR_ACCELERATION, [SI]: IMG_DIR
  ; Load Car Info Depending on BX: Car_Number
  xor BX, BX
  mov BL, CURRENT_CAR
  lea DI, [CAR_ACCELERATION + BX]
  shr BX, 1
  cmp CX, 0
  jz DECELERATE
  mov AL, [SI]
  mov AH, [CAR_MOVEMENT_DIR + BX]
  XOR AL, AH                            ; if AL = AH, ZF = 1
  mov AX, ACCELERATION_INCREASE
  jnz NEG_ACCELERATION                  ; Car is reversing
  add [DI], AX
  jmp FIX_1
  NEG_ACCELERATION:
  sub [DI], AX
  jmp FIX_3

  DECELERATE:
  mov AX, 0
  cmp [DI], AX 
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
  call USE_SPEED_RELATED_POWERUP
  mov AX, [DI]
  imul BL                               ; (Velocity + Boost) * Acceleration(DX)
  ;mov DL, TIME_AUX
  ;sub DL, OLD_TIME_AUX                 ; delta(T) = New T - Old T
  ;mul DL                               ; (Velocity + Boost) * Acceleration(DX) * delta(T)
                                        ; NOT WORKING XD
  mov CL, 3                            
  SAR AX, CL                            ; To make acceleration smaller
  mov CURRENT_VELOCITY, AX                            ; (Velocity + Boost) * Acceleration(DX)
  ret
HANDLE_ACCELERATION endp
;-------------------------------------------------------
MOVE_CAR proc near                      ; AL: CAR_IMG_DIR, [DI]: CAR_CenterX, [SI]: CAR_CenterY, DX: Velocity
  ; Load Car Info Depending on BX: Car_Number
  xor BX, BX
  mov BL, CURRENT_CAR
  lea DI, [CAR_X + BX]
  lea SI, [CAR_Y + BX]
  sar BX, 1
  mov AL, [CAR_IMG_DIR + BX]
  mov DX, CURRENT_VELOCITY
  ; Move Car According To The Current Direction
  ; Horizontal Movement
  cmp AL, 0
  jnz SKIP_MOVE_UP
  call MOVE_UP_PROC
  jmp EXIT_MOVE_CAR
  SKIP_MOVE_UP:
  cmp AL, 1
  jnz SKIP_MOVE_DOWN
  call MOVE_DOWN_PROC
  jmp EXIT_MOVE_CAR
  SKIP_MOVE_DOWN:
  cmp AL, 2
  jnz SKIP_MOVE_RIGHT
  call MOVE_RIGHT_PROC
  jmp EXIT_MOVE_CAR
  SKIP_MOVE_RIGHT:
  cmp AL, 3
  jnz SKIP_MOVE_LEFT
  call MOVE_LEFT_PROC
  jmp EXIT_MOVE_CAR
  SKIP_MOVE_LEFT:
  mov BH, AL
  mov AX, DX
  mov BL, 3
  idiv BL
  CBW
  sub DX, AX
  mov AL, BH
  cmp AL, 4
  jnz SKIP_MOVE_UP_RIGHT
  call MOVE_UP_PROC
  call MOVE_RIGHT_PROC
  jmp EXIT_MOVE_CAR
  SKIP_MOVE_UP_RIGHT:
  cmp AL, 5
  jnz SKIP_MOVE_DOWN_LEFT
  call MOVE_DOWN_PROC
  call MOVE_LEFT_PROC
  jmp EXIT_MOVE_CAR
  SKIP_MOVE_DOWN_LEFT:
  cmp AL, 6
  jnz SKIP_MOVE_UP_LEFT
  call MOVE_UP_PROC
  call MOVE_LEFT_PROC
  jmp EXIT_MOVE_CAR
  SKIP_MOVE_UP_LEFT:
  cmp AL, 7
  jnz SKIP_MOVE_DOWN_RIGHT
  call MOVE_DOWN_PROC
  call MOVE_RIGHT_PROC
  SKIP_MOVE_DOWN_RIGHT:

  EXIT_MOVE_CAR:
  mov BX, 0
  mov BL, CURRENT_CAR
  call FIX_BOUNDARIES_CONDITION
    ret
MOVE_CAR endp
;-------------------------------------------------------
MOVE_UP_PROC proc near                  ; DX: Velocity, [BX]: Direction, [SI]: CAR_CenterY
    sub [SI], DX
    ret
MOVE_UP_PROC endp
;-------------------------------------------------------
MOVE_DOWN_PROC proc near                ; DX: Velocity, [BX]: Direction, [SI]: CAR_CenterY
    add [SI], DX
    ret
MOVE_DOWN_PROC endp
;-------------------------------------------------------
MOVE_RIGHT_PROC proc near               ; DX: Velocity, [BX]: Direction, [DI]: CAR_CenterX
    add [DI], DX              ; DI = CAR_X
    ret
MOVE_RIGHT_PROC endp
;-------------------------------------------------------
MOVE_LEFT_PROC proc near                ; DX: Velocity, [BX]: Direction, [DI]: CAR_CenterX
    sub [DI], DX
    ret
MOVE_LEFT_PROC endp
;-------------------------------------------------------
FIX_BOUNDARIES_CONDITION proc near      ; AL: CAR_IMG_DIR, [DI]: CAR_CenterX, [SI]: CAR_CenterY
  mov BX, CAR_HEIGHT / 2
  ;shr DX, 1                             ; DX = height / 2
  ; X < 0 + height / 2
  mov AX, GAME_BORDER_X_MIN
  add AX, BX
  cmp [DI], AX
  jl FIX_X
  ; X > X_Limit
  mov AX, GAME_BORDER_X_MAX - 1
  sub AX, BX
  cmp [DI], AX
  jg FIX_X
  jmp SKIP_FIX_X
  FIX_X:
  mov [DI], AX
  SKIP_FIX_X:
  ; Y < 0 + height / 2
  mov AX, GAME_BORDER_Y_MIN
  add AX, BX
  cmp [SI], AX
  jl FIX_Y
  ; Y > Y_Limit
  mov AX, GAME_BORDER_Y_MAX - 1
  sub AX, BX
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
  xor BX, BX
  mov BL, CURRENT_CAR
  shr BX, 1
  mov AL, [CAR_IMG_DIR + BX]
  lea SI, [CAR_MOVEMENT_DIR + BX]
  cmp DX, 0
  jnz EXIT_CAR_AT_REST
    mov [SI], AL
  EXIT_CAR_AT_REST:
  ret
CAR_AT_REST endp
;-------------------------------------------------------
CHECK_ENTITY_COLLISION proc near
  xor BX, BX
  mov BL, CURRENT_CAR
  mov CX, [CAR_X + BX]
  mov DX, [CAR_Y + BX]
  shr BX, 1
  mov AL, [CAR_IMG_DIR + BX]
  ; CHECK IF POWER IS USED
  mov AH, CAR1_POWERS_TIME[3]
  cmp BX, 0
  jz HANDLE_PASS_CAR1
  mov AH, CAR2_POWERS_TIME[3]
  HANDLE_PASS_CAR1:
  mov BH, AH
  push BX
  call CHECK_COLLISION                  ; Returns AX = 1, ZF = 1, DH = delta(X), DL = delta(Y) on collision
  pop BX
  jnz SKIP_COLLISION_FIX
  mov AH, BH
  mov BH, 0
  cmp AH, 0                             ; IF AH is 0 then the pass ability is used.
  jz HANDLE_TIRE_COLLISION
  ; USE THE POWER TO PASS
  mov AH, 0
  cmp BX, 0
  jnz REMOVE_PASS_CAR2
  mov CAR1_POWERS_TIME[3], AH
  jmp EXIT_CHECK_ENTITY_COLLISION
  REMOVE_PASS_CAR2:
  mov CAR2_POWERS_TIME[3], AH
  jmp EXIT_CHECK_ENTITY_COLLISION
  HANDLE_TIRE_COLLISION:
  call FIX_COLLISION
  mov CURRENT_VELOCITY, DX
  call MOVE_CAR
  jmp EXIT_CHECK_ENTITY_COLLISION
  SKIP_COLLISION_FIX:
  cmp AH, 0
  jz EXIT_CHECK_ENTITY_COLLISION
  mov [CAR_POWER + BX], AH
  EXIT_CHECK_ENTITY_COLLISION:
  ret
CHECK_ENTITY_COLLISION endp
;-------------------------------------------------------
FIX_COLLISION proc near                 ; AL: CAR_IMG_DIR, [DI]: CAR_ACCELERATION, [SI]: MOVEMENT_DIR, DH: delta(X), DL: delta(Y)
  xor BX, BX
  mov BL, CURRENT_CAR
  lea DI, [CAR_ACCELERATION + BX]
  shr BX, 1
  mov AL, [CAR_IMG_DIR + BX]
  lea SI, [CAR_MOVEMENT_DIR + BX]
  mov AH, [SI]
  cmp AL, DOWN
  jng FIX_VERTICAL
  mov DL, DH
  FIX_VERTICAL:
  mov DH, 0
  xor AH, 1                           ; Switch Movement Direction
  mov [SI], AH
  XOR AH, AL                          ; 0 if the car collided while reversing
  ; EDIT VELOCITY
  jz SKIP_FIX_VELOCITY
  mov DH, -1
  xor DL, -1
  add DX, 1
  SKIP_FIX_VELOCITY:
  push AX
  mov AX, [DI]
  xor AX, -1                          ; Make Acceleration = - Acceleration
  sar AX, 1
  mov [DI], AX
  pop AX
  ret
FIX_COLLISION endp
;-------------------------------------------------------
CHECK_PATH_COLLISION proc near
  push DI
  xor BX, BX
  mov BL, CURRENT_CAR
  mov CX, [CAR_X + BX]
  mov DX, [CAR_Y + BX]
  mov AX, 0
  shr BX, 1
  mov AH, [CAR_MOVEMENT_DIR + BX]
  cmp AH, Left
  jz CHECK_HORIZONTAL
  cmp AH, Right
  jz CHECK_HORIZONTAL
  ; Vertical
  add CX, CAR_WIDTH / 2
  mov BX, CX
  sub CX, CAR_WIDTH                     ; BX -> CX + CAR_WIDTH
  cmp AH, UP
  jnz CHECK_DOWN
  ; Go To Upper Side
  sub DX, CAR_HEIGHT / 2
  mov DI, DX
  jmp CHECK_PATH
  CHECK_DOWN:
  ; Go To Lower Side
  add DX, CAR_HEIGHT / 2
  mov DI, DX
  jmp CHECK_PATH
  CHECK_HORIZONTAL:
  ; Horizontal
  add DX, CAR_WIDTH / 2
  mov DI, DX
  sub DX, CAR_WIDTH                     ; DI -> DX + CAR_WIDTH
  cmp AH, LEFT
  jnz CHECK_RIGHT
  ; Go To Left Side
  sub CX, CAR_HEIGHT / 2
  mov BX, CX
  jmp CHECK_PATH
  CHECK_RIGHT:
  ; Go To Right Side
  add CX, CAR_HEIGHT / 2
  mov BX, CX
  jmp CHECK_PATH
  CHECK_PATH:
  call CHECK_CAR_ON_PATH
  cmp al, GREEN
  jz PATH_COLLISION
  cmp al, RED
  jz PATH_COLLISION
  jmp EXIT_CHECK_PATH
  PATH_COLLISION:
  xor BX, BX
  mov BL, CURRENT_CAR
  mov AX, 0
  mov [CAR_ACCELERATION + BX], AX
  mov AX, CURRENT_VELOCITY
  xor AX, -1
  add AX, 1
  mov CURRENT_VELOCITY, AX
  call MOVE_CAR
  EXIT_CHECK_PATH:
  pop DI
  ret
CHECK_PATH_COLLISION endp
;-------------------------------------------------------
USE_POWERUP proc near                   ; [SI]: POWERUPS_TIME
  mov BH, 0
  mov BL, CURRENT_CAR
  shr BX, 1
  mov AH, POWERUP_TIME
  mov AL, [CAR_POWER + BX]              ; Store Activated Power
  cmp AL, 0
  jz EXIT_USE_POWERUP
  mov [CAR_POWER + BX], BH
  dec AL
  mov BH, 0
  mov BL, AL
  add SI, BX
  mov AH, 5
  mov [SI], AH                      ; Update Powerup Time
  EXIT_USE_POWERUP:
  ret
USE_POWERUP endp
;-------------------------------------------------------
USE_SPEED_RELATED_POWERUP proc near     ; BX: CURRENT SELECTED CAR
  cmp BX, 0
  mov AH, [CAR1_POWERS_TIME]            ; BOOST
  mov AL, CAR2_POWERS_TIME[1]           ; SLOW
  jz HANDLE_BOOST_CAR1
  mov AH, [CAR2_POWERS_TIME]            ; BOOST
  mov AL, CAR1_POWERS_TIME[1]           ; SLOW
  HANDLE_BOOST_CAR1:
  mov BL, CAR_SPEED
  cmp AH, 0
  jz SKIP_ADDING_BOOST
  add BL, BOOST
  SKIP_ADDING_BOOST:
  cmp AL, 0
  jz SKIP_SLOWING_DOWN
  sub BL, SLOW
  SKIP_SLOWING_DOWN:
  ret
USE_SPEED_RELATED_POWERUP endp
;-------------------------------------------------------
DROP_OBSTACLE proc near                 ; AL: MOVEMENT_DIR
  xor BX, BX
  mov BL, CURRENT_CAR
  lea SI, CAR1_POWERS_TIME[2]          ; BOOSTS
  cmp BX, 0
  jz HANDLE_DROP_CAR1
  lea SI, CAR2_POWERS_TIME[2]          ; BOOST
  HANDLE_DROP_CAR1:
  cmp [SI], BH
  jz EXIT_DROP_OBSTACLE
  mov [SI], BH
  mov BL, CURRENT_CAR
  mov CX, [CAR_X + BX]
  mov DX, [CAR_Y + BX]
  shr BL, 1
  mov AL, [CAR_MOVEMENT_DIR + BX]
  ; VERTICAL WILL ADD ON DX
  cmp AL, UP
  jnz SKIP_DROP_BACKWARD
  add DX, CAR_HEIGHT / 2 + 3
  SKIP_DROP_BACKWARD:
  cmp AL, DOWN
  jnz SKIP_DROP_UPWARD
  sub DX, CAR_HEIGHT / 2 + 3
  SKIP_DROP_UPWARD:
  ; HORIZONTAL WILL ADD ON CX
  cmp AL, LEFT
  jnz SKIP_DROP_LEFT
  add CX, CAR_HEIGHT / 2 + 3
  SKIP_DROP_LEFT:
  cmp AL, RIGHT
  jnz SKIP_DROP_RIGHT
  sub CX, CAR_HEIGHT / 2 + 3
  SKIP_DROP_RIGHT:
  mov AX, 0
  call ADD_OBSTACLE
  EXIT_DROP_OBSTACLE:
  ret
DROP_OBSTACLE endp
;-------------------------------------------------------
UPDATE_POWERUPS proc near               ; [SI]: POWERUPS_TIME
  mov AL, TIME_SEC
  cmp OLD_TIME_SEC, AL
  jz EXIT_UPDATE_POWERUPS
  mov OLD_TIME_SEC, AL
  xor BX, BX
  mov BL, CURRENT_CAR
  lea SI, CAR1_POWERS_TIME
  mov CX, POWERUPS_COUNT
  mov AH, 1
  mov AL, 0
  UPDATE_POWERUPS_LOOP:
    cmp [SI], AL
    jz DONT_LOWER_TIMER
    sub [SI], AH
    DONT_LOWER_TIMER:
    inc SI
    loop UPDATE_POWERUPS_LOOP
  lea SI, CAR2_POWERS_TIME
  mov CX, POWERUPS_COUNT
  UPDATE_POWERUPS_LOOP_2:
    cmp [SI], AL
    jz DONT_LOWER_TIMER_2
    sub [SI], AH
    DONT_LOWER_TIMER_2:
    inc SI
    loop UPDATE_POWERUPS_LOOP_2
  EXIT_UPDATE_POWERUPS:
  ret
UPDATE_POWERUPS endp
;-------------------------------------------------------
DRAW_CARS proc far
  push ES
  mov AX, 0A000h
  mov ES, AX
  mov CX, CAR_X                        ; Set initial column (X)
  mov DX, CAR_Y                        ; Set initial row (Y)
  lea SI, img1                          ; Load image adress
  cmp CAR_COLLISION, 0
  jz skip_col1
  lea SI, img2                          ; Load image adress
  skip_col1:
  mov BL, CAR_IMG_DIR                  ; Set Face Direction
  call DRAW_CAR

  mov CX, CAR_X + 2                        ; Set initial column (X)
  mov DX, CAR_Y + 2                        ; Set initial row (Y)
  lea SI, img2                          ; Load image adress
  mov BL, CAR_IMG_DIR + 1                  ; Set Face Direction
  call DRAW_CAR
  pop ES
  ret
DRAW_CARS endp
;-------------------------------------------------------
DRAW_CAR proc near                      ; CX: CAR_X, DX: CAR_Y, [SI]: CAR_IMG, BL: IMG_DIR
    
    cmp BL, RIGHT                           
    jl  SKIP_DX_ADDITION                ; SKIP IF VERTICAL
    cmp BL, LEFT                           
    jg  SKIP_DX_ADDITION                ; SKIP IF DIAGONAL 
    sub CX, CAR_HEIGHT / 2
    add DX, CAR_WIDTH / 2               ; IF IMG_DIR is Horizontal
    jmp GET_CAR_DI_INDEX
    SKIP_DX_ADDITION:
    sub CX, CAR_WIDTH / 2
    sub DX, CAR_HEIGHT / 2
    cmp BL, RIGHT
    jl GET_CAR_DI_INDEX                 ; IF Not Diagonal Skip Shifting
    sub CX, CAR_WIDTH / 2
    cmp BL, UP_LEFT
    jz GET_CAR_DI_INDEX
    cmp BL, DOWN_RIGHT
    jz GET_CAR_DI_INDEX
    add CX, CAR_WIDTH / 2
    add CX, CAR_WIDTH / 2
    add CX, CAR_WIDTH / 2               ; IF Shifted in the other direction
    GET_CAR_DI_INDEX:
    mov AX, SCREEN_WIDTH
    mul DX
    add AX, CX
    mov DI, AX                          ; load adress  (CX + DX * 320)
    mov DX, CAR_HEIGHT                  ; number of rows
    cmp BL, DOWN             
    jz SKIP_REVERSING                   ; Facing Down
    cmp BL, RIGHT             
    jz SKIP_REVERSING                   ; Facing Right
    add SI, CAR_HEIGHT * CAR_WIDTH - 1
    SKIP_REVERSING:
DRAW_HEIGHT:
    ; Draw Width
    mov CX, CAR_WIDTH                   ; size of Width
    TRANSFER:
        ;cmp SI, 0                      ; Pixel is Transparent
        ;jz  TRANSPARENT
        MOVSB
        cmp BL, RIGHT                           
        jl  SKIP_DI_ADDITION                ; SKIP IF VERTICAL
        cmp BL, LEFT                           
        jg  SKIP_DI_ADDITION                ; SKIP IF DIAGONAL 
        sub DI, SCREEN_WIDTH + 1
        SKIP_DI_ADDITION:
        cmp BL, LEFT                           
        jng  SKIP_SHIFT_DI_DIAG                ; SKIP IF DIAGONAL
        sub DI, SCREEN_WIDTH
        cmp BL, UP_LEFT
        jz SKIP_SHIFT_DI_DIAG
        cmp BL, DOWN_RIGHT
        jz SKIP_SHIFT_DI_DIAG
        add DI, 640
        SKIP_SHIFT_DI_DIAG:
        ;TRANSPARENT:
        cmp BL, DOWN             
        jz SKIP_SUBBING                 ; Facing Down
        cmp BL, RIGHT            
        jz SKIP_SUBBING                 ; Facing Right
        sub SI, 2                       ; IF Facing Up or Left decrement SI for IMG reversing
        SKIP_SUBBING:
        loop TRANSFER
    ; Go to next Row
    add DI, SCREEN_WIDTH - CAR_WIDTH
    cmp BL, RIGHT                           
    jl  NEXT_BAR                ; SKIP IF VERTICAL
    mov DI, AX
    add DI, SCREEN_WIDTH
    inc DI
    cmp BL, UP_LEFT
    jz NEXT_BAR
    cmp BL, DOWN_RIGHT
    jz NEXT_BAR
    sub DI, 2
    cmp BL, LEFT                           
    jg  NEXT_BAR                ; SKIP IF DIAGONAL 
    inc AX
    mov DI, AX
    NEXT_BAR:
    mov AX, DI
    dec DX                              ; check if end condition
    cmp DX, 0
    jnz DRAW_HEIGHT

    ret
DRAW_CAR endp
;-------------------------------------------------------;
LOAD_CARS proc far                      ; AL: Start Direction
  mov BX, xstart
  add BX, 5
  mov [CAR_X], BX
  add BX, 9
  mov [CAR_X + 2], BX
  cmp AL, UP
  jnz LOAD_CARS_DOWN
  mov [CAR_IMG_DIR], UP
  mov [CAR_IMG_DIR + 1], UP
  mov BX, ystart
  add BX, 13
  mov [CAR_Y], BX
  mov [CAR_Y + 2], BX
  ret
  LOAD_CARS_DOWN:
  cmp AL, DOWN
  jnz LOAD_CARS_LEFT
  mov [CAR_IMG_DIR], DOWN
  mov [CAR_IMG_DIR + 1], DOWN
  mov BX, ystart
  add BX, 7
  mov [CAR_Y], BX
  mov [CAR_Y + 2], BX
  ret
  LOAD_CARS_LEFT:
  mov BX, ystart
  add BX, 5
  mov [CAR_Y], BX
  add BX, 9
  mov [CAR_Y + 2], BX
  cmp AL, LEFT
  jnz LOAD_CARS_RIGHT
  mov [CAR_IMG_DIR], LEFT
  mov [CAR_IMG_DIR + 1], LEFT
  mov BX, xstart
  add BX, 13
  mov [CAR_x], BX
  mov [CAR_x + 2], BX
  ret
  LOAD_CARS_RIGHT:
  mov [CAR_IMG_DIR], RIGHT
  mov [CAR_IMG_DIR + 1], RIGHT
  mov BX, xstart
  add BX, 7
  mov [CAR_x], BX
  mov [CAR_x + 2], BX
  ret
LOAD_CARS endp
;-------------------------------------------------------;
PRINT_TEST proc far
moveCursor 0CH, 0AH
    mov ah, 2h
    mov dl, CAR1_KEYS_STATUS
    add dl, '0'
    int 21H
    moveCursor 0FH, 0AH
    mov dl, CAR1_KEYS_STATUS[1]
    add dl, '0'
    int 21H
    moveCursor 012H, 0AH
    mov dl, CAR1_KEYS_STATUS[2]
    add dl, '0'
    int 21H
    moveCursor 015H, 0AH
    mov dl, CAR1_KEYS_STATUS[3]
    add dl, '0'
    int 21H
    moveCursor 0CH, 0FH
    mov ah, 2h
    mov dl, CAR2_KEYS_STATUS
    add dl, '0'
    int 21H
    moveCursor 0FH, 0FH
    mov dl, CAR2_KEYS_STATUS[1]
    add dl, '0'
    int 21H
    moveCursor 012H, 0FH
    mov dl, CAR2_KEYS_STATUS[2]
    add dl, '0'
    int 21H
    moveCursor 015H, 0FH
    mov dl, CAR2_KEYS_STATUS[3]
    add dl, '0'
    int 21H

    moveCursor 0CH, 02H
    mov ah, 2h
    mov dl, CAR_POWER
    add dl, '0'
    int 21H
    moveCursor 0FH, 02H
    mov dl, CAR_POWER[1]
    add dl, '0'
    int 21H
    moveCursor 012H, 02H
    mov dl, CAR_MOVEMENT_DIR[1]
    add dl, '0'
    int 21H
    moveCursor 015H, 02H
    mov dl, CAR_IMG_DIR[1]
    add dl, '0'
    int 21H

ret
PRINT_TEST endp
end