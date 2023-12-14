EXTRN TRACK:FAR
PUBLIC ALLLOST
.model huge
.stack 64
.data
p2buffer label byte
p2size db 14
p2actual db ?
p2name  db 16 dup("$")

filename db 'd.bin', 0
buffer_size equ 64000

toutm db "time out"

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
    row273:             mov  AL,[SI]
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

    mov ah, 03Dh
    mov al, 0 ; open attribute: 0 - read-only, 1 - write-only, 2 -read&write
    mov dx, offset filename ; ASCIIZ filename to open
    int 21h

    mov bx, AX
    mov ah, 03Fh
    mov cx, buffer_size ; number of bytes to read
    mov dx, offset TRACK ; were to put read data
    int 21h

   

    CALL drawallost
    mov ax,@data
    mov es,ax
    mov  bh, 0    ; page.
    lea  bp, toutm  ; offset.
    mov  bl,40h ; default attribute.
    mov  cx, 8  ; char number.
    mov  dl, 11h    ; col.
    mov  dh, 16h    ; row.
    mov  ah, 13h    ; function.
    mov  al, 0h    ; sub-function.
    int  10h
    ret
ALLLOST ENDP
end 