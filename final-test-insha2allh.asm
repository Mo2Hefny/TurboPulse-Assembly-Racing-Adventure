.model medium
.stack 64
.data
    direction        db ?                ;; the randomized direction

    pathlength       dw 0                ;; length of the track
    maxpathlength    dw 30

    leftboundry      dw 0                ;; track boundries
    lowboundry       dw 180
    rightboundry     dw 320
    upperboundry     dw 0

    xstart           dw 0                ;; starting indeces
    ystart           dw 80

    currx            dw ?
    curry            dw ?

    max_rand         dw 25
    curr_rand        dw 0
    runtime_loop     dw 377
    FinishLineColor  db 4
    boolFinished     db 0
    TRACK            DB 57800 DUP (?)
    Block_Percentage db 10
    Block_SIZE       DW 6
    ;;;;;;;;;;;;;;;; done

.code
                      jmp  main
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
Save_Track proc
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

Load_Track proc
                      
    
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

PATH_BLOCK proc
                      push ax                           ;1
                      push bx                           ;2
                      push di                           ;3
                      mov  cx,currx
                      mov  dx,curry
                      mov  ax,0c06h
                      add  cx,3
                      add  dx,3
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

draw_square PROC
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
                      pop  di                           ;3
                      pop  bx                           ;2
                      pop  ax                           ;1
                      ret
draw_square ENDP


whitevertical proc
                      mov  cx,currx
                      mov  dx,curry
                      push ax
                      push bx
                      push di
                      mov  ax,0c0fh
                      add  cx,9
                      add  dx,8
                      mov  bx,cx
                      mov  di,dx
                      add  bx,1
                      add  di,4
    row2:             int  10h
                      inc  cx
                      cmp  cx,bx
                      jz   column2
                      jmp  row2
    column2:          
                      sub  cx,1
                      inc  dx
                      cmp  dx,di
                      jz   exit3
                      jmp  row2

    exit3:            pop  di                           ;3
                      pop  bx                           ;2
                      pop  ax                           ;1
                      ret

whitevertical endp


whitehorizontal proc
                      mov  cx,currx
                      mov  dx,curry
                      push ax
                      push bx
                      push di
                      mov  ax,0c0fh
                      add  cx,6
                      add  dx,10
                      mov  bx,cx
                      mov  di,dx
                      add  bx,4
                      add  di,1
    row12:            int  10h
                      inc  cx
                      cmp  cx,bx
                      jz   column12
                      jmp  row12
    column12:         
                      sub  cx,4
                      inc  dx
                      cmp  dx,di
                      jz   exit12
                      jmp  row12

    exit12:           pop  di                           ;3
                      pop  bx                           ;2
                      pop  ax                           ;1
                      ret

whitehorizontal endp


main proc far

                      mov  AX, @data
                      mov  DS, AX

    ; Initialize Video Mode
                      mov  AX, 0013h                    ; Select 320x200, 256 color graphics
                      int  10h
    ;restart should clear screen and put in sqaurenumbers 0 and move the cx and dx to initial position


    restart:          
                      push ax
                      mov  ax,maxpathlength
                      cmp  pathlength,ax
                      pop  AX
                      jb   extra1
                      jmp  far ptr Terminate_Program
    extra1:           
                      call RESET_BACKGROUND
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
                      jz   GENERATE_LOOP

                      cmp  dx,0
                      jz   skipup

                      sub  dx,20                        ; if upper pixel is gray
                      int  10h
                      cmp  al,08
                      jz   GENERATE_LOOP
                      add  dx,20
    skipup:           

                      cmp  cx,300                       ;; if at right boundrie
                      jz   skipup2

                      add  cx,20                        ;if right pixel gray
                      int  10h                          ;get color
                      cmp  al,08
                      jz   GENERATE_LOOP
                      sub  cx,20
    skipup2:          
                      cmp  cx,0
                      jz   skipup3
                      sub  cx,20                        ;if left pixel gray
                      int  10h                          ;get color
                      cmp  al,08
                      jnz  skipup3
                      jmp  far ptr GENERATE_LOOP
    skipup3:          sub  curry,20
                      call draw_square
                      call whitevertical
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
                      call whitevertical
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
                      call whitehorizontal
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
                      call whitehorizontal
                      jmp  cont
    Terminate_Program:
                      MOV  boolFinished,1
                      CALL draw_square
                      call Save_Track
                      CALL Load_Track
                      HLT
main endp
end main