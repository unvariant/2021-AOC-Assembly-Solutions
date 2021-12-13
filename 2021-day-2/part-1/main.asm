section .data
file_path db "../input.txt", 0
magic_number dq 1717986919
neg_one dq 0x1
two dd 0x2
four dd 0x4
seven dd 0x7
xpos dq 0
ypos dq 0
xaddr dq xpos
yaddr dq ypos

section .bss
file_fd resb 8
answer resb 8
trash resb 16
char resb 2

global _start
%define O_RDONLY 0

section .text

_start:
mov rax, 2
mov rdi, file_path
mov rsi, 0
syscall

mov qword[file_fd], rax

mov qword[answer], 0
mov qword[xpos], 0
mov qword[ypos], 0
mov byte[trash + 8], 0x0a

main:

mov rax, 0
mov rdi, qword[file_fd]
mov rsi, char
mov rdx, 1
syscall

mov rax, 1
mov rdi, 1
mov rsi, char
mov rdx, 1
syscall

cmp byte[char], 0x64  ;d (own )
je char_d
cmp byte[char], 0x66  ;f (orward )
je char_f
cmp byte[char], 0x75  ;u (p )
je char_u

char_u:
mov rdx, 2
mov rsi, qword[yaddr]
jmp fi

char_f:
mov rdx, 7
mov rsi, qword[xaddr]
jmp fi

char_d:
mov rdx, 4
mov rsi, qword[yaddr]

fi:

push rsi

mov rax, 0
mov rdi, qword[file_fd]
mov rsi, trash
syscall

mov rax, 1
mov rdi, 1
mov rsi, trash
mov rdx, 9
syscall

mov rdi, trash
mov qword[rdi], 0
call getline_int

cmp rax, 0
jz print_answer

pop rsi

cmp byte[char], 0x64
je positive

cmp byte[char], 0x66
je positive

cmp byte[char], 0x75
je negative

negative:
neg rax
jmp positive

positive:

add qword[rsi], rax

jmp main

print_answer:
mov rax, qword[xpos]
mov rcx, qword[ypos]

mul rcx

mov rdi, rax
call itos
mov qword[trash], rax
mov rax, 1
mov rdi, 1
mov rsi, trash
mov rdx, 9
syscall

close:
mov rax, 3
mov rdi, qword[file_fd]
syscall

exit:
mov rax, 60
xor rdi, rdi
syscall

getline_int:
;rdi - pointer to buf
push rdi
call getline
pop rdi

cmp rax, 0
jz .end

call stoi
mov qword[rdi], rax
.end:
ret

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
jl .read_fail
inc r10
cmp byte[r10 - 1], 0x0a
jne .read
mov byte[r10 - 1], 0
mov rax, 1
ret
.read_fail:
xor rax, rax
ret

strlen:
;rdi - pointer to buffer
xor rax, rax
cmp byte[rdi], 0
jz .end
.loop:
inc rax
cmp byte[rdi + rax], 0
jnz .loop
.end:
ret

itos:
;rdi - number
mov rax, rdi
xor rdi, rdi
cmp rax, 0
jge .loop
neg rax
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

stoi:
;rdi - pointer to string
call strlen
lea rsi, [rdi + rax]
mov r8, 1           ;put 1 into r8
xor r9, r9          ;result number
.loop:
dec rsi           ;dec to next char, right to left
mov dh, byte[rsi] ;get char
sub dh, 0x30      ;turn char to int
xor rax, rax      ;zero out rax for multiplication
mov al, dh        ;put dh into lower byte of rax
mul r8            ;multiply by r8
add r9, rax       ;add to result
push r8           ;save r8 ---------------|multiply
shl r8, 2         ;mul by 4               |r8
pop rcx           ;old r8 in rcx          |by
add r8, rcx       ;add old r8 to new r8   |ten
shl r8, 1         ;mul by 2 --------------|
cmp rdi, rsi      ;end of string?
jne .loop         ;if not, continue
mov rax, r9         ;put result in rax
ret                 ;return