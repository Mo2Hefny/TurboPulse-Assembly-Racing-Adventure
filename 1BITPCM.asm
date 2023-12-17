EXTRN TRACK:FAR
PUBLIC PlaySound
.MODEL small
.STACK 64
.DATA
sound_size DW 38000  ; size in bytes
filename DB 'digdug.wav', 0
buffer_size EQU 45000
.CODE
PlaySound PROC far
    push AX
    push BX
    push CX
    push DX
    push SI
    push DI
    push DS
    push ES
    MOV AX, @DATA
    MOV DS, AX
    MOV ES, AX
    
    MOV AH, 3Dh        ; DOS function to open file
    MOV AL, 0          ; Read-only mode
    MOV DX, OFFSET filename ; ASCIIZ filename to open
    INT 21h            ; Call DOS interrupt

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
    call stop_fast_clock

    ; return to DOS
EXIT_PLAY_SOUND:
    pop ES
    pop DS
    pop DI
    pop SI
    pop DX
    pop CX
    pop BX
    pop AX
    RET
PlaySound endp
;---------------------------------------
speaker_on proc near
    IN AL, 61h
    OR AL, 2
    OUT 61h, AL
    RET
speaker_on endp
;---------------------------------------
speaker_off proc near
    IN AL, 61h
    AND AL, 0FCh
    OUT 61h, AL
    RET
speaker_off endp
;---------------------------------------
delay proc near
    push ES
    MOV DI, ES:[046Ch]  ; Accessing memory location ES:046Ch
    pop ES
_wait:
    push ES
    CMP DI, ES:[046Ch]  ; Comparing with the value at ES:046Ch
    pop ES
    JZ _wait
    ret
delay endp
;---------------------------------------
change_timer_0 PROC near
    CLI
    MOV AL, 00110110b
    OUT 43h, AL
    MOV AL, BL
    OUT 40h, AL
    STI
    RET
change_timer_0 ENDP
;---------------------------------------
start_fast_clock PROC near
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
;---------------------------------------
stop_fast_clock PROC near
	cli
	mov al, 36h
	out 43h, al
	mov al, 0h ; low 
	out 40h, al
	mov al, 0h ; high
	out 40h, al
	sti
	ret
stop_fast_clock ENDP
end