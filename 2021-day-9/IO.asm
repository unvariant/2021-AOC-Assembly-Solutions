%macro pushAll 0
push rax
push rdi
push rsi
push rdx
push rcx
push r8
push r9
push r10
push r11
%endmacro

%macro popAll 0
pop r11
pop r10
pop r9
pop r8
pop rcx
pop rdx
pop rsi
pop rdi
pop rax
%endmacro

getline:
;rdi - pointer to buffer
mov rsi, 0x0a
push rdi
call read_until_EOF
pop rdi
ret

read_until_space:
;rdi - pointer
mov rsi, " "
call read_until_newline
ret

clear_newline:
push rdi
mov rdi, trash
call getline
pop rdi
ret

print_int:
;rdi - int
call itos
mov qword[trash], rax
mov rax, 1
mov rdi, 1
mov rsi, trash
mov rdx, 8
syscall
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

itos_buf:
;rdi - number
;rsi - buffer
mov rax, rdi
xor rdi, rdi
mov r8, 10
push 0x0
.loop:
mov rcx, rax
xor rdx, rdx
div r8
add rdx, 0x30
push rdx
cmp rax, 0
jnz .loop
.write:
pop rax
mov byte[rsi], al
inc rsi
cmp al, 0
jnz .write
ret

stoi:
;rdi - pointer to string
call strlen
lea rsi, [rdi + rax]
mov r8, 1           ;put 1 into r8
xor r9, r9          ;result number
.loop:
dec rsi           ;dec to next char, right to left
mov dl, byte[rsi] ;get char
sub dl, 0x30      ;turn char to int
xor rax, rax      ;zero out rax for multiplication
mov al, dl        ;put dh into lower byte of rax
mul r8            ;multiply by r8
add r9, rax       ;add to result
push r8           ;save r8 ---------------|multiply
shl r8, 2         ;mul by 4               |r8
pop rcx           ;old r8 in rcx          |by
add r8, rcx       ;add old r8 to new r8   |ten
shl r8, 1         ;mul by 2 --------------|
cmp rdi, rsi      ;end of string?
jne .loop         ;if not, continue
mov rax, r9       ;put result in rax
ret               ;return

print_newline:
pushAll
mov rax, 1
mov rdi, 1
mov rsi, newline
mov rdx, 1
syscall
popAll
ret
newline db 0x0a

read_until_EOF:
;rdi - pointer to buffer
;rsi - char to find
mov r10, rdi
.read:
push rsi
mov rax, 0
mov rdi, qword[file_fd]
mov rsi, r10
mov rdx, 1
syscall
pop rsi
mov al, byte[r10]
cmp al, 0x05
je .EOF
inc r10
cmp al, sil
jne .read
mov rax, 1
jmp .end
.EOF:
xor rax, rax
.end:
mov byte[r10], 0
ret

read_until_newline:
;rdi - pointer to buffer
;rsi - char to find
mov r10, rdi
.read:
push rsi
mov rax, 0
mov rdi, qword[file_fd]
mov rsi, r10
mov rdx, 1
syscall
pop rsi
mov al, byte[r10]
inc r10
cmp al, 0x0a
je .end
cmp al, sil
jne .read
.end:
mov byte[r10 - 1], 0
ret