get_board:
xor r12, r12
mov rdi, boards
.outer:
call clear_newline
lea rcx, [rdi + 25]

.inner:
push rcx
push rdi
mov rdi, temp
call getline

mov rdi, temp
pop rsi
push rsi
mov rbx, 0x20
call word_split_on_char

pop rdi
call words_to_int

pop rcx
add rdi, 5
cmp rdi, rcx
jne .inner

.clear:
mov dword[rdi], 0xfefefefe
mov word[rdi + 4], 0xfefe
mov byte[rdi + 6], 0xfe
add rdi, 7
inc r12
cmp r12, 100
jne .outer
ret

get_numbers:
mov rdi, temp
call getline

mov rdi, temp
mov rsi, numbers
call word_split_comma_no_whitespace

mov rdi, numbers
call words_to_int
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
mov rdx, 9
syscall
ret

words_to_int:
;rdi - input buffer
push rdi
xor rcx, rcx
mov r10, rdi
mov byte[trash + 2], 0
.loop:
mov dx, word[r10 + rcx * 2]
mov word[trash], dx
mov rdi, trash
call wtoi
mov byte[r10 + rcx], al
inc rcx
cmp word[r10 + rcx * 2], 0
jnz .loop
pop rdi
ret

wtoi:
;rdi - input buffer
movzx rax, byte[rdi + 1]
sub al, 0x30
movzx rdx, byte[rdi]
cmp dl, 0x30
jl .set_zero
sub dl, 0x30
jmp .next
.set_zero:
xor dl, dl
.next:
mov rbx, rdx
shl rdx, 2
add rdx, rbx
shl rdx, 1
add rax, rdx
ret

word_split_comma_no_whitespace:
;rdi - input buffer
;rsi - output buffer
xor rcx, rcx
.loop:
xor rax, rax
.find_comma:
shr rax, 8
mov ah, byte[rdi]
inc rdi
cmp byte[rdi], 0
je .store
cmp byte[rdi], ","
jne .find_comma
.store:
mov word[rsi], ax
add rsi, 2
inc rdi
inc rcx
cmp rcx, 100
jne .loop
mov word[rsi], 0
ret

word_split_on_char:
;rdi - input buffer
;rsi - output buffer
;rbx - char to split
xor rcx, rcx
.loop:
mov ax, word[rdi + rcx]
cmp ah, bl
je .clear_high
jne .store
.clear_high:
mov dl, al
xor ax, ax
mov al, dl
mov word[rsi], ax
jmp .next
.store:
mov word[rsi], ax
.next:
add rsi, 2
add rcx, 3
cmp byte[rdi + rcx], 0
jnz .loop
mov word[rsi], 0
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
;call strlen
lea rsi, [rdi + 2]
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
mov rax, r9         ;put result in rax
ret                 ;return

print_newline:
push rax
push rdi
push rsi
push rdx
push rcx
push r8
push r9
mov rax, 1
mov rdi, 1
mov rsi, newline
mov rdx, 1
syscall
pop r9
pop r8
pop rcx
pop rdx
pop rsi
pop rdi
pop rax
ret

print_win:
mov r12, win
call print_arrays
ret

print_board:
mov r12, boards
call print_arrays
ret

print_arrays:
;r12 - array to read from
xor r11, r11
.outer:
push r11
mov rdi, r11
call print_int
call print_newline
xor rcx, rcx
.inner:
push rcx
movzx rdi, byte[r12 + rcx]
call itos
shr rax, 8
mov qword[trash], rax
mov byte[trash + 3], 0x20
mov rax, 1
mov rdi, 1
mov rsi, trash
mov rdx, 4
syscall
pop rcx
inc rcx
mov rax, rcx
xor rdx, rdx
div qword[five]
cmp rdx, 0
jnz .next
call print_newline
.next:
cmp rcx, 25
jne .inner
call print_newline
add r12, 32
pop r11
inc r11
cmp r11, 100
jne .outer
ret

set_compare:
;rdi - byte
push rcx
mov rcx, 31
.loop:
mov byte[compare + rcx], dil
loop .loop
mov byte[compare], dil
pop rcx
ret

set_boards:
push rcx
movzx rdi, byte[numbers + rdi]
call set_compare
xor rcx, rcx
.loop:
shl rcx, 5
vmovdqu ymm0, yword[boards + rcx]
vpcmpeqb ymm0, ymm0, yword[compare]
vpor ymm0, ymm0, yword[win + rcx]
vmovdqu yword[win + rcx], ymm0
shr rcx, 5
inc rcx
cmp rcx, 100
jne .loop
pop rcx
ret

check_win:
push rcx
mov rdi, win
xor rcx, rcx
.loop:
push rdi
call check
pop rdi
cmp rax, 1
je .win
add rdi, 32
inc rcx
cmp rcx, 100
jne .loop
.end:
pop rcx
ret
.win:
mov rax, rcx
jmp .end

check:
;rdi - pointer to 32 byte part of board
push rcx
xor rcx, rcx
mov rdx, 0xffffffffffffffff
.vert_setup:
and rdx, qword[rdi + rcx]
add rcx, 5
cmp rcx, 25
jne .vert_setup
mov qword[trash], rdx
xor rcx, rcx
mov rsi, qword[h_win]
xor rax, rax
mov rbx, 1
.loop:
cmp byte[trash + rcx], 0xff
je .win
cmp dword[rdi], esi
jne .next
cmp byte[rdi + 4], sil
je .win
.next:
add rdi, 5
inc rcx
cmp rcx, 5
jne .loop
.end:
pop rcx
ret
.win:
mov rax, 1
jmp .end

count_wins:
push rcx
mov rdi, win
xor rcx, rcx
xor rsi, rsi
.loop:
push rdi
push rsi
call check
pop rsi
pop rdi
add rsi, rax
add rdi, 32
inc rcx
cmp rcx, 100
jne .loop
.end:
pop rcx
mov rax, rsi
ret