.model medium
.stack 64
.data
    direction db ?
    seed      dW 0
.code
                     jmp  main
RESET_BACKGROUND proc
    ; (Send to TRACK file)
    ; Set background color to WHITE
                     mov  AH, 06h               ; Scroll up function
                     xor  AL, AL                ; Clear entire screen
                     xor  CX, CX                ; Upper left corner CH=row, CL=column
                     mov  DX, 184Fh             ; lower right corner DH=row, DL=column
                     mov  BH, 1Eh               ; YellowOnBlue
                     int  10h
                     ret
RESET_BACKGROUND endp

random_number proc
                     push bx                    ;1
                     push ax                    ;2
                     push dx                    ;4
                     push cx
                     mov  ah, 2CH
                     INT  21h                   ; CH = hour CL = minute DH - second DL = 1/100 seconds
                     mov  ax,dx
                     pop  cx                    ;5
                     add  ax,cx
                     pop  dx                    ;4
                     add  ax,dx
                     mov  bl,7
                     mov  ah,0
                     div  bl
                     mov  al,ah
                     mov  ah,0
                     mov  bl,4
                     div  bl
                     mov  al, direction
                     xor  al, 1
                     cmp  ah, al
                     jnz  DONT_FIX
                     xor  ah, 1
    DONT_FIX:                                   ;5
                     mov  direction,ah
                     pop  ax                    ;2
                     pop  bx                    ;1
                     ret
random_number endp

draw_square PROC
                     mov  ax,0c08h
                     push bx
                     push di
                     mov  bx,cx
                     add  bx,20
                     mov  di,dx
                     add  di,20
    row:             int  10h
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
                     pop  di
                     pop  bx
                     ret
draw_square ENDP
main proc far

                     mov  AX, @data
                     mov  DS, AX

    ; Initialize Video Mode
                     mov  AX, 0013h             ; Select 320x200, 256 color graphics
                     int  10h

    ; Else draw the new frame
    restart:         call RESET_BACKGROUND
                     mov  cx,0
                     mov  dx,0
                     call draw_square
                     mov  cx,0
                     mov  dx,0
    GENERATE_LOOP:   
                     CALL random_number         ; Get a random direction

    ; Process the direction to determine the movement
                     CMP  direction, 0          ; Up          00    --> xor 1 --> 01
                     Jz   MOVE_UP
                     CMP  direction, 1          ; Down        01    --> xor 1 --> 00
                     Jz   MOVE_DOWN
                     CMP  direction, 2          ; Left        10    --> xor 1 --> 11
                     jnz  extra19
                     jmp  far ptr MOVE_LEFT
    extra19:         
                     CMP  direction, 3          ; Right       11    --> xor 1 --> 10
                     jnz  extra22
                     jmp  far ptr MOVE_RIGHT
    extra22:         
    cont:            
    ; Continue loop
                     cmp  cx,300
                     Jnz  GENERATE_LOOP
                     jmp  SKIP_MOVEMENT

    MOVE_UP:         
                     cmp  dx,0                  ;if out of boundries
                     jz   restart

                     sub  dx,20

                     mov  ah,0dh                ; if current pixel is gray
                     int  10h
                     cmp  al,08
                     jz   restart


                     cmp  dx,0
                     jz   skipup

                     sub  dx,20                 ; if upper pixel is gray
                     int  10h
                     cmp  al,08
                     jz   restart
                     add  dx,20

    skipup:          

                     add  cx,20                 ;if right pixel gray
                     int  10h
                     cmp  al,08
                     jz   restart
                     sub  cx,20

                     cmp  cx,0
                     jz   skipup2

                     sub  cx,20                 ;if left pixel gray
                     int  10h
                     cmp  al,08
     
                     jnz  ext995
                     jmp  far ptr restart
    ext995:          
                     add  cx,20

    skipup2:         
                     call draw_square
                     jmp  cont
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    MOVE_DOWN:       


                     cmp  dx,180                ;if out of boundries
                     jnz  extra
                     jmp  far ptr restart
    extra:           
                     add  dx,20

                     mov  ah,0dh                ; if current pixel is gray
                     int  10h
                     cmp  al,08
                     jnz  extra1
                     jmp  far ptr restart
    extra1:          

                     cmp  dx,180
                     jz   skiplow

                     add  dx,20                 ; if lower pixel is gray
                     int  10h
                     cmp  al,08
                     jnz  extra2
                     jmp  far ptr restart
    extra2:          
                     sub  dx,20
    skiplow:         


                     add  cx,20                 ;if right pixel gray
                     int  10h
                     cmp  al,08
                     jnz  extra3
                     jmp  far ptr restart
    extra3:          
                     sub  cx,20

                     cmp  cx,0
                     jz   skiplow2

                     sub  cx,20                 ;if left pixel gray
                     int  10h
                     cmp  al,08
                     jnz  extra4
                     jmp  far ptr restart
    extra4:          
                     add  cx,20

    skiplow2:        

                     call draw_square
                     jmp  cont
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    MOVE_LEFT:       

                     cmp  cx,0                  ;if out of boundries
                     jnz  extra15
                     jmp  far ptr restart
    extra15:         

                     sub  cx,20



                     mov  ah,0dh                ; if current pixel is gray
                     int  10h
                     cmp  al,08
                     jnz  extra5
                     jmp  far ptr restart
    extra5:          

                     cmp  dx,180
                     jz   skipleft



                     add  dx,20                 ; if lower pixel is gray
                     int  10h
                     cmp  al,08
                     jnz  extra75
                     jmp  far ptr restart
    extra75:         
                     sub  dx,20

    skipleft:        

                     cmp  dx,0
                     jz   skipleft2

                     sub  dx,20                 ;if upper pixel gray
                     int  10h
                     cmp  al,08
                     jnz  extra6
                     jmp  far ptr restart
    extra6:          
                     add  dx,20

    skipleft2:       

                     cmp  cx,0
                     jz   skipleft3

                     sub  cx,20                 ;if left pixel gray
                     int  10h
                     cmp  al,08
                     jnz  extra7
                     jmp  far ptr restart
    extra7:          
                     add  cx,20
    skipleft3:       
                     call draw_square
                     jmp  cont
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    MOVE_RIGHT:      


                     add  cx,20

                     mov  ah,0dh                ; if current pixel is gray
                     int  10h
                     cmp  al,08
                     jnz  extra8
                     jmp  far ptr restart
    extra8:          

                     cmp  dx,0
                     jz   skipright

                     sub  dx,20                 ; if upper pixel is gray
                     int  10h
                     cmp  al,08
                     jnz  extra9
                     jmp  far ptr restart
    extra9:          
                     add  dx,20

    skipright:       

                     cmp  dx,180
                     jz   skipright2


                     add  dx,20                 ;if lower pixel gray
                     int  10h
                     cmp  al,08
                     jnz  extra10
                     jmp  far ptr restart
    extra10:         
                     sub  dx,20

    skipright2:      
                     call draw_square
                     jmp  cont


    SKIP_MOVEMENT:   
                     call draw_square

    ; Terminate Program
                     mov  ah, 9
                     int  21h

main endp
end main