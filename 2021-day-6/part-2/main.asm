%include "../IO.asm"

section .data
file_path db "../input.txt", 0
magic_number dq 1717986919
permMask db 0b00011011

array    dq 0
         dq 0
         dq 0
         dq 0
         dq 0
         dq 0
         dq 0
         dq 0
         dq 0

section .bss
file_fd resb 8
temp resb 1024
trash resb 32

global _start
%define O_RDONLY 0

%macro read_byte_from_file 2
mov rax, 0
mov rdi, %1
mov rsi, %2
mov rdx, 1
syscall
%endmacro

%macro debug 0
xor rcx, rcx
%%loop:
pushAll
mov rdi, qword[array + rcx * 8]
mov rsi, temp
call itos_buf
mov rdi, temp
call strlen
mov rdx, rax
mov rax, 1
mov rdi, 1
mov rsi, temp
syscall
mov rax, 1
mov rdi, 1
mov rsi, newline
mov rdx, 1
syscall
popAll
inc rcx
cmp rcx, 9
jne %%loop
%endmacro

section .text

_start:
mov rax, 2
mov rdi, file_path
mov rsi, O_RDONLY
syscall

mov qword[file_fd], rax

xor rcx, rcx
loop:
push rcx
read_byte_from_file qword[file_fd], trash
movzx rax, byte[trash]
sub rax, 0x30
inc dword[array + rax * 8]
read_byte_from_file qword[file_fd], trash
pop rcx
inc rcx
cmp byte[trash], 0x0a
jne loop

main:

debug

call print_newline

xor rcx, rcx
main.loop:
vpermpd ymm1, yword[array + 40], 0b00111001
vmovdqu yword[array + 40], ymm1
mov rax, qword[array + 64]
mov rdx, qword[array + 8]
mov rdi, qword[array]
vpermpd ymm1, yword[array + 8], 0b00111001
vmovdqu yword[array + 8], ymm1
mov qword[array + 32], rax
mov qword[array], rdx
mov qword[array + 64], rdi
add qword[array + 48], rdi
push rcx
debug
mov rax, 1
mov rdi, 1
mov rsi, newline
mov rdx, 1
syscall
pop rcx
inc rcx
cmp rcx, 256
jne main.loop

print_answer:

xor rcx, rcx
xor rdi, rdi
print_answer.loop:
mov rax, qword[array + rcx * 8]
add rdi, rax
inc rcx
cmp rcx, 9
jne print_answer.loop

mov rsi, temp
call itos_buf
mov rdi, temp
call strlen
mov rdx, rax
mov rax, 1
mov rdi, 1
mov rsi, temp
syscall
call print_newline

close:
mov rax, 3
mov rdi, qword[file_fd]
syscall

exit:
mov rax, 60
xor rdi, rdi
syscall