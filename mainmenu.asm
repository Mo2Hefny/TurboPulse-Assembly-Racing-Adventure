.model medium
.stack 64
.data
xind equ 0Dh
yind equ 08h
p1buffer label byte
p1size db 14
p1actual db ?
p1name  db 16 dup("$")

p2buffer label byte
p2size db 14
p2actual db ?
p2name  db 16 dup("$")

filename db 'b.bin', 0
buffer_size equ 64000
buffer db buffer_size dup(?)

IMAGE_HEIGHT equ 200;YOUR HEIGHT
IMAGE_WIDTH equ 320;YOUR WIDTH

SCREEN_WIDTH equ 320
SCREEN_HEIGHT equ 200
;---------------------------------------
.code
jmp MAINMENU
drawImage proc                                         ;Function To Load Track From array to Screen
                      mov  cx,0
                      mov  dx,0
                      mov  bx,320
                      MOV  di,200
                      mov  ah,0ch
                      mov  si,offset buffer
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
drawImage endp

MAIN PROC FAR
    MOV AX,@DATA
    MOV DS,AX

    mov ah, 03Dh
    mov al, 0 ; open attribute: 0 - read-only, 1 - write-only, 2 -read&write
    mov dx, offset filename ; ASCIIZ filename to open
    int 21h



    mov bx, AX
    mov ah, 03Fh
    mov cx, buffer_size ; number of bytes to read
    mov dx, offset buffer ; were to put read data
    int 21h



    mov ah, 3Eh         ; DOS function: close file
    INT 21H

  ;  MOV DI,320/2 - IMAGE_WIDTH/2 ;STARTING PIXEL
    
    mov ah,0
    mov al,13h
    int 10h

    CALL drawImage
     
     push AX
     push bx
     push dx
   ; MOV AH, 0
    ;INT 16h
    mov ah,2
    mov bh,0
    mov dh,yind
    mov dl,xind
    int 10h

    mov ah,0Ah 
    lea dx,p1buffer
    int 21h
    pop dx
    pop bx
    pop ax


    CALL drawImage

    push AX
     push bx
     push dx
    mov ah,2
    mov bh,0
    mov dh,yind
    mov dl,xind
    int 10h

    mov ah,0Ah 
    lea dx,p2buffer
    int 21h    
    pop dx
    pop bx
    pop ax
MAINMENU ENDP

