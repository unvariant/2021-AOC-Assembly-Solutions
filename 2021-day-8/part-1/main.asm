%include "../IO.asm"

section .data
file_path db "../input.txt", 0
magic_number dq 1717986919
total dq 0

section .bss
file_fd resb 8
temp resb 5000
trash resb 32
one_symbol resb 2
four_symbol resb 4
seven_symbol resb 3
eight_symbol resb 8

global _start
%define O_RDONLY 0

section .text

_start:
mov rax, 2
mov rdi, file_path
mov rsi, O_RDONLY
syscall

mov qword[file_fd], rax

main:

xor rcx, rcx
loop:
push rcx
mov rdi, temp
mov rsi, "|"
call read_until_newline

mov rax, 0
mov rdi, qword[file_fd]
mov rsi, temp
mov rdx, 1
syscall

mov rdi, temp
mov rsi, 0x0a
call read_until_newline

xor rbx, rbx
xor rdi, rdi
inner:
mov r10b, byte[temp + rbx]
mov byte[trash + rdi], r10b
cmp r10b, 0x20
je count_len
inc rdi
next:
inc rbx
cmp r10b, 0x0
jne inner

mov byte[trash + rdi], 0x0
push rcx
mov rdi, trash
call strlen
mov rdx, rax
mov rax, 1
mov rdi, 1
mov rsi, trash
syscall
call print_newline
pop rcx
mov rdi, trash
call strlen
xor r8, r8
mov r9, 1
cmp rax, 2
cmove r8, r9
cmp rax, 3
cmove r8, r9
cmp rax, 4
cmove r8, r9
cmp rax, 7
cmove r8, r9
add qword[total], r8
xor rdi, rdi

pop rcx
inc rcx
cmp rcx, 200
jne loop

print_answer:

mov rdi, qword[total]
call print_int

close:
mov rax, 3
mov rdi, qword[file_fd]
syscall

exit:
mov rax, 60
xor rdi, rdi
syscall

count_len:
mov byte[trash + rdi], 0x0
push rcx
mov rdi, trash
call strlen
mov rdx, rax
mov rax, 1
mov rdi, 1
mov rsi, trash
syscall
call print_newline
pop rcx
mov rdi, trash
call strlen
xor r8, r8
mov r9, 1
cmp rax, 2
cmove r8, r9
cmp rax, 3
cmove r8, r9
cmp rax, 4
cmove r8, r9
cmp rax, 7
cmove r8, r9
add qword[total], r8
xor rdi, rdi
jmp next