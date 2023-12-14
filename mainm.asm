EXTRN TRACK:FAR
PUBLIC p1name
PUBLIC p2name
PUBLIC p1actual
PUBLIC p2actual

PUBLIC MAINMENU
.model huge
.stack 64
.data
xind equ 0Dh
yind equ 08h

varx db ?
vary db ?

maxnumchar equ 14

currentchar db ?

p1name db 15 dup('$')
p1actual db 0

p2name db 15 dup('$')
p2actual db 0


filename db 'b.bin', 0
buffer_size equ 64000
emessage db "error:reenter your name"
lenmessage db "only 14 chars allowed"


IMAGE_HEIGHT equ 200;YOUR HEIGHT
IMAGE_WIDTH equ 320;YOUR WIDTH

SCREEN_WIDTH equ 320
SCREEN_HEIGHT equ 200
;---------------------------------------
.code
drawImage proc                                         ;Function To Load Track From array to Screen
                      mov  cx,0
                      mov  dx,0
                      mov  bx,320
                      MOV  di,200
                      mov  ah,0ch
                      mov  si,offset TRACK
    row696:             mov  AL,[SI]
                      int  10h
                      inc  si
                      inc  cx
                      cmp  cx,bx
                      jz   column696
                      jmp  row696
    column696:          
                      sub  cx,320
                      inc  dx
                      cmp  dx,di
                      jz   exit696
                      jmp  row696
    exit696:            
                      ret
drawImage endp

MAINMENU PROC FAR
    push DS
    push ES
    MOV AX,@DATA
    MOV ds,AX

    mov ah, 03Dh
    mov al, 0 ; open attribute: 0 - read-only, 1 - write-only, 2 -read&write
    mov dx, offset filename ; ASCIIZ filename to open
    int 21h



    mov bx, AX
    mov ah, 03Fh
    mov cx, buffer_size ; number of bytes to read
    mov dx, offset TRACK ; were to put read data
    int 21h

   



    ;mov ah, 3Eh         ; DOS function: close file
    ;INT 21H



    CALL drawImage
     
    push AX
    push bx
    push dx
    lea di,p1name
checkfchar1:
    mov ah,2
    mov bh,0
    mov dh,yind
    mov dl,xind
    int 10h


charloop:

    jmp innerloop
applyback:
    cmp p1actual,0
    jz innerloop

    mov ah,3h  ;;getcursor
    mov bh,0h
    int 10h

    dec di     ;dec si
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
    dec p1actual
    jmp innerloop
checksize:
    cmp p1actual,maxnumchar
    jz lenerror
    jnz continue

innerloop:  
    mov ah,0
    int 16h
    mov currentchar,al
    cmp al,8d
    jz applyback
    jmp checksize
continue: 
    cmp al,13d
    JZ finalchecks
    mov dl,currentchar
    mov ah,2
    int 21h
    mov [di],al
    inc di
    inc p1actual
    JMP innerloop

finalchecks:
    cmp p1actual,0
    jz error1

    mov al,byte ptr p1name

    cmp al,'A'
    jb  error1
    cmp al,'['
    jb  done    
    cmp al,'a'
    jb error1
    cmp al,'{'
    jb done

error1:
    
    mov ah,3h  ;;getcursor
    mov bh,0h
    int 10h
    mov varx,dl
    mov vary,dh
    mov ax,@data
    mov es,ax
    mov  bh, 0    ; page.
    lea  bp, emessage  ; offset.
    mov  bl,40h ; default attribute.
    mov  cx, 23  ; char number.
    mov  dl, 0ah    ; col.
    mov  dh, 0ah    ; row.
    mov  ah, 13h    ; function.
    mov  al, 0h    ; sub-function.
    int  10h
    mov DL,varx
    mov dh,vary
    mov ah,2
    int 10h
    jmp innerloop

lenerror:
    mov ah,3h  ;;getcursor
    mov bh,0h
    int 10h
    mov varx,dl
    mov vary,dh
    mov ax,@data
    mov es,ax
    mov  bh, 0    ; page.
    lea  bp, lenmessage  ; offset.
    mov  bl,40h ; default attribute.
    mov  cx, 21  ; char number.
    mov  dl, 0ah    ; col.
    mov  dh, 0ah    ; row.
    mov  ah, 13h    ; function.
    mov  al, 0h    ; sub-function.
    int  10h
    mov DL,varx
    mov dh,vary
    mov ah,2
    int 10h
    jmp innerloop

done:
    pop dx
    pop bx
    pop ax



;;;;;;;;;;;; player2


    CALL drawImage

    push AX
    push bx
    push dx
    lea di,p2name
checkfchar2:
    mov ah,2
    mov bh,0
    mov dh,yind
    mov dl,xind
    int 10h


charloop2:

    jmp innerloop2
applyback2:
    cmp p2actual,0
    jz innerloop2

    mov ah,3h  ;;getcursor
    mov bh,0h
    int 10h

    dec di     ;dec si
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
    dec p2actual
    jmp innerloop2
checksize2:
    cmp p2actual,maxnumchar
    jz lenerror2
    jnz continue2

innerloop2:  
    mov ah,0
    int 16h
    mov currentchar,al
    cmp al,8d
    jz applyback2
    jmp checksize2
continue2: 
    cmp al,13d
    JZ finalchecks2
    mov dl,currentchar
    mov ah,2
    int 21h
    mov [di],al
    inc di
    inc p2actual
    JMP innerloop2

finalchecks2:
    cmp p2actual,0
    jz error2

    mov al,byte ptr p2name

    cmp al,'A'
    jb  error2
    cmp al,'['
    jb  done2    
    cmp al,'a'
    jb error2
    cmp al,'{'
    jb done2

error2:
    
    mov ah,3h  ;;getcursor
    mov bh,0h
    int 10h
    mov varx,dl
    mov vary,dh
    mov ax,@data
    mov es,ax
    mov  bh, 0    ; page.
    lea  bp, emessage  ; offset.
    mov  bl,40h ; default attribute.
    mov  cx, 23  ; char number.
    mov  dl, 0ah    ; col.
    mov  dh, 0ah    ; row.
    mov  ah, 13h    ; function.
    mov  al, 0h    ; sub-function.
    int  10h
    mov DL,varx
    mov dh,vary
    mov ah,2
    int 10h
    jmp innerloop2

lenerror2:
    mov ah,3h  ;;getcursor
    mov bh,0h
    int 10h
    mov varx,dl
    mov vary,dh
    mov ax,@data
    mov es,ax
    mov  bh, 0    ; page.
    lea  bp, lenmessage  ; offset.
    mov  bl,40h ; default attribute.
    mov  cx, 21  ; char number.
    mov  dl, 0ah    ; col.
    mov  dh, 0ah    ; row.
    mov  ah, 13h    ; function.
    mov  al, 0h    ; sub-function.
    int  10h
    mov DL,varx
    mov dh,vary
    mov ah,2
    int 10h
    jmp innerloop2

done2:
    pop dx
    pop bx
    pop ax
    pop ES
    pop DS
    ret
MAINMENU ENDP
end 