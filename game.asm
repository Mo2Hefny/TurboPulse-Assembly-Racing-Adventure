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
  PUBLIC TIME_AUX
.model small
.stack 64
.data
  TIME_AUX  DB 0                        ; Used when checking if time has changed.code
.code
main proc far

  mov AX, @data
  mov DS, AX

  mov AX, 0A000h
  mov ES, AX

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
  ; Generate Track
  call GENERATE_TRACK                   ; Return Starting Direction in AL
  call LOAD_CARS
  ;;;;;;; TESTING COLLISION ;;;;;;
  mov AX, 0
  mov CX, 0Ah
  mov DX, 3Ah
  call ADD_OBSTACLE
  mov AX, 0
  mov CX, 2Fh
  mov DX, 3Ah
  call ADD_OBSTACLE

  ; Get the systen time
  CHECK_TIME:
    mov AH, 2Ch
    int 21h                             ; CH = hour CL = minute DH - second DL = 1/100 seconds
    cmp DL, TIME_AUX                    ; fps = 100
    je  CHECK_TIME                      ; repeat till time frame changes
    mov TIME_AUX, DL
  ; Else draw the new frame
  ;call Load_Track
  ; Draw Obstacles
  call DRAW_OBSTACLES
  ; Draw Cars
  call MOVE_CARS
  mov AX, 0A000h
  mov ES, AX
  call DRAW_CARS
  
  ; Repeat the process
  jmp CHECK_TIME

  ; Terminate Program
  mov ah, 4Ch
  int 21h

main endp
;-------------------------------------------------------
RESET_BACKGROUND proc near
  ; (Send to TRACK file)
  ; Set background color to WHITE
  mov AH, 06h                           ; Scroll up function
  xor AL, AL                            ; Clear entire screen
  xor CX, CX                            ; Upper left corner CH=row, CL=column
  mov DX, 184Fh                         ; lower right corner DH=row, DL=column 
  mov BH, 1Eh                           ; YellowOnBlue
  int 10h
  ret
RESET_BACKGROUND endp
;-------------------------------------------------------
end main