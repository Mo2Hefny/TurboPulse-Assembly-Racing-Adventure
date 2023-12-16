EXTRN TRACK:FAR
EXTRN GETCARINFO:FAR
EXTRN p1name:FAR
EXTRN p2name:FAR
EXTRN getsizes:FAR
PUBLIC ALLLOST
.model huge
.stack 64
.data
xcursor equ 11h
ycursor equ 07h
p1size db 1
p2size db 1
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

ALLLOST PROC FAR
    MOV AX,@DATA
    MOV ds,AX
    mov es,ax
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
    mov  bh, 0    ; page.
    lea  bp, p2name  ; offset.
    mov  bl, 01D ; default attribute.
    mov  cx, 0  ; char number.
    mov cl,p2size
    mov  dl, xcursor    ; col.
    mov  dh, ycursor    ; row.
    mov  ah, 13h    ; function.
    mov  al, 0h    ; sub-function.
    int  10h
    jmp exittotal
    player1_name:
    mov  bh, 0    ; page.
    lea  bp, p1name  ; offset.
    mov  bl, 012D ; default attribute.
    mov  cx, 0  ; char number.
    mov  cl,p1size
    mov  dl, xcursor    ; col.
    mov  dh, ycursor   ; row.
    mov  ah, 13h    ; function.
    mov  al, 0h    ; sub-function.
    int  10h
    exittotal:ret
ALLLOST ENDP
end 