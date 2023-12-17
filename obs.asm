  ; GAME.asm
  EXTRN TIME_SEC:BYTE
  ; PATHGEN.asm
  EXTRN RANDOM_SPAWN_POWERUP:FAR
  EXTRN CLEAR_ENTITY:FAR
  PUBLIC ADD_OBSTACLE
  PUBLIC CHECK_COLLISION
  PUBLIC DRAW_ENTITIES
  PUBLIC UPDATE_ENTITIES
.model small
.data
  ; Constants
  RANDOM_SPAWN EQU 2               ; The width of all cars
  CAR_WIDTH EQU 05h               ; The width of all cars
  CAR_HEIGHT EQU 09h               ; The height of all cars
  UP EQU 0
  DOWN EQU 1
  RIGHT EQU 2
  LEFT EQU 3
  UP_RIGHT EQU 4
  DOWN_LEFT EQU 5
  UP_LEFT EQU 6
  DOWN_RIGHT EQU 7
  ; Variables
  ; 0 Obstacle, 1 Speed Boost, 2 Slow down, 3 Drop an Obstacle, 4 Pass through
  MAX_ENTITIES_NUM EQU 100
  OLD_TIME_SEC DB 0
  RANDOM_SPAWN_TIME DB RANDOM_SPAWN
  TYPE_WIDTH  DB 5, 5, 5, 5, 5
  TYPE_HEIGHT DB 5, 5, 5, 5, 5
  TIRE_IMG        DB   0,   0,   0,   0,   0 
                  DB   0,   0,   0,   0,   0 
                  DB   0,   0, 1Fh,   0,   0
                  DB   0,   0,   0,   0,   0 
                  DB   0,   0,   0,   0,   0 
  SPEED_BOOST_IMG DB 2Bh, 2Bh, 2Ch, 2Bh, 2Bh
                  DB 2Bh, 2Ch, 2Ch, 2Ch, 2Bh
                  DB 2Ch, 2Ch, 2Ch, 2Ch, 2Ch
                  DB 2Bh, 2Ch, 2Ch, 2Ch, 2Bh
                  DB 2Bh, 2Bh, 2Ch, 2Bh, 2Bh
  SLOW_DOWN_IMG   DB 37h, 37h, 37h, 37h, 37h
                  DB 37h, 39h, 39h, 39h, 37h
                  DB 39h, 39h, 39h, 39h, 39h
                  DB 37h, 39h, 39h, 39h, 37h
                  DB 37h, 37h, 37h, 37h, 37h
  DROP_TIRE_IMG   DB 11h, 11h, 18h, 11h, 11h
                  DB 11h, 17h, 17h, 17h, 11h
                  DB 18h, 18h, 17h, 18h, 18h
                  DB 11h, 18h, 18h, 18h, 11h
                  DB 11h, 11h, 18h, 11h, 11h
  PASS_TIRE_IMG   DB 35h, 36h, 36h, 36h, 35h
                  DB 35h, 34h, 34h, 34h, 35h
                  DB 35h, 34h, 34h, 34h, 35h
                  DB 36h, 34h, 34h, 34h, 36h
                  DB 36h, 35h, 34h, 35h, 36h
  ;TYPE1 DB 25 dup(09h)
  OLD_TIME_AUX DB 0
  ENTITIES_COUNT DW 0
  ENTITIES_TYPE DW MAX_ENTITIES_NUM dup(-1)
  ENTITIES_X DW MAX_ENTITIES_NUM dup(-1)                            ; OBSTACLE_Center_X
  ENTITIES_Y DW MAX_ENTITIES_NUM dup(-1)                            ; OBSTACLE_Center_Y
  PLAYER_X DW ?
  PLAYER_Y DW ?
  PLAYER_DIRECTION DB ?
  CURR_ENTITY_WIDTH DB ?
  CURR_ENTITY_HEIGHT DB ?
  CAN_PASS DB ?
  CURR_TRANSPARENT_COLOR DB ?
.code
;-------------------------------------------------------
ADD_OBSTACLE proc far                   ; CX: OBSTACLE_X, DX: OBSTACLE_Y, AX: Type
  xor BX, BX
  cmp AH, -1
  jnz DONT_RESET_COUNT
  mov AX, 0
  mov ENTITIES_COUNT, AX
  jmp EXIT_ADD_OBSTACLE
  DONT_RESET_COUNT:
  mov BX, ENTITIES_COUNT
  cmp BL, MAX_ENTITIES_NUM
  jnl EXIT_ADD_OBSTACLE
  mov AH, 0
  jnl EXIT_ADD_OBSTACLE
  mov ENTITIES_X[BX], CX
  mov ENTITIES_Y[BX], DX
  mov ENTITIES_TYPE[BX], AX
  mov AX, 2
  add [ENTITIES_COUNT], AX
  EXIT_ADD_OBSTACLE:
  ret
ADD_OBSTACLE endp
;-------------------------------------------------------
UPDATE_ENTITIES proc far
  ;HANDLE RANDOM SPAWN
  call RANDOM_SPAWN_ENTITY
  ret
UPDATE_ENTITIES endp
;-------------------------------------------------------
RANDOM_SPAWN_ENTITY proc near
  mov AL, TIME_SEC
  cmp AL, OLD_TIME_SEC
  jz EXIT_RANDOM_SPAWN
  mov OLD_TIME_SEC, AL
  dec RANDOM_SPAWN_TIME
  jnz SKIP_SPAWN
  mov RANDOM_SPAWN_TIME, RANDOM_SPAWN
  call RANDOM_SPAWN_POWERUP
  SKIP_SPAWN:
  EXIT_RANDOM_SPAWN:
  ret
RANDOM_SPAWN_ENTITY endp
;-------------------------------------------------------
CHECK_COLLISION proc far                ; CX: CAR_CenterX, [SI]: CAR_CenterY, AL: MOVEMENT_DIR, AH: CAN PASS
                                        ; Returns AX = 1, ZF = 1, DH = delta(X), DL = delta(Y) on collision
  push DI
  mov PLAYER_DIRECTION, AL
  mov CAN_PASS, AH
  mov PLAYER_X, CX
  mov PLAYER_Y, DX
  mov BX, ENTITIES_COUNT
  jmp CHECK_NEXT_ENTITY
  ENTITY_COLLISION_LOOP:
    sub BX, 2
    call CHECK_ENTITY_COLLISION
    cmp AL, -1
    jz COLLIDED
    ; Loop On The Next Obstacle
    CHECK_NEXT_ENTITY:
    cmp BX, 0
    jnz ENTITY_COLLISION_LOOP
  mov AH, 0
  or AL, -1                            ; ZF = 0 since no collision has occured
  EXIT_CHECK_COLLISION:
  pop DI
  ret
  COLLIDED:
  mov CX, DI
  pop DI
  cmp AH, 0
  ret
CHECK_COLLISION endp
;-------------------------------------------------------
CHECK_ENTITY_COLLISION proc near
  mov DI, 0
  mov DL, CAR_HEIGHT
  mov DH, CAR_WIDTH
  mov AL, PLAYER_DIRECTION
  cmp AL, RIGHT
  jl SKIP_DIMENSION_SWITCH           ; IF Vertical DH = PW, DL = PH
  cmp AL, LEFT
  jg SKIP_DIMENSION_SWITCH           ; IF Vertical DH = PW, DL = PH
  mov CL, 8
  rol DX, CL                          ; ELSE DH = PH, DL = PW
  SKIP_DIMENSION_SWITCH:
  mov AX, [ENTITIES_TYPE + BX]
  cmp AX, 10
  jz EXIT_CHECK_ENTITY_COLLISION
  push BX
  mov BX, AX
  add DL, [TYPE_WIDTH + BX]           ; Vertical: DH = W/2 + PW/2
                                      ; Horizontal: DH = W/2 + PH/2
  add DH, [TYPE_HEIGHT + BX]          ; Vertical: DL = H/2 + PH/2
                                      ; Horizontal: DL = H/2 + PW/2
  mov AX, BX
  pop BX
  push AX
  ; IF (abs(x - Px) >= DH)  isn't colliding
  mov AX, [ENTITIES_X + BX]
  mov CX, PLAYER_X
  cmp AX, CX
  mov DI, LEFT                          ; CL = 3 LEFT
  jnl ABSOLUTE_X
  mov DI, RIGHT                         ; CL = 2 then Car is on the Entity's right side (RIGHT 2)
  xchg AX, CX
  ABSOLUTE_X:
  sub AX, CX
  mov CX, 0
  mov CL, DH
  shl AX, 1
  cmp AX, CX
  jnl NO_COLLISION
  sub DH, AL                          ; Stores the needed X to move
  shr DH, 1
  ; IF (abs(y - Py) >= DL)  isn't colliding
  mov AX, [ENTITIES_Y + BX]
  mov CX, PLAYER_Y
  cmp AX, CX
  jnl ABSOLUTE_Y
  add DI, 256                       ; BH = 1 then Car is below the Entity (DOWN 1)
  xchg AX, CX
  ABSOLUTE_Y:
  sub AX, CX
  mov CX, 0
  mov CL, DL
  shl AX, 1
  cmp AX, CX
  jnl NO_COLLISION
  sub DL, AL                          ; Stores the needed Y to move
  shr DL, 1
  pop AX
  cmp AX, 0
  jnz NOT_OBSTACLE_COLLISION
  call HANDLE_OBSTACLE_COLLISION
  jmp EXIT_CHECK_ENTITY_COLLISION
  NOT_OBSTACLE_COLLISION:
  call HANDLE_POWER_COLLISION
  jmp EXIT_CHECK_ENTITY_COLLISION
  NO_COLLISION:
  pop AX
  EXIT_CHECK_ENTITY_COLLISION:
  ret
CHECK_ENTITY_COLLISION endp
;-------------------------------------------------------
HANDLE_OBSTACLE_COLLISION proc near
  push BX
  push DX
  mov AH, CAN_PASS
  cmp AH, 0
  jz CANT_PASS_THROUGH
  mov CX, 10
  mov [ENTITIES_TYPE + BX], CX
  mov CX, [ENTITIES_X + BX]
  mov DX, [ENTITIES_Y + BX]
  mov BX, 5
  call CLEAR_ENTITY
  CANT_PASS_THROUGH:
  xor AH, AH                           ; AH = 0 since a collision has occured
  mov AL, -1
  pop DX
  pop BX
  ret
HANDLE_OBSTACLE_COLLISION endp
;-------------------------------------------------------
HANDLE_POWER_COLLISION proc near
  mov CX, 10
  mov [ENTITIES_TYPE + BX], CX
  mov CX, [ENTITIES_X + BX]
  mov DX, [ENTITIES_Y + BX]
  mov BX, 7
  call CLEAR_ENTITY
  mov AH, AL
  mov AL, -1
  ret
HANDLE_POWER_COLLISION endp
;-------------------------------------------------------
DRAW_ENTITIES proc far
  mov BX, ENTITIES_COUNT
  cmp BX, 0
  jz EXIT_DRAW_ENTITIES
  DRAW_ENTITY_LOOP:
    sub BX, 2
    mov AX, ENTITIES_TYPE[BX]
    mov CX, ENTITIES_X[BX]
    mov DX, ENTITIES_Y[BX]
    cmp AX, -1                          ; TYPE -1
    jz EXIT_DRAW_ENTITIES
    cmp AX, 0                           ; TYPE 0: Obstacle
    jnz SKIP_TIRE
    call DRAW_TIRE
    jmp EXIT_DRAW_ENTITIES
    SKIP_TIRE:
    cmp AX, 1                           ; TYPE 0: Obstacle
    jnz SKIP_SPEED_BOOST
    call DRAW_SPEED_BOOST
    jmp EXIT_DRAW_ENTITIES
    SKIP_SPEED_BOOST:
    cmp AX, 2                           ; TYPE 0: Obstacle
    jnz SKIP_SLOW_DOWN
    call DRAW_SLOW_DOWN
    jmp EXIT_DRAW_ENTITIES
    SKIP_SLOW_DOWN:
    cmp AX, 3                           ; TYPE 0: Obstacle
    jnz SKIP_DROP_OBSTACLE
    call DRAW_DROP_OBSTACLE
    jmp EXIT_DRAW_ENTITIES
    SKIP_DROP_OBSTACLE:
    cmp AX, 4                           ; TYPE 0: Obstacle
    jnz SKIP_PASS_OBSTACLE
    call DRAW_PASS_OBSTACLE
    jmp EXIT_DRAW_ENTITIES
    SKIP_PASS_OBSTACLE:

    EXIT_DRAW_ENTITIES:
    ; Loop On The Next Obstacle
    cmp BX, 0
    jnz DRAW_ENTITY_LOOP
  ret
DRAW_ENTITIES endp
;-------------------------------------------------------
DRAW_TIRE proc near                   ; CX: OBSTACLE_CENTER_X, DX: OBSTACLE_CENTER_Y
  push BX
  push AX
  mov AL, TYPE_WIDTH[0]
  mov AH, TYPE_HEIGHT[0]
  mov CURR_ENTITY_WIDTH, AL
  mov CURR_ENTITY_HEIGHT, AH
  mov AL, -1
  mov CURR_TRANSPARENT_COLOR, AL
  lea SI, TIRE_IMG
  call DRAW_SELECTED_ENTITY
  pop AX
  pop BX
  ret
DRAW_TIRE endp
;-------------------------------------------------------
DRAW_SPEED_BOOST proc near
  push BX
  push AX
  mov AL, TYPE_WIDTH[1]
  mov AH, TYPE_HEIGHT[1]
  mov CURR_ENTITY_WIDTH, AL
  mov CURR_ENTITY_HEIGHT, AH
  mov AL, 0
  mov CURR_TRANSPARENT_COLOR, AL
  lea SI, SPEED_BOOST_IMG
  call DRAW_SELECTED_ENTITY
  pop AX
  pop BX
  ret
DRAW_SPEED_BOOST endp
;-------------------------------------------------------
DRAW_SLOW_DOWN proc near
  push BX
  push AX
  mov AL, TYPE_WIDTH[2]
  mov AH, TYPE_HEIGHT[2]
  mov CURR_ENTITY_WIDTH, AL
  mov CURR_ENTITY_HEIGHT, AH
  mov AL, 0
  mov CURR_TRANSPARENT_COLOR, AL
  lea SI, SLOW_DOWN_IMG
  call DRAW_SELECTED_ENTITY
  pop AX
  pop BX
  ret
DRAW_SLOW_DOWN endp
;-------------------------------------------------------
DRAW_DROP_OBSTACLE proc near
  push BX
  push AX
  mov AL, TYPE_WIDTH[3]
  mov AH, TYPE_HEIGHT[3]
  mov CURR_ENTITY_WIDTH, AL
  mov CURR_ENTITY_HEIGHT, AH
  mov AL, 0
  mov CURR_TRANSPARENT_COLOR, AL
  lea SI, DROP_TIRE_IMG
  call DRAW_SELECTED_ENTITY
  pop AX
  pop BX
  ret
DRAW_DROP_OBSTACLE endp
;-------------------------------------------------------
DRAW_PASS_OBSTACLE proc near
  push BX
  push AX
  mov AL, TYPE_WIDTH[4]
  mov AH, TYPE_HEIGHT[4]
  mov CURR_ENTITY_WIDTH, AL
  mov CURR_ENTITY_HEIGHT, AH
  mov AL, 0
  mov CURR_TRANSPARENT_COLOR, AL
  lea SI, PASS_TIRE_IMG
  call DRAW_SELECTED_ENTITY
  pop AX
  pop BX
  ret
DRAW_PASS_OBSTACLE endp
;-------------------------------------------------------
DRAW_SELECTED_ENTITY proc near
  ; Send coordinates to top left corner
  xor AX, AX
  mov AL, CURR_ENTITY_WIDTH
  shr AL, 1
  sub CX, AX
  mov AL, CURR_ENTITY_HEIGHT
  shr AL, 1
  sub DX, AX
  ; Get DI Index from CX and DX
  mov AL, CURR_ENTITY_WIDTH
  mov AH, CURR_ENTITY_HEIGHT
  
  DRAW_ENTITY_COL:
    push AX
    mov AH, 0Ch
    mov AL, [SI]
    cmp CURR_TRANSPARENT_COLOR, AL
    jz TRANSPARENT_ENTITY
    int 10h
    TRANSPARENT_ENTITY:
    pop AX
    inc SI
    inc CX
    dec AL
    jnz DRAW_ENTITY_COL
    mov BH, 0
    mov BL, CURR_ENTITY_HEIGHT
    sub CX, BX
    mov AL, BL
    inc DX
    dec AH
    jnz DRAW_ENTITY_COL
  ret
DRAW_SELECTED_ENTITY endp
;-------------------------------------------------------
end