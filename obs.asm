  ; GAME.asm
  EXTRN TIME_AUX:BYTE
  PUBLIC ADD_OBSTACLE
  PUBLIC CHECK_COLLISION
  PUBLIC DRAW_OBSTACLES
.model small
.data
  ; Constants
  CAR_WIDTH EQU 06h       ; The width of all cars
  CAR_HEIGHT EQU 0Bh      ; The height of all cars
  DOWN EQU 1
  ; Variables
  MAX_OBSTACLES_NUM EQU 30
  TYPE_WIDTH  DB 7
  TYPE_HEIGHT DB 7
  TYPE0 DB 49 dup(130)
  OLD_TIME_AUX DB 0
  OBSTACLES_COUNT DW 0
  OBSTACLES_TYPE DW MAX_OBSTACLES_NUM dup(-1)
  OBSTACLES_X DW MAX_OBSTACLES_NUM dup(-1)                            ; OBSTACLE_Center_X
  OBSTACLES_Y DW MAX_OBSTACLES_NUM dup(-1)                            ; OBSTACLE_Center_Y
  PLAYER_X DW ?
  PLAYER_Y DW ?
  PLAYER_DIRECTION DB ?
.code
;-------------------------------------------------------
ADD_OBSTACLE proc far                   ; CX: OBSTACLE_X, DX: OBSTACLE_Y, AX: Type
  mov BX, OBSTACLES_COUNT
  cmp BL, MAX_OBSTACLES_NUM
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
  cmp BX, 0
  jz EXIT_CHECK_COLLISION
  CHECK_OBSTACLE_COLLISION:
    sub BX, 2
    mov DL, 6
    mov DH, 11
    mov AL, PLAYER_DIRECTION
    cmp AL, 3
    jnz SKIP_DIMENSION_SWITCH           ; IF Vertical DL = W, DH = H
    cmp AL, 2
    jnz SKIP_DIMENSION_SWITCH           ; IF Vertical DL = W, DH = H
    mov CL, 8
    rol DX, CL                          ; ELSE DL = H, DH = W
    SKIP_DIMENSION_SWITCH:
    push BX
    mov BX, [OBSTACLES_TYPE + BX]
    add DL, [TYPE_WIDTH + BX]           ; Vertical: DL = W/2 + PW/2
                                        ; Horizontal: DL = W/2 + PH/2
    add DH, [TYPE_HEIGHT + BX]          ; Vertical: DH = H/2 + PH/2
                                        ; Horizontal: DH = H/2 + PW/2
    pop BX
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
    jnl CHECK_NEXT_OBSTACLE
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
    jnl CHECK_NEXT_OBSTACLE
    sub DL, AL                          ; Stores the needed Y to move
    shr DL, 1
    xor AX, AX                          ; ZF = 1 since a collision has occured
    jmp EXIT_CHECK_COLLISION
    ; Loop On The Next Obstacle
    CHECK_NEXT_OBSTACLE:
    cmp BX, 0
    jnz CHECK_OBSTACLE_COLLISION
  or AX, -1                            ; ZF = 0 since no collision has occured
  EXIT_CHECK_COLLISION:
  ret
CHECK_COLLISION endp
;-------------------------------------------------------
DRAW_OBSTACLES proc far
  mov AX, 0A000h
  mov ES, AX
  mov BX, OBSTACLES_COUNT
  DRAW_OBSTACLE:
    sub BX, 2
    mov AX, OBSTACLES_TYPE[BX]
    mov CX, OBSTACLES_X[BX]
    mov DX, OBSTACLES_Y[BX]
    cmp AX, -1                          ; TYPE -1
    jz EXIT_DRAW_OBSTACLES
    cmp AX, 0                           ; TYPE 0: Obstacle
    jnz SKIP_0
    call DRAW_TYPE_0
    EXIT_DRAW_OBSTACLES:
    SKIP_0:

    ; Loop On The Next Obstacle
    cmp BX, 0
    jnz DRAW_OBSTACLE
  ret
DRAW_OBSTACLES endp
;-------------------------------------------------------
DRAW_TYPE_0 proc near                   ; CX: OBSTACLE_CENTER_X, DX: OBSTACLE_CENTER_Y
  ; Send coordinates to top left corner
  xor AX, AX
  mov AL, TYPE_WIDTH[0]
  shr AL, 1
  sub CX, AX
  mov AL, TYPE_HEIGHT[0]
  shr AL, 1
  sub DX, AX
  ; Get DI Index from CX and DX
  mov AX, 320
  mul DX
  add AX, CX
  mov DI, AX                            ; Index = Row * 320 + Col
  lea SI, TYPE0                         ; Source IMG
  XOR CX, CX
  XOR DX, DX
  mov DL, TYPE_HEIGHT[0]
  mov CL, TYPE_WIDTH[0]
  DRAW_TYPE_0_COL:
    rep MOVSB
    mov CL, TYPE_WIDTH[0]
    add DI, 320
    sub DI, CX
    dec DX
    cmp DX, 0
    jnz DRAW_TYPE_0_COL
  ret
DRAW_TYPE_0 endp
;-------------------------------------------------------
end