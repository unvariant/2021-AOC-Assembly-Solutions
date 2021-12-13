%include "../IO.asm"

section .data
file_path db "../input.txt", 0
magic_number dq 1717986919
up_nine dq 0x1B, "[9A", 0x1B, "[J"
up_nine_len equ $ - up_nine
hide_cursor db 0x1B, "[8m"
hide_cursor_len equ $ - hide_cursor
show_cursor db 0x1B, "[28m"
show_cursor_len equ $ - show_cursor
timespec dq 1
         dq 0
         ;dq 500000000
padding times 9 db 0x0a
         
log db "0: "
    dq 0
    db 10, "1: "
    dq 0
    db 10, "2: "
    dq 0
    db 10, "3: "
    dq 0
    db 10, "4: "
    dq 0
    db 10, "5: "
    dq 0
    db 10, "6: "
    dq 0
    db 10, "7: "
    dq 0
    db 10, "8: "
    dq 0
    db 10

log_len equ $ - log

permMask dd 0
         dd 1
         dd 2
         dd 3
         dd 4
         dd 5
         dd 6
         dd 7

testMask dd 1
         dd 2
         dd 3
         dd 4
         dd 5
         dd 6
         dd 7
         dd 0

array    dd 0
         dd 0
         dd 0
         dd 0
         dd 0
         dd 0
         dd 0
         dd 0
         dd 0

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
mov rbx, 3
%%loop:
pushAll
mov edi, dword[array + rcx * 4]
call itos
mov qword[log + rbx], rax
popAll
inc rcx
add rbx, 12
cmp rcx, 9
jne %%loop
mov rax, 1
mov rdi, 1
mov rsi, log
mov rdx, log_len
syscall
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
inc dword[array + rax * 4]
read_byte_from_file qword[file_fd], trash
pop rcx
inc rcx
cmp byte[trash], 0x0a
jne loop

main:

mov rax, 1
mov rdi, 1
mov rsi, padding
mov rdx, 9
syscall

vmovdqu ymm0, yword[testMask]
xor rcx, rcx
main.loop:
mov eax, dword[array]
vpermd ymm1, ymm0, yword[array + 4]
vmovdqu yword[array + 4], ymm1
add dword[array + 24], eax
mov edx, dword[array + 32]
mov dword[array], edx
mov dword[array + 32], eax
push rcx
call refresh
debug
pop rcx
inc rcx
cmp rcx, 80
je print_answer
push rcx
mov rax, 35
mov rdi, timespec
mov rsi, 0
syscall
pop rcx
jmp main.loop

print_answer:

xor rcx, rcx
xor rdi, rdi
print_answer.loop:
mov eax, dword[array + rcx * 4]
add rdi, rax
inc rcx
cmp rcx, 9
jne print_answer.loop

call print_newline
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

refresh:
mov rax, 1
mov rdi, 1
mov rsi, up_nine
mov rdx, up_nine_len
syscall
ret

show:
mov rax, 1
mov rdi, 1
mov rsi, show_cursor
mov rdx, show_cursor_len
syscall
ret

hide:
mov rax, 1
mov rdi, 1
mov rsi, hide_cursor
mov rdx, hide_cursor_len
syscall
ret