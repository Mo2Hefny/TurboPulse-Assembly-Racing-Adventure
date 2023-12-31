  ; Sender.asm
  EXTRN CONFIG_PORT:FAR
  EXTRN SEND_INPUT:FAR
  EXTRN SERIAL_STATUS:BYTE
  EXTRN SEND:BYTE
  ;Receiver.asm
  EXTRN RECEIVE_INPUT:FAR
  EXTRN RECEIVED:BYTE
PUBLIC GameMenu
PUBLIC TEMP
PUBLIC GAME_MENU_INPUT
PUBLIC getmode
EXTRN TRACK:FAR
.model compact
.stack 64
.data
MAINMENUIMG db 'GMenu.bin', 0
chatmodemsg   db  " Check The Chat  ",'$'
playmodemsg   db  "   Let's Play    ",'$'
emptymodemsg   db  "                 ",'$'
GameModes db 0 ;1 for chat 2 for game
SerialGameModes db 0 ;1 for chat 2 for game
TEMP DW 0
INPUT DB -1
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
    mov input, -1
    mov GameModes, -1
    mov SerialGameModes, -1
BEGIN:
    ; CHECK IF OTHER PLAYER PRESSED PLAYED
    CALL RECEIVE_INPUT
    MOV AL, RECEIVED
    MOV SerialGameModes, AL
    call SHOW_MSGS
    cmp INPUT, -1
    jz BEGIN
    cmp INPUT, 1
    JZ CHAT
    cmp INPUT, 2
    JZ GAME
    cmp INPUT, 0
    JZ EXIT
    JMP BEGIN
EXIT:mov  ax,4ch
     int  21H
     RET
GAME: 
MOV SEND, 2
CALL SEND_INPUT
; CHECK IF HE WANTS TO PLAY AS WELL
cmp SerialGameModes, 2
jnz BEGIN                           ; PRESSED OTHER KEY
MOV GameModes, 2
mov AL, 2
ret
CHAT: 
    MOV SEND, 1
    CALL SEND_INPUT
    cmp SerialGameModes, 1
    jnz BEGIN
    mov GameModes, 1
    mov AL, 1
    ret
JMP BEGIN
MODES ENDP
;------------------------------------------------------------------------------
SHOW_MSGS proc near
    ; CHECK IF HE WANTS TO PLAY AS WELL
    mov  bh, 0    ; page.
    mov  bl, 012D ; default attribute.
    mov  cx, 0  ; char number.
    mov  cl,017D
    mov  dl, 11    ; col.
    mov  ah, 13h    ; function.
    mov  al, 0h    ; sub-function.
    cmp SerialGameModes, 1
    jz PRINT_CHAT_MSG
    cmp SerialGameModes, 2
    jz PRINT_PLAY_MSG
    ret

    PRINT_CHAT_MSG:
    lea  bp, chatmodemsg  ; offset.
    mov  dh, 6   ; row.
    int  10h
    lea  bp, emptymodemsg  ; offset.
    mov  dh, 9   ; row.
    int  10h
    ret

    PRINT_PLAY_MSG:
    lea  bp, emptymodemsg  ; offset.
    mov  dh, 6   ; row.
    int  10h
    lea  bp, playmodemsg  ; offset.
    mov  dh, 9   ; row.
    int  10h
    ret

SHOW_MSGS endp
;------------------------------------------------------------------------------
getmode proc
mov cl,GameModes
getmode endp

GameMenu proc far
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
    mov INPUT, -1
    call MODES
    ret
GameMenu endp
;-------------------------------------------------------
GAME_MENU_INPUT proc far
    in al, 60h
    cmp AL,03Bh
    jz CHATTING
    cmp AL,03CH
    jz PLAY
    CMP AL, 81h                     ; Release of ESC
    JZ CLOSE_GAME
    jmp EXIT_GAME_MENU_INPUT
    CHATTING:
        mov INPUT, 1
        jmp EXIT_GAME_MENU_INPUT
    PLAY:
        mov INPUT, 2
        jmp EXIT_GAME_MENU_INPUT
    CLOSE_GAME:
        mov INPUT, 0
        jmp EXIT_GAME_MENU_INPUT
    EXIT_GAME_MENU_INPUT:
    ret
GAME_MENU_INPUT endp
;-------------------------------------------------------
end 