.model small
JUMPS           
.stack 100h

.data
    ; messages
    msg_size     db 'Enter array size (1-20): $'
    msg_elem     db 'Enter element: $'
    msg_sum      db 13, 10, 'Sum of elements: $'
    msg_max      db 13, 10, 'Maximum element: $'
    msg_sort     db 13, 10, 'Sorted array: $'
    msg_space    db ' $'

    msg_err      db 13, 10, 'Error: Invalid input!$'
    msg_ovf      db 13, 10, 'Error: Overflow! Limit to 16-bit.$'
    msg_size_err db 13, 10, 'Error: Size must be between 1 and 20.$'

    ; variables & array
    buffer       db 7, 0, 7 dup(0)
    arr          dw 20 dup(0)                                           ; reserved for 20 words (40 bytes)
    arr_size     dw 0
    is_neg       db 0

.code
main proc
                    mov  ax, @data
                    mov  ds, ax

                    ; input size
                    lea  dx, msg_size
                    mov  ah, 09h
                    int  21h

                    call InputProc
                    jc   exit_prog

                    ; check size [1; 20]
                    cmp  ax, 1
                    jl   bad_size
                    cmp  ax, 20
                    jg   bad_size
                    mov  arr_size, ax

                    ; crlf new line
                    mov  ah, 02h
                    mov  dl, 13              ; \r
                    int  21h
                    mov  dl, 10              ; \n
                    int  21h

                    ; input elements
                    mov  cx, arr_size
                    lea  di, arr
    input_loop:
                    push cx                  ; save counter

                    lea  dx, msg_elem
                    mov  ah, 09h
                    int  21h

                    call InputProc
                    pop  cx
                    jc   exit_prog           ; invalid input

                    mov  [di], ax            ; in c => *di = ax
                    add  di, 2               ; move 1 word ahead

                    ; new line
                    mov  ah, 02h
                    mov  dl, 13
                    int  21h
                    mov  dl, 10
                    int  21h

                    loop input_loop

                    ; find sum
                    lea  dx, msg_sum
                    mov  ah, 09h
                    int  21h

                    mov  cx, arr_size
                    lea  si, arr
                    xor  bx, bx              ; bx - sum
    sum_loop:
                    mov  ax, [si]
                    add  bx, ax
                    jo   overflow_err        ; if sum overflows
                    add  si, 2
                    loop sum_loop

                    mov  ax, bx              ; ax - 1st argument
                    call OutputProc

                    ; find max
                    lea  dx, msg_max
                    mov  ah, 09h
                    int  21h

                    mov  cx, arr_size
                    lea  si, arr
                    mov  ax, [si]            ; first max - first element
    max_loop:
                    cmp  ax, [si]
                    jge  skip_max            ;  max >= el - skip
                    mov  ax, [si]            ; otherwise update max
    skip_max:
                    add  si, 2
                    loop max_loop

                    call OutputProc

                    ; bubble sort
                    mov  cx, arr_size
                    dec  cx                  ; num of iters: size - 1
                    cmp  cx, 0
                    je   print_sorted        ; only 1 el - skip sort

    outer_sort:
                    push cx
                    mov  cx, arr_size
                    dec  cx
                    lea  si, arr
    inner_sort:
                    mov  ax, [si]
                    mov  bx, [si+2]
                    cmp  ax, bx
                    jle  no_swap             ; first <= second - skip

                    ; swap
                    mov  [si], bx
                    mov  [si+2], ax
    no_swap:
                    add  si, 2
                    loop inner_sort

                    pop  cx
                    loop outer_sort

    ; finally print ts
    print_sorted:
                    lea  dx, msg_sort
                    mov  ah, 09h
                    int  21h

                    mov  cx, arr_size
                    lea  si, arr
    print_arr_loop:
                    mov  ax, [si]
                    push cx
                    push si
                    call OutputProc

                    ; print space between numbers
                    lea  dx, msg_space
                    mov  ah, 09h
                    int  21h

                    pop  si
                    pop  cx
                    add  si, 2
                    loop print_arr_loop

                    jmp  exit_prog


    bad_size:
                    lea  dx, msg_size_err
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



    ; copied from lab2
    ; returns in ax

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
                    jo   ovf_err_proc

                    add  ax, cx
                    jo   ovf_err_proc

                    mov  bx, ax
                    pop  cx

                    inc  si
                    dec  cx
                    jmp  parse_loop

    parse_done:
                    cmp  is_neg, 1
                    jne  save_number
                    neg  bx
                    jo   ovf_err_proc

    save_number:
                    mov  ax, bx
                    clc
                    ret

    ovf_err_proc:
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
