  ; GAME.asm
  EXTRN TIME_AUX:BYTE
  PUBLIC ADD_OBSTACLE
  PUBLIC CHECK_COLLISION
  PUBLIC DRAW_OBSTACLES
  PUBLIC OBSTACLES_COUNT
.model small
.data
  ; Constants
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
  MAX_OBSTACLES_NUM EQU 100
  TYPE_WIDTH  DB 5, 7, 7, 7
  TYPE_HEIGHT DB 5, 7, 7, 7
  TIRE_IMG        DB  0,  0,  0,  0,  0 
                  DB  0,  0,  0,  0,  0 
                  DB  0,  0, 15,  0,  0
                  DB  0,  0,  0,  0,  0 
                  DB  0,  0,  0,  0,  0 
  SPEED_BOOST_IMG DB  0,  0, 43, 43, 43,  0,  0
                  DB  0, 43, 43, 43, 43, 43,  0
                  DB 43, 43, 43, 43, 43, 43, 43
                  DB 43, 43, 43, 43, 43, 43, 43
                  DB 43, 43, 43, 43, 43, 43, 43
                  DB  0, 43, 43, 43, 43, 43,  0
                  DB  0,  0, 43, 43, 43,  0,  0
  SLOW_DOWN_IMG   DB  0,  0, 13, 13, 13,  0,  0
                  DB  0, 13, 13, 13, 13, 13,  0
                  DB 13, 13, 13, 13, 13, 13, 13
                  DB 13, 13, 13, 13, 13, 13, 13
                  DB 13, 13, 13, 13, 13, 13, 13
                  DB  0, 13, 13, 13, 13, 13,  0
                  DB  0,  0, 13, 13, 13,  0,  0
  DROP_TIRE_IMG   DB  0,  0, 15, 43, 15,  0,  0
                  DB  0, 43, 15, 43, 15, 43,  0
                  DB 43, 43, 15, 43, 15, 43, 43
                  DB 43, 43, 15, 43, 15, 43, 43
                  DB 43, 43, 15, 43, 15, 43, 43
                  DB  0, 43, 15, 43, 15, 43,  0
                  DB  0,  0, 15, 43, 15,  0,  0
  PASS_TIRE_IMG   DB  0,  0, 53, 43, 53,  0,  0
                  DB  0, 53, 53, 43, 53, 53,  0
                  DB 53, 53, 53, 43, 53, 53, 53
                  DB 53, 53, 53, 43, 53, 53, 53
                  DB 53, 53, 53, 43, 53, 53, 53
                  DB  0, 53, 53, 43, 53, 53,  0
                  DB  0,  0, 53, 43, 53,  0,  0
  ;TYPE1 DB 25 dup(09h)
  OLD_TIME_AUX DB 0
  OBSTACLES_COUNT DW 0
  OBSTACLES_TYPE DW MAX_OBSTACLES_NUM dup(-1)
  OBSTACLES_X DW MAX_OBSTACLES_NUM dup(-1)                            ; OBSTACLE_Center_X
  OBSTACLES_Y DW MAX_OBSTACLES_NUM dup(-1)                            ; OBSTACLE_Center_Y
  PLAYER_X DW ?
  PLAYER_Y DW ?
  PLAYER_DIRECTION DB ?
  CURR_ENTITY_WIDTH DB ?
  CURR_ENTITY_HEIGHT DB ?
  CURR_TRANSPARENT_COLOR DB ?
.code
;-------------------------------------------------------
ADD_OBSTACLE proc far                   ; CX: OBSTACLE_X, DX: OBSTACLE_Y, AX: Type
  xor BX, BX
  mov BL, AH
  mov OBSTACLES_COUNT, BX
  cmp BL, MAX_OBSTACLES_NUM
  mov AH, 0
  jnl EXIT_ADD_OBSTACLE
  mov OBSTACLES_X[BX], CX
  mov OBSTACLES_Y[BX], DX
  mov OBSTACLES_TYPE[BX], AX
  mov AX, 2
  add [OBSTACLES_COUNT], AX
  EXIT_ADD_OBSTACLE:
  ret
ADD_OBSTACLE endp
;-------------------------------------------------------
CHECK_COLLISION proc far                ; CX: CAR_CenterX, [SI]: CAR_CenterY, AL: MOVEMENT_DIR
                                        ; Returns AX = 1, ZF = 1, DH = delta(X), DL = delta(Y) on collision
  mov PLAYER_DIRECTION, AL
  mov PLAYER_X, CX
  mov PLAYER_Y, DX
  mov BX, OBSTACLES_COUNT
  jmp CHECK_NEXT_ENTITY
  ENTITY_COLLISION_LOOP:
    sub BX, 2
    push BX
    call CHECK_ENTITY_COLLISION
    mov AX, BX
    pop BX
    cmp AX, 0
    jnz NOT_OBSTACLE
    call CHECK_OBSTACLE_COLLISION
    cmp AX, -1
    jz EXIT_CHECK_COLLISION
    ;jmp CHECK_NEXT_ENTITY
    NOT_OBSTACLE:
    ; Loop On The Next Obstacle
    CHECK_NEXT_ENTITY:
    cmp BX, 0
    jnz ENTITY_COLLISION_LOOP
  or AX, -1                            ; ZF = 0 since no collision has occured
  EXIT_CHECK_COLLISION:
  ret
CHECK_COLLISION endp
;-------------------------------------------------------
CHECK_ENTITY_COLLISION proc near
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
  mov BX, [OBSTACLES_TYPE + BX]
  add DL, [TYPE_WIDTH + BX]           ; Vertical: DH = W/2 + PW/2
                                      ; Horizontal: DH = W/2 + PH/2
  add DH, [TYPE_HEIGHT + BX]          ; Vertical: DL = H/2 + PH/2
                                      ; Horizontal: DL = H/2 + PW/2
  ret
CHECK_ENTITY_COLLISION endp
;-------------------------------------------------------
CHECK_OBSTACLE_COLLISION proc near
  ; IF (abs(x - Px) >= DH)  isn't colliding
    mov AX, [OBSTACLES_X + BX]
    mov CX, PLAYER_X
    cmp AX, CX
    jnl ABSOLUTE_X
    xchg AX, CX
    ABSOLUTE_X:
    sub AX, CX
    mov CX, 0
    mov CL, DH
    shl AX, 1
    cmp AX, CX
    jnl EXIT_CHECK_OBSTACLE_COLLISION
    sub DH, AL                          ; Stores the needed X to move
    shr DH, 1
    ; IF (abs(y - Py) >= DL)  isn't colliding
    mov AX, [OBSTACLES_Y + BX]
    mov CX, PLAYER_Y
    cmp AX, CX
    jnl ABSOLUTE_Y
    xchg AX, CX
    ABSOLUTE_Y:
    sub AX, CX
    mov CX, 0
    mov CL, DL
    shl AX, 1
    cmp AX, CX
    jnl EXIT_CHECK_OBSTACLE_COLLISION
    sub DL, AL                          ; Stores the needed Y to move
    shr DL, 1
    xor AX, AX                          ; ZF = 1 since a collision has occured
    mov AX, -1
    EXIT_CHECK_OBSTACLE_COLLISION:
    ret
CHECK_OBSTACLE_COLLISION endp
;-------------------------------------------------------
DRAW_OBSTACLES proc far
  mov AX, 0A000h
  mov ES, AX
  mov BX, OBSTACLES_COUNT
  cmp BX, 0
  jz EXIT_DRAW_OBSTACLES
  DRAW_OBSTACLE:
    sub BX, 2
    mov AX, OBSTACLES_TYPE[BX]
    mov CX, OBSTACLES_X[BX]
    mov DX, OBSTACLES_Y[BX]
    cmp AX, -1                          ; TYPE -1
    jz EXIT_DRAW_OBSTACLES
    cmp AX, 0                           ; TYPE 0: Obstacle
    jnz SKIP_TIRE
    call DRAW_TIRE
    jmp EXIT_DRAW_OBSTACLES
    SKIP_TIRE:
    cmp AX, 1                           ; TYPE 0: Obstacle
    jnz SKIP_SPEED_BOOST
    call DRAW_SPEED_BOOST
    jmp EXIT_DRAW_OBSTACLES
    SKIP_SPEED_BOOST:
    cmp AX, 2                           ; TYPE 0: Obstacle
    jnz SKIP_SLOW_DOWN
    call DRAW_SLOW_DOWN
    jmp EXIT_DRAW_OBSTACLES
    SKIP_SLOW_DOWN:
    cmp AX, 3                           ; TYPE 0: Obstacle
    jnz SKIP_DROP_OBSTACLE
    call DRAW_DROP_OBSTACLE
    jmp EXIT_DRAW_OBSTACLES
    SKIP_DROP_OBSTACLE:

    EXIT_DRAW_OBSTACLES:
    ; Loop On The Next Obstacle
    cmp BX, 0
    jnz DRAW_OBSTACLE
  ret
DRAW_OBSTACLES endp
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