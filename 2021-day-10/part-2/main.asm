%include "../IO.asm"

section .data
file_path db "../input.txt", 0
magic_number dq 1717986919
loop_counter dq 0
inner_counter dq 0
invalid_msg db "invalid: "
invalid_msg_len equ $ - invalid_msg
one dq 1
two dq 2
three dq 3
four dq 4
five dq 5
total dq 0
illegal_paran_score dq 1
illegal_bracket_score dq 2
illegal_curly_score dq 3
illegal_tag_score dq 4
array_len dq 0
arr dq 3, 4, 1, 2

section .bss
file_fd resb 8
trash resb 32
buffer resb 1000
array resq 100
tarray resq 100

global _start
%define O_RDONLY 0

section .text

_start:
mov rax, 2
mov rdi, file_path
mov rsi, O_RDONLY
syscall

mov qword[file_fd], rax

mov qword[array], 0xffffffffffffffff

mov qword[loop_counter], 0
main:

mov rdi, buffer
call getline

mov qword[total], 0

mov rbp, rsp
xor rcx, rcx
loop:
mov al, byte[buffer + rcx]

xor rbx, rbx
cmp al, "("
je close_paran
cmp al, "{"
je close_curly
cmp al, "["
je close_bracket
cmp al, "<"
je close_tag
jmp check_close

close_paran:
push ")"
jmp continue
close_curly:
push "}"
jmp continue
close_bracket:
push "]"
jmp continue
close_tag:
push ">"
jmp continue

check_close:

pop rdx
cmp rdx, rax
jne corrupted

continue:

inc rcx
cmp byte[buffer + rcx], 0
jnz loop

loopend:
invalid_loop:
pop rdx
call set_score
call print_illegal
cmp rsp, rbp
jne invalid_loop

mov rax, qword[array_len]
mov rdx, qword[total]
mov qword[array + rax * 8], rdx
inc qword[array_len]

corrupted:

call print_newline
mov rdi, buffer
call strlen
mov rdx, rax
mov rax, 1
mov rdi, 1
mov rsi, buffer
syscall
mov rax, 1
mov rdi, 1
mov rsi, newline
mov rdx, 1
syscall

end:
inc qword[loop_counter]
cmp qword[loop_counter], 94
jne main

print_answer:

sub rsp, 32
mov qword[rsp], array        ;arg 1 - array to sort
mov qword[rsp + 8], tarray   ;arg 2 - temp array
mov qword[rsp + 16], 0       ;arg 3 - start index
mov rdi, qword[array_len]    ;load array length
mov qword[rsp + 24], rdi     ;arg 4 - end index
call merge_sort
add rsp, 32

xor rcx, rcx
.loop:
mov rdi, qword[array + rcx * 8]
push rcx
call itos_buf
mov rdi, trash
call strlen
mov rdx, rax
mov rax, 1
mov rdi, 1
mov rsi, trash
syscall
call print_newline
pop rcx
inc rcx
cmp rcx, qword[array_len]
jne .loop

call print_newline

mov rdi, qword[array_len]
shr rdi, 1
mov rdi, qword[array + rdi * 8]
mov rsi, trash
call itos_buf
mov rdi, trash
call strlen
mov rdx, rax
mov rax, 1
mov rdi, 1
mov rsi, trash
syscall
call print_newline

close:
mov rax, 3
mov rdi, qword[file_fd]
syscall

exit:
mov rax, 60
xor rdi, rdi
syscall

merge_sort:
;qword[rsp + 8],  pointer to array
;qword[rsp + 16], pointer to temp array
;qword[rsp + 24], start index
;qword[rsp + 32], end index

mov r8, qword[rsp + 24] ;start index
mov r9, qword[rsp + 32] ;end index

mov rdi, r9             ;end index
sub rdi, r8             ;subtract start index

cmp rdi, 1              ;if one return
jle .end
shr rdi, 1              ;divide by two
add rdi, r8             ;add back start to calculate mid index
mov rsi, qword[rsp + 8] ;array pointer

sub rsp, 40

mov qword[rsp + 32], rdi ;save mid index

mov rsi, qword[rsp + 48] ;pointer to array
mov qword[rsp], rsi      ;arg 1 - pointer to start
mov rsi, qword[rsp + 56] ;pointer to temp array
mov qword[rsp + 8], rsi  ;arg 2 - pointer to temp
mov rsi, qword[rsp + 64] ;start index
mov qword[rsp + 16], rsi ;arg 3 - start index
mov qword[rsp + 24], rdi ;arg 4 - mid index
call merge_sort

mov rsi, qword[rsp + 48] ;pointer to array
mov qword[rsp], rsi      ;arg 1 - pointer to start
mov rsi, qword[rsp + 56] ;pointer to temp array
mov qword[rsp + 8], rsi  ;arg 2 - pointer to temp
mov rsi, qword[rsp + 32] ;mid index
mov qword[rsp + 16], rsi ;arg 3 - mid index
mov rsi, qword[rsp + 72] ;end index
mov qword[rsp + 24], rsi ;arg 4 - end index
call merge_sort

mov rdi, qword[rsp + 48]
mov rsi, qword[rsp + 56]
mov rdx, qword[rsp + 64]
mov rcx, qword[rsp + 32]
mov r8,  qword[rsp + 72]
call merge

add rsp, 40
.end:
ret

merge:
;rdi - array to sort
;rsi - temp array
;rdx - start index
;rcx - mid index
;r8  - end index
lea r9,  qword[rsi + rdx * 8] ;temp left array
lea r10, qword[rsi + rcx * 8] ;temp right array

mov r11, rcx
sub r11, rdx

xor r15, r15
lea r12, qword[rdi + rdx * 8]
copyleftloop:
mov rax, qword[r12 + r15 * 8]
mov qword[r9 + r15 * 8], rax
inc r15
cmp r15, r11
jne copyleftloop

mov r11, r8
sub r11, rcx

xor r15, r15
lea r12, qword[rdi + rcx * 8]
copyrightloop:
mov rax, qword[r12 + r15 * 8]
mov qword[r10 + r15 * 8], rax
inc r15
cmp r15, r11
jne copyrightloop

xor r11, r11 ;left  array counter
xor r12, r12 ;right array counter
mov r13, rdx ;main array counter
mov r14, rcx ;left max
sub r14, rdx
mov r15, r8  ;right max
sub r15, rcx
mergeloop:
cmp r11, r14
jge mergeloopbreak
cmp r12, r15
jge mergeloopbreak

mov rax, qword[r9 + r11 * 8]
cmp rax, qword[r10 + r12 * 8]

jg mergeright
;jle mergeleft
;mergeleft:

mov qword[rdi + r13 * 8], rax
inc r11
jmp mergeloopend

mergeright:
mov rax, qword[r10 + r12 * 8]
mov qword[rdi + r13 * 8], rax
inc r12

mergeloopend:
inc r13
jmp mergeloop

mergeloopbreak:

cmp r11, r14
jge leftavailableend
leftavailable:
mov rax, qword[r9 + r11 * 8]
mov qword[rdi + r13 * 8], rax
inc r11
inc r13
cmp r11, r14
jl leftavailable

leftavailableend:

cmp r12, r15
jge rightavailableend
rightavailable:
mov rax, qword[r10 + r12 * 8]
mov qword[rdi + r13 * 8], rax
inc r12
inc r13
cmp r12, r15
jl rightavailable

rightavailableend:

ret

print_illegal:
push rcx
mov byte[trash], dl
mov rax, 1
mov rdi, 1
mov rsi, trash
mov rdx, 1
syscall
pop rcx
ret

set_score:
cmp rdx, ")"
cmove r8, qword[one]
cmp rdx, "]"
cmove r8, qword[two]
cmp rdx, "}"
cmove r8, qword[three]
cmp rdx, ">"
cmove r8, qword[four]

push rdx
mov rax, qword[total]
mul qword[five]
add rax, r8
mov qword[total], rax
pop rdx
ret

print_tarray:
pushAll
xor rcx, rcx
.loop:
mov rdi, qword[tarray + rcx * 8]
push rcx
call print_int
call print_newline
pop rcx
inc rcx
cmp rcx, 10
jne .loop
mov rax, 1
mov rdi, 1
mov rsi, newline
mov rdx, 1
syscall
popAll
ret