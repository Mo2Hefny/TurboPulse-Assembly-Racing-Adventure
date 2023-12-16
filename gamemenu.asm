PUBLIC GameMenu
PUBLIC getmode
EXTRN TRACK:FAR
.model medium
.stack 64
.data
MAINMENUIMG db 'MMimg.bin', 0
chatmodemsg   db  "Not Available yet",'$'
GameModes db 0 ;1 for chat 2 for game
buffer_size equ 64000
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
    row54:             mov  AL,[SI]
                      int  10h
                      inc  si
                      inc  cx
                      cmp  cx,bx
                      jz   column54
                      jmp  row54
    column54:          
                      sub  cx,320
                      inc  dx
                      cmp  dx,di
                      jz   exit54
                      jmp  row54
    exit54:            
                      ret
drawImage endp
MODES PROC
BEGIN:
mov ah,0
int 16h
cmp AH,03BH
JZ CHAT
CMP AH,03CH
JZ GAME
CMP AH,1
JZ EXIT
JMP BEGIN
EXIT:mov  ax,4ch
     int  21H
     RET
GAME: MOV GameModes,2
ret
CHAT: mov GameModes,1
    mov  bh, 0    ; page.
    lea  bp, chatmodemsg  ; offset.
    mov  bl, 012D ; default attribute.
    mov  cx, 0  ; char number.
    mov  cl,017D
    mov  dl, 11    ; col.
    mov  dh, 7   ; row.
    mov  ah, 13h    ; function.
    mov  al, 0h    ; sub-function.
    int  10h
JMP BEGIN
MODES ENDP
getmode proc
mov cl,GameModes
getmode endp

GameMenu proc
    mov ax,@data
    mov ds,ax
    mov ah, 03Dh
    mov al, 0 ; open attribute: 0 - read-only, 1 - write-only, 2 -read&write
    mov dx, offset MAINMENUIMG ; ASCIIZ filename to open
    int 21h
    mov bx, AX
    mov ah, 03Fh
    mov cx, buffer_size ; number of bytes to read
    mov dx, offset TRACK ; were to put read data
    int 21h
    CALL drawImage
    call MODES
    ret
GameMenu endp
end 