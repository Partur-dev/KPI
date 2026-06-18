.model small
JUMPS
.stack 100h

.data
    ; Input messages
    msg_a       db 'Enter a: $'
    msg_b       db 13, 10, 'Enter b: $'
    msg_x       db 13, 10, 'Enter x: $'

    ; Output messages
    msg_res     db 13, 10, 'Result Z = $'
    msg_rem     db ' (rem: $'
    msg_rem_end db ')$'

    ; Error messages
    msg_err     db 13, 10, 'Error: Invalid input! (Numbers only)$'
    msg_ovf     db 13, 10, 'Error: Overflow/Underflow! Limit to 16-bit.$'

    ; Variables
    buffer      db 7, 0, 7 dup(0)
    val_a       dw 0
    val_b       dw 0
    val_x       dw 0
    is_neg      db 0
    res_rem     dw 0

.code
main proc
                  mov  ax, @data
                  mov  ds, ax

                  ; Input a
                  lea  dx, msg_a
                  mov  ah, 09h
                  int  21h
                  call InputProc
                  jc   exit_prog          ; Exit on error
                  mov  val_a, ax

                  ; Input b
                  lea  dx, msg_b
                  mov  ah, 09h
                  int  21h
                  call InputProc
                  jc   exit_prog          ; Exit on error
                  mov  val_b, ax

                  ; Input x
                  lea  dx, msg_x
                  mov  ah, 09h
                  int  21h
                  call InputProc
                  jc   exit_prog          ; Exit on error
                  mov  val_x, ax

                  mov  ax, val_x
                  cmp  ax, 0
                  jg   calc_greater       ; x > 0
                  je   calc_equal         ; x == 0
                  jl   calc_less          ; x < 0

    ; x > 0 => ax^2 + b/x
    calc_greater:
                  ; Calculate ax^2
                  mov  ax, val_x
                  imul ax                 ; ax = x^2 (dx:ax)
                  jo   overflow_err
                  imul val_a              ; ax = a * x^2
                  jo   overflow_err
                  mov  bx, ax             ; bx = ax^2

                  ; Calculate b/x
                  mov  ax, val_b
                  cwd                     ; Extend ax to dx:ax for idiv
                  idiv val_x              ; ax, dx = rem

                  ; Calculate (ax^2) + (b/x)
                  add  ax, bx
                  jo   overflow_err

                  ; Save remaining
                  mov  res_rem, dx
                  jmp  print_res

    ; x = 0 => a + 2b
    calc_equal:
                  mov  ax, val_b
                  mov  cx, 2
                  imul cx                 ; ax = 2b
                  jo   overflow_err

                  add  ax, val_a          ; ax = a + 2b
                  jo   overflow_err

                  jmp  print_res

    ; x < 0 => ax^2 - bx
    calc_less:
                  ; Calculate ax^2
                  mov  ax, val_x
                  imul ax
                  jo   overflow_err
                  imul val_a
                  jo   overflow_err
                  mov  bx, ax             ; bx = ax^2

                  ; Calculate bx
                  mov  ax, val_b
                  imul val_x
                  jo   overflow_err       ; ax = bx

                  ; Calculate ax^2 - bx
                  sub  bx, ax
                  jo   overflow_err

                  mov  ax, bx
                  jmp  print_res


    print_res:
                  push ax                 ; Save result Z
                  lea  dx, msg_res
                  mov  ah, 09h
                  int  21h
                  pop  ax

                  ; HOTFIX
                  push ax
                  push bx

                  mov  bx, res_rem
                  cmp  bx, 0

                  jge  just_print
                  neg  bx
                  mov  ax, val_x
                  sub  ax, bx
                  mov  res_rem, ax

                  pop  bx
                  pop  ax

                  dec  ax

    just_print:

                  call OutputProc         ; Print first part

                  cmp  res_rem, 0         ; Skip if 0
                  je   exit_prog

                  ; Print rem
                  lea  dx, msg_rem
                  mov  ah, 09h
                  int  21h

                  mov  ax, res_rem
                  call OutputProc

                  lea  dx, msg_rem_end
                  mov  ah, 09h
                  int  21h
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



    ; Copied from lab2
    ; Returns in AX

InputProc proc
                  lea  dx, buffer
                  mov  ah, 0Ah
                  int  21h

                  lea  si, buffer+2
                  mov  cl, buffer+1
                  xor  ch, ch
                  cmp  cx, 0
                  je   input_error

                  xor  bx, bx
                  mov  is_neg, 0

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
                  cmp  al, '0'
                  jl   input_error
                  cmp  al, '9'
                  jg   input_error

                  sub  al, '0'
                  xor  ah, ah
                  push cx

                  mov  cx, ax
                  mov  ax, bx
                  mov  dx, 10
                  imul dx
                  jo   ovf_error

                  add  ax, cx
                  jo   ovf_error

                  mov  bx, ax
                  pop  cx

                  inc  si
                  dec  cx
                  jmp  parse_loop

    parse_done:
                  cmp  is_neg, 1
                  jne  save_number
                  neg  bx
                  jo   ovf_error

    save_number:
                  mov  ax, bx             ; Return in AX
                  clc
                  ret

    ovf_error:
                  pop  cx
                  lea  dx, msg_ovf
                  mov  ah, 09h
                  int  21h
                  stc
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
                  jge  start_convert

                  push ax
                  mov  ah, 02h
                  mov  dl, '-'
                  int  21h
                  pop  ax
                  neg  ax

    start_convert:
                  xor  cx, cx
                  mov  bx, 10
    divide_loop:
                  xor  dx, dx
                  div  bx
                  push dx
                  inc  cx
                  test ax, ax
                  jnz  divide_loop

    print_loop:
                  pop  dx
                  add  dl, '0'
                  mov  ah, 02h
                  int  21h
                  loop print_loop

                  ret
OutputProc endp

end main
