%include "../IO.asm"

extern malloc
extern realloc
extern free

section .data
file_path db "../input.txt", 0
magic_number dq 1717986919
loop_counter dq 0
debug_counter dq 0
start db "start", 0
end db "end", 0
testNode db "test", 0
mNode dq 0
mNodeSize dq 0
paths dq 0
names dq 0
nodeMsg db "node: "
nodeMsgSize equ $ - nodeMsg
connectMsg db "connection: "
connectMsgSize equ $ - connectMsg
branchMsg db "branching to: "
branchMsgSize equ $ - branchMsg
branches dq 0
one dq 1
space db " "

section .bss
buffer resb 64
trash resb 32
file_fd resb 8
temp1 resb 8
temp2 resb 8

%DEFINE PROT_READ 1
%DEFINE PROT_WRITE 2
%DEFINE RW PROT_READ | PROT_WRITE

global main

section .text

main:

mov rax, 2
mov rdi, file_path
mov rsi, 0
syscall
mov qword[file_fd], rax

mov qword[loop_counter], 0
setup:
mov rdi, temp1
mov rsi, "-"
call read_until_newline

mov rdi, temp1
call  newNode

mov rdi, temp2
mov rsi, 0x0a
call read_until_newline

mov rdi, temp2
call newNode

mov rdi, temp1
mov rsi, temp2
call addConnections

inc qword[loop_counter]
cmp qword[loop_counter], 22
jne setup

mainloop:

mov r12, qword[mNode]
xor rcx, rcx
.loop:
mov rdi, qword[r12 + rcx]
push rcx
call debug
call newline_unsafe
pop rcx
add rcx, 8
cmp rcx, qword[mNodeSize]
jne .loop

sub rsp, 16
mov rdi, start
call nodeExists
mov rdi, qword[mNode]
mov rdi, qword[rdi + rcx]
mov qword[rsp], rdi
mov rdi, 8
call malloc
mov qword[rax], 0
mov qword[rsp + 8], rax
call findPaths
add rsp, 16

mov rax, 3
mov rdi, qword[file_fd]
syscall

print_answer:
mov rdi, qword[branches]
call print_int

exit:
mov rax, 60
xor rdi, rdi
syscall

findPaths:
;qword[rsp + 8]  current node address
;qword[rsp + 16] pointer to array of visited nodes
;(first element of array is its length)

.addCurrent:

mov rdi, qword[rsp + 16]
call copyVisited        ;rax contains new array

mov rdi, qword[rsp + 8]
mov rdi, qword[rdi]     ;pointer to name of node
mov rcx, qword[rax]
mov qword[rax + rcx], rdi

push rax
mov rsi, end
call strcmp
cmp rax, 0
pop rax
jnz .pathEnd

sub rsp, 32              ;make space for local variables
mov qword[rsp + 16], 0   ;initalize loop counter
mov qword[rsp + 24], rax ;save visited nodes
.branchloop:

mov rcx, qword[rsp + 16]   ;get loop counter
mov rdi, qword[rsp + 40]   ;get current node
mov rdi, qword[rdi + 16]   ;get current node connection array
mov rdi, qword[rdi + rcx]  ;get connect node at offset

push rdi
call isLower
pop rdi
cmp rax, 0
jz .branch

push rdi
mov rsi, qword[rdi]
mov rdi, qword[rsp + 32]
call contains
pop rdi
cmp rax, 0
jnz .continue

.branch:
push rdi
mov rax, 1
mov rdi, 1
mov rsi, branchMsg
mov rdx, branchMsgSize
syscall
pop rdi
push rdi
mov rdi, qword[rdi]
call strlen
mov rdx, rax
mov rsi, rdi
mov rax, 1
mov rdi, 1
syscall
call newline_unsafe
pop rdi
mov qword[rsp], rdi
mov rax, qword[rsp + 24]
mov qword[rsp + 8], rax
call findPaths

.continue:
add qword[rsp + 16], 8
mov rdi, qword[rsp + 40]
mov rdi, qword[rdi + 8]
cmp qword[rsp + 16], rdi
jne .branchloop
add rsp, 32

.end:
ret

.pathEnd:
xor rcx, rcx
mov rdx, qword[rax]
.loop:
push rax
push rdx
push rcx
mov rdi, qword[rax + rcx + 8]
call strlen
mov rdx, rax
mov rsi, rdi
mov rax, 1
mov rdi, 1
syscall
call space_unsafe
pop rcx
pop rdx
pop rax
add rcx, 8
cmp rcx, rdx
jne .loop
call newline_unsafe
inc qword[branches]
jmp .end

copyVisited:
;rdi - pointer to array
mov rsi, qword[rdi]
push rdi
push rsi
mov rdi, rsi
add rdi, 16
call malloc
pop rsi       ;length of original array
pop rdi       ;pointer to array
              ;rax new array
mov qword[rax], rsi
add qword[rax], 8
cmp rsi, 0
jz .loopend
mov rcx, 8
add rsi, 8
.loop:
mov rdx, qword[rdi + rcx]
mov qword[rax + rcx], rdx
add rcx, 8
cmp rcx, rsi
jne .loop
.loopend:
ret          ;pointer to new array in rax

contains:
;rdi - pointer to visited array of char pointers
;(first element is length)
;rsi - char pointer of string to find
mov rdx, qword[rdi]
cmp rdx, 0
jz .fail
mov rcx, 8
add rdx, 8
.loop:
push rdi
push rsi
mov rdi, qword[rdi + rcx]
call strcmp
pop rsi
pop rdi
cmp rax, 0
jnz .found
add rcx, 8
cmp rcx, rdx
jne .loop

.fail:
xor rax, rax
.end:
ret

.found:
mov rax, 1
jmp .end

isLower:
;rdi - node address
mov rsi, qword[rdi]
mov sil, byte[rsi]
xor rax, rax
cmp sil, 0x61
cmovg rax, qword[one]
.end:
ret

addConnections:
;rdi - name of node 1
;rsi - name of node 2
push rsi
call nodeExists
mov r8, rcx             ;r8 offset of node 1
pop rdi
call nodeExists
mov r9, rcx             ;r9 offset of node 2
mov rdx, qword[mNode]   ;array of nodes
mov r8, qword[rdx + r8] ;get node 1
mov r9, qword[rdx + r9] ;get node 2

.node1:
push r9
push r8
add qword[r8 + 8], 8
cmp qword[r8 + 8], 8
jne .reallocNode1

mov rdi, 8
call malloc
jmp .node1end

.reallocNode1:

mov rdi, qword[r8 + 16]
mov rsi, qword[r8 + 8]
call realloc

.node1end:
pop r8
mov qword[r8 + 16], rax

.node2:
pop r9
push r8
push r9
add qword[r9 + 8], 8
cmp qword[r9 + 8], 8
jne .reallocNode2

mov rdi, 8
call malloc
jmp .node2end

.reallocNode2:

mov rdi, qword[r9 + 16]
mov rsi, qword[r9 + 8]
call realloc

.node2end:
pop r9
pop r8
mov qword[r9 + 16], rax

.setConnections:
mov rdi, qword[r8 + 8]
mov rsi, qword[r8 + 16]
mov qword[rsi + rdi - 8], r9

mov rdi, qword[r9 + 8]
mov rsi, qword[r9 + 16]
mov qword[rsi + rdi - 8], r8
ret

newNode:
;rdi - name of node
call nodeExists
cmp rax, 0
jnz .end

push rdi                   ;save string
mov rdi, 24
call malloc                ;allocate 24 bytes
pop rdi                    ;restore string

push rax                   ;save pointer to node
call new_string            ;create new string
pop rdi                    ;rdi is now pointer to node

mov qword[rdi], rax        ;move string into node
mov qword[rdi + 8], 0      ;set node length to 0
mov qword[rdi + 16], 0     ;set connections to none

add qword[mNodeSize], 8    ;increment amount of nodes

push rdi                   ;save pointer to node
cmp qword[mNodeSize], 8    ;if no current pointers malloc
jne .realloc               ;else realloc

mov rdi, 8
call malloc
mov qword[mNode], rax
jmp .setPointer

.realloc:
mov rdi, qword[mNode]
mov rsi, qword[mNodeSize]
call realloc
mov qword[mNode], rax

.setPointer:
pop rdi                    ;restore pointer to node
mov rax, qword[mNodeSize]
mov rsi, qword[mNode]
mov qword[rsi + rax - 8], rdi
.end:
ret

nodeExists:
;rdi - node name
xor rax, rax
cmp qword[mNodeSize], 0
jz .end

mov rbx, qword[mNode]
xor rcx, rcx
.loop:
mov rsi, qword[rbx + rcx]
mov rsi, qword[rsi]
push rdi
call strcmp
pop rdi
cmp rax, 0
jnz .end
add rcx, 8
cmp rcx, qword[mNodeSize]
jne .loop

.end:
ret

strcopy:
;rdi - pointer
;rsi - pointer
call strlen
xor rcx, rcx
.loop:
mov bl, byte[rdi + rcx]
mov byte[rsi + rcx], bl
inc rcx
cmp rcx, rax
jne .loop
mov byte[rsi + rcx], 0
ret

strcmp:
;rdi - pointer
;rsi - pointer
;r8 - rdi length
;r9 - rsi length
sub rsp, 16
call strlen
mov qword[rsp], rax
mov qword[rsp + 8], rdi
mov rdi, rsi
call strlen
mov rdi, qword[rsp + 8]
mov qword[rsp + 8], rax
mov rax, qword[rsp]
cmp rax, qword[rsp + 8]
jne .fail

.loop:
cmpsb
jne .fail
cmp byte[rdi], 0
jnz .loop

mov rax, 1

.end:
add rsp, 16
ret

.fail:
xor rax, rax
jmp .end

newline_unsafe:
mov rax, 1
mov rdi, 1
mov rsi, newline
mov rdx, 1
syscall
ret

new_string:
;rdi - pointer to string
call strlen
push rdi
mov rdi, rax
call malloc
pop rdi
push rax
mov rsi, rax
call strcopy
pop rax
ret

debug:
;rdi - node address
mov r10, rdi
mov rax, 1
mov rdi, 1
mov rsi, nodeMsg
mov rdx, nodeMsgSize
syscall

mov rdi, qword[r10]
call strlen
mov rdx, rax
mov rsi, rdi
mov rax, 1
mov rdi, 1
syscall
call newline_unsafe

mov r9, qword[r10 + 16]
mov qword[debug_counter], 0
.loop:
push r9
mov rax, 1
mov rdi, 1
mov rsi, connectMsg
mov rdx, connectMsgSize
syscall
pop r9
push r9
mov rcx, qword[debug_counter]
mov rdi, qword[r9 + rcx]
mov rdi, qword[rdi]
call strlen
mov rdx, rax
mov rsi, rdi
mov rax, 1
mov rdi, 1
syscall
call newline_unsafe
pop r9
add qword[debug_counter], 8
mov rcx, qword[debug_counter]
cmp rcx, qword[r10 + 8]
jne .loop
ret

space_unsafe:
mov rax, 1
mov rdi, 1
mov rsi, space
mov rdx, 1
syscall
ret