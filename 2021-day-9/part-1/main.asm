%include "../IO.asm"

section .data
file_path db "../input.txt", 0
magic_number dq 1717986919
total dq 0
array db 0
      db 1
      db 0
      db 255
      db 1
      db 0
      db 255
      db 0
plane times 100 dq 0
position dd 0
one dq 1
one_hundred dq 100
loop_counter dq 0
outer_counter dq 0

section .bss
file_fd resb 8
trash resb 32
vents resb 10000

global _start
%define O_RDONLY 0

%macro abs 1
cmp %1, 0
jg %%end
neg %1
%%end:
%endmacro

section .text

_start:
mov rax, 2
mov rdi, file_path
mov rsi, O_RDONLY
syscall

mov qword[file_fd], rax

mov qword[loop_counter], 0
mov rdi, vents
.loop:
call getline
mov rcx, qword[loop_counter]
mov qword[plane + rcx * 8], rdi
add rdi, 100
inc qword[loop_counter]
cmp qword[loop_counter], 100
jne .loop

main:

xor r15, r15 ;ypos
outer:
xor r14, r14 ;xpos
inner:

mov qword[loop_counter], 0 ;loop counter
xor r12, r12 ;number of greater adjacents
mov rdi, qword[plane + r15 * 8]
movzx r11, byte[rdi + r14]
check_point:

mov rdi, r14 ;mov xpos into rdi
mov rax, r15 ;mov ypos into rax
mov r13, qword[loop_counter]
add dil, byte[array + r13 * 2]
add al, byte[array + r13 * 2 + 1]

cmp dil, 0
jl edge
cmp al, 0
jl edge
cmp dil, 99
jg edge
cmp al, 99
jng next
edge:
inc r12
jmp end
next:

mov rsi, qword[plane + rax * 8]
movzx rsi, byte[rsi + rdi]

xor rdi, rdi
cmp r11, rsi
cmovl rdi, qword[one]
add r12, rdi

end:

inc qword[loop_counter]
cmp qword[loop_counter], 4
jne check_point

cmp r12, 4
jne continue

sub r11, 0x30
inc r11
add qword[total], r11

continue:

inc r14
cmp r14, 100
jne inner

inc r15
cmp r15, 100
jne outer

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

debug:
mov qword[loop_counter], 0
.loop:
mov rax, 1
mov rdi, 1
mov rcx, qword[loop_counter]
mov rsi, qword[plane + rcx * 8]
mov rdx, 100
syscall
mov rax, 1
mov rdi, 1
mov rsi, newline
mov rdx, 1
syscall
inc qword[loop_counter]
cmp qword[loop_counter], 100
jne .loop
ret