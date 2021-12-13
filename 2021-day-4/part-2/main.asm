%include "../IO.asm"

section .data
file_path db "../input.txt", 0
magic_number dq 1717986919
newline db 10
h_win times 8 db 0xff
zeros times 8 db 0x30
ones times 8 db 0x31
five dq 0x5

section .bss
file_fd resb 8
temp resb 1024
trash resb 32
numbers resw 100
        resw 1
boards resy 100
       resb 1
win    resy 100
compare resb 32

global _start
%define O_RDONLY 0

section .text

_start:
mov rax, 2
mov rdi, file_path
mov rsi, O_RDONLY
syscall

mov qword[file_fd], rax

mov word[numbers + 100 * 2], 0

call get_numbers

call get_board

call print_board

xor rcx, rcx
mov byte[trash + 8], 0x0a
.loop:
mov rdi, rcx
call set_boards
call count_wins
inc rcx
cmp rcx, 99
jg print_answer
cmp rax, 99
jne .loop

push rcx
call print_win

print_answer:

xor rcx, rcx
mov rdi, win
.find_unsolved:
push rdi
call check
pop rdi
cmp rax, 0
jz .next_unsolved
inc rcx
add rdi, 32
jmp .find_unsolved

.next_unsolved:

push rcx
mov rdi, rcx
call print_int
pop rcx

mov r12, rcx
shl r12, 5
add r12, win
;index of unsolved

pop rcx
.find_solve_num:
mov rdi, rcx
call set_boards
mov rdi, r12
call check
cmp rax, 0
jnz .calculate_sum
inc rcx
jmp .find_solve_num

.calculate_sum:
sub r12, win
push rcx
xor rdi, rdi
xor rcx, rcx
.loop:
xor rbx, rbx
cmp byte[win + r12 + rcx], 0
jne .next
mov bl, byte[boards + r12 + rcx]
.next:
movzx rbx, bl
add rdi, rbx
inc rcx
cmp rcx, 25
jne .loop

push rdi
call print_int
pop rdi

call print_newline

pop rcx
mov rax, rdi
movsx rdi, byte[numbers + rcx]

mul rdi
mov rdi, rax
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