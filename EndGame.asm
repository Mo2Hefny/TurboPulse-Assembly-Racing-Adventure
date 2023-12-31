EXTRN TRACK:FAR
EXTRN GETCARINFO:FAR
EXTRN p1name:FAR
EXTRN p2name:FAR
EXTRN getsizes:FAR 
EXTRN PRESSED_F4:BYTE 
PUBLIC END_GAME
.model huge
.stack 64
.data
xcursor equ 11h
ycursor equ 05h
p1size db 1
p2size db 1
p1score db 0
p2score db 0
scorestr db "Score "
PWinimg db 'Pwin.bin', 0
BothLimg db 'TimOt.bin', 0
WhoWon db 0
buffer_size equ 64000
IMAGE_HEIGHT equ 200;YOUR HEIGHT
IMAGE_WIDTH equ 320;YOUR WIDTH

SCREEN_WIDTH equ 320
SCREEN_HEIGHT equ 200
;---------------------------------------
.code
drawallost proc                                         ;Function To Load Track From array to Screen
                      mov  cx,0
                      mov  dx,0
                      mov  bx,320
                      MOV  di,200
                      mov  ah,0ch
                      mov  si,offset TRACK
    row273:           mov  AL,[SI]
                      int  10h
                      inc  si
                      inc  cx
                      cmp  cx,bx
                      jz   column273
                      jmp  row273
    column273:          
                      sub  cx,320
                      inc  dx
                      cmp  dx,di
                      jz   exit273
                      jmp  row273
    exit273:            
                      ret
drawallost endp

END_GAME PROC FAR
    push ES
    MOV AX,@DATA
    MOV ds,AX
    mov es,ax
    mov AL, 1
    cmp PRESSED_F4, AL
    jnz NO_SCORE_LEAVE
    jmp far ptr printscore
    NO_SCORE_LEAVE:
    call GETCARINFO
    mov WhoWon,al
    call getsizes
    mov p1size,al
    mov p2size,ah
    mov ah, 03Dh
    mov al, 0 ; open attribute: 0 - read-only, 1 - write-only, 2 -read&write
    cmp WhoWon,1
    jz playerwin
    cmp WhoWon,2
    jz playerwin
    mov dx, offset BothLimg ; ASCIIZ filename to open
    jmp loadbin
    playerwin:
    mov dx,offset PWinimg
   loadbin: int 21h

    mov bx, AX
    mov ah, 03Fh
    mov cx, buffer_size ; number of bytes to read
    mov dx, offset TRACK ; were to put read data
    int 21h
    CALL drawallost
    cmp WhoWon,1
    jz player1_name
    cmp WhoWon,2
    jz player2_name
    jmp exittotal
    player2_name:
    inc p2score
    mov  bh, 0    ; page.
    lea  bp, p2name  ; offset.
    mov  bl, 0Bh ; default attribute.
    mov  cx, 0  ; char number.
    mov cl,p2size
    mov  dl, xcursor    ; col.
    mov Al, p2size
    shr AL, 1
    shr AL, 1
    sub dl, al
    mov  dh, ycursor    ; row.
    mov  ah, 13h    ; function.
    mov  al, 0h    ; sub-function.
    int  10h
    jmp printscore
    player1_name:
    inc p1score
    mov  bh, 0    ; page.
    lea  bp, p1name  ; offset.
    mov  bl, 012D ; default attribute.
    mov  cx, 0  ; char number.
    mov  cl,p1size
    mov  dl, xcursor    ; col.
    mov Al, p1size
    shr AL, 1
    shr AL, 1
    sub dl, al
    mov  dh, ycursor   ; row.
    mov  ah, 13h    ; function.
    mov  al, 0h    ; sub-function.
    int  10h
printscore: mov  bh, 0    ; page.
    lea  bp, scorestr  ; offset.
    mov  bl, 012D ; default attribute.
    mov  cx, 0  ; char number.
    mov  cl,6
    mov  dl, xcursor    ; col.
    sub dl,4
    mov  dh, ycursor   ; row.
    add dh,2
    mov  ah, 13h    ; function.
    mov  al, 0h    ; sub-function.
    int  10h
                      mov  bh,0
                      MOV  AH,2
                      mov  dl, xcursor                        ; col.
                      add dl,2
                      mov  dh, ycursor                        ;ROW
                      add dh,2
                      int  10h
    mov bh,0
    mov al,p1score
    add al,'0'
    mov ah,9
    mov cx,1
    mov bl,012D
    int 10h
      mov  bh,0
                      MOV  AH,2
                      mov  dl, xcursor                        ; col.
                      add dl,3
                      mov  dh, ycursor                        ;ROW
                      add dh,2
                      int  10h
    mov dl,'-'
    mov ah,2
    int 21h
      mov bh,0
    mov al,p2score
    add al,'0'
    mov ah,9
    mov cx,1
    mov bl,0Bh
    int 10h
    exittotal:
    pop ES
    ret
END_GAME ENDP
end 
