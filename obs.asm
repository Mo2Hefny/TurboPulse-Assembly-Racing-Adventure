  EXTRN TIME_AUX:BYTE
  EXTRN CAR1_X:WORD
  EXTRN CAR1_Y:WORD
  EXTRN CAR2_X:WORD
  EXTRN CAR2_Y:WORD
  PUBLIC ADD_OBSTACLE
  PUBLIC CHECK_COLLISION
  PUBLIC DRAW_OBSTACLES
.model small
.data
  MAX_OBSTACLES_NUM EQU 30
  TYPE_WIDTH  DB 5
  TYPE_HEIGHT DB 5
  TYPE0 DB 25 dup(25)
  OLD_TIME_AUX DB 0
  OBSTACLES_COUNT DW 0
  OBSTACLES_TYPE DW MAX_OBSTACLES_NUM dup(-1)
  OBSTACLES_X DW MAX_OBSTACLES_NUM dup(-1)
  OBSTACLES_Y DW MAX_OBSTACLES_NUM dup(-1)
.code
;-------------------------------------------------------
ADD_OBSTACLE proc far                   ; CX: X, DX: Y, AX: Type
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
CHECK_COLLISION proc far
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
    cmp AX, 0                           ; TYPE 0
    jnz SKIP_0
    call DRAW_TYPE_0
    SKIP_0:

    ; Loop On The Next Obstacle
    cmp BX, 0
    jnz DRAW_OBSTACLE
  ret
DRAW_OBSTACLES endp
;-------------------------------------------------------
DRAW_TYPE_0 proc near                   ; CX: OBSTACLE_X, DX: OBSTACLE_Y
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
    add DI, 315
    ;sub DI, CX
    dec DX
    cmp DX, 0
    jnz DRAW_TYPE_0_COL
  ret
DRAW_TYPE_0 endp
;-------------------------------------------------------
end