    ; Sender.asm
  EXTRN CONFIG_PORT:FAR
  EXTRN SEND_INPUT:FAR
  EXTRN WAIT_TILL_SEND:FAR
  EXTRN SEND_WORD:FAR
  EXTRN WAIT_TILL_SEND_WORD:FAR
  EXTRN SERIAL_STATUS:BYTE
  EXTRN SEND:BYTE
  ;Receiver.asm
  EXTRN RECEIVE_INPUT:FAR
  EXTRN WAIT_TILL_RECEIVE:FAR
  EXTRN RECEIVE_WORD:FAR
  EXTRN WAIT_TILL_RECEIVE_WORD:FAR
  EXTRN RECEIVED:BYTE
  EXTRN p1name:BYTE
  EXTRN p2name:BYTE
  EXTRN p1actual:BYTE
  EXTRN p2actual:BYTE
  PUBLIC CHATTING
.model small
.stack 64
.data
    X           db  ?
    VALUE       db  ?
    newline     db  10,13,'$'

    myname      db  "karim mahmoud","$"
    othername   db  "karim mohamed","$"
    exitmessage db  "exit","$"
    exitmessagelbl db "to end chat with ","$"
    pressf3 db ", Press F3","$"
    sf          db  ?
    rf          db  ?

    mynamex     equ 6                      ;;player1name
    mynamey     equ 2

    otherpnamex equ 48                     ;;otherplayername
    otherpnamey equ 2
    
    
    
    mychatx     equ 38                     ;;chatboundries
    maxchaty    equ 20
    otherchatx  equ 78
    othechaty   equ 20


    otherplayerstart equ 39

    lastrx      db  39                     ;last indices
    lastry      db  5
    lastsx      db  0
    lastsy      db  5


.code
;----------------------------------------------------------
decoration proc
               mov  cx,12
               mov  ah,2
               mov  dh,0
               mov  bx,0
    lbl:       
               mov  dl,39
               mov  dh,bl
               int  10h
               mov  dl,"|"
               int  21h
               add  bx,2
               loop lbl
               ret
decoration endp
;----------------------------------------------------------
scroll1 proc
    push ax
    push bx
    push cx
    push dx
    mov ah, 06h     ; AH = Scroll up function
    mov al, 01h     ; AL = Number of lines to scroll (1 line)
    mov bh, 07h     ; BH = Text attribute (color, if applicable)
    mov cx, 0500h     ; CH = Starting row (5), CL = Starting column (0)
    mov dh, 15h     ; DH = Ending row (35), DL = Ending column (20)
    mov dl,26h
    int 10h         ; Call BIOS video services
    pop dx
    pop cx
    pop bx
    pop ax   
   ret

scroll1 endp
;----------------------------------------------------------
scroll2 proc
    push ax
    push bx
    push cx
    push dx
    mov ah, 06h     ; AH = Scroll up function
    mov al, 01h     ; AL = Number of lines to scroll (1 line)
    mov bh, 07h     ; BH = Text attribute (color, if applicable)
    mov cx, 0528h     ; CH = Starting row (5), CL = Starting column (0)
    mov dh, 15h     ; DH = Ending row (35), DL = Ending column (20)
    mov dl,4fh
    int 10h         ; Call BIOS video services
    pop dx
    pop cx
    pop bx
    pop ax   
   ret         
scroll2 endp
;----------------------------------------------------------
backspace1 proc

    cmp lastsx,0
    jz return

    mov ah,3h  ;;getcursor
    mov bh,0h
    int 10h

    dec lastsx
    dec dl     ; dec cursor

    mov ah,2
    int 10h    ;move cursor

    mov ah,2 ;display space
    mov dl,' '
    int 21h
  
    mov ah,3h  ;return again
    mov bh,0h
    int 10h
    dec dl
    mov ah,2
    int 10h
return:   
    ret
backspace1 endp
;----------------------------------------------------------
backspace2 proc

    cmp lastrx,otherplayerstart
    jz return2

    mov ah,3h  ;;getcursor
    mov bh,0h
    int 10h

    dec lastrx
    dec dl     ; dec cursor

    mov ah,2
    int 10h    ;move cursor

    mov ah,2 ;display space
    mov dl,' '
    int 21h
  
    mov ah,3h  ;return again
    mov bh,0h
    int 10h
    dec dl
    mov ah,2
    int 10h
return2:   
    ret
backspace2 endp
;----------------------------------------------------------
exitmsgtoolbar proc

     mov  cx,80
     mov  ah,2
     mov  dh,23
     mov  bx,0
lbl2:       
    mov  dl,bl
    int  10h
    mov  dl,"-"
    int  21h
    inc  bx
    loop lbl2

    mov  dl,0
    mov  dh,24
    mov  ah,2
    int  10h

    mov ah,9
    lea dx,exitmessagelbl
    int 21h

    lea dx,othername
    int 21h

    lea dx,pressf3
    int 21h

    ret

exitmsgtoolbar endp
;----------------------------------------------------------
CHATTING proc far
               mov  ax,@data
               mov  ds,ax
    ;Check that Data Ready
               mov  ah, 0             ; convert to text mode
               mov  al, 3
               int  10h

              mov CX, 4
              clear:
                call scroll1
                call scroll2
                loop clear

    ;;mov cursor to myname
               mov  ah,2
               mov  dl,mynamex
               mov  dh,mynamey
               int  10h

    ;; display names
               mov  ah,9
               lea  dx,p1name
               int  21h

    ;;mov cursor to myname
               mov  ah,2
               mov  dl,otherpnamex
               mov  dh,otherpnamey
               int  10h

    ;; display otherplayer
               mov  ah,9
               lea  dx,p2name
               int  21h

               call decoration
               call exitmsgtoolbar
               mov  dl,lastrx
               mov  dh,lastry
               mov  ah,2
               int  10h

    again1:    mov  ah,1
               int  16h
               jz   farjmp              ;checks if any key pressed to transmit
               mov  ah,0              ;takes the char
               int  16h


               cmp  ah,61d 
               jnz  notexit
               mov  VALUE,61d
               mov  dx , 3F8H         ; Transmit data register
               mov  al,VALUE
               out  dx , al
               jmp  far ptr exit 
notexit:
               cmp al,8d
               jnz notback     
               CALL backspace1
               mov  VALUE,8d
               mov  dx , 3F8H         ; Transmit data register
               mov  al,VALUE
               out  dx , al 
               jmp farjmp
notback:

               cmp  al,13d
               jnz  notenter
               mov  lastsx,0
               cmp lastsy,20
               jb skip4
               call scroll1
               dec lastsy
   skip4:      inc  lastsy
               mov  VALUE,13d
               mov  dx , 3F8H         ; Transmit data register
               mov  al,VALUE
               out  dx , al
     farjmp:
                jmp  far ptr next
    notenter:  
               mov  VALUE,al
               push ax
               push dx
               mov  dl,lastsx
               mov  dh,lastsy
               mov  ah,2
               int  10h
               cmp  lastsx,mychatx  ;; chat 1 boundry
               jnz  label1
               mov  lastsx,0
               cmp lastsy,20
               jb skip3
               mov  dl,VALUE
               mov  ah,2
               int  21h
               call scroll1
               jmp  sk
    skip3:     inc  lastsy
               jmp  skip
    label1:    
               inc  lastsx
    skip:      mov  dl,VALUE
               mov  ah,2
               int  21h
     sk:       pop  dx
               pop  ax
    ;Check that Transmitter Holding Register is Empty
               mov  dx , 3FDH         ; Line Status Register
    AGAIN:     
               In   al , dx           ;Read Line Status
               AND  al , 00100000B
               JZ   next
    ;If empty put the VALUE in Transmit data register
               mov  dx , 3F8H         ; Transmit data register
               mov  al,VALUE
               out  dx , al
    next:      
    CHK:       
               mov  dx , 3FDH         ; Line Status Register
               in   al , dx
               AND  al , 1
               JZ   faragain

    ;If Ready read the VALUE in Receive data register

               mov  dx , 03F8H
               in   al , dx
               mov  X, al

               cmp X,61d
               jz exit      ;; if f3(exist) 

               cmp X,8d
               jnz notback2     
               CALL backspace2 
               jmp faragain
notback2:


               cmp  X,13d
               jnz  label3
               mov  lastrx,otherplayerstart  ; x start
               cmp lastry,20
               jb skip101
               call scroll2
               dec lastry
   skip101:    inc  lastry
    faragain:
       jmp  far ptr again1
    label3:    
               
                
               push ax
               push dx
               mov  dl,lastrx
               mov  dh,lastry
               mov  ah,2
               int  10h
               cmp  lastrx,otherchatx   ;; chat2 boundries
               jnz  label2
               mov  lastrx,otherplayerstart+1  ;;x start+1
               cmp lastry,20
               jb skip5
               call scroll2
               dec lastry
       skip5 : inc  lastry
               jmp  skip2
    label2:    
               inc  lastrx
    skip2:     
               mov  dl,lastrx
               mov  dh,lastry
               mov  ah,2
               int  10h
               mov  dl,X
               mov  ah,2
               int  21h
               pop  dx
               pop  ax
               jmp  again1
    exit:      
                mov  AX, 0013h                      ; Select 320x200, 256 color graphics
                int  10h
  
  ; By default, there are 16 colors for text and only 8 colors for background.
  ; There is a way to get all the 16 colors for background, which requires turning off the "blinking attribute".
  ; Toggle Intensity/Blinking Bit
                mov  AX, 1003h
                mov  BX, 0000h                      ; 00h Background intensity enabled
  ; 01h Blink enabled
                int  10h   
                ret

CHATTING endp
end