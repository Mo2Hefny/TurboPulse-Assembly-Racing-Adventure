    PUBLIC TRACK
    ; OBSTACLES.asm
    EXTRN ADD_OBSTACLE:FAR
    EXTRN OBSTACLES_COUNT:WORD
    PUBLIC GENERATE_TRACK
    PUBLIC Load_Track
    PUBLIC CLEAR_ENTITY
    PUBLIC CHECK_CAR_ON_PATH
    PUBLIC xstart
    PUBLIC ystart
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
    WHITE_STRIP_WIDTH     EQU 1
    WHITE_STRIP_HEIGHT    EQU 4
    GREY                  EQU 08h
    GREEN                 EQU 02h
    RED                   EQU 0Ch
    UP EQU 0
    DOWN EQU 1
    RIGHT EQU 2
    LEFT EQU 3
    FINISH EQU 4

    direction        db ?                ; the randomized direction
    ENTITIES_COUNT   db 0

    pathlength       dw 0                ;Current length of the track
    minpathlength    dw 40               ;MinPath Length Before Restarting

    xstart           dw 0                ; starting indeces
    ystart           dw 80
    CURR_X            dw ?                ;Current pntY
    CURR_Y            dw ?                ;Current pntX
    max_rand         dw 25               ;Max Trials To Draw Before Restart
    curr_rand        dw 0                ;Current Trials to Draw
    prev_rand        db 0
    FinishLineColor  db 4                ;Color Of Last Sqaure
    boolFinished     db 0                ;To color last Sqaure
    TRACK            DB 64000 DUP (?)    ;To save and Load Track
    Block_Percentage db 10               ;real Percentage
    Block_SIZE       DW 6                ;size of any block(path_block,boosters)
    Boost_Percentage db 90               ;100-this Percentage so if 90 its 10
    DIRECTIONS       DB -1, 200 DUP(-2)   ; -1 (start), 4 (end), -2 (invalid)
    CURR_BLOCK       DW 0
    ;;;;;;;;;;;;;;;; done

.code
;-------------------------------------------------------
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
RESET_BACKGROUND proc
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
    mov prev_rand, al
    div  bl
    pop dx
    pop cx
    ret
RANDOM_NUMBER endp
;-------------------------------------------------------
random_direction proc
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
random_direction endp
;-------------------------------------------------------
PATH_BLOCK proc                                         ;Draw Brown (06h) Square to Represent Path Block
                      push ax                           ;1
                      push bx                           ;2
                      push di                           ;3
                      mov cx, CURR_X
                      mov dx, CURR_Y
                      mov bx, 4
                      call RANDOM_NUMBER
                      mov al, ah
                      mov ah, 0
                      mov bx, 5
                      mul bl
                      add ax, 2
                      add cx, ax                        ; 0, 5, 10, 15
                      mov  bl, 4
                      call RANDOM_NUMBER
                      mov al, ah
                      mov ah, 0
                      mov bx, 5
                      mul bl
                      add ax, 2
                      add dx, ax                        ; 0, 5, 10, 15
                      mov AH, ENTITIES_COUNT
                      mov AL, 0
                      inc ENTITIES_COUNT
                      inc ENTITIES_COUNT
                      call ADD_OBSTACLE
                      pop  di                           ;3
                      pop  bx                           ;2
                      pop  ax                           ;1
                      ret
PATH_BLOCK endp
;-------------------------------------------------------
Make_Boost PROC                                         ;Draw Boost
                      push ax                           ;1
                      push bx                           ;2
                      push di                           ;3
                      mov  cx,CURR_X
                      mov  dx,CURR_Y
                      CALL random_direction
                      CMP  direction, UP                 ; Blue boost  1
                      Jz   Blue
                      CMP  direction, DOWN                 ; Yellow boost E
                      Jz   Yellow
                      CMP  direction, LEFT                 ; Magenta boost D
                      JZ   Magenta
                      CMP  direction, RIGHT                  ; Cyan boost C
                      JZ   Cyan
    Blue:             mov  ax,0C01h
                      JMP  CONT_BOOST
    Yellow:           mov  ax,0C0Eh
                      JMP  CONT_BOOST
    Magenta:          mov  ax,0C0Dh
                      JMP  CONT_BOOST
    Cyan:             mov  ax,0C03h
    CONT_BOOST:       
                      add  cx,2
                      add  dx,2
                      mov  bx,cx
                      add  bx,Block_SIZE
                      mov  di,dx
                      add  di,Block_SIZE
    roW7:             int  10h
                      inc  cx
                      cmp  cx,bx
                      jz   column7
                      jmp  row7
    column7:          
                      sub  cx,Block_SIZE
                      inc  dx
                      cmp  dx,di
                      jz   exit7
                      jmp  row7
    exit7:            
                      sub  dx,Block_SIZE
                      pop  di                           ;3
                      pop  bx                           ;2
                      pop  ax                           ;1
                      ret
Make_Boost ENDP
;-------------------------------------------------------
draw_square PROC                                        ;Draw A gray Square to Represnt Our beautiful Track
                      push ax                           ;1
                      push bx                           ;2
                      push di                           ;3
                      cmp  boolFinished,0
                      jz   no
                      mov  ah, 0ch
                      mov  al, FinishLineColor
                      JMP  YES
    no:               mov  ax,0c08h
    YES:              
                      mov  curr_rand, 0
                      inc  pathlength
                      mov  cx, CURR_X
                      mov  dx, CURR_Y
                      mov  bx, cx
                      add  bx, BLOCK_WIDTH
                      mov  di, dx
                      add  di, BLOCK_HEIGHT
    row:              int  10h
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
                      sub  dx, BLOCK_HEIGHT
                      mov dx, CURR_BLOCK
                      cmp dx, 2
                      jng Dont_Boost
                      mov  ah, 2ch
                      int  21h
                      ;cmp  dl,Block_Percentage
                      and dl, prev_rand
                      cmp  dl,Block_Percentage
                      ja   Dont_block
                      call PATH_BLOCK
    Dont_block:       
                      cmp  dl,Boost_Percentage
                      jb   Dont_Boost
                      call Make_Boost
    Dont_Boost:       
                      pop  di                           ;3
                      pop  bx                           ;2
                      pop  ax                           ;1
                      ret
draw_square ENDP
;-------------------------------------------------------
GENERATE_TRACK proc far

                      mov  AX, @data
                      mov  DS, AX
                      xor BX, BX
    ; Initialize Video Mode
    ;restart should clear screen and put in sqaurenumbers 0 and move the cx and dx to initial position


    restart:                                            ;Restart Only if less than MinPathLength
                      mov dx, CURR_BLOCK
                      mov CURR_BLOCK, 0
                      mov ENTITIES_COUNT, 0
                      push ax
                      mov  ax,minpathlength
                      cmp  pathlength,ax
                      pop  AX
                      jb   extra1
                      mov CURR_BLOCK, dx
                      jmp  far ptr Terminate_Program
    extra1:           
                      call RESET_BACKGROUND             ;Resest Our Green BackGround
                      mov  cx,xstart
                      mov  dx,ystart
                      mov  CURR_X,cx
                      mov  CURR_Y,dx
                      call draw_square
                      mov  pathlength,1
                      mov  curr_rand,0
    GENERATE_LOOP:    
                      mov  cx,CURR_X
                      mov  dx,CURR_Y
                      CALL random_direction                ; Get a random direction
                      push ax
                      mov  ax,max_rand
                      cmp  curr_rand,ax
                      pop  AX
                      jz   restart
    ; Process the direction to determine the movement
                      CMP  direction, UP                 ; Up
                      Jz   MOVE_UP
                      CMP  direction, DOWN                 ; Down 
                      Jz   MOVE_DOWN
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
                      cmp  dx,GAME_BORDER_Y_MIN              ;if out of boundries
                      JNZ  skipupbound
                      jmp  far ptr GENERATE_LOOP
    skipupbound:      
                      sub  dx, BLOCK_HEIGHT
                      mov  ah, 0dh                      ; Get pixel color to AL
                      int  10h
                      cmp  al, GREY                     ; if current pixel is gray
                      jz   GENERATE_LOOP                ; Block already found

                      cmp  dx, GAME_BORDER_Y_MIN
                      jz   skipup                       ; New Block At Screen Top

                      sub  dx, BLOCK_HEIGHT             ; if upper pixel is gray
                      int  10h
                      cmp  al, GREY
                      jz   GENERATE_LOOP                ; New Block will generate loop (connected above it)
                      add  dx, BLOCK_HEIGHT
    skipup:           

                      cmp  cx, GAME_BORDER_X_MAX - BLOCK_WIDTH   ; if at right boundary
                      jz   skipup2

                      add  cx, BLOCK_WIDTH              ; if right pixel gray
                      int  10h                          ; get color
                      cmp  al, GREY
                      jz   GENERATE_LOOP                ; New Block will generate loop (connected on its right)
                      sub  cx, BLOCK_WIDTH
    skipup2:          
                      cmp  cx, GAME_BORDER_X_MIN
                      jz   skipup3                      ; if at left boundary
                      sub  cx, BLOCK_WIDTH              ;if left pixel gray
                      int  10h                          ;get color
                      cmp  al, GREY
                      jnz  skipup3
                      jmp  far ptr GENERATE_LOOP        ; New Block will generate loop (connected on its left)
    skipup3:          sub  CURR_Y, BLOCK_HEIGHT
                      call draw_square
                      mov al, UP                        ; Store UP direction
                      call STORE_DIRECTION
                      jmp  cont
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    MOVE_DOWN:        
                      cmp  dx, GAME_BORDER_Y_MAX - BLOCK_HEIGHT ;out of bound
                      jnz  skipdownboundary
                      jmp  far ptr GENERATE_LOOP
    skipdownboundary:  
                      add  dx, BLOCK_HEIGHT
                      mov  ah,0dh                       ; if current pixel is gray
                      int  10h
                      cmp  al, GREY
                      jnz  extra2
                      jmp  far ptr GENERATE_LOOP
    extra2:           
                      cmp  dx, GAME_BORDER_Y_MAX - BLOCK_HEIGHT
                      jz   skipdown

                      add  dx, BLOCK_HEIGHT                        ; if lower pixel is gray
                      int  10h
                      cmp  al, GREY
                      jnz  extra3
                      jmp  far ptr GENERATE_LOOP
    extra3:           
                      sub  dx, BLOCK_HEIGHT

    skipdown:         

                      cmp  cx, GAME_BORDER_X_MAX - BLOCK_WIDTH  ; if at right boundrie
                      jz   skipdown2

                      add  cx, BLOCK_WIDTH              ;if right pixel gray
                      int  10h                          ;get color
                      cmp  al, GREY
                      jnz  extra4
                      jmp  far ptr GENERATE_LOOP
    extra4:           
                      sub  cx, BLOCK_WIDTH
    skipdown2:        
                      cmp  cx, GAME_BORDER_X_MIN
                      jz   skipdown3

                      sub  cx, BLOCK_WIDTH              ;if left pixel gray
                      int  10h                          ;get color
                      cmp  al, GREY
                      jnz  skipdown3
                      jmp  far ptr GENERATE_LOOP


    skipdown3:        
                      add  CURR_Y, BLOCK_HEIGHT
                      call draw_square
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
                      mov  ah, 0dh                       ; if current pixel is gray
                      int  10h
                      cmp  al, GREY
                      jnz  skipleft
                      jmp  far ptr GENERATE_LOOP
    skipleft:         
                      cmp  dx, GAME_BORDER_Y_MAX - BLOCK_HEIGHT
                      jz   skipleft2                    ; if lower pixel is gray
                      add  dx, BLOCK_HEIGHT
                      int  10h
                      cmp  al, GREY
                      jnz  extra5                       
                      jmp  far ptr GENERATE_LOOP
    extra5:           
                      sub  dx, BLOCK_HEIGHT
    skipleft2:        
                      cmp  dx, GAME_BORDER_Y_MIN
                      jz   skipleft3
                      sub  dx, BLOCK_HEIGHT                   ;if upper pixel gray
                      int  10h
                      cmp  al, GREY
                      jnz  extra6
                      jmp  far ptr GENERATE_LOOP
    extra6:           add  dx, BLOCK_HEIGHT
    skipleft3:        
                      cmp  cx, GAME_BORDER_X_MIN               ;if left pixel gray
                      jz   skipleft4
                      sub  cx, BLOCK_WIDTH
                      int  10h
                      cmp  al, GREY
                      jnz  skipleft4
                      jmp  far ptr GENERATE_LOOP
    skipleft4:        
                      sub  CURR_X, BLOCK_WIDTH
                      call draw_square
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
                      mov  ah,0dh                       ; if current pixel is gray
                      int  10h
                      cmp  al, GREY
                      jnz  skipright
                      jmp  far ptr GENERATE_LOOP
    skipright:        
                      cmp  dx, GAME_BORDER_Y_MAX - BLOCK_HEIGHT
                      jz   skipright2
                      add  dx, BLOCK_HEIGHT
                      int  10h                          ;if lower
                      cmp  al, GREY
                      jnz  extra7
                      jmp  far ptr GENERATE_LOOP
    extra7:           sub  dx, BLOCK_HEIGHT
    skipright2:       
                      cmp  dx, GAME_BORDER_Y_MIN
                      jz   skipright3
                      sub  dx, BLOCK_HEIGHT                        ;if upper pixel gray
                      int  10h
                      cmp  al, GREY
                      jnz  extra8
                      jmp  far ptr GENERATE_LOOP
    extra8:           add  dx, BLOCK_HEIGHT
    skipright3:       

                      cmp  cx, GAME_BORDER_X_MAX - BLOCK_WIDTH
                      jz   skipright4
                      add  cx, BLOCK_WIDTH                        ;if right pixel gray
                      int  10h
                      cmp  al, GREY
                      jnz  skipright4
                      jmp  far ptr GENERATE_LOOP
    skipright4:       
                      add  CURR_X, BLOCK_WIDTH
                      call draw_square
                      mov al, RIGHT
                      call STORE_DIRECTION
                      jmp  cont
    Terminate_Program:
                      MOV  boolFinished, 1
                      mov al, FINISH
                      call STORE_DIRECTION
                      call DECORATE_TRACK
                      ;CALL draw_square                 ; Draw Our Final RedSqaure To Represnt End Line
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
CHECK_CAR_ON_PATH proc far              ; CX: X_FIRST_CORNER, DX: Y_FIRST_CORNER, BX: X_SEC_CORNER, DI: Y_SEC_CORNER
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
end