    PUBLIC GENERATE_TRACK
    PUBLIC Load_Track
    PUBLIC xstart
    PUBLIC ystart
.model medium
.stack 64
.data
    direction        db ?                ; the randomized direction

    pathlength       dw 0                ;Current length of the track
    minpathlength    dw 30               ;MinPath Length Before Restarting

    leftboundry      dw 0                ; track boundries
    lowboundry       dw 160
    rightboundry     dw 320
    upperboundry     dw 0

    xstart           dw 0                ; starting indeces
    ystart           dw 80
    currx            dw ?                ;Current pntY
    curry            dw ?                ;Current pntX
    max_rand         dw 25               ;Max Trials To Draw Before Restart
    curr_rand        dw 0                ;Current Trials to Draw
    runtime_loop     dw 377              ;Like Delay to Make sure we get random number every time
    FinishLineColor  db 4                ;Color Of Last Sqaure
    boolFinished     db 0                ;To color last Sqaure
    TRACK            DB 57800 DUP (?)    ;To save and Load Track
    Block_Percentage db 10               ;real Percentage
    Block_SIZE       DW 6                ;size of any block(path_block,boosters)
    Boost_Percentage db 90               ;100-this Percentage so if 90 its 10
    DIRECTIONS       DB -1, 200 DUP(-2)   ; -1 (start), 4 (end), -2 (invalid)
    CURR_BLOCK       DW 0
    ;;;;;;;;;;;;;;;; done

.code
;-------------------------------------------------------
RESET_BACKGROUND proc
    ; (Send to TRACK file)
    ; Set background color to WHITE
                      mov  AH, 06h                      ; Scroll up function
                      xor  AL, AL                       ; Clear entire screen
                      xor  CX, CX                       ; Upper left corner CH=row, CL=column
                      mov  DX, 184Fh                    ; lower right corner DH=row, DL=column
                      mov  BH, 02h                      ; Green-BackGround
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
random_number proc
                      push bx                           ;1
                      push ax                           ;2
                      push dx                           ;3
                      push cx                           ;4
                      push di                           ;5
                      inc  curr_rand
                      mov  di,runtime_loop
    f1:               
                      mov  ah, 2ch
                      int  21h
                      mov  ah, 0
                      mov  al, dl                       ;;micro seconds
                      mov  bl, 4
                      div  bl
                      dec  di
                      cmp  di,0                         ;;; ah = rest
                      jnz  f1
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
random_number endp
;-------------------------------------------------------
PATH_BLOCK proc                                         ;Draw Brown (06h) Square to Represent Path Block
                      push ax                           ;1
                      push bx                           ;2
                      push di                           ;3
                      mov  cx,currx
                      mov  dx,curry
                      mov  ax,0c06h
                      add  cx,2
                      add  dx,2
                      mov  bx,cx
                      add  bx,Block_SIZE
                      mov  di,dx
                      add  di,Block_SIZE
    row1:             int  10h
                      inc  cx
                      cmp  cx,bx
                      jz   column1
                      jmp  row1
    column1:          
                      sub  cx,Block_SIZE
                      inc  dx
                      cmp  dx,di
                      jz   exit1
                      jmp  row1
    exit1:            
                      sub  dx,Block_SIZE
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
                      mov  cx,currx
                      mov  dx,curry
                      CALL random_number
                      CMP  direction, 0                 ; Blue boost  1
                      Jz   Blue
                      CMP  direction, 1                 ; Yellow boost E
                      Jz   Yellow
                      CMP  direction, 2                 ; Magenta boost D
                      JZ   Magenta
                      CMP  direction,3                  ; Cyan boost C
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
                      mov  ah,0ch
                      mov  al,FinishLineColor
                      JMP  YES
    no:               mov  ax,0c08h
    YES:              
                      mov  curr_rand,0
                      inc  pathlength
                      mov  cx,currx
                      mov  dx,curry
                      mov  bx,cx
                      add  bx,20
                      mov  di,dx
                      add  di,20
    row:              int  10h
                      inc  cx
                      cmp  cx,bx
                      jz   column
                      jmp  row
    column:           
                      sub  cx,20
                      inc  dx
                      cmp  dx,di
                      jz   exit
                      jmp  row
    exit:             
                      sub  dx,20
                      mov  ah, 2ch
                      int  21h
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

    ; Initialize Video Mode
                      mov  AX, 0013h                    ; Select 320x200, 256 color graphics
                      int  10h
    ;restart should clear screen and put in sqaurenumbers 0 and move the cx and dx to initial position


    restart:                                            ;Restart Only if less than MinPathLength
                      mov dx, CURR_BLOCK
                      mov CURR_BLOCK, 0
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
                      mov  currx,cx
                      mov  curry,dx
                      call draw_square
                      mov  pathlength,1
                      mov  curr_rand,0
    GENERATE_LOOP:    
                      mov  cx,currx
                      mov  dx,curry
                      CALL random_number                ; Get a random direction
                      push ax
                      mov  ax,max_rand
                      cmp  curr_rand,ax
                      pop  AX
                      jz   restart
    ; Process the direction to determine the movement
                      CMP  direction, 0                 ; Up          00    --> xor 1 --> 01
                      Jz   MOVE_UP
                      CMP  direction, 1                 ; Down        01    --> xor 1 --> 00
                      Jz   MOVE_DOWN
                      CMP  direction, 2                 ; Left        10    --> xor 1 --> 11
                      jnz  rightdirection
                      jmp  far ptr MOVE_LEFT
    rightdirection:   
                      CMP  direction, 3                 ; Right       11    --> xor 1 --> 10
                      jnz  nodirection
                      jmp  far ptr MOVE_RIGHT
    nodirection:      
    cont:             JMP  GENERATE_LOOP



    MOVE_UP:          
                      cmp  dx,upperboundry              ;if out of boundries
                      JNZ  skipupbound
                      jmp  far ptr GENERATE_LOOP
    skipupbound:      
                      sub  dx,20
                      mov  ah,0dh                       ; if current pixel is gray
                      int  10h
                      cmp  al,08
                      jz   GENERATE_LOOP                ; Block already found

                      cmp  dx,0
                      jz   skipup                       ; New Block At Screen Top

                      sub  dx,20                        ; if upper pixel is gray
                      int  10h
                      cmp  al,08
                      jz   GENERATE_LOOP                ; New Block will generate loop (connected above it)
                      add  dx,20
    skipup:           

                      cmp  cx,300                       ; if at right boundary
                      jz   skipup2

                      add  cx,20                        ; if right pixel gray
                      int  10h                          ; get color
                      cmp  al,08
                      jz   GENERATE_LOOP                ; New Block will generate loop (connected on its right)
                      sub  cx,20
    skipup2:          
                      cmp  cx,0
                      jz   skipup3                      ; if at left boundary
                      sub  cx,20                        ;if left pixel gray
                      int  10h                          ;get color
                      cmp  al,08
                      jnz  skipup3
                      jmp  far ptr GENERATE_LOOP        ; New Block will generate loop (connected on its left)
    skipup3:          sub  curry,20
                      call draw_square
                      mov al, 0
                      call STORE_DIRECTION
                      jmp  cont
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    MOVE_DOWN:        
                      cmp  dx,160                       ;;out of bound
                      jnz  skipdownboundry
                      jmp  far ptr GENERATE_LOOP
    skipdownboundry:  
                      add  dx,20
                      mov  ah,0dh                       ; if current pixel is gray
                      int  10h
                      cmp  al,08
                      jnz  extra2
                      jmp  far ptr GENERATE_LOOP
    extra2:           
                      cmp  dx,160
                      jz   skipdown

                      add  dx,20                        ; if lower pixel is gray
                      int  10h
                      cmp  al,08
                      jnz  extra3
                      jmp  far ptr GENERATE_LOOP
    extra3:           
                      sub  dx,20

    skipdown:         

                      cmp  cx,300                       ;; if at right boundrie
                      jz   skipdown2

                      add  cx,20                        ;if right pixel gray
                      int  10h                          ;get color
                      cmp  al,08
                      jnz  extra4
                      jmp  far ptr GENERATE_LOOP
    extra4:           
                      sub  cx,20
    skipdown2:        
                      cmp  cx,0
                      jz   skipdown3

                      sub  cx,20                        ;if left pixel gray
                      int  10h                          ;get color
                      cmp  al,08
                      jnz  skipdown3
                      jmp  far ptr GENERATE_LOOP


    skipdown3:        
                      add  curry,20
                      call draw_square
                      mov al, 1
                      call STORE_DIRECTION
                      jmp  cont
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    MOVE_LEFT:        

                      cmp  cx,leftboundry               ;if out of boundries
                      jnz  skipleftboundry
                      jmp  far ptr GENERATE_LOOP
    skipleftboundry:  

                      sub  cx,20
                      mov  ah,0dh                       ; if current pixel is gray
                      int  10h
                      cmp  al,08
                      jnz  skipleft
                      jmp  far ptr GENERATE_LOOP
    skipleft:         
                      cmp  dx,160
                      jz   skipleft2                    ; if lower pixel is gray
                      add  dx,20
                      int  10h
                      cmp  al,08
                      jnz  extra5                       ;
                      jmp  far ptr GENERATE_LOOP
    extra5:           
                      sub  dx,20
    skipleft2:        
                      cmp  dx,upperboundry
                      jz   skipleft3
                      sub  dx,20                        ;if upper pixel gray
                      int  10h
                      cmp  al,08
                      jnz  extra6
                      jmp  far ptr GENERATE_LOOP
    extra6:           add  dx,20
    skipleft3:        
                      cmp  cx,leftboundry               ;if left pixel gray
                      jz   skipleft4
                      sub  cx,20
                      int  10h
                      cmp  al,08
                      jnz  skipleft4
                      jmp  far ptr GENERATE_LOOP
    skipleft4:        
                      sub  currx,20
                      call draw_square
                      mov al, 2
                      call STORE_DIRECTION
                      jmp  cont
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    MOVE_RIGHT:       
                      cmp  cx,300                       ;if out of boundries
                      jnz  skiprightboundry
                      jmp  far ptr GENERATE_LOOP
    skiprightboundry: 
                      add  cx,20
                      mov  ah,0dh                       ; if current pixel is gray
                      int  10h
                      cmp  al,08
                      jnz  skipright
                      jmp  far ptr GENERATE_LOOP
    skipright:        
                      cmp  dx,160
                      jz   skipright2
                      add  dx,20
                      int  10h                          ;if lower
                      cmp  al,08
                      jnz  extra7
                      jmp  far ptr GENERATE_LOOP
    extra7:           sub  dx,20
    skipright2:       
                      cmp  dx,upperboundry
                      jz   skipright3
                      sub  dx,20                        ;if upper pixel gray
                      int  10h
                      cmp  al,08
                      jnz  extra8
                      jmp  far ptr GENERATE_LOOP
    extra8:           add  dx,20
    skipright3:       

                      cmp  cx,300
                      jz   skipright4
                      add  cx,20                        ;if right pixel gray
                      int  10h
                      cmp  al,08
                      jnz  skipright4
                      jmp  far ptr GENERATE_LOOP
    skipright4:       
                      add  currx,20
                      call draw_square
                      mov al, 3
                      call STORE_DIRECTION
                      jmp  cont
    Terminate_Program:
                      MOV  boolFinished,1
                      mov al, 4
                      call STORE_DIRECTION
                      call DECORATE_TRACK
                      ;CALL draw_square                  ;Draw Our Final RedSqaure To Represnt End Line
                      call Save_Track                   ;Save Track in Array For Further Usage
                      mov al, DIRECTIONS
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
    mov currx, CX
    mov curry, DX
    lea BX, DIRECTIONS
    mov ah, 3
    loop_on_directions:
    call TRACK_BORDER
    mov AL, -1
    cmp AL, [BX]                                        ; Start
    jnz NOT_START
    jmp NEXT_DIRECTION
    NOT_START:
    mov AL, 0
    cmp [BX], AL                                        ; UP (0)
    jnz NOT_UP
    call TRACK_VERTICAL
    sub curry, 20                                       ; Go to upper block
    jmp NEXT_DIRECTION
    NOT_UP:
    inc AL
    cmp [BX], AL                                        ; DOWN (1)
    jnz NOT_DOWN
    add curry, 20
    call TRACK_VERTICAL
    jmp NEXT_DIRECTION
    NOT_DOWN:
    inc AL
    cmp [BX], AL                                        ; LEFT (2)
    jnz NOT_LEFT
    call TRACK_HORIZONTAL
    sub currx, 20
    jmp NEXT_DIRECTION
    NOT_LEFT:
    inc AL
    cmp [BX], AL                                        ; RIGHT (3)
    jnz NOT_RIGHT
    add currx, 20
    call TRACK_HORIZONTAL
    jmp NEXT_DIRECTION
    NOT_RIGHT:
    inc AL
    cmp [BX], AL                                        ; END
    jz EXIT_DECORATE_TRACK
    ;jnz EXIT_DECORATE_TRACK
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
                      mov  cx,currx
                      mov  dx,curry
                      push ax
                      push bx
                      push di
                      mov  ax,0c0fh
                      add  cx,9                         ; Send to upper block center
                      sub  dx,11                        ; Send to upper block center
                      mov  bx,cx
                      mov  di,dx
                      add  bx,1
                      add  di,4
    TOP_STRIP:        int  10h
                      inc  cx
                      cmp  cx,bx
                      jl  TOP_STRIP
                      sub  CX, 1
                      inc DX
                      cmp DX, DI
                      jl TOP_STRIP

                      mov  dx,curry
                      add  dx,9                        ; Send to lower block center
                      mov  di,dx
                      sub  di,4
    BOTTOM_STRIP:     int  10h
                      inc  cx
                      cmp  cx,bx
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
                      mov  cx,currx
                      mov  dx,curry
                      push ax
                      push bx
                      push di
                      mov  ax,0c0fh
                      sub  cx,11                        ; Send to left block center
                      add  dx,9                         ; Send to left block center
                      mov  bx,cx
                      mov  di,dx
                      add  bx,4
                      add  di,1
    LEFT_STRIP:       int  10h
                      inc  dx
                      cmp  dx,di
                      jl  LEFT_STRIP
                      sub  dx, 1
                      inc CX
                      cmp CX, BX
                      jl LEFT_STRIP

                      mov  cx,currx
                      add  cx,9                        ; Send to right block center
                      mov  bx,cx
                      sub  bx,4
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
    mov al, ah
    xor al, [BX]                                        ; ZF = (prev == current)
    jz NO_CORNER
    mov al, [BX]
    cmp al, 0                                        ; Corner upwards
    jz CORNER_UP
    cmp al, 1                                        ; Corner downwards
    jz CORNER_DOWN
    cmp al, 2                                        ; Corner left
    jz CORNER_LEFT
    jmp CORNER_RIGHT

    NO_CORNER:
        mov AH, 2                                       ; LEFT
        cmp [BX], AH
        jl BLOCK_V
        call BORDER_UP
        call BORDER_DOWN
        jmp EXIT_TRACK_BORDER
        BLOCK_V:
        call BORDER_LEFT
        call BORDER_RIGHT
        jmp EXIT_TRACK_BORDER

    CORNER_UP:
        call BORDER_DOWN
        cmp AH, 3
        jz RIGHT_UP_CORNER
        call BORDER_LEFT
        jmp EXIT_TRACK_BORDER
        RIGHT_UP_CORNER:
        call BORDER_RIGHT
        jmp EXIT_TRACK_BORDER

    CORNER_DOWN:
        call BORDER_UP
        cmp AH, 3
        jz RIGHT_DOWN_CORNER
        call BORDER_LEFT
        jmp EXIT_TRACK_BORDER
        RIGHT_DOWN_CORNER:
        call BORDER_RIGHT
        jmp EXIT_TRACK_BORDER

    CORNER_RIGHT:
        call BORDER_LEFT
        cmp AH, 0
        jz UP_RIGHT_CORNER
        call BORDER_DOWN
        jmp EXIT_TRACK_BORDER
        UP_RIGHT_CORNER:
        call BORDER_UP
        jmp EXIT_TRACK_BORDER

    CORNER_LEFT:
        call BORDER_RIGHT
        cmp AH, 0
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
                      mov  cx,currx
                      mov  dx,curry
                      push SI
                      push ax
                      push bx
                      push di
                      mov  ax,0c0ch                     ; RED
                      mov  bx,0c0fh                     ; WHITE
                      sub cx, 1
                      js EXIT_BORDER_LEFT               ; left border
                      mov di, dx
                      add di, 20
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
                      mov  cx,currx
                      mov  dx,curry
                      push SI
                      push ax
                      push bx
                      push di
                      mov  ax,0c0ch                     ; RED
                      mov  bx,0c0fh                     ; WHITE
                      add cx, 20
                      cmp cx, rightboundry
                      jz EXIT_BORDER_RIGHT
                      mov di, dx
                      add di, 20
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
                      mov  cx,currx
                      mov  dx,curry
                      push SI
                      push ax
                      push bx
                      push di
                      mov  ax,0c0ch                     ; RED
                      mov  bx,0c0fh                     ; WHITE
                      sub dx, 1
                      js EXIT_BORDER_UP                 ; left border
                      mov di, cx
                      add di, 20
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
                      mov  cx,currx
                      mov  dx,curry
                      push SI
                      push ax
                      push bx
                      push di
                      mov  ax,0c0ch                     ; RED
                      mov  bx,0c0fh                     ; WHITE
                      add dx, 20
                      cmp dx, 181
                      jz EXIT_BORDER_DOWN
                      mov di, cx
                      add di, 20
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
end