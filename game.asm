  ; PATHGEN.asm
  EXTRN GENERATE_TRACK:FAR
  EXTRN Load_Track:FAR
  EXTRN pathlength:FAR
  ;GAMEMENU.ASM
  EXTRN GAME_MENU_INPUT:FAR
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
  EXTRN RESET_CARS:FAR
  EXTRN PLAYER_NUMBER:BYTE
  EXTRN PRESSED_F4:BYTE
  ;mainmenu.asm
  EXTRN MAINMENU:FAR
  EXTRN p1name:FAR
  EXTRN p2name:FAR
  EXTRN p1actual:FAR
  EXTRN p2actual:FAR
  ; CHAT.asm
  EXTRN CHATTING:FAR
  ;sound
  EXTRN PlaySound:FAR
  ;END_GAME.asm
  EXTRN END_GAME:FAR
  EXTRN CAR_WON:FAR
  EXTRN CAR_PROGRESS:FAR
  EXTRN CAR_POWER:FAR
  ; Sender.asm
  EXTRN CONFIG_PORT:FAR
  EXTRN SEND_INPUT:FAR
  EXTRN SERIAL_STATUS:BYTE
  EXTRN SEND:BYTE
  ;Receiver.asm
  EXTRN RECEIVE_INPUT:FAR
  EXTRN RECEIVED:BYTE
  PUBLIC TIME_AUX
  PUBLIC TIME_SEC
.model compact
.stack 64
.data
  GAME_MENU      EQU 0
  CHAT           EQU 1
  RACING         EQU 2
  TERMINATION    EQU 4
  CURR_PAGE      DB  0               ; Used when checking if time has changed.code
  TIME_AUX       DB  0               ; Used when checking if time has changed.code
  min            db  0
  sec            db  0
  TIME_SEC       DB  0               ; Used for updating time for games
  delay_seconds  db  0
  delay_secConst equ 3
  BoostUIMsg     db  "Power:"
  ProgressUIMsg  DB  "Progress:"
  ClearPerc      DB  "  ",'$'  ;DONT YOU DARE REMOVE SPACES
  BOOST0NAME     DB  "No Power",'$'  ;DONT YOU DARE REMOVE SPACES
  BOOST1NAME     DB  "Nitro   ",'$'  ;DONT YOU DARE REMOVE SPACES
  BOOST2NAME     DB  "Frost   ",'$'  ;DONT YOU DARE REMOVE SPACES
  BOOST3NAME     DB  "Blockade",'$'  ;DONT YOU DARE REMOVE SPACES
  BOOST4NAME     DB  "Bypass  ",'$'  ;DONT YOU DARE REMOVE SPACES
  ProgressBuffer db  10 dup('$')     ; this is to print decimal numbers
  perasci        db  "%",'$'
  xc1            equ 132                                                        ;crown cursor
  yc1            equ 165
  xc2            equ 185
  yc2            equ 165
  cimgw          equ 10
  cimgh          equ 7
  currentleading db  0
  leading        db  0
  CRWONIMG       DB  162, 21, 21, 161, 21, 21, 162, 21, 21
                 DB  162, 140, 140, 21, 140, 140, 21, 140, 162, 21, 140, 140
                 DB  43, 162, 43, 140, 140, 43, 140, 140, 140, 161, 43, 43, 43
                 DB  43, 43, 43, 43, 43, 140 ,21, 140, 43, 43, 43, 43, 43, 43
                 DB  43, 162, 21, 140, 43, 43, 43, 43, 43, 43, 43, 21, 21, 162
                 DB  140, 140, 140, 140, 140, 140, 140, 21
  origInt9Segment DW ?
  origInt9Offset DW ?
.code
  ;-------------------------------------------------------
main proc far
                mov  AX, @data
                mov  DS, AX

                mov  ES, AX
  ; Initialize Video Mode
                call CONFIG_PORT
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
                call OVERRIDE_INT                                 ;Generate Track
                mov  AX, @data
                mov  DS, AX
  GameMenulabel:
                mov CURR_PAGE, GAME_MENU
                CALL GameMenu                       ; AL has the game mode
                call RECEIVE_INPUT
                cmp AL, CHAT
                jnz CHECK_PLAY
                  call RESTORE_INT9
                  call CHATTING
                  call OVERRIDE_INT
                  jmp GameMenulabel
                CHECK_PLAY:
                mov min, 2
                mov sec, 1
                call GENERATE_TRACK                 ; Return Starting Direction in AL
                call LOAD_CARS
                mov  AH, 2Ch                        ;initialize currentsec
                int  21h
                mov  TIME_SEC,dh
                mov CURR_PAGE, RACING
                call RECEIVE_INPUT
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
  call setcurrentleading
  ; Draw
  call DRAW_ENTITIES
  ;call PRINT_TEST
  call DRAW_CARS
  
  ; Repeat the process
                mov AL, 1
                cmp PRESSED_F4, AL
                jz   SHOW_SCORE
                CALL GETCARINFO
                cmp  AL,1
                jz   terminate
                cmp  AL,2
                jz   terminate
                jmp  CHECK_TIME

  ; Terminate Program
  SHOW_SCORE:   call RESET_BACKGROUND
  terminate:    
                mov CURR_PAGE, TERMINATION
                call END_GAME
                call GETCARINFO
                cmp  al,1
                jz   withoutdelay
  checkplayer2: cmp  al,2
                jz   withoutdelay
  withdelay:    
                call delay_proc
                call RESET_CARS
                jmp  GameMenulabel
  withoutdelay: call PlaySound
                call RESET_CARS
                jmp  GameMenulabel
main endp
  ;-------------------------------------------------------
KEYBOARD_INTERRUPT proc far
  push AX
  push BX
  push CX
  push DX
  push SI
  push DI
  push DS
  push ES
  mov AL, CURR_PAGE
  cmp AL, GAME_MENU
  jnz SKIP_GAMEMENU_INPUT
  call GAME_MENU_INPUT
  jmp EXIT_KEYBOARD_INTERRUPT
  SKIP_GAMEMENU_INPUT:

  cmp AL, RACING
  jnz SKIP_RACE_INPUT
  call CHECK_INPUT_UPDATES
  jmp EXIT_KEYBOARD_INTERRUPT
  SKIP_RACE_INPUT:

  cmp AL, TERMINATION
  jnz SKIP_TERMINATION_INPUT
  ;; terminate
  in al, 60h
  jmp EXIT_KEYBOARD_INTERRUPT
  SKIP_TERMINATION_INPUT:
  EXIT_KEYBOARD_INTERRUPT:
  mov al,20h
  out 20h,al
  pop ES
  pop DS
  pop DI
  pop SI
  pop DX
  pop CX
  pop BX
  pop AX
  iret
KEYBOARD_INTERRUPT endp
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
                      mov  dl, 0h                         ; col.
                      mov  dh, 15h                        ; row.
                      mov  ah, 13h                        ; function.
                      mov  al, 0h                         ; sub-function.
                      int  10h
  ;p2 name
                      mov  bh, 0                          ; page.
                      lea  bp, p2name                     ; offset.
                      mov  bl,0bh                         ; default attribute.
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
                      mov  dh, 17h                        ; row.
                      mov  ah, 13h                        ; function.
                      mov  al, 0h                         ; sub-function.
                      int  10h
                      mov  dl, 06h                        ; col.
                      mov  dh, 17h                        ; row.
                      MOV  AH,2
                      INT  10H
                      CALL GETCARINFO
  NOBOOST:            CMP  CL,0
                      jnz  Nitro
                      mov  dx,offset BOOST0NAME
                      jmp  printboost
  Nitro:              CMP  CL,1
                      jnz  Frost
                      mov  dx,offset BOOST1NAME
                      jmp  printboost
  Frost:              CMP  CL,2
                      jnz  Block
                      mov  dx,offset BOOST2NAME
                      jmp  printboost
  Block:              CMP  CL,3
                      jnz  Bypass
                      mov  dx,offset BOOST3NAME
                      jmp  printboost
  Bypass:                                                 ; CMP  CL,4
  ;              ; jnz  printboost
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
                      mov  dl, 1ah                        ; col.
                      mov  dh, 17h                        ; row.
                      mov  ah, 13h                        ; function.
                      mov  al, 0h                         ; sub-function.
                      int  10h
                      mov  dl, 20h                        ; col.
                      mov  dh, 17h                        ; row.
                      MOV  AH,2
                      INT  10H
                      CALL GETCARINFO
  NOBOOST2:           CMP  CH,0
                      jnz  Nitro2
                      mov  dx,offset BOOST0NAME
                      jmp  printboost2
  Nitro2:             CMP  CH,1
                      jnz  Frost2
                      mov  dx,offset BOOST1NAME
                      jmp  printboost2
  Frost2:             CMP  CH,2
                      jnz  Block2
                      mov  dx,offset BOOST2NAME
                      jmp  printboost2
  Block2:             CMP  CH,3
                      jnz  Bypass2
                      mov  dx,offset BOOST3NAME
                      jmp  printboost2
  Bypass2:            CMP  CH,4
                      jnz  printboost2
                      mov  dx,offset BOOST4NAME
  printboost2:        
                      MOV  AH,9
                      INT  21H
  ;p1progress
                      mov  bh, 0                          ; page.
                      lea  bp,ProgressUIMsg               ; offset.
                      mov  bl,012D                        ; default attribute.
                      mov  cx,0
                      mov  cl, 09h                        ; char number.
                      mov  dl, 0h                         ; col.
                      mov  dh, 18h                        ; row.
                      mov  ah, 13h                        ; function.
                      mov  al, 0h                         ; sub-function.
                      int  10h
  ;Conver Progress to ASCI
                      call GETCARINFO
                      mov  ah,0
                      mov  al,dl
                      mov  bh,0
                      mov  bl,pathlength
                      sub  bl,3
                      call calculatePercentage
                      mov  bx,10
                      mov  cx,10
                      call convert
  ;set cursor
                      mov  bh,0
                      MOV  AH,2
                      mov  dl, 0ah                        ; col.
                      mov  dh, 18h                        ;ROW
                      int  10h
  ;print string
                      mov  bh,0
                      mov  dx,offset ClearPerc
                      mov  ah,9
                      int  21h
  ;set cursor
                      mov  bh,0
                      MOV  AH,2
                      mov  dl, 0ah                        ; col.
                      mov  dh, 18h                        ;ROW
                      int  10h
  ;print string
                      mov  bh,0
                      mov  dx,offset ProgressBuffer
                      mov  ah,9
                      int  21h
  ;set cursor
                      MOV  AH,2
                      mov  dl, 0ch                        ; col.
                      mov  dh, 18h                        ;ROW
                      int  10h
  ;PRINT %
                      mov  bh,0
                      mov  dx,offset perasci
                      mov  ah,9
                      int  21h
  ;p2progress
                      mov  bh, 0                          ; page.
                      lea  bp,ProgressUIMsg               ; offset.
                      mov  bl,0bh                         ; default attribute.
                      mov  cx,0
                      mov  cl, 09h                        ; char number.
                      mov  dl, 1ah                        ; col.
                      mov  dh, 18h                        ; row.
                      mov  ah, 13h                        ; function.
                      mov  al, 0h                         ; sub-function.
                      int  10h
  ;Conver Progress to ASCI
                      call GETCARINFO
                      mov  ah,0
                      mov  al,dh
                      mov  bh,0
                      mov  bl,pathlength
                      sub  bl,3
                      call calculatePercentage
                      mov  bx,10
                      mov  cx,10
                      call convert
  ;set cursor
                      MOV  AH,2
                      mov  dl, 24h                        ; col.
                      mov  dh, 18h                        ;ROW
                      int  10h
  ;print string
                      mov  bh,0
                      mov  dx,offset ClearPerc
                      mov  ah,9
                      int  21h
  ;set cursor
                      MOV  AH,2
                      mov  dl, 24h                        ; col.
                      mov  dh, 18h                        ;ROW
                      int  10h
  ;print string
                      mov  bh,0
                      mov  dx,offset ProgressBuffer
                      mov  ah,9
                      int  21h
  ;set cursor
                      MOV  AH,2
                      mov  dl, 26h                        ; col.
                      mov  dh, 18h                        ;ROW
                      int  10h
  ;PRINT %
                      mov  bh,0
                      mov  dx,offset perasci
                      mov  ah,9
                      int  21h
                      pop  BP
                      ret
DisplayUI endp
;-------------------------------------------------------
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
  ;-------------------------------------------------------
delay_proc PROC near
  push AX
  push BX
  push CX
  push DX
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
  pop DX
  pop CX
  pop BX
  pop AX
                ret
delay_proc ENDP
  ;-------------------------------------------------------
calculatePercentage proc
  ; Input: ax = num1, bx = num2
  ; Output: result = (num1 * 100) / num2
                      mov  dx,0
                      mov  cx, 100                        ; Percentage factor
                      imul cx                             ; Multiply num1 by 100
                      idiv bx                             ; Divide by num2
                      ret
calculatePercentage endp
  ;-------------------------------------------------------
clean proc
                      mov  al,0h
                      mov  ah,0ch
                      mov  bx,cx
                      mov  di,dx
                      add  di,cimgh
                      add  bx,cimgw
  rowcle:             
                      int  10h
                      inc  cx
                      cmp  cx,bx
                      jz   columncle
                      jmp  rowcle
  columncle:          
                      sub  cx,cimgw
                      inc  dx
                      cmp  dx,di
                      jz   exitcle
                      jmp  rowcle
  exitcle:            
                      ret
clean endp
  ;-------------------------------------------------------
drawcrown proc
                      mov  bx,CX
                      MOV  di,DX
                      ADD  BX,cimgw
                      ADD  DI,cimgh
                      mov  ah,0ch
                      mov  si,offset CRWONIMG
  rowC:               mov  AL,[SI]
                      int  10h
                      inc  si
                      inc  cx
                      cmp  cx,bx
                      jz   columnC
                      jmp  rowC
  columnC:            
                      sub  cx,cimgw
                      inc  dx
                      cmp  dx,di
                      jz   exitC
                      jmp  rowC
  exitC:              
                      ret
drawcrown endp
  ;-------------------------------------------------------
setcurrentleading proc
                      mov CX, xc2
                      mov DX, yc2
                      call clean
                      mov CX, xc1
                      mov DX, yc1
                      call clean
                      call GETCARINFO
                      cmp  dl,dh
                      ja   p1crown
                      jz   exitcrown
                      mov CX, xc2
                      mov DX, yc2
                      call drawcrown
                      jmp  exitcrown
  p1crown:            
                      mov CX, xc1
                      mov DX, yc1
                      call drawcrown

  exitcrown:          ret
setcurrentleading endp
  ;-------------------------------------------------------
OVERRIDE_INT PROC
  cli
  mov ax, 3509h
  int 21h
  mov origInt9Offset, bx
  mov origInt9Segment, es
  push ds
  mov ax, cs
  mov ds, ax
  mov ax, 2509h
  lea dx, KEYBOARD_INTERRUPT
  int 21h
  pop ds
  sti
  mov ax, 0A000h
  mov es,ax
  ret
OVERRIDE_INT ENDP
  ;-------------------------------------------------------
RESTORE_INT9 proc
  cli
  mov ax, origInt9Segment
  mov dx, origInt9Offset
  push ds
  mov ds, ax
  mov ax, 2509h
  int 21h
  pop ds
  sti
  ret
RESTORE_INT9 endp
  ;-------------------------------------------------------
  RESET_BACKGROUND proc near
    ; (Send to TRACK file)
    ; Set background color to WHITE
                      mov  AH, 06h                      ; Scroll up function
                      xor  AL, AL                       ; Clear entire screen
                      xor  CX, CX                       ; Upper left corner CH=row, CL=column
                      mov  DX, 184Fh                    ; lower right corner DH=row, DL=column
                      mov  BH, 012h                       ; Green-BackGround
                      int  10h
                      ret
RESET_BACKGROUND endp
;-------------------------------------------------------
end main