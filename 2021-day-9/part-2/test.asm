%include "../IO.asm"

section .data
file_path db "../test.txt", 0
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
plane times 5 dq 0
basin_plane times 5 dq 0
previous times 50 db 0x30
position dd 0
one dq 1
one_hundred dq 100
loop_counter dq 0
direction_counter dq 0
outer_counter dq 0
basin_size dq 0
point db "x: "
      dq 0x30
      db "y: "
      dq 0x30
      db 10
point_len equ $ - point
fb_msg db "branching", 10
fb_msg_len equ $ - fb_msg
done_msg db "branch finished", 10
done_msg_len equ $ - done_msg
max1 dq 0
max2 dq 0
max3 dq 0

section .bss
file_fd resb 8
trash resb 32
vents resb 50

global _start
%define O_RDONLY 0

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
add rdi, 10
inc qword[loop_counter]
cmp qword[loop_counter], 5
jne .loop

setup_basin_plane:
xor rcx, rcx
mov rdi, previous
.loop:
mov qword[basin_plane + rcx * 8], rdi
add rdi, 10
inc rcx
cmp rcx, 5
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
cmp dil, 9
jg edge
cmp al, 4
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

mov qword[basin_size], 0
sub rsp, 8
mov dword[rsp], r14d     ;xpos
mov dword[rsp + 4], r15d ;ypos
call find_basin
add rsp, 8

pushAll
mov rdi, qword[basin_size]
call print_int
call print_newline
popAll

mov rax, qword[basin_size]
cmp rax, qword[max1]
jg set_max1
cmp rax, qword[max2]
jg set_max2
cmp rax, qword[max3]
jg set_max3
jmp continue

set_max1:
mov rdi, qword[max1]
mov rsi, qword[max2]
mov qword[max3], rsi
mov qword[max2], rdi
mov qword[max1], rax
jmp continue
set_max2:
mov rdi, qword[max2]
mov qword[max3], rdi
mov qword[max2], rax
jmp continue
set_max3:
mov qword[max3], rax

continue:

inc r14
cmp r14, 10
jne inner

inc r15
cmp r15, 5
jne outer

print_answer:

mov rdi, qword[max1]
call print_int
call print_newline
mov rdi, qword[max2]
call print_int
call print_newline
mov rdi, qword[max3]
call print_int
call print_newline

mov rax, qword[max1]
mov rdi, qword[max2]
mul rdi
mov rdi, qword[max3]
mul rdi
mov rdi, rax
call print_int
call print_newline

call print_basin_plane

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
mov rdx, 10
syscall
mov rax, 1
mov rdi, 1
mov rsi, newline
mov rdx, 1
syscall
inc qword[loop_counter]
cmp qword[loop_counter], 5
jne .loop
ret

find_basin:
inc qword[basin_size]
mov edi, dword[rsp + 8]  ;xpos
mov esi, dword[rsp + 12] ;ypos

mov r9, qword[basin_plane + rsi * 8]
mov byte[r9 + rdi], 0x31

sub rsp, 20
mov qword[rsp + 12], rax ;directions
mov dword[rsp + 8], 0    ;loop counter
.loop:

mov ecx, dword[rsp + 8]

mov edi, dword[rsp + 28]
mov esi, dword[rsp + 32]

add dil, byte[array + rcx * 2]
add sil, byte[array + rcx * 2 + 1]

;pushAll
;call itos
;mov qword[point + 3], rax
;popAll
;pushAll
;mov rdi, rsi
;call itos
;mov qword[point + 14], rax
;mov rax, 1
;mov rdi, 1
;mov rsi, point
;mov rdx, point_len
;syscall
;call print_newline
;popAll

cmp dil, 0
jl .loopend
cmp sil, 0
jl .loopend
cmp dil, 9
jg .loopend
cmp sil, 4
jg .loopend
mov r10, qword[plane + rsi * 8]
cmp byte[r10 + rdi], "9"
je .loopend
mov r10, qword[basin_plane + rsi * 8]
cmp byte[r10 + rdi], "0"
jne .loopend

mov dword[rsp], edi
mov dword[rsp + 4], esi

;pushAll
;mov rax, 1
;mov rdi, 1
;mov rsi, fb_msg
;mov rdx, fb_msg_len
;syscall
;popAll

call find_basin

;pushAll
;mov rax, 1
;mov rdi, 1
;mov rsi, done_msg
;mov rdx, done_msg_len
;syscall
;popAll

.loopend:
inc dword[rsp + 8]

mov edi, dword[rsp + 8]

cmp dword[rsp + 8], 4
jne .loop

add rsp, 20
ret

.return:
ret

directions:
;rdi - xpos
;rsi - ypos
xor rcx, rcx
xor rax, rax
.loop:
mov r8, rdi
mov r9, rsi
add r8b, byte[array + rcx * 2]
add r9b, byte[array + rcx * 2 + 1]

cmp r8b, 0
jl .basin_edge
cmp r9b, 0
jl .basin_edge
cmp r8b, 9
jg .basin_edge
cmp r9b, 4
jg .basin_edge
mov r10, qword[plane + r9 * 8]
movzx r10, byte[r10 + r8]
cmp r10, 0x39
je .basin_edge

mov r10, qword[basin_plane + r9 * 8]
cmp byte[r10 + r8], 0x30 ;has the point already been visited
jne .basin_edge

shl rax, 8
mov al, byte[array + rcx * 2]
shl rax, 8
mov al, byte[array + rcx * 2 + 1]

.basin_edge:
inc rcx
cmp rcx, 4
jne .loop
ret

print_basin_plane:
xor rcx, rcx
.loop:
push rcx
mov rax, 1
mov rdi, 1
mov rsi, qword[basin_plane + rcx * 8]
mov rdx, 10
syscall
mov rax, 1
mov rdi, 1
mov rsi, newline
mov rdx, 1
syscall
pop rcx
inc rcx
cmp rcx, 5
jne .loop
ret