    PUBLIC TRACK
    ; OBSTACLES.asm
    EXTRN ADD_OBSTACLE:FAR
    EXTRN ENTITIES_COUNT:WORD
    PUBLIC GENERATE_TRACK
    PUBLIC Load_Track
    PUBLIC RANDOM_SPAWN_POWERUP
    PUBLIC CLEAR_ENTITY
    PUBLIC CHECK_CAR_ON_PATH
    PUBLIC GET_BLOCK_DEPTH
    PUBLIC HANDLE_DROP_POSITION
    PUBLIC xstart
    PUBLIC ystart
    PUBLIC pathlength
.model huge
.stack 64
.data
    ; Constants
    GAME_BORDER_X_MIN     EQU 0                ; track boundries
    GAME_BORDER_X_MAX     EQU 320
    GAME_BORDER_Y_MIN     EQU 0
    GAME_BORDER_Y_MAX     EQU 160
    SCREEN_WIDTH          EQU 320
    SCREEN_HEIGHT         EQU 200
    BLOCK_WIDTH           EQU 20
    BLOCK_HEIGHT          EQU 20
    GRID_WIDTH            EQU GAME_BORDER_X_MAX / BLOCK_WIDTH
    GRID_HEIGHT           EQU GAME_BORDER_Y_MAX / BLOCK_HEIGHT
    WHITE_STRIP_WIDTH     EQU 1
    WHITE_STRIP_HEIGHT    EQU 4
    GREY                  EQU 08h
    GREEN                 EQU 02h
    RED                   EQU 0Ch
    WHITE                 EQU 0Fh
    BLACK                 EQU 0
    UP EQU 0
    DOWN EQU 1
    RIGHT EQU 2
    LEFT EQU 3
    FINISH EQU 4

    direction        db ?                ; the randomized direction

    pathlength       dw 0                ;Current length of the track
    minpathlength    dw 50               ;MinPath Length Before Restarting

    xstart           dw 0                ; starting indeces
    ystart           dw 80
    GRID_INDEX       DW 40h              ; 10h each row, 8 rows
    CURR_X           dw ?                ;Current pntY
    CURR_Y           dw ?                ;Current pntX
    max_rand         dw 25               ;Max Trials To Draw Before Restart
    curr_rand        dw 0                ;Current Trials to Draw
    prev_rand        db 0
    FinishLineColor  db 4                ;Color Of Last Sqaure
    boolFinished     db 0                ;To color last Sqaure
    TRACK            DB 64000 DUP (?)    ;To save and Load Track
    Block_Percentage db 10               ;real Percentage
    Block_SIZE       DW 6                ;size of any block(path_block,boosters)
    Boost_Percentage db 20               ;100-this Percentage so if 90 its 10
    GRID             DB (GRID_WIDTH) * (GRID_HEIGHT) dup(-1)
    GRID_SIZE        EQU $-GRID
    DIRECTIONS       DB -1, 200 DUP(-2)   ; -1 (start), 4 (end), -2 (invalid)
    CURR_BLOCK       DW 0
    FINAL_BLOCK      DB 0
    VALID_BOT      DB 0
    VALID_UP      DB 0
    ;;;;;;;;;;;;;;;; done

.code
;-------------------------------------------------------
;-------------------- CLEANING ------------------------;
CLEAR_ENTITY proc far                                   ; CX: centerX of entity, DX: centerY of entity, BX: dimension
    push SI
    push DI
    push DX
    push CX
    push BX
    push AX
    push ES
    mov AX, 0A000h
    mov ES, AX
    ; Top Left
    shr BL, 1
    sub CX, BX
    sub DX, BX
    ; Get DI and SI indexing
    mov AX, SCREEN_WIDTH
    mul DX
    add AX, CX
    mov DI, AX
    lea SI, TRACK
    add SI, AX
    shl BL, 1
    or BL, 1
    mov DX, BX
    mov  ah,0ch
    CLEAR_ENTITY_ROW:             
        mov CX, BX
        rep MOVSB
        add SI, SCREEN_WIDTH
        sub SI, BX
        cmp SI, 57800
        jnb EXIT_CLEAR_ENTITY
        add DI, SCREEN_WIDTH
        sub DI, BX
        dec DX 
        jnz  CLEAR_ENTITY_ROW
    EXIT_CLEAR_ENTITY:
    pop ES
    pop AX
    pop BX
    pop CX
    pop DX
    pop DI
    pop SI
    ret
CLEAR_ENTITY endp
;-------------------------------------------------------
RESET_TRACK proc near
    push AX
    push BX
    push CX
    push DX
    push DI
    push ES
    push DS
    ; Reset grid
    mov AX, @data
    mov ES, AX
    lea DI, GRID
    mov CX, GRID_SIZE / 2
    mov AX, -1
    REP STOSW
    ; RESET COUNTERS
    mov CURR_BLOCK, 0
    mov  pathlength,1
    mov  curr_rand,0
    mov ah, -1
    call ADD_OBSTACLE
    call RANDOMIZE_START
    pop DS
    pop ES
    pop DI
    pop DX
    pop CX
    pop BX
    pop AX
    ret
RESET_TRACK endp
;-------------------------------------------------------
RESET_BACKGROUND proc near
    ; (Send to TRACK file)
    ; Set background color to WHITE
                      mov  AH, 06h                      ; Scroll up function
                      xor  AL, AL                       ; Clear entire screen
                      xor  CX, CX                       ; Upper left corner CH=row, CL=column
                      mov  DX, 134Fh                    ; lower right corner DH=row, DL=column
                      mov  BH, GREEN                      ; Green-BackGround
                      int  10h
                      mov  CX,1400h                       ; Upper left corner CH=row, CL=column
                      mov  DX, 184Fh                    ; lower right corner DH=row, DL=column
                      mov  BH, 00h                      ; Green-BackGround
                      int  10h
                      ret
RESET_BACKGROUND endp
;-------------------------------------------------------
;----------------- RANDOMIZATION ----------------------;
RANDOM_NUMBER proc near                 ; AH = RANDOM_NUMBER % BL
    push cx
    push dx
    mov  ah, 2ch
    int  21h
    mov  ah, 0
    mov  al, dl                       ;;micro seconds
    add al, prev_rand
    mov cl, dh
    ror al, cl
    ;mov cx, CURR_Y
    ;ror al, cl
    mov prev_rand, al
    div  bl
    pop dx
    pop cx
    ret
RANDOM_NUMBER endp
;-------------------------------------------------------
GET_RANDOM_INDEX proc near      ; BL: number of indexes, BH: multiply
 call RANDOM_NUMBER
 mov al, ah
 mov ah, 0
 mov bl, bh
 mul bl
 ret
GET_RANDOM_INDEX endp
;-------------------------------------------------------
RANDOM_DIRECTION proc
                      push bx                           ;1
                      push ax                           ;2
                      push dx                           ;3
                      push cx                           ;4
                      push di                           ;5
                      inc  curr_rand
                      mov  bl, 4
                      call RANDOM_NUMBER
                      mov  al, direction
                      xor  al, 1
                      cmp  ah, al
                      jnz  DONT_FIX
                      xor  ah, 1
    DONT_FIX:         
                      mov  direction,ah
                      pop  di                           ;5
                      pop  cx                           ;4
                      pop  dx                           ;3
                      pop  ax                           ;2
                      pop  bx                           ;1
                      ret
RANDOM_DIRECTION endp
;-------------------------------------------------------
RANDOMIZE_START proc near
    mov BL, GRID_SIZE / 2
    call RANDOM_NUMBER
    mov AL, AH
    mov AH, 0                           ; AX = NEW_INDEX
    mov GRID_INDEX, AX
    call GET_GRID_INDEX
    mov xstart, CX
    mov ystart, DX
    ret
RANDOMIZE_START endp
;-------------------------------------------------------
GET_GRID_INDEX proc near
    push BX
    push AX
    mov AX, GRID_INDEX
    mov BL, GRID_WIDTH
    div BL                              ; AL = INDEX / ROW_SIZE = Y, AH = X
    push AX
    mov AH, 0
    mov BL, BLOCK_HEIGHT
    mul BL
    mov DX, AX
    pop AX
    mov AL, AH
    mov AH, 0
    mov BL, BLOCK_WIDTH
    mul BL
    mov CX, AX
    pop AX
    pop BX
    ret
GET_GRID_INDEX endp
;-------------------------------------------------------
RANDOM_SPAWN_POWERUP proc far
  RANDOM_SPAWN_LOOP:
  mov CX, 0
  mov DX, 0
  mov BL, GAME_BORDER_X_MAX / BLOCK_WIDTH
  mov BH, BLOCK_WIDTH
  call GET_RANDOM_INDEX             ; 16 options, mul by 20
  add CX, AX
  mov BL, GAME_BORDER_Y_MAX / BLOCK_HEIGHT
  mov BH, BLOCK_HEIGHT
  call GET_RANDOM_INDEX             ; 16 options, mul by 20
  add DX, AX
  ; CHECK IF AVAILABLE
  mov AH, 0Dh
  int 10h
  cmp AL, RED
  jz RANDOM_SPAWN_LOOP
  cmp AL, GREEN
  jz RANDOM_SPAWN_LOOP
  call SPAWN_POWERUP
  ret
RANDOM_SPAWN_POWERUP endp
;-------------------------------------------------------
;------------------- GENERATION -----------------------;
Save_Track proc                                         ;;Function To Save Track From Screen to Array
                      mov  cx,0
                      mov  dx,0
                      mov  bx,320
                      MOV  di,180
                      mov  ah,0dh
                      lea  si,TRACK
    row8:             int  10h
                      mov  [si],al
                      inc  si
                      inc  cx
                      cmp  cx,bx
                      jz   column8
                      jmp  row8
    column8:          
                      sub  cx,320
                      inc  dx
                      cmp  dx,di
                      jz   exit8
                      jmp  row8
    exit8:            
                      ret
Save_Track endp
;-------------------------------------------------------
Load_Track proc                                         ;Function To Load Track From array to Screen
                      mov  cx,0
                      mov  dx,0
                      mov  bx,320
                      MOV  di,180
                      mov  ah,0ch
                      mov  si,offset TRACK
    row9:             mov  AL,[SI]
                      int  10h
                      inc  si
                      inc  cx
                      cmp  cx,bx
                      jz   column9
                      jmp  row9
    column9:          
                      sub  cx,320
                      inc  dx
                      cmp  dx,di
                      jz   exit9
                      jmp  row9
    exit9:            
                      ret
Load_Track endp
;-------------------------------------------------------
SPAWN_POWERUP proc near
  ;push DI
  mov bx, 0703h
  call GET_RANDOM_INDEX             ; 3 options, mul by 5
                                    ; 0, 5, 10
  add ax, 3                         ; 5, 10, 15
  add cx, ax
  mov bx, 0703h
  call GET_RANDOM_INDEX             ; 3 options, mul by 5
                                    ; 0, 5, 10
  add ax, 3                         ; 5, 10, 15
  add dx, ax
  mov bl, 4                         ; 4 options
  CALL RANDOM_NUMBER
  mov al, ah
  inc al
  ; CHECK IF AVAILABLE
  mov DI, AX
  mov BH, 0
  mov AH, 0Dh
  int 10h
  cmp AL, GREY
  jz VALID_SPAWN_LOCATION
  cmp AL, WHITE
  jz VALID_SPAWN_LOCATION
  jmp EXIT_SPAWN_POWERUP
  VALID_SPAWN_LOCATION:
  mov AX, DI
  call ADD_OBSTACLE
  EXIT_SPAWN_POWERUP:
  ;pop DI
  ret
SPAWN_POWERUP endp
;-------------------------------------------------------
PATH_BLOCK proc near                                        ;Draw Brown (06h) Square to Represent Path Block
                      push ax                           ;1
                      push bx                           ;2
                      push di                           ;3
                      call GET_GRID_INDEX
                      mov bx, 0703h
                      call GET_RANDOM_INDEX             ; 3 options, mul by 7
                                                        ; 0, 7, 14
                      add ax, 3                         ; 2, 10, 17
                      add cx, ax
                      mov bx, 0703h
                      call GET_RANDOM_INDEX             ; 3 options, mul by 7
                                                        ; 0, 7, 14
                      add ax, 3                         ; 2, 10, 17
                      add dx, ax
                      mov AL, 0
                      call ADD_OBSTACLE
                      pop  di                           ;3
                      pop  bx                           ;2
                      pop  ax                           ;1
                      ret
PATH_BLOCK endp
;-------------------------------------------------------
Make_Boost PROC near                                       ;Draw Boost
                      push ax                           ;1
                      push bx                           ;2
                      push di                           ;3
                      call GET_GRID_INDEX
                      ;push DI
                      mov bx, 0703h
                      call GET_RANDOM_INDEX             ; 3 options, mul by 5
                                                        ; 0, 5, 10
                      add ax, 3                         ; 5, 10, 15
                      add cx, ax
                      mov bx, 0703h
                      call GET_RANDOM_INDEX             ; 3 options, mul by 5
                                                        ; 0, 5, 10
                      add ax, 3                         ; 5, 10, 15
                      add dx, ax
                      mov bl, 4                         ; 4 options
                      CALL RANDOM_NUMBER
                      mov al, ah
                      inc al
                      call ADD_OBSTACLE
                      pop  di                           ;3
                      pop  bx                           ;2
                      pop  ax                           ;1
                      ret
Make_Boost ENDP
;-------------------------------------------------------
CREATE_BLOCK PROC near                                        ;Draw A gray Square to Represnt Our beautiful Track
                      push ax                           ;1
                      push bx                           ;2
                      push di                           ;3
                      ; cccccccc           count bits
                      ; Store direction in another array
                      mov  curr_rand, 0
                      inc  pathlength
                      ;call DRAW_BLOCK
                      lea BX, GRID
                      add BX, GRID_INDEX
                      mov AX, CURR_BLOCK
                      mov [BX], AL
                      mov dx, CURR_BLOCK
                      cmp dx, 2
                      jng Dont_Boost
                      mov bl, 100
                      call RANDOM_NUMBER
                      cmp  ah,Block_Percentage
                      ja   Dont_block
                      call PATH_BLOCK
                      jmp Dont_Boost
    Dont_block:       
                      mov bl, 100
                      call RANDOM_NUMBER
                      cmp  ah,Boost_Percentage
                      ja   Dont_Boost
                      call Make_Boost
    Dont_Boost:       
                      pop  di                           ;3
                      pop  bx                           ;2
                      pop  ax                           ;1
                      ret
CREATE_BLOCK ENDP
;-------------------------------------------------------
GENERATE_TRACK proc far

                      mov  AX, @data
                      mov  DS, AX
                      xor BX, BX
    ; Initialize Video Mode
    ;restart should clear screen and put in sqaurenumbers 0 and move the cx and dx to initial position
                      call RESET_BACKGROUND             ;Resest Our Green BackGround
                      call RESET_TRACK
    restart:                                            ;Restart Only if less than MinPathLength
                      push ax
                      mov  ax,minpathlength
                      cmp  pathlength,ax
                      pop  AX
                      jb   extra1
                      jmp  far ptr Terminate_Program
    extra1:           
                      call RESET_TRACK
                      mov  cx,xstart
                      mov  dx,ystart
                      ;call GET_GRID_INDEX
                      mov  CURR_X,cx
                      mov  CURR_Y,dx
                      call CREATE_BLOCK
    GENERATE_LOOP:    
                      mov  cx,CURR_X
                      mov  dx,CURR_Y
                      mov BX, GRID_INDEX
                      ;call GET_GRID_INDEX
                      CALL RANDOM_DIRECTION                ; Get a random direction
                      mov AL, direction
                      push ax
                      mov  ax,max_rand
                      cmp  curr_rand,ax
                      pop  AX
                      mov AL, -1
                      jz   restart
                      ; Process the direction to determine the movement
                      CMP  direction, UP                 ; Up
                      Jz   MOVE_UP
                      CMP  direction, DOWN                 ; Down 
                      Jnz   skip_MOVE_DOWN
                      Jmp   far ptr MOVE_DOWN
                      skip_MOVE_DOWN:
                      CMP  direction, LEFT                 ; Left
                      jnz  rightdirection
                      jmp  far ptr MOVE_LEFT
    rightdirection:   
                      CMP  direction, RIGHT                 ; Right
                      jnz  nodirection
                      jmp  far ptr MOVE_RIGHT
    nodirection:      
    cont:             JMP  GENERATE_LOOP
    MOVE_UP:          
                     ; call GET_GRID_INDEX
                      cmp  bx, GRID_WIDTH              ;if out of boundries
                      Jnl  skipupbound
                      jmp  far ptr GENERATE_LOOP
    skipupbound:      
                      sub BX, GRID_WIDTH
                      cmp [GRID + BX], AL
                      jnz cont
                      cmp  BX, GRID_WIDTH
                      jl   skipup                       ; New Block At Screen Top

                      sub BX, GRID_WIDTH
                      cmp [GRID + BX], AL
                      jnz cont
                      add BX, GRID_WIDTH
                      add  dx, BLOCK_HEIGHT
    skipup:           
                      cmp  cx, GAME_BORDER_X_MAX - BLOCK_WIDTH   ; if at right boundary
                      jz   skipup2

                      add  cx, BLOCK_WIDTH              ; if right pixel gray
                      add BX, 1
                      cmp [GRID + BX], AL
                      jnz   cont                ; New Block will generate loop (connected on its right)
                      sub  cx, BLOCK_WIDTH
                      sub BX, 1
    skipup2:          
                      cmp  cx, GAME_BORDER_X_MIN
                      jz   skipup3                      ; if at left boundary
                      sub  cx, BLOCK_WIDTH              ;if left pixel gray
                      sub BX, 1
                      cmp [GRID + BX], AL
                      jz  skipup3
                      jmp  far ptr GENERATE_LOOP        ; New Block will generate loop (connected on its left)
    skipup3:          sub  CURR_Y, BLOCK_HEIGHT
                      sub GRID_INDEX, GRID_WIDTH
                      call CREATE_BLOCK
                      mov al, UP                        ; Store UP direction
                      call STORE_DIRECTION
                      jmp  cont
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    MOVE_DOWN:        
                      cmp  bx, GRID_SIZE - GRID_WIDTH ;out of bound
                      jl  skipdownboundary
                      jmp  far ptr GENERATE_LOOP
    skipdownboundary:  
                      add BX, GRID_WIDTH
                      cmp [GRID + BX], AL
                      jz  extra2
                      jmp  far ptr GENERATE_LOOP
    extra2:           
                      cmp  bx, GRID_SIZE - GRID_WIDTH ;out of bound
                      jnl   skipdown

                      add BX, GRID_WIDTH
                      cmp [GRID + BX], AL
                      jz  extra3
                      jmp  far ptr GENERATE_LOOP
    extra3:           
                      sub BX, GRID_WIDTH

    skipdown:         
                      cmp  cx, GAME_BORDER_X_MAX - BLOCK_WIDTH  ; if at right boundrie
                      jz   skipdown2

                      add  cx, BLOCK_WIDTH              ;if right pixel gray
                      add BX, 1
                      cmp [GRID + BX], AL
                      jz  extra4
                      jmp  far ptr GENERATE_LOOP
    extra4:           
                      sub  cx, BLOCK_WIDTH
                      sub BX, 1
    skipdown2:        
                      cmp  cx, GAME_BORDER_X_MIN
                      jz   skipdown3

                      sub  cx, BLOCK_WIDTH              ;if left pixel gray
                      sub BX, 1
                      cmp [GRID + BX], AL
                      jz  skipdown3
                      jmp  far ptr GENERATE_LOOP
    skipdown3:        
                      add  CURR_Y, BLOCK_HEIGHT
                      add GRID_INDEX, GRID_WIDTH
                      call CREATE_BLOCK
                      mov al, DOWN
                      call STORE_DIRECTION
                      jmp  cont
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    MOVE_LEFT:        

                      cmp  cx, GAME_BORDER_X_MIN               ;if out of boundries
                      jnz  skipleftboundary
                      jmp  far ptr GENERATE_LOOP
    skipleftboundary:  

                      sub  cx, BLOCK_WIDTH
                      sub BX, 1
                      cmp [GRID + BX], AL
                      jz  skipleft
                      jmp  far ptr GENERATE_LOOP
    skipleft:         
                      cmp  bx, GRID_SIZE - GRID_WIDTH
                      jnl   skipleft2                    ; if lower pixel is gray
                      add BX, GRID_WIDTH
                      cmp [GRID + BX], AL
                      jz  extra5                       
                      jmp  far ptr GENERATE_LOOP
    extra5:           
                      sub BX, GRID_WIDTH
    skipleft2:        
                      cmp  bx, GRID_WIDTH
                      jl   skipleft3
                      sub BX, GRID_WIDTH
                      cmp [GRID + BX], AL
                      jz  extra6
                      jmp  far ptr GENERATE_LOOP
                      
    extra6:           
                      add BX, GRID_WIDTH
    skipleft3:        
                      cmp  cx, GAME_BORDER_X_MIN               ;if left pixel gray
                      jz   skipleft4
                      sub  cx, BLOCK_WIDTH
                      sub BX, 1
                      cmp [GRID + BX], AL
                      jz  skipleft4
                      jmp  far ptr GENERATE_LOOP
    skipleft4:        
                      sub  CURR_X, BLOCK_WIDTH
                      sub GRID_INDEX, 1
                      call CREATE_BLOCK
                      mov al, LEFT
                      call STORE_DIRECTION
                      jmp  cont
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    MOVE_RIGHT:       
                      cmp  cx, GAME_BORDER_X_MAX - BLOCK_WIDTH   ;if out of boundries
                      jnz  skiprightboundary
                      jmp  far ptr GENERATE_LOOP
    skiprightboundary: 
                      add  cx, BLOCK_WIDTH
                      add BX, 1
                      cmp [GRID + BX], AL
                      jz  skipright
                      jmp  far ptr GENERATE_LOOP
    skipright:        
                      cmp  bx, GRID_SIZE - GRID_WIDTH ;out of bound
                      jnl  skipright2
                      add BX, GRID_WIDTH
                      cmp [GRID + BX], AL
                      jz  extra7
                      jmp  far ptr GENERATE_LOOP
    extra7:           
                      sub BX, GRID_WIDTH
    skipright2:       
                      cmp  bx, GRID_WIDTH
                      jl   skipright3
                      sub BX, GRID_WIDTH
                      cmp [GRID + BX], AL
                      jz  extra8
                      jmp  far ptr GENERATE_LOOP
    extra8:           
                      add BX, GRID_WIDTH
    skipright3:       

                      cmp  cx, GAME_BORDER_X_MAX - BLOCK_WIDTH
                      jz   skipright4
                      add  cx, BLOCK_WIDTH                        ;if right pixel gray
                      add BX, 1
                      cmp [GRID + BX], AL
                      jz  skipright4
                      jmp  far ptr GENERATE_LOOP
    skipright4:       
                      add  CURR_X, BLOCK_WIDTH
                      add GRID_INDEX, 1
                      call CREATE_BLOCK
                      mov al, RIGHT
                      call STORE_DIRECTION
                      jmp  cont
    Terminate_Program:
                      ;MOV  boolFinished, 1
                      mov AX, CURR_BLOCK
                      dec AX
                      mov FINAL_BLOCK, AL
                      mov al, FINISH
                      call STORE_DIRECTION
                      call DRAW_TRACK
                      call DECORATE_TRACK
                      ;CALL CREATE_BLOCK                 ; Draw Our Final RedSqaure To Represnt End Line
                      call Save_Track                   ; Save Track in Array For Further Usage
                      mov al, DIRECTIONS                ; Store first direction for cars starting direction
                      ;HLT
                      ret
GENERATE_TRACK endp
;-------------------------------------------------------
STORE_DIRECTION proc near
    push BX
    push AX
    lea BX, DIRECTIONS
    add BX, CURR_BLOCK
    inc CURR_BLOCK
    mov [BX], al                             ; Store Current Direction In An Array
    mov ah, [BX]
    pop AX
    pop BX
    ret
STORE_DIRECTION endp
;-------------------------------------------------------
;------------------- DISPLAYING -----------------------;
DRAW_BLOCK proc near                                    ; AL: block color
  push AX
  push BX
  cmp  boolFinished,0
  jz   no
  mov  ah, 0ch
  mov  al, FinishLineColor
  JMP  YES
  no:               
  mov  ax,0c08h
  YES:              
  
  ;mov  cx, CURR_X
  ;mov  dx, CURR_Y
  call GET_GRID_INDEX
  mov  bx, cx
  add  bx, BLOCK_WIDTH
  mov  di, dx
  add  di, BLOCK_HEIGHT
  row:              
  int  10h
  inc  cx
  cmp  cx,bx
  jz   column
  jmp  row
  column:           
  sub  cx, BLOCK_WIDTH
  inc  dx
  cmp  dx,di
  jz   exit
  jmp  row
  exit:
  pop BX
  pop AX
  ret        
DRAW_BLOCK endp
;-------------------------------------------------------
DRAW_TRACK proc near
    push BX
    push AX
    call RESET_BACKGROUND             ;Resest Our Green BackGround
    mov GRID_INDEX, 0
    lea BX, GRID
    mov CX, 128
    Draw_Blocks_loop:
    mov AL, -1
    mov AH, [BX]
    cmp AL, AH
    jz Next_loop_1
    push CX
    call DRAW_BLOCK
    pop CX
    Next_loop_1:
    inc BX
    inc GRID_INDEX
    loop Draw_Blocks_loop
    EXIT_DRAW_TRACK:
    pop AX
    pop BX
    ret
DRAW_TRACK endp
;-------------------------------------------------------
DECORATE_TRACK proc near
    push BX
    push AX
    mov CX, xstart
    mov DX, ystart
    mov CURR_X, CX
    mov CURR_Y, DX
    lea BX, DIRECTIONS
    mov ah, RIGHT
    loop_on_directions:
    call TRACK_BORDER
    mov AL, -1
    cmp AL, [BX]                                        ; Start
    jnz NOT_START
    jmp NEXT_DIRECTION
    NOT_START:
    mov AL, UP
    cmp [BX], AL                                        ; UP (0)
    jnz NOT_UP
    call TRACK_VERTICAL
    sub CURR_Y, BLOCK_HEIGHT                            ; Go to upper block
    jmp NEXT_DIRECTION
    NOT_UP:
    mov AL, DOWN
    cmp [BX], AL                                        ; DOWN (1)
    jnz NOT_DOWN
    add CURR_Y, BLOCK_HEIGHT
    call TRACK_VERTICAL
    jmp NEXT_DIRECTION
    NOT_DOWN:
    mov AL, RIGHT
    cmp [BX], AL                                        ; RIGHT (3)
    jnz NOT_RIGHT
    add CURR_X, BLOCK_WIDTH
    call TRACK_HORIZONTAL
    jmp NEXT_DIRECTION
    NOT_RIGHT:
    mov AL, LEFT
    cmp [BX], AL                                        ; LEFT (2)
    jnz NOT_LEFT
    call TRACK_HORIZONTAL
    sub CURR_X, BLOCK_WIDTH
    jmp NEXT_DIRECTION
    NOT_LEFT:
    mov AL, FINISH
    cmp [BX], AL                                        ; END
    jz EXIT_DECORATE_TRACK
    NEXT_DIRECTION:
    mov ah, [BX]                                        ; Store Previous Direction
    inc BX
    mov AL, -2
    cmp [BX], AL
    jz EXIT_DECORATE_TRACK
    dec CURR_BLOCK
    jnz loop_on_directions
    EXIT_DECORATE_TRACK:
    pop AX
    pop BX
    ret
DECORATE_TRACK endp
;-------------------------------------------------------
TRACK_VERTICAL proc near
                      mov  cx,CURR_X
                      mov  dx,CURR_Y
                      push ax
                      push bx
                      push di
                      mov  ax,0c0fh
                      add  cx, BLOCK_WIDTH / 2 - 1          ; Send to upper block center
                      sub  dx, BLOCK_HEIGHT / 2 + 1         ; Send to upper block center
                      mov  bx,cx
                      mov  di,dx
                      add  bx, WHITE_STRIP_WIDTH
                      add  di, WHITE_STRIP_HEIGHT
    TOP_STRIP:        int  10h
                      inc  cx
                      cmp  cx,bx
                      jl  TOP_STRIP
                      sub  CX, 1
                      inc DX
                      cmp DX, DI
                      jl TOP_STRIP

                      mov  dx,CURR_Y
                      add  dx, BLOCK_HEIGHT / 2 - 1         ; Send to lower block center
                      mov  di,dx
                      sub  di, WHITE_STRIP_HEIGHT
    BOTTOM_STRIP:     int  10h
                      inc  cx
                      cmp  cx, bx
                      jl  BOTTOM_STRIP
                      sub  CX, 1
                      dec DX
                      cmp DX, DI
                      jg BOTTOM_STRIP

    EXIT_TRACK_V:     pop  di                           ;3
                      pop  bx                           ;2
                      pop  ax                           ;1
                      ret
TRACK_VERTICAL endp
;-------------------------------------------------------
TRACK_HORIZONTAL proc near
                      mov  cx,CURR_X
                      mov  dx,CURR_Y
                      push ax
                      push bx
                      push di
                      mov  ax,0c0fh
                      sub  cx, BLOCK_WIDTH / 2 + 1      ; Send to left block center
                      add  dx, BLOCK_HEIGHT / 2 - 1     ; Send to left block center
                      mov  bx,cx
                      mov  di,dx
                      add  bx, WHITE_STRIP_HEIGHT
                      add  di, WHITE_STRIP_WIDTH
    LEFT_STRIP:       int  10h
                      inc  dx
                      cmp  dx,di
                      jl  LEFT_STRIP
                      sub  dx, 1
                      inc CX
                      cmp CX, BX
                      jl LEFT_STRIP

                      mov  cx,CURR_X
                      add  cx, BLOCK_WIDTH / 2 - 1                        ; Send to right block center
                      mov  bx,cx
                      sub  bx, WHITE_STRIP_HEIGHT
    RIGHT_STRIP:      int  10h
                      inc  dx
                      cmp  dx,di
                      jl  RIGHT_STRIP
                      sub  dx, 1
                      dec CX
                      cmp CX, BX
                      jg RIGHT_STRIP

    EXIT_TRACK_H:     pop  di                           ;3
                      pop  bx                           ;2
                      pop  ax                           ;1
                      ret
TRACK_HORIZONTAL endp
;-------------------------------------------------------
TRACK_BORDER proc near                                  ; AH: prev, [BX]: current
    push AX
    push BX
    mov AL, AH
    xor AL, [BX]                                        ; ZF = (prev == current)
    jz NO_CORNER
    mov AL, [BX]
    cmp AL, FINISH
    jnz CORNER
    
    NO_CORNER:
        cmp AH, RIGHT                                    ; IF Vertical
        jl BLOCK_V
        call BORDER_UP
        call BORDER_DOWN
        cmp AL, FINISH
        jnz SKIP_FINISH
        call END_BLOCK_V
        cmp AH, RIGHT
        jnz SKIP_FINISH_RIGHT
        call BORDER_RIGHT
        jmp EXIT_TRACK_BORDER
        SKIP_FINISH_RIGHT:
        call BORDER_LEFT
        jmp EXIT_TRACK_BORDER
        BLOCK_V:
        call BORDER_LEFT
        call BORDER_RIGHT
        cmp AL, FINISH
        jnz SKIP_FINISH
        call END_BLOCK_H
        cmp AH, UP
        jnz SKIP_FINISH_UP
        call BORDER_UP
        jmp EXIT_TRACK_BORDER
        SKIP_FINISH_UP:
        call BORDER_DOWN
        SKIP_FINISH:
        jmp EXIT_TRACK_BORDER

    CORNER:
    cmp AL, UP                                        ; Corner upwards
    jz CORNER_UP
    cmp AL, DOWN                                        ; Corner downwards
    jz CORNER_DOWN
    cmp AL, LEFT                                        ; Corner left
    jz CORNER_LEFT
    jmp CORNER_RIGHT

    CORNER_UP:
        call BORDER_DOWN
        cmp AH, RIGHT                                   ; RIGHT
        jz RIGHT_UP_CORNER
        call BORDER_LEFT
        jmp EXIT_TRACK_BORDER
        RIGHT_UP_CORNER:
        call BORDER_RIGHT
        jmp EXIT_TRACK_BORDER

    CORNER_DOWN:
        call BORDER_UP
        cmp AH, RIGHT
        jz RIGHT_DOWN_CORNER
        call BORDER_LEFT
        jmp EXIT_TRACK_BORDER
        RIGHT_DOWN_CORNER:
        call BORDER_RIGHT
        jmp EXIT_TRACK_BORDER

    CORNER_RIGHT:
        call BORDER_LEFT
        cmp AH, UP
        jz UP_RIGHT_CORNER
        call BORDER_DOWN
        jmp EXIT_TRACK_BORDER
        UP_RIGHT_CORNER:
        call BORDER_UP
        jmp EXIT_TRACK_BORDER

    CORNER_LEFT:
        call BORDER_RIGHT
        cmp AH, UP
        jz UP_LEFT_CORNER
        call BORDER_DOWN
        jmp EXIT_TRACK_BORDER
        UP_LEFT_CORNER:
        call BORDER_UP
        jmp EXIT_TRACK_BORDER

    EXIT_TRACK_BORDER:
    pop BX
    pop AX
    ret
TRACK_BORDER endp
;-------------------------------------------------------
BORDER_LEFT proc near
                      mov  cx, CURR_X
                      mov  dx, CURR_Y
                      push SI
                      push ax
                      push bx
                      push di
                      mov  ax,0c0ch                     ; RED
                      mov  bx,0c0fh                     ; WHITE
                      sub cx, 1                         ; Start beside the track
                      js EXIT_BORDER_LEFT               ; left border
                      mov di, dx
                      add di, BLOCK_HEIGHT
                      mov si, 5
    LEFT_BORDER:      int  10h
                      dec si
                      jnz SKIP_CLR_SWITCH
                      mov si, 5
                      xchg AX, BX
                      SKIP_CLR_SWITCH:
                      inc  dx
                      cmp  dx, di
                      jl  LEFT_BORDER
    EXIT_BORDER_LEFT: pop  di                           ;3
                      pop  bx                           ;2
                      pop  ax                           ;1
                      pop SI
                      ret
BORDER_LEFT endp
;-------------------------------------------------------
BORDER_RIGHT proc near
                      mov  cx,CURR_X
                      mov  dx,CURR_Y
                      push SI
                      push ax
                      push bx
                      push di
                      mov  ax,0c0ch                     ; RED
                      mov  bx,0c0fh                     ; WHITE
                      add cx, BLOCK_WIDTH               ; Start beside the track
                      cmp cx, GAME_BORDER_X_MAX
                      jz EXIT_BORDER_RIGHT
                      mov di, dx
                      add di, BLOCK_HEIGHT
                      mov si, 5
    RIGHT_BORDER:     int  10h
                      dec si
                      jnz SKIP_CLR_SWITCH_R
                      mov si, 5
                      xchg AX, BX
                      SKIP_CLR_SWITCH_R:
                      inc  dx
                      cmp  dx, di
                      jl  RIGHT_BORDER
    EXIT_BORDER_RIGHT: pop  di                           ;3
                      pop  bx                           ;2
                      pop  ax                           ;1
                      pop SI
                      ret
BORDER_RIGHT endp
;-------------------------------------------------------
BORDER_UP proc near
                      mov  cx,CURR_X
                      mov  dx,CURR_Y
                      push SI
                      push ax
                      push bx
                      push di
                      mov  ax,0c0ch                     ; RED
                      mov  bx,0c0fh                     ; WHITE
                      sub dx, 1                         ; Start above the track
                      js EXIT_BORDER_UP                 ; left border
                      mov di, cx
                      add di, BLOCK_WIDTH
                      mov si, 5
    UP_BORDER:        int  10h
                      dec si
                      jnz SKIP_CLR_SWITCH_U
                      mov si, 5
                      xchg AX, BX
                      SKIP_CLR_SWITCH_U:
                      inc  cx
                      cmp  cx, di
                      jl  UP_BORDER
    EXIT_BORDER_UP:   pop  di                           ;3
                      pop  bx                           ;2
                      pop  ax                           ;1
                      pop SI
                      ret
BORDER_UP endp
;-------------------------------------------------------
BORDER_DOWN proc near
                      mov  cx,CURR_X
                      mov  dx,CURR_Y
                      push SI
                      push ax
                      push bx
                      push di
                      mov  ax,0c0ch                     ; RED
                      mov  bx,0c0fh                     ; WHITE
                      add dx, BLOCK_HEIGHT              ; Start below the track
                      cmp dx, 181
                      jz EXIT_BORDER_DOWN
                      mov di, cx
                      add di, BLOCK_WIDTH
                      mov si, 5
    DOWN_BORDER:     int  10h
                      dec si
                      jnz SKIP_CLR_SWITCH_D
                      mov si, 5
                      xchg AX, BX
                      SKIP_CLR_SWITCH_D:
                      inc  cx
                      cmp  cx, di
                      jl  DOWN_BORDER
    EXIT_BORDER_DOWN: pop  di                           ;3
                      pop  bx                           ;2
                      pop  ax                           ;1
                      pop SI
                      ret
BORDER_DOWN endp
;-------------------------------------------------------
END_BLOCK_V proc near
                      mov  cx,CURR_X
                      mov  dx,CURR_Y
                      push SI
                      push ax
                      push bx
                      push di
                      add  cx, 5         ; Shift End Line
                      cmp AH, LEFT
                      jnz END_BLOCK_RIGHT
                      add  cx, 10         ; Shift End Line
                      END_BLOCK_RIGHT:
                      mov  ax, 0c0fh                     ; WHITE
                      mov di, dx
                      add di, BLOCK_HEIGHT
    ENDLINE_V:        int  10h
                      inc dx
                      xor cx, 1
                      cmp di, dx
                      jnz ENDLINE_V
    EXIT_ENDLINE_V:   pop  di                           ;3
                      pop  bx                           ;2
                      pop  ax                           ;1
                      pop SI
                      ret
END_BLOCK_V endp
;-------------------------------------------------------
END_BLOCK_H proc near
                      mov  cx,CURR_X
                      mov  dx,CURR_Y
                      push SI
                      push ax
                      push bx
                      push di
                      add  dx, 5         ; Shift End Line
                      cmp AH, UP
                      jnz END_BLOCK_DOWN
                      add  dx, 10         ; Shift End Line
                      END_BLOCK_DOWN:
                      mov  ax, 0c0fh                     ; WHITE
                      mov di, cx
                      add di, BLOCK_WIDTH
    ENDLINE_H:        int  10h
                      inc cx
                      xor dx, 1
                      cmp di, cx
                      jnz ENDLINE_H
    EXIT_ENDLINE_H:   pop  di                           ;3
                      pop  bx                           ;2
                      pop  ax                           ;1
                      pop SI
                      ret
END_BLOCK_H endp
;-------------------------------------------------------
;------------------- GAME LOGIC -----------------------;
CHECK_CAR_ON_PATH proc far              ; CX: X_FIRST_CORNER, DX: Y_FIRST_CORNER, BX: X_SEC_CORNER, DI: Y_SEC_CORNER
    mov AL, GREEN
    cmp DX, 0
    jl EXIT_CHECK_CAR_ON_PATH
    cmp DX, GAME_BORDER_Y_MAX
    jnl EXIT_CHECK_CAR_ON_PATH
    cmp CX, 0
    jl EXIT_CHECK_CAR_ON_PATH
    cmp CX, GAME_BORDER_X_MAX
    jnl EXIT_CHECK_CAR_ON_PATH
    push BX
    call GET_BLOCK_INDEX
    mov AH, 0dh
    int 10h
    pop BX
    cmp al, GREEN
    jz EXIT_CHECK_CAR_ON_PATH
    cmp al, RED
    jz EXIT_CHECK_CAR_ON_PATH
    ; CHECK NEXT CORNER
    sub DI, BLOCK_HEIGHT
    cmp DI, DX
    jnl CHECK_OTHER_CORNER_DOWN
    sub BX, BLOCK_WIDTH
    cmp BX, CX
    jl EXIT_CHECK_CAR_ON_PATH
    add CX, BLOCK_WIDTH
    jmp CHECK_OTHER_CORNER
    CHECK_OTHER_CORNER_DOWN:
    add DX, BLOCK_HEIGHT
    CHECK_OTHER_CORNER:
    cmp DX, 0
    jl EXIT_CHECK_CAR_ON_PATH
    cmp DX, GAME_BORDER_Y_MAX
    jnl EXIT_CHECK_CAR_ON_PATH
    cmp CX, 0
    jl EXIT_CHECK_CAR_ON_PATH
    cmp CX, GAME_BORDER_X_MAX
    jnl EXIT_CHECK_CAR_ON_PATH
    mov AH, 0dh
    int 10h
    cmp al, GREEN
    jz EXIT_CHECK_CAR_ON_PATH
    cmp al, RED
    jz EXIT_CHECK_CAR_ON_PATH
    EXIT_CHECK_CAR_ON_PATH:
    ;xor al, 1
    ret
CHECK_CAR_ON_PATH endp
;-------------------------------------------------------
GET_BLOCK_INDEX proc near               ; CX: X, DX, Y
    mov AX, CX
    mov BL, BLOCK_WIDTH
    div BL
    mov AH, 0
    mul BL
    mov CX, AX
    mov AX, DX
    mov BL, BLOCK_HEIGHT
    div BL
    mov AH, 0
    mul BL
    mov DX, AX
    ret
GET_BLOCK_INDEX endp
;-------------------------------------------------------
GET_BLOCK_DEPTH proc far
    push BX
    mov AX, CX
    mov BL, BLOCK_WIDTH
    div BL
    mov AH, 0
    mov CX, AX
    mov AX, DX
    mov BL, BLOCK_HEIGHT
    div BL
    mov AH, 0
    mov BL, GRID_WIDTH
    mul BL
    add AX, CX                                          ; AX = GRID_INDEX
    lea BX, GRID
    add BX, AX
    mov AH, 0
    mov AL, [BX]
    cmp FINAL_BLOCK, AL
    jg DIDNT_REACH_END
        mov AH, 1
    DIDNT_REACH_END:
    pop BX
    ret
GET_BLOCK_DEPTH endp
;-------------------------------------------------------
GET_BLOCK_DIRECTION proc near
    push BX
    push CX
    push DX
    mov AX, CX
    mov BL, BLOCK_WIDTH
    div BL
    mov AH, 0
    mov CX, AX
    mov AX, DX
    mov BL, BLOCK_HEIGHT
    div BL
    mov AH, 0
    mov BL, GRID_WIDTH
    mul BL
    add AX, CX                                          ; AX = GRID_INDEX
    dec AX
    lea BX, GRID
    add BX, AX
    mov AL, [BX]
    mov AH, 1
    cmp AL, -1
    jnz HORIZONTAL
    mov AH, 0
    HORIZONTAL:
    mov AL, AH
    pop DX
    pop CX
    pop BX
    ret
;-------------------------------------------------------
CHECK_NEARBY_BOXES proc near
    push AX
    push CX
    push DX
    mov AH, 0dh
    mov BH, 0
    mov BL, 1
    ; TOP LEFT
    sub CX, 2
    sub DX, 2
    int 10h
    cmp AL, BLACK
    jz BOX_NEARBY
    cmp AL, 1Fh
    jz BOX_NEARBY
    cmp AL, GREEN
    jz BOX_NEARBY
    ; TOP RIGHT
    add CX, 4
    int 10h
    cmp AL, BLACK
    jz BOX_NEARBY
    cmp AL, 1Fh
    jz BOX_NEARBY
    cmp AL, GREEN
    jz BOX_NEARBY
    ; BOTTOM RIGHT
    add DX, 4
    int 10h
    cmp AL, BLACK
    jz BOX_NEARBY
    cmp AL, 1Fh
    jz BOX_NEARBY
    cmp AL, GREEN
    jz BOX_NEARBY
    ; BOTTOM LEFT
    sub CX, 4
    int 10h
    cmp AL, BLACK
    jz BOX_NEARBY
    cmp AL, 1Fh
    jz BOX_NEARBY
    cmp AL, GREEN
    jz BOX_NEARBY
    jmp EXIT_BOX_NEARBY
    BOX_NEARBY:
    mov BL, 0
    EXIT_BOX_NEARBY:
    pop DX
    pop CX
    pop AX
    ret
CHECK_NEARBY_BOXES endp
;-------------------------------------------------------
HANDLE_DROP_POSITION proc far
    push SI
    mov VALID_UP, 0
    mov VALID_BOT, 0
    call CHECK_NEARBY_BOXES
    cmp BL, 0
    jz EXIT_HANDLE_DROP_OBSTACLE
    call GET_BLOCK_DIRECTION
    push CX
    push DX
    push AX
    call GET_BLOCK_INDEX
    pop AX                              ; GET BLOCK DIRECTION
    cmp AL, 1
    pop AX
    pop BX
    jnl SET_VERTICAL                    ; If direction is right or left skip
    xchg AX, BX                         ; AX: X, BX: Y
    call CHECK_VALID_DROP_V_LANES
    mov CX, CURR_X
    mov DX, CURR_Y
    jmp EXIT_HANDLE_DROP_OBSTACLE
    SET_VERTICAL:
    call CHECK_VALID_DROP_H_LANES
    mov CX, CURR_X
    mov DX, CURR_Y
    jmp EXIT_HANDLE_DROP_OBSTACLE

    ; Changing AX only
    EXIT_HANDLE_DROP_OBSTACLE:
    mov BH, VALID_BOT
    mov BL, VALID_UP
    and BL, BH
    pop SI
    ret
HANDLE_DROP_POSITION endp
;-------------------------------------------------------
CHECK_VALID_DROP_V_LANES proc near            ; AX: X, BX: Y, CX: BLOCK_X, DX: BLOCK_Y
    mov CURR_X, CX
    mov CURR_Y, BX
    sub AX, CX
    ; CHECK LANE ONE
    cmp AX, 7
    jnl SKIP_V_LANE_1
        mov BX, 3
        add CURR_X, BX
        jmp CHECK_V_LANE_2
    SKIP_V_LANE_1:
        push CX
        mov DX, CURR_Y
        add CX, 3
        call SCAN_SECTION_V
        or VALID_BOT, BL
        sub DX, 13
        call SCAN_SECTION_V
        or VALID_UP, BL
        pop CX
    CHECK_V_LANE_2:
    ; CHECK LANE TWO
    cmp AX, 14
    jnl SKIP_V_LANE_2
    cmp AX, 7
    jl SKIP_V_LANE_2
        mov BX, 10
        add CURR_X, BX
        jmp CHECK_V_LANE_3
    SKIP_V_LANE_2:
        push CX
        mov DX, CURR_Y
        add CX, 10
        call SCAN_SECTION_V
        or VALID_BOT, BL
        sub DX, 13
        call SCAN_SECTION_V
        or VALID_UP, BL
        pop CX
    CHECK_V_LANE_3:

    ; CHECK LANE THREE
    cmp AX, 20
    jnl SKIP_V_LANE_3
    cmp AX, 14
    jl SKIP_V_LANE_3
        mov BX, 17
        add CURR_X, BX
        jmp CHECK_V_LANE_4
    SKIP_V_LANE_3:
        push CX
        mov DX, CURR_Y
        add CX, 17
        call SCAN_SECTION_V
        or VALID_BOT, BL
        sub DX, 13
        call SCAN_SECTION_V
        or VALID_UP, BL
        pop CX
    CHECK_V_LANE_4:
    ret
CHECK_VALID_DROP_V_LANES endp
;-------------------------------------------------------
CHECK_VALID_DROP_H_LANES proc near            ; AX: Y, BX: X, CX: BLOCK_X, DX: BLOCK_Y
    mov CURR_X, BX
    mov CURR_Y, DX
    sub AX, DX
    ; CHECK LANE ONE
    cmp AX, 7
    jnl SKIP_H_LANE_1
        mov BX, 3
        add CURR_Y, BX
        jmp CHECK_H_LANE_2
    SKIP_H_LANE_1:
        push DX
        mov CX, CURR_X
        add DX, 3
        call SCAN_SECTION_H
        or VALID_BOT, BL
        sub CX, 13
        call SCAN_SECTION_H
        or VALID_UP, BL
        pop DX
    CHECK_H_LANE_2:
    ; CHECK LANE TWO
    cmp AX, 14
    jnl SKIP_H_LANE_2
    cmp AX, 7
    jl SKIP_H_LANE_2
        mov BX, 10
        add CURR_Y, BX
        jmp CHECK_H_LANE_3
    SKIP_H_LANE_2:
        push DX
        mov CX, CURR_X
        add DX, 10
        call SCAN_SECTION_H
        or VALID_BOT, BL
        sub CX, 13
        call SCAN_SECTION_H
        or VALID_UP, BL
        pop DX
    CHECK_H_LANE_3:

    ; CHECK LANE THREE
    cmp AX, 20
    jnl SKIP_H_LANE_3
    cmp AX, 14
    jl SKIP_H_LANE_3
        mov BX, 17
        add CURR_Y, BX
        jmp CHECK_H_LANE_4
    SKIP_H_LANE_3:
        push DX
        mov CX, CURR_X
        add DX, 17
        call SCAN_SECTION_H
        or VALID_BOT, BL
        sub CX, 13
        call SCAN_SECTION_H
        or VALID_UP, BL
        pop DX
    CHECK_H_LANE_4:
    ret
CHECK_VALID_DROP_H_LANES endp
;-------------------------------------------------------
SCAN_SECTION_H proc near                         ; CX : starting X, DX: Y level
    push AX
    push CX
    cmp CX, 0
    jl EXIT_SCAN_TRACK_H
    cmp CX, GAME_BORDER_X_MAX
    jnl EXIT_SCAN_TRACK_H
    mov AH, 0dh
    mov BH, 0
    mov SI, CX
    add SI, 13
    SCAN_H:
            int 10h
            cmp AL, BLACK
            jz EXIT_SCAN_TRACK_H
            inc CX
            cmp CX, SI
            jnz SCAN_H
    EXIT_SCAN_TRACK_VALID:
    mov BX, 1
    pop CX
    pop AX
    ret
    EXIT_SCAN_TRACK_H:
    mov BX, 0
    pop CX
    pop AX
    ret
SCAN_SECTION_H endp
;-------------------------------------------------------
SCAN_SECTION_V proc near                           ; CX : X level, DX: starting Y
    push AX
    push DX
    cmp DX, 0
    jl EXIT_SCAN_TRACK_V
    cmp DX, GAME_BORDER_Y_MAX
    jnl EXIT_SCAN_TRACK_V
    mov AH, 0dh
    mov BH, 0
    mov SI, DX
    add SI, 13
    SCAN_V:
            int 10h
            cmp AL, BLACK
            jz EXIT_SCAN_TRACK_V
            inc DX
            cmp DX, SI
            jnz SCAN_V
    EXIT_SCAN_TRACK_V_VALID:
    mov BX, 1
    pop DX
    pop AX
    ret
    EXIT_SCAN_TRACK_V:
    mov BX, 0
    pop DX
    pop AX
    ret
SCAN_SECTION_V endp
end