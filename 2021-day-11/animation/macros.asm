%macro print_info 1
mov rax, 1
mov rdi, 1
mov rsi, %1_msg
mov rdx, %1_msg_len
syscall
mov rdi, qword[ %1 ]
mov rsi, %1_buffer
call itos_buf
mov rdi, %1_buffer
call strlen
mov byte[ %1_buffer + rax], 0x0a
mov rdx, rax
inc rdx
mov rax, 1
mov rdi, 1
mov rsi, %1_buffer
syscall
%endmacro

%macro reserve_info_buffer 1
%1_buffer_len equ 16
%1_buffer resb %1_buffer_len
%endmacro