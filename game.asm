  ; PATHGEN.asm
  EXTRN GENERATE_TRACK:FAR
  EXTRN Load_Track:FAR
  EXTRN pathlength:FAR
  ;GAMEMENU.ASM
  EXTRN GameMenu:FAR
  EXTRN getmode:FAR
  ; OBSTACLES.asm
  EXTRN ADD_OBSTACLE:FAR
  EXTRN DRAW_ENTITIES:FAR
  EXTRN UPDATE_ENTITIES:FAR
  ; CARS.asm
  EXTRN GETCARINFO:FAR
  EXTRN CHECK_INPUT_UPDATES:FAR
  EXTRN DRAW_CARS:FAR
  EXTRN PRINT_TEST:FAR
  EXTRN UPDATE_CARS:FAR
  EXTRN LOAD_CARS:FAR
  ;mainmenu.asm
  EXTRN MAINMENU:FAR
  EXTRN p1name:FAR
  EXTRN p2name:FAR
  EXTRN p1actual:FAR
  EXTRN p2actual:FAR
  ;sound
  EXTRN PlaySound:FAR
  ;alllost.asm
  EXTRN ALLLOST:FAR
  EXTRN CAR_WON:FAR
  EXTRN CAR_PROGRESS:FAR
  EXTRN CAR_POWER:FAR
  PUBLIC TIME_AUX
  PUBLIC TIME_SEC
.model small
.stack 64
.data
  TIME_AUX       DB  0               ; Used when checking if time has changed.code
  min            db  0
  sec            db  2
  TIME_SEC       DB  0               ; Used for updating time for games
  delay_seconds  db  0
  delay_secConst equ 3
  BoostUIMsg     db  "Power Ups:"
  ProgressUIMsg  DB  "Progress:"
  BOOST0NAME     DB  "No Power",'$'  ;DONT YOU DARE REMOVE SPACES
  BOOST1NAME     DB  "Nitro   ",'$'  ;DONT YOU DARE REMOVE SPACES
  BOOST2NAME     DB  "Frost   ",'$'  ;DONT YOU DARE REMOVE SPACES
  BOOST3NAME     DB  "Blockade",'$'  ;DONT YOU DARE REMOVE SPACES
  BOOST4NAME     DB  "Bypass  ",'$'  ;DONT YOU DARE REMOVE SPACES
  ProgressBuffer db  10 dup('$')     ; this is to print decimal numbers
  slash          db  "/",'$'
.code
  ;-------------------------------------------------------
main proc far
                mov  AX, @data
                mov  DS, AX

                mov  ES, AX
  ; Initialize Video Mode
                mov  AX, 0013h                      ; Select 320x200, 256 color graphics
                int  10h
  
  ; By default, there are 16 colors for text and only 8 colors for background.
  ; There is a way to get all the 16 colors for background, which requires turning off the "blinking attribute".
  ; Toggle Intensity/Blinking Bit
                mov  AX, 1003h
                mov  BX, 0000h                      ; 00h Background intensity enabled
  ; 01h Blink enabled
                int  10h
                call MAINMENU
  GameMenulabel:
                CALL GameMenu
  ;CALL getmode
                cli
                push ds
                mov  ax,cs
                mov  ds,ax
                mov  ax,2509h
                lea  dx, CHECK_INPUT_UPDATES
                int  21h
                pop  ds
                sti                                 ;Generate Track
                mov  AX, @data
                mov  DS, AX
                call GENERATE_TRACK                 ; Return Starting Direction in AL
                call LOAD_CARS
                mov  AH, 2Ch                        ;initialize currentsec
                int  21h
                mov  TIME_SEC,dh
  
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
                mov  AH, 2Ch
                int  21h                            ; CH = hour CL = minute DH - second DL = 1/100 seconds
                cmp  DL, TIME_AUX                   ; fps = 100
                je   CHECK_TIME                     ; repeat till time frame changes
                mov  TIME_AUX, DL
  ; CHECK IF SECOND HAS CHANGED
                cmp  TIME_SEC, DH
                jz   skipcheck
                call modify
                cmp  min,0
                jnz  skipcheck
                cmp  sec,0
                jz   terminate
  skipcheck:    
  ; Logic
  call UPDATE_ENTITIES
  call UPDATE_CARS
  call DisplayUI
  ; Draw
  call DRAW_ENTITIES
  ;call PRINT_TEST
  call DRAW_CARS
  
  ; Repeat the process
                CALL GETCARINFO
                cmp  AL,1
                jz   terminate
                cmp  AL,2
                jz   terminate
                jmp  CHECK_TIME

  ; Terminate Program
  terminate:    
                call ALLLOST
                call PlaySound
                jmp  GameMenulabel
main endp
  ;-------------------------------------------------------
modify proc near
                mov  cl,sec
                cmp  cl,0
                jz   adjustmin
                MOV  TIME_SEC,dh
                dec  sec
                call dtime
                jmp  retlabel
  adjustmin:    cmp  min,0
                JZ   retlabel
                dec  min
                mov  sec,60
                call dtime

  retlabel:     
                ret
modify endp
  ;-------------------------------------------------------
dtime proc near
  ;display min
                mov  ah,2
                mov  bh,0
                mov  dh,2eh
                mov  dl,32h
                int  10h
                MOV  dl,'0'
                mov  ah,2
                int  21h
                mov  al,min
                add  al,30h
                mov  dl,al
                mov  ah,02
                int  21h
                mov  dl,':'
                mov  ah,2
                int  21H
  ;display sec
                mov  bh,10
                mov  al,sec
                mov  ah,0
                div  bh
                add  al,30h
                add  ah,30h
                mov  bh,ah
                mov  dl,al
                mov  ah,02
                int  21h
                mov  dl,Bh
                mov  ah,02
                int  21h
                ret
dtime endp
  ;-------------------------------------------------------
DisplayUI proc near
                push BP
                mov  ax,@data
                mov  es,ax
  ; p1 name
                mov  bh, 0                          ; page.
                lea  bp, p1name                     ; offset.
                mov  bl,012D                        ; default attribute.
                mov  cx,0
                mov  cl, byte ptr p1actual          ; char number.
                mov  dl, 2h                         ; col.
                mov  dh, 15h                        ; row.
                mov  ah, 13h                        ; function.
                mov  al, 0h                         ; sub-function.
                int  10h
  ;p2 name
                mov  bh, 0                          ; page.
                lea  bp, p2name                     ; offset.
                mov  bl,01D                         ; default attribute.
                mov  cx,0
                mov  cl, byte ptr p2actual          ; char number.
                mov  dl, 1ah                        ; col.
                mov  dh, 15h                        ; row.
                mov  ah, 13h                        ; function.
                mov  al, 0h                         ; sub-function.
                int  10h
  p1powerup:    
                mov  bh, 0                          ; page.
                lea  bp, BoostUIMsg                 ; offset.
                mov  bl,0Fh                         ; default attribute.
                mov  cx,0
                mov  cl, 0ah                        ; char number.
                mov  dl, 0h                         ; col.
                mov  dh, 16h                        ; row.
                mov  ah, 13h                        ; function.
                mov  al, 0h                         ; sub-function.
                int  10h
                mov  dl, 0ah                        ; col.
                mov  dh, 16h                        ; row.
                MOV  AH,2
                INT  10H
                CALL GETCARINFO
  NOBOOST:      CMP  CL,0
                jnz  Nitro
                mov  dx,offset BOOST0NAME
                jmp  printboost
  Nitro:        CMP  CL,1
                jnz  Frost
                mov  dx,offset BOOST1NAME
                jmp  printboost
  Frost:        CMP  CL,2
                jnz  Block
                mov  dx,offset BOOST2NAME
                jmp  printboost
  Block:        CMP  CL,3
                jnz  Bypass
                mov  dx,offset BOOST3NAME
                jmp  printboost
  Bypass:       CMP  CL,4
                jnz  printboost
                mov  dx,offset BOOST4NAME
  printboost:   
                MOV  AH,9
                INT  21H
  p2powerup:    
                mov  bh, 0                          ; page.
                lea  bp, BoostUIMsg                 ; offset.
                mov  bl,0Fh                         ; default attribute.
                mov  cx,0
                mov  cl, 0ah                        ; char number.
                mov  dl, 16h                        ; col.
                mov  dh, 16h                        ; row.
                mov  ah, 13h                        ; function.
                mov  al, 0h                         ; sub-function.
                int  10h
                mov  dl, 20h                        ; col.
                mov  dh, 16h                        ; row.
                MOV  AH,2
                INT  10H
                CALL GETCARINFO
  NOBOOST2:     CMP  CH,0
                jnz  Nitro2
                mov  dx,offset BOOST0NAME
                jmp  printboost2
  Nitro2:       CMP  CH,1
                jnz  Frost2
                mov  dx,offset BOOST1NAME
                jmp  printboost2
  Frost2:       CMP  CH,2
                jnz  Block2
                mov  dx,offset BOOST2NAME
                jmp  printboost2
  Block2:       CMP  CH,3
                jnz  Bypass2
                mov  dx,offset BOOST3NAME
                jmp  printboost2
  Bypass2:      CMP  CH,4
                jnz  printboost2
                mov  dx,offset BOOST4NAME
  printboost2:  
                MOV  AH,9
                INT  21H
  ;p1progress
                mov  bh, 0                          ; page.
                lea  bp,ProgressUIMsg               ; offset.
                mov  bl,0Fh                         ; default attribute.
                mov  cx,0
                mov  cl, 09h                        ; char number.
                mov  dl, 0h                         ; col.
                mov  dh, 18h                        ; row.
                mov  ah, 13h                        ; function.
                mov  al, 0h                         ; sub-function.
                int  10h
  ;Conver Progress to ASCI
                call GETCARINFO
                mov  ax,0
                mov  al,dl
                mov  cx, 10                         ; Set divisor to 10 for decimal conversion
                mov  bx, 10                         ; Set base to 10
                call convert
  ;set cursor
                MOV  AH,2
                mov  dl, 09h                        ; col.
                mov  dh, 18h                        ;ROW
                int  10h
  ;print string
                mov  bh,0
                mov  dx,offset ProgressBuffer
                mov  ah,9
                int  21h
  ;set cursor
                MOV  AH,2
                mov  dl, 0bh                        ; col.
                mov  dh, 18h                        ;ROW
                int  10h
  ;PRINT SLASH
                mov  bh,0
                mov  dx,offset slash
                mov  ah,9
                int  21h
  ;SET CURSOR
                MOV  AH,2
                mov  dl, 0ch                        ; col.
                mov  dh, 18h                        ;ROW
                int  10h
  ;Print Track Length
                mov  ax,0
                mov  al, byte ptr pathlength
                sub  al,4                           ;FOR SOME REASON THERE IS ALWAYS A DIFFERNCE OF 4 BETWEEN PROGRESS AND TRACK LENGTH SO LAF2THA
                mov  cx, 10                         ; Set divisor to 10 for decimal conversion
                mov  bx, 10                         ; Set base to 10
                call convert
                mov  bh,0
                mov  dx,offset ProgressBuffer
                mov  ah,9
                int  21h
  ;p2progress
                mov  bh, 0                          ; page.
                lea  bp,ProgressUIMsg               ; offset.
                mov  bl,0Fh                         ; default attribute.
                mov  cx,0
                mov  cl, 09h                        ; char number.
                mov  dl, 19h                        ; col.
                mov  dh, 18h                        ; row.
                mov  ah, 13h                        ; function.
                mov  al, 0h                         ; sub-function.
                int  10h
  ;Conver Progress to ASCI
                call GETCARINFO
                mov  ax,0
                mov  al,dh
                mov  cx, 10                         ; Set divisor to 10 for decimal conversion
                mov  bx, 10                         ; Set base to 10
                call convert
  ;set cursor
                MOV  AH,2
                mov  dl, 22h                        ; col.
                mov  dh, 18h                        ;ROW
                int  10h
  ;print string
                mov  bh,0
                mov  dx,offset ProgressBuffer
                mov  ah,9
                int  21h
  ;set cursor
                MOV  AH,2
                mov  dl, 24h                        ; col.
                mov  dh, 18h                        ;ROW
                int  10h
  ;PRINT SLASH
                mov  bh,0
                mov  dx,offset slash
                mov  ah,9
                int  21h
  ;SET CURSOR
                MOV  AH,2
                mov  dl, 25h                        ; col.
                mov  dh, 18h                        ;ROW
                int  10h
  ;Print Track Length
                mov  ax,0
                mov  al,byte ptr pathlength
                sub  al,4                           ;FOR SOME REASON THERE IS ALWAYS A DIFFERNCE OF 4 BETWEEN PROGRESS AND TRACK LENGTH SO LAF2THA
                mov  cx, 10                         ; Set divisor to 10 for decimal conversion
                mov  bx, 10                         ; Set base to 10
                call convert
                mov  bh,0
                mov  dx,offset ProgressBuffer
                mov  ah,9
                int  21h
                pop  BP
                ret
DisplayUI endp




convert proc                                        ;Convert Decimal Number to ASCI IN BUFFER TO BE PRINTED EASILY
                push ax
                push bx
                push cx
                push dx
                push si
                push di
                mov  di, offset ProgressBuffer + 8  ; Point to the end of the buffer
                mov  si, 0

  convert_loop: 
                mov  dx, 0
                div  cx                             ; Divide AX by CX, result in AX, remainder in DX
                add  dl, '0'                        ; Convert remainder to ASCII
                dec  di
                mov  [di], dl                       ; Store ASCII character in buffer

                test ax, ax
                jnz  convert_loop                   ; Continue until AX becomes zero

                mov  si, di                         ; Set SI to point to the beginning of the converted string
                lea  di, ProgressBuffer             ; Set DI to point to the buffer

  copy_loop:    
                mov  al, [si]
                mov  [di], al
                inc  di
                inc  si
                cmp  al, '$'
                jne  copy_loop                      ; Copy the converted string to the buffer
                pop  di
                pop  si
                pop  dx
                pop  cx
                pop  bx
                pop  ax
                ret
convert endp
delay_proc PROC
                mov  delay_seconds,delay_secConst
                mov  AH, 2Ch
                int  21h
                mov  al,dh
  labelloop:    
                mov  AH, 2Ch
                int  21h
                cmp  dh,al
                jz   labelloop
                dec  delay_seconds
                mov  al,dh
                cmp  delay_seconds,0
                jnz  labelloop
                ret
delay_proc ENDP
  ;-------------------------------------------------------
end main