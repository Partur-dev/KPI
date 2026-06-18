.model small
JUMPS           
.stack 100h

print_str macro str
              lea dx, str
              mov ah, 09h
              int 21h
endm

print_nl macro
             mov ah, 02h
             mov dl, 13     ; \r
             int 21h
             mov dl, 10     ; \n
             int 21h
endm

check_bounds macro reg, l, h, err
                 cmp reg, l
                 jl  err
                 cmp reg, h
                 jg  err
endm

input_str macro buffer
              lea dx, buffer
              mov ah, 0Ah
              int 21h
endm

arr_sum macro arr, sum, overflow_err
              local sum_loop

    sum_loop:
              mov   ax, [arr]
              add   sum, ax
              jo    overflow_err    ; if sum overflows
              add   arr, 2
              loop  sum_loop
endm

arr_max macro arr, reg
              local max_loop
              local skip_max

              mov   reg, [arr]    ; first max - first element
    max_loop:
              cmp   reg, [arr]
              jge   skip_max      ;  max >= el - skip
              mov   reg, [arr]    ; otherwise update max
    skip_max:
              add   arr, 2
              loop  max_loop
endm

arr_sort macro arr, arr_size
                local outer_sort
                local inner_sort
                local no_swap

    outer_sort:
                push  cx
                mov   cx, arr_size
                dec   cx
                lea   si, arr
    inner_sort:
                mov   ax, [si]
                mov   bx, [si+2]
                cmp   ax, bx
                jle   no_swap         ; first <= second - skip

                ; swap
                mov   [si], bx
                mov   [si+2], ax
    no_swap:
                add   si, 2
                loop  inner_sort

                pop   cx
                loop  outer_sort
endm

print_arr macro arr
                    local     print_arr_loop

    print_arr_loop:
                    mov       ax, [arr]
                    push      cx
                    push      arr
                    call      OutputProc

                    ; print space between numbers
                    print_str msg_space

                    pop       arr
                    pop       cx
                    add       arr, 2
                    loop      print_arr_loop
endm

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
                  mov          ax, @data
                  mov          ds, ax

                  ; input size
                  print_str    msg_size

                  call         InputProc
                  jc           exit_prog

                  check_bounds ax, 1, 20, bad_size
                  mov          arr_size, ax

                  print_nl

                  ; input elements
                  mov          cx, arr_size
                  lea          di, arr
    input_loop:
                  push         cx                      ; save counter

                  print_str    msg_elem

                  call         InputProc
                  pop          cx
                  jc           exit_prog               ; invalid input

                  mov          [di], ax                ; in c => *di = ax
                  add          di, 2                   ; move 1 word ahead

                  print_nl
                  loop         input_loop

                  ; find sum
                  print_str    msg_sum
                  mov          cx, arr_size
                  lea          si, arr
                  xor          bx, bx                  ; bx - sum

                  arr_sum      si, bx, overflow_err
                  mov          ax, bx                  ; ax - 1st argument
                  call         OutputProc

                  ; find max
                  print_str    msg_max

                  mov          cx, arr_size
                  lea          si, arr

                  arr_max      si, ax
                  arr_max      si, ax
                  call         OutputProc

                  ; bubble sort
                  mov          cx, arr_size
                  dec          cx                      ; num of iters: size - 1
                  cmp          cx, 0
                  je           print_sorted            ; only 1 el - skip sort
                  arr_sort     arr, arr_size


    ; finally print ts
    print_sorted:
                  print_str    msg_sort

                  mov          cx, arr_size
                  lea          si, arr
                  print_arr    si

                  jmp          exit_prog

    bad_size:
                  print_str    msg_size_err
                  jmp          exit_prog

    overflow_err:
                  print_str    msg_ovf
                  jmp          exit_prog

    exit_prog:
                  mov          ax, 4c00h
                  int          21h
main endp



    ; copied from lab2
    ; returns in ax

InputProc proc
                  input_str    buffer

                  lea          si, buffer+2
                  mov          cl, buffer+1
                  xor          ch, ch
                  cmp          cx, 0
                  je           input_error

                  xor          bx, bx
                  mov          is_neg, 0

                  mov          al, [si]
                  cmp          al, '-'
                  jne          check_plus
                  mov          is_neg, 1
                  inc          si
                  dec          cx
                  jmp          parse_loop
    check_plus:
                  cmp          al, '+'
                  jne          parse_loop
                  inc          si
                  dec          cx

    parse_loop:
                  cmp          cx, 0
                  je           parse_done

                  mov          al, [si]
                  cmp          al, '0'
                  jl           input_error
                  cmp          al, '9'
                  jg           input_error

                  sub          al, '0'
                  xor          ah, ah
                  push         cx

                  mov          cx, ax
                  mov          ax, bx
                  mov          dx, 10
                  imul         dx
                  jo           ovf_err_proc

                  add          ax, cx
                  jo           ovf_err_proc

                  mov          bx, ax
                  pop          cx

                  inc          si
                  dec          cx
                  jmp          parse_loop

    parse_done:
                  cmp          is_neg, 1
                  jne          save_number
                  neg          bx
                  jo           ovf_err_proc

    save_number:
                  mov          ax, bx
                  clc
                  ret

    ovf_err_proc:
                  pop          cx
                  print_str    msg_ovf
                  stc
                  ret

    input_error:
                  print_str    msg_err
                  stc
                  ret
InputProc endp

OutputProc proc
                  cmp          ax, 0
                  jge          start_convert

                  push         ax
                  mov          ah, 02h
                  mov          dl, '-'
                  int          21h
                  pop          ax
                  neg          ax

    start_convert:
                  xor          cx, cx
                  mov          bx, 10
    divide_loop:
                  xor          dx, dx
                  div          bx
                  push         dx
                  inc          cx
                  test         ax, ax
                  jnz          divide_loop

    print_loop:
                  pop          dx
                  add          dl, '0'
                  mov          ah, 02h
                  int          21h
                  loop         print_loop

                  ret
OutputProc endp

end main
