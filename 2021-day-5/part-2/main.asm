%include "../IO.asm"

section .data
file_path db "../input.txt", 0
magic_number dq 1717986919
comma db ","

section .bss
file_fd resb 8
temp resb 1024
trash resb 32
plane1 resb 125000
plane2 resb 125000
points resw 4000
x1 resw 1
y1 resw 1
x2 resw 1
y2 resw 1
coord1 resw 1
coord2 resw 1

global _start
%define O_RDONLY 0

%macro setY 0
mov r12, 0xffffffffffffffff
mov r10, 1
cmp si, word[y2]
cmovg r10, r12
mov r12, r10
%endmacro

%macro setX 0
mov r12, 0xffffffffffffffff
mov r11, 1
cmp di, word[x2]
cmovg r11, r12
mov r12, r11
%endmacro

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

xor rcx, rcx
.loop:
lea rdi, [points + rcx * 8]
push rcx
call getLinePoints
pop rcx
inc rcx
cmp rcx, 500
jne .loop

main:

xor rcx, rcx
loop:
mov rax, qword[points + rcx * 8]
mov qword[x1], rax
mov di, word[x1]
mov si, word[y1]
cmp di, word[x2] ;x1 == x2?
jne vertical
horizontal:
;r10 is added to x, r11 is added to y
mov word[coord1], si
mov r11w, word[y2]
mov word[coord2], r11w
setY         ;set Y increment
xor r11, r11 ;set X increment to zero
jmp setLine_pro
vertical:
cmp si, word[y2] ;y1 == y2?
jne diagonal
mov word[coord1], di
mov r11w, word[x2]
mov word[coord2], r11w
setX         ;set X increment
xor r10, r10 ;set Y increment to zero
jmp setLine_pro
diagonal:
mov r10w, di
sub r10w, word[x2]
mov r11w, si
sub r11w, word[y2]
abs r10w
abs r11w
cmp r11w, r10w
jne setLine_pro
mov word[coord1], si
mov r12w, word[y2]
mov word[coord2], r12w
setX
setY
setLine_pro:
add word[coord2], r12w
setLine:
movzx rdi, word[x1]
movzx rsi, word[y1]
call bitPosition
bts word[plane1 + r8], r9w
jnc next
bts word[plane2 + r8], r9w
next:
add word[x1], r11w
add word[y1], r10w
add word[coord1], r12w
mov r8w, word[coord1]
cmp r8w, word[coord2]
jne setLine
skip:
inc rcx
cmp rcx, 500 ;supposed to be 500
jne loop

print_answer:

xor rcx, rcx
xor rdi, rdi
.loop:
mov rax, qword[plane2 + rcx * 8]
popcnt rax, rax
add rdi, rax
inc rcx
cmp rcx, 15625
jne .loop

call print_int
call print_newline

xor rcx, rcx
.debug:
mov rdi, rcx
push rcx
call printPlane1Line
pop rcx
call print_newline
inc rcx
cmp rcx, 1000
jne .debug

close:
mov rax, 3
mov rdi, qword[file_fd]
syscall

exit:
mov rax, 60
xor rdi, rdi
syscall

bitPosition:
;rdi - x pos
;rsi - y pos
push rdi
push rsi
mov rax, rsi
mov rsi, 125
mul rsi
mov rsi, rdi
shr rdi, 3
add rax, rdi
shl rdi, 3
sub rsi, rdi
mov r8, rax
mov r9, rsi
pop rsi
pop rdi
;r8 - byte position
;r9 - bit offset
ret

printPlane1Line:
;rdi - row
mov rax, rdi
mov rdi, 125
mul rdi
lea rdi, [plane1 + rax]
lea rcx, [plane2 + rax]
lea rsi, [rdi + 125]
.loop:
mov al, byte[rdi]
mov bpl, byte[rcx]
xor rbx, rbx
.inner:
bt ax, bx
jnc .set_zero
bt bp, bx
jnc .set_one
mov byte[temp], 0x32
jmp .next
.set_one:
mov byte[temp], 0x31
jmp .next
.set_zero:
mov byte[temp], "."
.next:
pushAll
mov rax, 1
mov rdi, 1
mov rsi, temp
mov rdx, 1
syscall
popAll
inc rbx
cmp rbx, 8
jne .inner
inc rdi
inc rcx
cmp rdi, rsi
jne .loop
ret

printPlane2Line:
;rdi - row
mov rax, rdi
mov rdi, 125
mul rdi
lea rdi, [plane2 + rax]
lea rsi, [rdi + 125]
.loop:
mov al, byte[rdi]
xor rbx, rbx
.inner:
shr al, 1
jnc .set_zero
mov byte[temp], 0x31
jmp .next
.set_zero:
mov byte[temp], "."
.next:
pushAll
mov rax, 1
mov rdi, 1
mov rsi, temp
mov rdx, 1
syscall
popAll
inc rbx
cmp rbx, 8
jne .inner
inc rdi
cmp rdi, rsi
jne .loop
ret