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
        resw 5
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

xor rcx, rcx
.loop:
mov rdi, rcx
call set_boards
call check_win
cmp rax, 0
jg print_answer
inc rcx
cmp rcx, 100
jne .loop

print_answer:
push rcx

xor rdi, rdi
xor rcx, rcx
shl rax, 5
.loop:
xor rbx, rbx
cmp byte[win + rax + rcx], 0
jne .next
mov bl, byte[boards + rax + rcx]
.next:
movzx rbx, bl
add rdi, rbx
inc rcx
cmp rcx, 25
jne .loop
shr rax, 5

push rdi
push rax
call print_int
pop rax
pop rdi

call print_newline

pop rcx
mov rax, rdi
movsx rdi, byte[numbers + rcx]

mul rdi
mov rdi, rax
call print_int
call print_newline
;call print_win

close:
mov rax, 3
mov rdi, qword[file_fd]
syscall

exit:
mov rax, 60
xor rdi, rdi
syscall