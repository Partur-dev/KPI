.model small
JUMPS
.stack 100h

.data
    ; messages
    msg_rows    db 'Enter number of rows (1-10): $'
    msg_cols    db 13, 10, 'Enter number of cols (1-10): $'
    msg_elem    db 'Enter element: $'
    msg_search  db 13, 10, 'Enter element to search: $'

    ; result messages
    msg_found   db 13, 10, 'Found at Row: $'
    msg_col     db ', Col: $'
    msg_not_fnd db 13, 10, 'Element not found in the array.$'
    msg_nl      db 13, 10, '$'

    ; error messages
    msg_err     db 13, 10, 'Error: Invalid input! (Numbers only)$'
    msg_ovf     db 13, 10, 'Error: Overflow/Underflow! Limit to 16-bit.$'
    msg_dim_err db 13, 10, 'Error: Dimension must be between 1 and 10.$'

    ; vars
    buffer      db 7, 0, 7 dup(0)
    arr         dw 100 dup(0)                                                ; reserved for 10x10 matrix (100 words)
    num_rows    dw 0
    num_cols    dw 0
    search_val  dw 0
    found_flag  db 0                                                         ; 1 - found, 0 - not found
    is_neg      db 0

.code
main proc
                  mov  ax, @data
                  mov  ds, ax

                  ; rows input
                  lea  dx, msg_rows
                  mov  ah, 09h
                  int  21h
                  call InputProc
                  jc   exit_prog
                  cmp  ax, 1
                  jl   bad_dim
                  cmp  ax, 10
                  jg   bad_dim
                  mov  num_rows, ax

                  ; cols input
                  lea  dx, msg_cols
                  mov  ah, 09h
                  int  21h
                  call InputProc
                  jc   exit_prog
                  cmp  ax, 1
                  jl   bad_dim
                  cmp  ax, 10
                  jg   bad_dim
                  mov  num_cols, ax

                  ; input elements
                  lea  dx, msg_nl
                  mov  ah, 09h
                  int  21h

                  ; calc all elements
                  mov  ax, num_rows
                  imul num_cols
                  mov  cx, ax             ; cx - counter for input loop
                  lea  di, arr            ; di - array start

    input_loop:
                  push cx                 ; save counter
                  lea  dx, msg_elem
                  mov  ah, 09h
                  int  21h

                  call InputProc
                  pop  cx
                  jc   exit_prog          ; wilted flower

                  mov  [di], ax           ; save to array
                  add  di, 2              ; and move to next element

                  ; new line, this time a bit better
                  lea  dx, msg_nl
                  mov  ah, 09h
                  int  21h

                  loop input_loop

                  ; search input
                  lea  dx, msg_search
                  mov  ah, 09h
                  int  21h
                  call InputProc
                  jc   exit_prog
                  mov  search_val, ax

                  ; actual search
                  lea  di, arr
                  mov  cx, num_rows       ; outer loop - rows
                  mov  bx, 1              ; bx - current row
                  mov  found_flag, 0

    row_loop:
                  push cx                 ; save rows
                  mov  cx, num_cols       ; inner loop on cols
                  mov  si, 1              ; si - current col

    col_loop:
                  mov  ax, [di]
                  cmp  ax, search_val
                  jne  not_match          ; skip if !=

                  ; found at least one
                  mov  found_flag, 1

                  ; save ts
                  push ax
                  push bx
                  push cx
                  push dx
                  push si
                  push di

                  lea  dx, msg_found
                  mov  ah, 09h
                  int  21h
                  mov  ax, bx             ; bx - row number
                  call OutputProc

                  lea  dx, msg_col
                  mov  ah, 09h
                  int  21h
                  mov  ax, si             ; si - col number
                  call OutputProc

                  ; restore ts
                  pop  di
                  pop  si
                  pop  dx
                  pop  cx
                  pop  bx
                  pop  ax

    not_match:
                  add  di, 2              ; next element
                  inc  si                 ; inc col number
                  loop col_loop

                  inc  bx                 ; col end reached - next row
                  pop  cx                 ; restore row counter
                  loop row_loop

                  ; check if found at least one
                  cmp  found_flag, 1
                  je   end_prog

                  ; if not print a message
                  lea  dx, msg_not_fnd
                  mov  ah, 09h
                  int  21h

    end_prog:
                  jmp  exit_prog

    bad_dim:
                  lea  dx, msg_dim_err
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
