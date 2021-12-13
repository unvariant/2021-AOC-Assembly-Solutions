%include "../IO.asm"

section .data
file_path db "../input.txt", 0
magic_number dq 1717986919
length2 dq 0
length3 dq 0
length4 dq 0
length5 times 3 dq 0
length6 times 3 dq 0
length7 dq 0
sort_input_counter dw 0
length5_counter dw 0
length6_counter dw 0
find_seven_counter dw 0
total dq 0
one dq 1
chars db "abcdefg", 0
four_digit_num dd 0
               db 0

length5_decode db 0, 1, 0, 3, 0, 5, 6, 0
               db 0, 0, 2, 3, 4, 0, 6, 0
               db 0, 0, 2, 0, 4, 0, 6, 7

length5_lookup db 0x35
               db 0x32
               db 0x33

section .bss
file_fd resb 8
input resb 5000
output resb 1000
trash resb 32
pos resb 8
posa resb 8
posb resb 8
posc resb 8
posd resb 8
pose resb 8
posf resb 8
posg resb 8

; aaaa 
;b    c
;b    c
; dddd 
;e    f
;e    f
; gggg

global _start
%define O_RDONLY 0

section .text

_start:
mov rax, 2
mov rdi, file_path
mov rsi, O_RDONLY
syscall

mov qword[file_fd], rax

main:

xor rcx, rcx
loop:
push rcx

mov rdi, input
mov rsi, "|"
call read_until_newline

mov rax, 0
mov rdi, qword[file_fd]
mov rsi, trash
mov rdx, 1
syscall

mov rsi, input
mov word[sort_input_counter], 0
mov word[length5_counter], 0
mov word[length6_counter], 0
sort_input:
mov qword[trash], 0
mov rdi, rsi
xor rax, rax
.find_space:
inc rax
cmp byte[rdi + rax], 0x20
jnz .find_space

mov r8, trash
lea rdx, [rdi + rax]
.loop:
mov bl, byte[rdi]
mov byte[r8], bl
inc rdi
inc r8
cmp rdi, rdx
jne .loop

mov rdx, qword[trash]

cmp rax, 5
jg len_6_7
jl len_2_3_4
je len_5

len_2_3_4:
cmp rax, 3
jg len_4
jl len_2
je len_3

len_2:
mov qword[length2], rdx
jmp next

len_3:
mov qword[length3], rdx
jmp next

len_4:
mov qword[length4], rdx
jmp next

len_5:
movzx rbx, word[length5_counter]
mov qword[length5 + rbx * 8], rdx
inc word[length5_counter]
jmp next

len_6_7:
cmp rax, 6
je len_6
jne len_7

len_6:
movzx rbx, word[length6_counter]
mov qword[length6 + rbx * 8], rdx
inc word[length6_counter]
jmp next

len_7:
mov qword[length7], rdx

next:

add rsi, rax
inc rsi
inc word[sort_input_counter]
cmp word[sort_input_counter], 10
jne sort_input

sort_input_end:

;mov rax, 1
;mov rdi, 1
;mov rsi, length2
;mov rdx, 80
;syscall
;call print_newline

mov rdx, qword[length2]
mov qword[posc], rdx
mov qword[posf], rdx

mov rcx, 0
find_seven_loop:
xor rdi, rdi
xor rsi, rsi
mov al, byte[length3 + rcx]
cmp al, byte[length2]
je .next
cmp al, byte[length2 + 1]
je .next
jmp found_seven
.next:
inc rcx
jmp find_seven_loop

found_seven:

mov byte[posa], al

xor rcx, rcx
find_three:
xor rdx, rdx
lea rdi, qword[length5 + rcx * 8]
movzx rsi, byte[posa]
call contains
add rdx, rax
movzx rsi, byte[posc]
call contains
add rdx, rax
movzx rsi, byte[posc + 1]
call contains
add rdx, rax
cmp rdx, 3
je found_three
inc rcx
cmp rcx, 3
jne find_three

found_three:
mov rdi, qword[length5 + rcx * 8]
mov qword[trash], rdi

xor rcx, rcx
xor rbx, rbx
.loop:
mov rdi, length3
movzx rsi, byte[trash + rcx]
call contains
cmp rax, 0
jnz .next
mov byte[posd + rbx], sil
mov byte[posg + rbx], sil
inc rbx
.next:
inc rcx
cmp rcx, 5
jne .loop

xor rcx, rcx
xor rbx, rbx
mov al, byte[posa]
mov byte[trash], al
mov ax, word[posc]
mov word[trash + 1], ax
mov ax, word[posd]
mov word[trash + 3], ax
mov byte[trash + 5], 0
find_last_two:
mov rdi, trash
movzx rsi, byte[chars + rcx]
call contains
cmp rax, 0
jnz .next
mov byte[posb + rbx], sil
mov byte[pose + rbx], sil
inc rbx
.next:
inc rcx
cmp rcx, 7
jne find_last_two

xor rcx, rcx
mov al, byte[posa]
mov byte[trash], al
mov ax, word[posc]
mov word[trash + 1], ax
mov ax, word[posb]
mov word[trash + 3], ax
mov byte[trash + 5], 0
find_zero:
lea rdi, qword[length6 + rcx * 8]
xor rbx, rbx
xor rdx, rdx
.inner:
movzx rsi, byte[trash + rbx]
call contains
add rdx, rax
inc rbx
cmp rbx, 5
jne .inner
cmp rdx, 5
je found_zero
inc rcx
cmp rcx, 3
jne find_zero

found_zero:
lea r9, qword[length6 + rcx * 8]
mov rdi, trash
xor rcx, rcx
.loop:
movzx rsi, byte[r9 + rcx]
call contains
cmp rax, 0
jz found_posg
inc rcx
cmp rcx, 6
jne .loop

found_posg:
mov byte[posg], sil
mov byte[posg + 1], 0
cmp sil, byte[posd]
jne set_posd_second_byte
mov sil, byte[posd + 1]
mov byte[posd], sil
mov byte[posd + 1], 0
set_posd_second_byte:
mov byte[posd + 1], 0

mov al, byte[posd]
mov byte[trash], al
mov ax, word[posc]
mov word[trash + 1], ax
mov byte[trash + 3], 0
four:
mov rdi, length4
movzx rsi, byte[posb]
call contains
cmp rax, 0
jnz found_posb
mov sil, byte[posb + 1]

found_posb:
mov byte[posb], sil
mov byte[posb + 1], 0
cmp sil, byte[pose]
jne set_pose_second_byte
mov sil, byte[pose + 1]
mov byte[pose], sil
mov byte[pose + 1], 0
set_pose_second_byte:
mov byte[pose + 1], 0

mov al, byte[posd]
mov byte[trash], al
mov al, byte[pose]
mov byte[trash + 1], al
mov byte[trash + 2], 0
xor rcx, rcx
find_posf:
lea rdi, qword[length6 + rcx * 8]
xor rbx, rbx
xor rdx, rdx
.inner:
movzx rsi, byte[trash + rbx]
call contains
add rdx, rax
inc rbx
cmp rbx, 2
jne .inner
cmp rdx, 2
je found_six
inc rcx
cmp rcx, 3
jne find_posf

found_six:
lea rdi, qword[length6 + rcx * 8]
movzx rsi, byte[posc]
call contains
cmp rax, 0
jnz set_posf
mov sil, byte[posc + 1]

set_posf:
mov byte[posf], sil
mov byte[posf + 1], 0
cmp sil, byte[posc]
jne set_posc_second_byte
mov sil, byte[posc + 1]
mov byte[posc], sil
mov byte[posc + 1], 0
set_posc_second_byte:
mov byte[posc + 1], 0

;mov rax, 1
;mov rdi, 1
;mov rsi, posa
;mov rdx, 56
;syscall
;call print_newline

mov rdi, output
mov rsi, 10
call read_until_newline

;mov rax, 1
;mov rdi, 1
;mov rsi, output
;mov rdx, 1000
;syscall
;call print_newline

xor r12, r12
xor rcx, rcx
xor rbx, rbx
mov rsi, output
decode:
mov rdi, rsi
xor r11, r11
.find_space:
inc r11
cmp byte[rdi + r11], 0
je .end
cmp byte[rdi + r11], 0x20
jne .find_space
.end:

mov byte[rdi + r11], 0
cmp r11, 2
jne not_digit_one
mov byte[four_digit_num + r12], 0x31
jmp decode_next
not_digit_one:
cmp r11, 3
jne not_digit_seven
mov byte[four_digit_num + r12], 0x37
shl rbx, 8
jmp decode_next
not_digit_seven:
cmp r11, 4
jne not_digit_four
mov byte[four_digit_num + r12], 0x34
jmp decode_next
not_digit_four:
cmp r11, 7
jne not_digit_eight
mov byte[four_digit_num + r12], 0x38
jmp decode_next
not_digit_eight:
cmp r11, 5
jne not_digit_five_two_three

push rsi
push rcx

mov rdi, rsi
movzx rsi, byte[posc]
call contains
cmp rax, 0
jnz set_three_two
mov byte[four_digit_num + r12], 0x35
jmp five.end
set_three_two:
movzx rsi, byte[pose]
call contains
cmp rax, 0
jnz set_two
mov byte[four_digit_num + r12], 0x33
jmp five.end
set_two:
mov byte[four_digit_num + r12], 0x32
five.end:

pop rcx
pop rsi

jmp decode_next

not_digit_five_two_three:
;must be zero / nine / six
push rsi
push rcx

mov rdi, rsi
movzx rsi, byte[posd]
call contains
cmp rax, 0
jnz set_nine_six
mov byte[four_digit_num + r12], 0x30
jmp six.end
set_nine_six:
movzx rsi, byte[posc]
call contains
cmp rax, 0
jnz set_nine
mov byte[four_digit_num + r12], 0x36
jmp six.end
set_nine:
mov byte[four_digit_num + r12], 0x39
six.end:

pop rcx
pop rsi

decode_next:
inc r12
add rsi, r11
inc rsi
inc rcx
cmp rcx, 4
jne decode

mov rdi, four_digit_num
call stoi
add qword[total], rax

pop rcx
inc rcx
cmp rcx, 200
jne loop

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

contains:
;rdi - buffer
;rsi - char to find
push rdi
xor rax, rax
.loop:
mov r8b, byte[rdi]
cmp r8b, sil
cmove rax, qword[one]
inc rdi
cmp r8b, 0
jnz .loop
pop rdi
ret