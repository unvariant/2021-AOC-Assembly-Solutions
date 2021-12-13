%include "../IO.asm"                            ;file with IO subroutines

section .data
file_path db "../input.txt", 0                  ;input file path
magic_number dq 1717986919                      ;magic number for reciprocal multiplication
array db 0, 1                                   ;x + 0, y + 1
      db 0, 255                                 ;x + 0, y - 1
      db 1, 0                                   ;x + 1, y + 0
      db 255, 0                                 ;x - 1, y + 0
plane times 100 dq 0                            ;array of pointers (2D array)
basin_plane times 100 dq 0                      ;array of pointers (2D array)
previous times 10000 db 0x30                    ;100 by 100 plane (previously checked positions)
one dq 1                                        ;used for cmov conditional
loop_counter dq 0                               ;general use loop counter
basin_size dq 0                                 ;used to record size of basin
point db "x: "                                  ;debugging string
      dq 0x30
      db "y: "
      dq 0x30
      db 10
point_len equ $ - point                         ;length of string
fb_msg db "branching", 10                       ;debugging string
fb_msg_len equ $ - fb_msg                       ;length of string
done_msg db "branch finished", 10               ;debugging string
done_msg_len equ $ - done_msg                   ;length of string
max1 dq 0                                       ;largest basin
max2 dq 0                                       ;second largest basin
max3 dq 0                                       ;third largest basin

section .bss
file_fd resb 8                                  ;8 bytes for input file descriptor
trash resb 32                                   ;general use buffer
vents resb 10000                                ;100 by 100 plane

global _start
%define O_RDONLY 0                              ;used with sys_open

section .text

_start:
mov rax, 2                                      ;sys_open
mov rdi, file_path
mov rsi, O_RDONLY
syscall                                         ;open(file_path, O_RDONLY);

mov qword[file_fd], rax                         ;store file descriptor

mov qword[loop_counter], 0                      ;zero loop counter
mov rdi, vents                                  ;mov address of vents
.loop:
call getline                                    ;read first row into buffer
mov rcx, qword[loop_counter]                    ;load current loop counter
mov qword[plane + rcx * 8], rdi                 ;store pointer to current row
add rdi, 100                                    ;next row in buffer to write
inc qword[loop_counter]                         ;incrememnt loop counter
cmp qword[loop_counter], 100                    ;loop 100 times
jne .loop

setup_basin_plane:
xor rcx, rcx                                    ;zero rcx for loop counter
mov rdi, previous                               ;mov addresss of previous
.loop:
mov qword[basin_plane + rcx * 8], rdi           ;store pointer to current row
add rdi, 100                                    ;next row in buffer
inc rcx                                         ;increment loop counter
cmp rcx, 100                                    ;loop 100 times
jne .loop

main:

xor r15, r15                                    ;set ypos to zero
outer:
xor r14, r14                                    ;set xpos to zero
inner:

mov qword[loop_counter], 0                      ;zero loop counter
xor r12, r12                                    ;zero number of greater adjacents
mov rdi, qword[plane + r15 * 8]                 ;load row y in plane
movzx r11, byte[rdi + r14]                      ;load char at position x in row y
check_point:

mov rdi, r14                                    ;mov xpos into rdi
mov rax, r15                                    ;mov ypos into rax
mov r13, qword[loop_counter]                    ;load current loop counter
add dil, byte[array + r13 * 2]                  ;inc/dec x
add al, byte[array + r13 * 2 + 1]               ;inc/dec y

cmp dil, 0                                      ;check is x is less than 0
jl edge
cmp al, 0                                       ;check if y is less than 0
jl edge
cmp dil, 99                                     ;check if x is greater than 99
jg edge
cmp al, 99                                      ;check if y is greater than 99
jng next
edge:                                           ;if found an edge
inc r12                                         ;incrememnt r12
jmp end                                         ;skip lines 99 - 108
next:

mov rsi, qword[plane + rax * 8]                 ;load row rax
movzx rsi, byte[rsi + rdi]                      ;load char at position rsi in row rax

xor rdi, rdi                                    ;zero rdi
cmp r11, rsi                                    ;r11 < rsi ?
cmovl rdi, qword[one]                           ;rdi = 1 : rdi
add r12, rdi                                    ;add rdi to r12

end:

inc qword[loop_counter]                         ;increment loop counter
cmp qword[loop_counter], 4                      ;repeat for every adjacent
jne check_point

cmp r12, 4                                      ;r12 == 4 ?
jne continue                                    ;if not skip lines 118 - 149

mov qword[basin_size], 0                        ;zero basin size
sub rsp, 8                                      ;create 8 bytes of space on stack
mov dword[rsp], r14d                            ;mov xpos onto stack
mov dword[rsp + 4], r15d                        ;mov ypos onto stack
call find_basin                                 ;load size of basin
add rsp, 8                                      ;reset stack

mov rax, qword[basin_size]                      ;load basin size into rax
cmp rax, qword[max1]                            ;rax > max1 ?
jg set_max1
cmp rax, qword[max2]                            ;rax > max2 ?
jg set_max2
cmp rax, qword[max3]                            ;rax > max3 ?
jg set_max3
jmp continue                                    ;if less than all skip lines 134 - 149

set_max1:
mov rdi, qword[max1]
mov rsi, qword[max2]
mov qword[max2], rdi                            ;new max2 = old max1
mov qword[max3], rsi                            ;new max3 = old max2
mov qword[max1], rax                            ;new max1 = rax
jmp continue                                    ;skip lines 141 - 149
set_max2:
mov rdi, qword[max2]
mov qword[max3], rdi                            ;new max3 = old max2
mov qword[max2], rax                            ;new max2 = rax
jmp continue                                    ;skip lines 146 - 149
set_max3:
mov qword[max3], rax                            ;new max3 = rax

continue:

inc r14                                         ;increment xpos
cmp r14, 100                                    ;loop inner 100 times
jne inner

inc r15                                         ;increment ypos
cmp r15, 100                                    ;loop outer 100 times
jne outer

print_answer:

call print_basin_plane                          ;debugging

mov rax, qword[max1]                            ;rax = max1
mov rdi, qword[max2]                            ;rdi = max2
mul rdi                                         ;rax = rax * rdi
mov rdi, qword[max3]                            ;rdi = max3
mul rdi                                         ;rax = rax * rdi
mov rdi, rax
call print_int                                  ;output rax
call print_newline                              ;output newline

close:
mov rax, 3                                      ;sys_close
mov rdi, qword[file_fd]
syscall                                         ;close(file_fd);

exit:
mov rax, 60                                     ;sys_exit
xor rdi, rdi
syscall                                         ;exit(0);

debug:                                          ;outputs out vents 2D array
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

find_basin:                                      ;recursive function to find size of basin
inc qword[basin_size]
mov edi, dword[rsp + 8]                          ;load xpos
mov esi, dword[rsp + 12]                         ;load ypos

mov r9, qword[basin_plane + rsi * 8]
mov byte[r9 + rdi], 0x31

sub rsp, 20                                      ;make space on stack for local variables
mov qword[rsp + 12], rax                         ;directions (not needed anymore)
mov dword[rsp + 8], 0                            ;loop counter
.loop:

mov ecx, dword[rsp + 8]                          ;load loop counter

mov edi, dword[rsp + 28]                         ;load xpos                    
mov esi, dword[rsp + 32]                         ;load ypos

add dil, byte[array + rcx * 2]                   ;inc/dec xpos
add sil, byte[array + rcx * 2 + 1]               ;inc/dec ypos

cmp dil, 0                                       ;xpos < 0 ?
jl .loopend                                      ;if true skip to end of loop
cmp sil, 0                                       ;ypos < 0 ?
jl .loopend                                      ;if true skip to end of loop
cmp dil, 99                                      ;100 < xpos ?
jg .loopend                                      ;if true skip to end of loop
cmp sil, 99                                      ;100 < ypos ?
jg .loopend                                      ;if true skip to end of loop
mov r10, qword[plane + rsi * 8]                  ;load row rsi in normal plane
cmp byte[r10 + rdi], "9"                         ;compare point (rdi, rsi) in plane to char 9
je .loopend                                      ;if equals cha r9 skip to end of loop
mov r10, qword[basin_plane + rsi * 8]            ;load row rsi in basin plane
cmp byte[r10 + rdi], "0"                         ;compare point (rdi, rsi) in basin plane to char 0
jne .loopend                                     ;if not zero skip to loopend

mov dword[rsp], edi                              ;mov xpos onto stack
mov dword[rsp + 4], esi                          ;mov ypos onto stack

call find_basin                                  ;call find_basin

.loopend:
inc dword[rsp + 8]                               ;increment loop counter
cmp dword[rsp + 8], 4                            ;loop for every adjacent
jne .loop

add rsp, 20                                      ;restore stack

.return:
ret                                              ;return from subroutine

print_basin_plane:                               ;outputs of basin plane 2D array
xor rcx, rcx
.loop:
push rcx
mov rax, 1
mov rdi, 1
mov rsi, qword[basin_plane + rcx * 8]
mov rdx, 100
syscall
mov rax, 1
mov rdi, 1
mov rsi, newline
mov rdx, 1
syscall
pop rcx
inc rcx
cmp rcx, 100
jne .loop
ret