.model small
.stack 100h

.data
    msg_input db 'Enter an integer: $'
    ; crlf
    msg_res   db 13, 10, 'Result (-34): $'
    msg_err   db 13, 10, 'Error: Invalid input! (Numbers only)$'
    msg_ovf   db 13, 10, 'Error: Overflow/Underflow! Keep it 16-bit.$'

    ; Buf for 10th DOS function: max len, real len, char array
    buffer    db 7, 0, 7 dup(0)
    num       dw 0
    is_neg    db 0

.code
main proc
                  mov  ax, @data
                  mov  ds, ax

                  lea  dx, msg_input
                  mov  ah, 09h
                  int  21h

                  call InputProc
                  jc   exit_prog        ; Carry Flag = 1 => error

                  ; Var. 19: -34
                  mov  ax, num
                  sub  ax, 34
                  jo   overflow_err

                  push ax               ; save ax
                  lea  dx, msg_res
                  mov  ah, 09h
                  int  21h
                  pop  ax               ; restore ax

                  call OutputProc
                  jmp  exit_prog

    overflow_err:
                  lea  dx, msg_ovf
                  mov  ah, 09h
                  int  21h
                  jmp  exit_prog

    exit_prog:
                  mov  ax, 4c00h
                  int  21h
main endp



InputProc proc
                  lea  dx, buffer
                  mov  ah, 0Ah
                  int  21h

                  lea  si, buffer+2     ; ptr of symbols
                  mov  cl, buffer+1     ; num of symbols
                  xor  ch, ch
                  cmp  cx, 0
                  je   input_error      ; zero characters

                  xor  bx, bx           ; num accumulator
                  mov  is_neg, 0

                  ; check for sign
                  mov  al, [si]
                  cmp  al, '-'
                  jne  check_plus
                  mov  is_neg, 1
                  inc  si
                  dec  cx
                  jmp  parse_loop

    check_plus:
                  cmp  al, '+'
                  jne  parse_loop
                  inc  si
                  dec  cx

    parse_loop:
                  cmp  cx, 0
                  je   parse_done

                  mov  al, [si]
                  ; check if it is a number (0-9)
                  cmp  al, '0'
                  jl   input_error
                  cmp  al, '9'
                  jg   input_error

                  sub  al, '0'          ; char -> num
                  xor  ah, ah
                  push cx               ; save counter

                  mov  cx, ax           ; cx = current num
                  mov  ax, bx
                  mov  dx, 10
                  imul dx               ; ax = ax * 10
                  jo   ovf_error

                  add  ax, cx           ; ax = ax + current num
                  jo   ovf_error

                  mov  bx, ax
                  pop  cx               ; restore counter

                  inc  si
                  dec  cx
                  jmp  parse_loop

    parse_done:
                  cmp  is_neg, 1
                  jne  save_number
                  neg  bx               ; swap left bit -> num is positive
                  jo   ovf_error

    save_number:
                  mov  num, bx
                  clc                   ; Carry Flag = 0
                  ret

    ovf_error:
                  pop  cx               ; clear stack when exiting loop
                  lea  dx, msg_ovf
                  mov  ah, 09h
                  int  21h
                  stc                   ; Carry Flag = 1
                  ret

    input_error:
                  lea  dx, msg_err
                  mov  ah, 09h
                  int  21h
                  stc
                  ret
InputProc endp



OutputProc proc
                  cmp  ax, 0
                  jge  start_convert    ; skip - if ax >= 0

                  ; print -
                  push ax
                  mov  ah, 02h
                  mov  dl, '-'
                  int  21h
                  pop  ax
                  neg  ax               ; swap left bit

    start_convert:
                  xor  cx, cx           ; reset cx
                  mov  bx, 10
    divide_loop:
                  xor  dx, dx
                  div  bx               ; ax = ax / 10, dx = rem
                  push dx               ; push to stack
                  inc  cx
                  test ax, ax
                  jnz  divide_loop

    print_loop:
                  pop  dx
                  add  dl, '0'          ; convert num to char
                  mov  ah, 02h
                  int  21h
                  loop print_loop

                  ret
OutputProc endp

end main
