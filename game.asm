  ; PATHGEN.asm
  EXTRN GENERATE_TRACK:FAR
  EXTRN Load_Track:FAR
  ; OBSTACLES.asm
  EXTRN ADD_OBSTACLE:FAR
  EXTRN DRAW_OBSTACLES:FAR
  ; CARS.asm
  EXTRN DRAW_CARS:FAR
  EXTRN MOVE_CARS:FAR
  EXTRN LOAD_CARS:FAR
  ;mainmenu.asm
  EXTRN MAINMENU:FAR
  EXTRN p1name:FAR
  EXTRN p2name:FAR
  EXTRN p1actual:FAR
  EXTRN p2actual:FAR
  ;alllost.asm
  EXTRN ALLLOST:FAR

  PUBLIC TIME_AUX
.model huge
.stack 64
.data
  TIME_AUX  DB 0                        ; Used when checking if time has changed.code
  min db 0
  sec db 10
  currsec db ?
  messlost db "both players lost" 
.code
jmp far ptr main
;

  ;-------------------------------------------------------
RESET_BACKGROUND proc near
  ; (Send to TRACK file)
  ; Set background color to WHITE
  mov AH, 06h                           ; Scroll up function
  xor AL, AL                            ; Clear entire screen
  xor CX, CX                            ; Upper left corner CH=row, CL=column
  mov DX, 104Fh                         ; lower right corner DH=row, DL=column 
  mov BH, 1Eh                           ; YellowOnBlue
  int 10h
  ret
RESET_BACKGROUND endp
;-------------------------------------------------------

dtime proc
;display min
    mov ah,2
    mov bh,0
    mov dh,2eh
    mov dl,32h
    int 10h
    MOV dl,'0'
    mov ah,2
    int 21h
    mov al,min
    add al,30h
    mov dl,al
    mov ah,02
    int 21h
    mov dl,':'
    mov ah,2
    int 21H
;display sec
    mov bh,10
    mov al,sec
    mov ah,0
    div bh
    add al,30h
    add ah,30h
    mov bh,ah
    mov dl,al
    mov ah,02
    int 21h
    mov dl,Bh
    mov ah,02
    int 21h
    ret
dtime endp 
displaynames proc
    mov ax,@data
    mov es,ax   
     
    ; p1 name 
    mov  bh, 0    ; page.
    lea  bp, p1name  ; offset.
    mov  bl,01h ; default attribute.
    mov cx,0
    mov  cl, p1actual  ; char number.
    mov  dl, 2h    ; col.
    mov  dh, 15h    ; row.
    mov  ah, 13h    ; function.
    mov  al, 0h    ; sub-function.
    int  10h

    mov  bh, 0    ; page.
    lea  bp, p2name  ; offset.
    mov  bl,04h ; default attribute.
    mov cx,0
    mov  cl, p2actual  ; char number.
    mov  dl, 1ah    ; col.
    mov  dh, 15h    ; row.
    mov  ah, 13h    ; function.
    mov  al, 0h    ; sub-function.
    int  10h



displaynames endp
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
modify proc 
    mov cl,sec
    cmp cl,0
    jz adjustmin
    MOV currsec,dh
    dec sec
    call dtime
    jmp retlabel
adjustmin:cmp min,0
          JZ retlabel
          dec min
          mov sec,60
          call dtime

retlabel:
    ret
modify endp
main proc far

  mov AX, @data
  mov DS, AX

  ; Initialize Video Mode
  mov AX, 0013h                         ; Select 320x200, 256 color graphics
  int 10h
  
  ; By default, there are 16 colors for text and only 8 colors for background.
  ; There is a way to get all the 16 colors for background, which requires turning off the "blinking attribute".
  ; Toggle Intensity/Blinking Bit
  mov AX, 1003h
  mov BX, 0000h                         ; 00h Background intensity enabled
                                        ; 01h Blink enabled
  int 10h
 
  call MAINMENU
  ;Generate Track
  call GENERATE_TRACK                   ; Return Starting Direction in AL
  call LOAD_CARS
  call displaynames
   mov AH, 2Ch                          ;initialize currentsec
   int 21h                             
   mov currsec,dh 


                                       ; initialize names

  ; ;;;;;; TESTING COLLISION ;;;;;;
  ; mov AX, 0
  ; mov CX, 25
  ; mov DX, 85
  ; call ADD_OBSTACLE
  ; mov AX, 0
  ; mov CX, 5
  ; mov DX, 105
  ; call ADD_OBSTACLE
  ; mov AX, 0
  ; mov CX, 5
  ; mov DX, 65
  ; call ADD_OBSTACLE

  ;Get the systen time
  CHECK_TIME:
    
    mov AH, 2Ch
    int 21h                             ; CH = hour CL = minute DH - second DL = 1/100 seconds
    cmp currsec,dh
    jz skipcheck 
    call modify
    cmp  min,0
    jnz skipcheck
    cmp sec,0
    jz terminate
skipcheck:
    cmp DL, TIME_AUX                    ; fps = 100
    je  CHECK_TIME                      ; repeat till time frame changes
    mov TIME_AUX, DL
  ; Else draw the new frame
  ;call Load_Track
  ; Draw Obstacles
  ; Draw Cars
  call MOVE_CARS
  mov AX, 0A000h
  mov ES, AX
  call DRAW_OBSTACLES
  call DRAW_CARS
  
  ; Repeat the process
  jmp CHECK_TIME

  ; Terminate Program
terminate:
  ; mov ah,2
  ; mov dx,0A0Ah
  ; mov bh,0
  ; int 10h
  ; mov ah,9
  ; lea dx,message
  ; int 21h
  ;base offset bp
  call ALLLOST

  mov ax,4ch
  int 21H
main endp
end main