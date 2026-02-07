stseg segment para stack "STACK"
          db 64 dup ( "STACK" )
stseg ends
dseg segment para public "DATA"
    source db 10, 20, 30, 40
    dest   db 4 dup ( "?" )
dseg ends
cseg segment para public "CODE"
main proc far
         assume cs: cseg, ds: dseg, ss: stseg
         ; return address
         push   ds
         xor    ax, ax
         push   ax
         ; initialize ds
         mov    ax, dseg
         mov    ds, ax
         ; zeroing dest
         mov    dest, 0
         mov    dest+1, 0
         mov    dest+2, 0
         mov    dest+3, 0
         ; copying source to dest in reverse order
         mov    al, source
         mov    dest+3, al
         mov    al, source+1
         mov    dest+2, al
         mov    al, source+2
         mov    dest+1, al
         mov    al, source+3
         mov    dest, al
         ret
main endp
cseg ends
end main
