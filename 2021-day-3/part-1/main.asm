section .data
file_path db "../input.txt", 0
magic_number dq 1717986919
ones_addr dq ones
zeros_addr dq zeros
newline db 0x0a

section .bss
file_fd resb 8
trash resb 16
ones resb 24
zeros resb 24

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

mov rdi, trash
call getline

cmp rax, 0
jz print_answer

xor rcx, rcx
.loop:
mov al, byte[trash + rcx]
sub al, 0x30
mov rsi, qword[ones_addr]
cmp al, 0
cmove rsi, qword[zeros_addr]
inc word[rsi + rcx * 2]
inc rcx
cmp rcx, 12
jne .loop

jmp main

print_answer:

xor rdi, rdi
xor rsi, rsi
xor rcx, rcx
.loop:
mov ax, word[ones + rcx * 2]
mov bx, word[zeros + rcx * 2]
cmp ax, bx
jg .set_rdi
jl .set_rsi
.set_rdi:
bts rdi, 0
jmp .next
.set_rsi:
bts rsi, 0
.next:
shl rdi, 1
shl rsi, 1
inc rcx
cmp rcx, 12
jne .loop
shr rdi, 1
shr rsi, 1

mov rax, rdi
mul rsi
mov rdi, rax
call itos
mov qword[trash], rax
mov rax, 1
mov rdi, 1
mov rsi, trash
mov rdx, 8
syscall

close:
mov rax, 3
mov rdi, qword[file_fd]
syscall

exit:
mov rax, 60
xor rdi, rdi
syscall

getline:
;rdi - pointer to buffer
mov r10, rdi
.read:
mov rax, 0
mov rdi, qword[file_fd]
mov rsi, r10
mov rdx, 1
syscall
cmp byte[r10], 0x05
je .read_fail
inc r10
cmp byte[r10 - 1], 0x0a
jne .read
mov byte[r10 - 1], 0
mov rax, 1
ret
.read_fail:
xor rax, rax
ret

itos:
;rdi - number
mov rax, rdi
xor rdi, rdi
.loop:
mov rcx, rax
mul qword[magic_number]
shr rax, 34
mov rsi, rax
shl rax, 2
add rax, rsi
shl rax, 1
sub rcx, rax
mov rax, rsi
add cl, 0x30
mov dil, cl
shl rdi, 8
cmp rax, 0
jnz .loop
mov rax, rdi
ret