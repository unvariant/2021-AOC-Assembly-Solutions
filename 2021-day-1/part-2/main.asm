section .data
file_path db "../input.txt", 0
magic_number dq 1717986919
newline db 0x0a
ymask dq 0xffffffffffffffff
      dq 0xffffffffffffffff
      dq 0xffffffffffffffff
      dq 0
         

section .bss
file_fd resb 8
answer resb 8
window resb 32
debug resb 64

global _start

section .text

_start:
mov rax, 2
mov rdi, file_path
mov rsi, 0
syscall

mov qword[file_fd], rax

mov qword[answer], 0

mov rdi, window
lea rsi, [rdi + 24]
.loop:
push rdi
push rsi
call getline_int
pop rsi
pop rdi
add rdi, 8
cmp rdi, rsi
jne .loop

main:
mov rdi, window + 24
call getline_int

cmp rax, 0
jz print_answer

mov rax, qword[window]

vmovdqu ymm0, yword[window]
vpermpd ymm0, ymm0, 0b00111001
vpand ymm0, ymm0, yword[ymask]
vmovdqu yword[window], ymm0
mov rdx, qword[window + 16]
xor rcx, rcx
mov rdi, 1
cmp rdx, rax
cmovg rcx, rdi

add qword[answer], rcx

jmp main

print_answer:
mov rdi, qword[answer]
call itos

mov qword[answer], rax

mov rax, 1
mov rdi, 1
mov rsi, answer
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

getline_int:
;rdi - pointer to buf
push rdi
call getline
pop rdi

cmp rax, 0
jz .read_fail

call stoi
mov qword[rdi], rax
ret
.read_fail:
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
.itos:
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
jnz .itos
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