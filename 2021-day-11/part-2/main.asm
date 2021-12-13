%include "../IO.asm"                            ;file with IO subroutines

section .data
file_path db "../input.txt", 0                  ;input file path
magic_number dq 1717986919                      ;magic number for reciprocal multiplication
array db 0, 1                                   ;x + 0, y + 1
      db 0, 255                                 ;x + 0, y - 1
      db 1, 0                                   ;x + 1, y + 0
      db 255, 0                                 ;x - 1, y + 0
      db 255, 255                               ;x - 1, y - 1
      db 1, 1                                   ;x + 1, y + 1
      db 255, 1                                 ;x - 1, y + 1
      db 1, 255                                 ;x + 1, y - 1
oct_plane times 10 dq 0
flash_plane times 10 dq 0 
flashed times 100 db 0
one dq 1
zero dq 0
loop_counter dq 0
total dq 0
inc_plane times 10 dq 0
increases times 100 db 0

section .bss
file_fd resb 8
trash resb 32
octopuses resb 100

global _start
%define O_RDONLY 0

section .text

_start:
mov rax, 2
mov rdi, file_path
mov rsi, O_RDONLY
syscall

mov qword[file_fd], rax

mov qword[loop_counter], 0
mov rdi, octopuses
.loop:
call getline
mov rcx, qword[loop_counter]
mov qword[oct_plane + rcx * 8], rdi
add rdi, 10
inc qword[loop_counter]
cmp qword[loop_counter], 10
jne .loop

setup_flash_plane:
xor rcx, rcx
mov rdi, flashed
.loop:
mov qword[flash_plane + rcx * 8], rdi
add rdi, 10
inc rcx
cmp rcx, 10
jne .loop

setup_inc_plane:
xor rcx, rcx
mov rdi, increases
.loop:
mov qword[inc_plane + rcx * 8], rdi
add rdi, 10
inc rcx
cmp rcx, 10
jne .loop

mov qword[loop_counter], 0
main:

mov qword[total], 0
mov rdi, increases
call clear_plane

mov rdi, flashed
call clear_plane

call increment_plane
call update

call print_oct
call print_newline

inc qword[loop_counter]

cmp qword[total], 100
je print_answer

jmp main

print_answer:

mov rdi, qword[loop_counter]
call print_int
call print_newline

close:
mov rax, 3
mov rdi, qword[file_fd]
syscall

exit:
mov rax, 60
xor rdi, rdi
syscall

clear_plane:
;rdi - pointer
xor rcx, rcx
.loop:
mov byte[rdi + rcx], 0
inc rcx
cmp rcx, 100
jne .loop
ret

increment_plane:
mov rdi, octopuses
xor rcx, rcx
.loop:
inc byte[rdi + rcx]
inc rcx
cmp rcx, 100
jne .loop
ret

update:
xor r14, r14 ;ypos
xor r9, r9   ;number of flashes
.outerloop:

xor r15, r15 ;xpos
mov rsi, qword[oct_plane + r14 * 8] ;row y

.innerloop:

cmp byte[rsi + r15], 0x39
jle .skipadjacents

mov rax, qword[flash_plane + r14 * 8]
cmp byte[rax + r15], 0
jnz .skipadjacents

mov byte[rax + r15], 0x31
inc r9

xor r13, r13                        ;counter to check adj
.adjacents:

mov r10, r15                        ;xpos
mov r11, r14                        ;ypos
add r10b, byte[array + r13 * 2]
add r11b, byte[array + r13 * 2 + 1]

cmp r10b, 0
jl .nextiter
cmp r11b, 0
jl .nextiter
cmp r10b, 9
jg .nextiter
cmp r11b, 9
jg .nextiter
mov rax, qword[flash_plane + r11 * 8]
cmp byte[rax + r10], 0
jnz .nextiter

mov rax, qword[inc_plane + r11 * 8]
inc byte[rax + r10]

.nextiter:

inc r13
cmp r13, 8
jne .adjacents

.skipadjacents:

inc r15
cmp r15, 10
jne .innerloop

inc r14
cmp r14, 10
jne .outerloop

add qword[total], r9

xor rcx, rcx
.apply:
mov al, byte[increases + rcx]
add byte[octopuses + rcx], al
inc rcx
cmp rcx, 100
jne .apply

xor r9, r9
xor rcx, rcx
.count:
cmp byte[octopuses + rcx], 0x39
jle .next
cmp byte[flashed + rcx], 0
jnz .set_zero
inc r9
jmp .next
.set_zero:
mov byte[octopuses + rcx], 0x30
.next:
inc rcx
cmp rcx, 100
jne .count

cmp r9, 0
jz .end

mov rdi, increases
call clear_plane

call update

.end:
ret

print_oct:
xor rcx, rcx
.loop:
mov rsi, qword[oct_plane + rcx * 8]
push rcx
mov rax, 1
mov rdi, 1
mov rdx, 10
syscall
mov rax, 1
mov rdi, 1
mov rsi, newline
mov rdx, 1
syscall
pop rcx
inc rcx
cmp rcx, 10
jne .loop
ret

print_flashes:
xor rcx, rcx
.loop:
mov rsi, qword[flash_plane + rcx * 8]
push rcx
mov rax, 1
mov rdi, 1
mov rdx, 10
syscall
mov rax, 1
mov rdi, 1
mov rsi, newline
mov rdx, 1
syscall
pop rcx
inc rcx
cmp rcx, 10
jne .loop
ret