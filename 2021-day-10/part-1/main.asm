%include "../IO.asm"

section .data
file_path db "../input.txt", 0
magic_number dq 1717986919
loop_counter dq 0
inner_counter dq 0
invalid_msg db "invalid: "
invalid_msg_len equ $ - invalid_msg
total dq 0
illegal_paran dq 3
illegal_bracket dq 57
illegal_curly dq 1197
illegal_tag dq 25137

section .bss
file_fd resb 8
trash resb 32
buffer resb 1000

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
main:

mov rdi, buffer
call getline

xor rcx, rcx
loop:
mov al, byte[buffer + rcx]

xor rbx, rbx
cmp al, "("
je close_paran
cmp al, "{"
je close_curly
cmp al, "["
je close_bracket
cmp al, "<"
je close_tag
jmp check_close

close_paran:
push ")"
jmp continue
close_curly:
push "}"
jmp continue
close_bracket:
push "]"
jmp continue
close_tag:
push ">"
jmp continue

check_close:

pop rdx
cmp rdx, rax
je continue

xor rdx, rdx
cmp rax, ")"
cmove rdx, qword[illegal_paran]
cmp rax, "}"
cmove rdx, qword[illegal_curly]
cmp rax, "]"
cmove rdx, qword[illegal_bracket]
cmp rax, ">"
cmove rdx, qword[illegal_tag]
add qword[total], rdx

continue:

inc rcx
cmp byte[buffer + rcx], 0
jnz loop

inc qword[loop_counter]
cmp qword[loop_counter], 94
jne main

print_answer:

mov rdi, qword[total]
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