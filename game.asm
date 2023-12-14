  ; PATHGEN.asm
  EXTRN GENERATE_TRACK:FAR
  EXTRN Load_Track:FAR
  ; OBSTACLES.asm
  EXTRN ADD_OBSTACLE:FAR
  EXTRN DRAW_ENTITIES:FAR
  EXTRN UPDATE_ENTITIES:FAR
  ; CARS.asm
  EXTRN CHECK_INPUT_UPDATES:FAR
  EXTRN DRAW_CARS:FAR
  EXTRN PRINT_TEST:FAR
  EXTRN MOVE_CARS:FAR
  EXTRN LOAD_CARS:FAR
  PUBLIC TIME_AUX
  PUBLIC TIME_SEC
.model small
.stack 64
.data 
  TIME_AUX  DB 0                        ; Used when checking if time has changed.code
  TIME_SEC  DB 0                        ; Used for updating time for games
.code
main proc far
  cli
  push ds
  mov ax,cs
  mov ds,ax
  mov ax,2509h
  lea dx, CHECK_INPUT_UPDATES
  int 21h
  pop ds
  sti
  mov AX, @data
  mov DS, AX
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
  ;mov AX, 1
  ;mov CX, 25
  ;mov DX, 85
  ;call ADD_OBSTACLE
  ;mov AX, 2
  ;mov CX, 5
  ;mov DX, 105
  ;call ADD_OBSTACLE
  ;mov AX, 4
  ;mov CX, 5
  ;mov DX, 65
  ;call ADD_OBSTACLE

  ; Get the systen time
  CHECK_TIME:
    
    mov AH, 2Ch
    int 21h                             ; CH = hour CL = minute DH - second DL = 1/100 seconds
    cmp DL, TIME_AUX                    ; fps = 100
    je  CHECK_TIME                      ; repeat till time frame changes
    mov TIME_AUX, DL
    mov TIME_SEC, DH
  ; Logic
  ;call PRINT_TEST
  call UPDATE_ENTITIES
  call MOVE_CARS
  
  ; Draw
  call DRAW_ENTITIES
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