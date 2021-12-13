section .data
file_path db "../input.txt", 0
magic_number dq 1717986919

section .bss
file_fd resb 8
trash resb 32
answer resb 8
array resw 1001
array1 resw 1001
array2 resw 1001

global _start
%define O_RDONLY 0

section .text

_start:
mov rax, 2
mov rdi, file_path
mov rsi, O_RDONLY
syscall

mov qword[file_fd], rax

mov qword[answer], 0

xor rcx, rcx
.loop:
push rcx
mov rdi, trash
call getline
mov rdi, trash
call binstrtoi
pop rcx
mov word[array + rcx * 2], ax
inc rcx
cmp rcx, 1000
jne .loop

mov byte[trash + 17], 0x0a
mov word[array + 2000], 0
mov word[array1 + 2000], 0
mov word[array2 + 2000], 0

main:

mov rdi, 11
mov rsi, 1
mov rdx, array
mov r10, array1
mov r11, 0
call filter

mov rcx, 10
.loop1:
push rcx
mov rdi, rcx
mov rsi, 1
mov rdx, array1
mov r10, array1
mov r11, 0
call filter
pop rcx
dec rcx
cmp word[array1 + 2], 0
jnz .loop1

mov rdi, 11
mov rsi, 1
mov rdx, array
mov r10, array2
mov r11, 1
call filter

mov rcx, 10
.loop2:
push rcx
mov rdi, rcx
mov rsi, 1
mov rdx, array2
mov r10, array2
mov r11, 1
call filter
pop rcx
dec rcx
cmp word[array2 + 2], 0
jnz .loop2

print_answer:

movsx rax, word[array1]
movsx rdx, word[array2]
mul rdx

mov rdi, rax
call itos
mov qword[trash], rax
mov byte[trash + 8], 0x0a
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

filter:
;rdi - bit index
;rsi - bit preference
;rdx - array to read
;r10 - array to write
;r11 - xor value
push rdx
call count
xor rax, r11
pop rdx
xor rcx, rcx
mov r9, 1
.loop:
xor r8, r8
mov bx, word[rdx + rcx * 2]
bt bx, di
cmovc r8, r9
cmp rax, r8
jne .next
mov word[r10], bx
add r10, 2
.next:
inc rcx
cmp bx, 0
jnz .loop
mov word[r10], 0
ret

count:
;rdi - bit index
;rsi - bit preference
;rdx - array to read
xor rcx, rcx ;loop counter
xor r8, r8 ;ones
xor r9, r9 ;zeros
.loop:
mov bx, word[rdx + rcx * 2]
bt bx, di
jc .inc_r8
inc r9
jmp .next
.inc_r8:
inc r8
.next:
inc rcx
cmp bx, 0
jnz .loop
dec r9
xor rax, rax
cmp r8, r9
jl .end
je .preference
mov rax, 1
jmp .end
.preference:
mov rax, rsi
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

binstrtoi:
;rdi - binary string
call strlen
mov rsi, rax
xor rax, rax
xor rcx, rcx
.loop:
mov dl, byte[rdi + rcx]
sub dl, 0x30
test dl, dl
jz .next
bts rax, 0
.next:
shl rax, 1
inc rcx
cmp rcx, rsi
jne .loop
shr rax, 1
ret