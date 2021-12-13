%include "../IO.asm"

section .data
file_path db "../input.txt", 0
magic_number dq 1717986919
array times 2000 dw 0
smallest dq 1000000000000

section .bss
file_fd resb 8
temp resb 5000
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

section .text

_start:
mov rax, 2
mov rdi, file_path
mov rsi, O_RDONLY
syscall

mov qword[file_fd], rax

xor rcx, rcx
loop:
mov rdi, temp
mov rsi, ","
push rcx
call read_until_newline
mov rdi, temp
call stoi
pop rcx
inc word[array + rax * 2]
inc rcx
cmp rcx, 1000
jne loop

debug:
xor rcx, rcx
mov byte[trash + 8], 0x0a
.loop:
movzx rdi, word[array + rcx * 2]
push rcx
call itos
mov qword[trash], rax
mov rax, 1
mov rdi, 1
mov rsi, trash
mov rdx, 9
syscall
pop rcx
inc rcx
cmp rcx, 2000
jne .loop

main:

xor rcx, rcx
.loop:
mov rdi, rcx
xor rbx, rbx
xor r8, r8
.innerloop:
movzx rsi, word[array + rbx * 2]
mov rax, rdi
sub rax, rbx
cmp rax, 0
jg .next
neg rax
.next:
mov r9, rax
inc r9
mul r9
shr rax, 1
mul rsi
add r8, rax
inc rbx
cmp rbx, 2000
jne .innerloop
pushAll
mov rdi, r8
call print_int
call print_newline
popAll
cmp r8, qword[smallest]
jnl .skip
mov qword[smallest], r8
.skip:
inc rcx
cmp rcx, 2000
jne .loop

print_answer:
call print_newline
mov rdi, qword[smallest]
mov rsi, temp
call itos_buf
mov rax, 1
mov rdi, 1
mov rsi, temp
mov rdx, 15
syscall

close:
mov rax, 3
mov rdi, qword[file_fd]
syscall

exit:
mov rax, 60
xor rdi, rdi
syscall