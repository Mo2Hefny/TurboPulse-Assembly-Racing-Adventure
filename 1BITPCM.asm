EXTRN TRACK:FAR
PUBLIC PlaySound
.MODEL small
.STACK 64
.DATA
sound_size DW 38000  ; size in bytes
filename DB 'digdug.wav', 0
buffer_size EQU 45000
.CODE
PlaySound PROC
    MOV AX, @DATA
    MOV DS, AX
    MOV ES, AX
    
    MOV AH, 3Dh        ; DOS function to open file
    MOV AL, 0          ; Read-only mode
    MOV DX, OFFSET filename ; ASCIIZ filename to open
    INT 21h            ; Call DOS interrupt

    JC ERROR           ; If file not found, jump to error handler
    MOV BX, AX         ; Store file handle

    MOV AH, 3Fh        ; DOS function to read file
    MOV CX, buffer_size ; number of bytes to read
    MOV DX, OFFSET TRACK ; where to put read data
    INT 21h            ; Call DOS interrupt

start:
    ; setup es to get the system
    ; timer count correctly
    MOV AX, 0
    MOV ES, AX

    ; change timer 0 to 4KHz
    CALL start_fast_clock

    MOV SI, 0 ; sound index

next_sample:
    MOV DL, [TRACK + SI]

    MOV CL, 7
    SHR DL, CL ; convert to 1-bit sound

    CMP DL, 1
    JAE on
    JMP off

on:
    CALL speaker_on
    JMP short continue

off:
    CALL speaker_off

continue:
    ; wait 0.25ms
    CALL delay

    INC SI
    CMP SI, sound_size
    JAE exit

    JMP next_sample


exit:
    CALL speaker_off

    ; return to DOS
    ret

ERROR:
    ; Handle file not found or other errors
    JMP EXIT

speaker_on:
    IN AL, 61h
    OR AL, 2
    OUT 61h, AL
    RET

speaker_off:
    IN AL, 61h
    AND AL, 0FCh
    OUT 61h, AL
    RET

delay:
    MOV DI, ES:[046Ch]  ; Accessing memory location ES:046Ch
_wait:
    CMP DI, ES:[046Ch]  ; Comparing with the value at ES:046Ch
    JZ _wait
    RET
PlaySound endp
change_timer_0 PROC
    CLI
    MOV AL, 00110110b
    OUT 43h, AL
    MOV AL, BL
    OUT 40h, AL
    STI
    RET
change_timer_0 ENDP

start_fast_clock PROC
    CLI
    MOV AL, 00110110b
    OUT 43h, AL
    MOV AL, 00101010b
    OUT 40h, AL
    MOV AL, 00000001b
    OUT 40h, AL
    STI
    RET
start_fast_clock ENDP
end