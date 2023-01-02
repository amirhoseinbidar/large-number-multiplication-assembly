org 100h

.data

; base setting -----------------------------------------------------------------

X db 20 dup(?)
Y db 20 dup(?)
X_length dw 0
Y_length dw 0

enter_X_str db "please enter X: $"
enter_Y_str db "please enter Y: $"
new_line db 13, 10, '$'

window_width = 80
window_height = 25

; graphic calculation ---------------------------------------------------------

; maximum length of result of two number's mupltiply is first number length + second number length
; Example:
;    99999 * 999 = 99899001
;        5 + 3   = 8
max_width dw ?

;          X  |
; *        Y  |
; ----------  |
; + Y_length  |
; ----------  |
;     result  |--> total height is 5 + Y_length
max_height dw ?  

two db 2
padding = 3

; multiply numbers -------------------------------------------------------------

result db 40 dup(?)
buffer db 40 dup(?)
carry db ?

; draw_rectangle arguments -----------------------------------------------------

;;; top left point
rectangle_col1 db ?
rectangle_row1 db ?
;;; bottom right point
rectangle_col2 db ?
rectangle_row2 db ?

; draw_horizontal_line or draw_vertical_line arguments -------------------------

line_char db ?
line_start_col db ?
line_start_row db ?
line_length dw ?

; asciify or numberify arguments -----------------------------------------------

array_offset dw ?
array_length dw ?

; rtl_print arguments ----------------------------------------------------------
;;; start point
print_col db ?
print_row db ?
; array_offset also required
; array_length also required

; single_number_multiply_X -----------------------------------------------------
number db ?
zero_pad dw ?
ten db 10
buffer_size dw ?



.code            

; input X and Y ----------------------------------------------------------------

mov dx, offset enter_X_str
mov ah, 09h
int 021h 
mov si, 0
lbl_input_X_loop:
    cmp si, 20
    je lbl_end_input_X_loop
    mov ah, 01h    
    int 021h
    cmp al, 13
    je lbl_end_input_X_loop
    sub al, 48
    mov X[si], al
    inc si
    inc X_length
    jmp lbl_input_X_loop

lbl_end_input_X_loop:
mov dx, offset new_line
mov ah, 09h
int 021h

mov dx, offset enter_Y_str
mov ah, 09h
int 021h 
mov si, 0
lbl_input_Y_loop:
    cmp si, 20
    je lbl_end_input_Y_loop
    mov ah, 01h    
    int 021h
    cmp al, 13
    je lbl_end_input_Y_loop
    sub al, 48
    mov Y[si], al
    inc si
    inc Y_length
    jmp lbl_input_Y_loop

lbl_end_input_Y_loop:
mov dx, offset new_line
mov ah, 09h
int 021h


mov ax, X_length
mov max_width, ax
mov ax, Y_length
add max_width, ax
mov ax, Y_length
mov max_height, ax
add max_height, 5

; draw rectangle ----------------------------------------------------------------

mov ch, window_width / 2 ; column center
mov cl, window_height / 2 ; row center

; find top left point of rectangle

; max_width / 2 + padding 
mov ax, max_width
div two
add al, padding
sub ch, al

; max_height / 2 + padding
mov ax, max_height
div two
add al, padding
sub cl, al
 
mov rectangle_col1, ch
mov rectangle_row1, cl

mov ch, window_width / 2 ; column center
mov cl, window_height / 2 ; row center

; find bottom right point of rectangle

; max_width / 2 + padding 
mov ax, max_width
div two
add al, padding
add ch, al

; max_height / 2 + padding
mov ax, max_height
div two
add al, padding
add cl, al

mov rectangle_col2, ch
mov rectangle_row2, cl

call draw_rectangle


; draw X -----------------------------------------------------------------                  
mov array_offset, offset X
mov ax, X_length
mov array_length, ax
call asciify


; find top right point
mov ch, window_width / 2 ; column center
mov cl, window_height / 2 ; row center

mov ax, max_width
div two
add ch, al

mov ax, max_height
div two
sub cl, al

mov print_col, ch
mov print_row, cl
call rtl_print


; draw Y -----------------------------------------------------------------

mov array_offset, offset Y
mov ax, Y_length
mov array_length, ax
call asciify

inc print_row
call rtl_print

; print * ----------------------------------------------------------------

mov dl, print_col
mov cx, max_width
sub dl, cl
mov dh, print_row
mov bh, 0
mov ah, 2
int 10h

mov ah, 2
mov dl, '*'
int 021h

; draw equation line -----------------------------------------------------

inc print_row
mov cl, print_col
mov line_start_col, cl
mov ax, max_width
dec ax
sub line_start_col, al
mov cl, print_row
mov line_start_row, cl
mov ax, max_width
mov line_length, ax
mov line_char, '-'
call draw_horizontal_line

; print additions ----------------------------------------------------

mov array_offset, offset X
mov ax, X_length
mov array_length, ax
call numberify

mov array_offset, offset Y
mov ax, Y_length
mov array_length, ax
call numberify


mov si, Y_length
dec si
multiply_loop:
    mov cx, Y_length
    dec cx
    sub cx, si
    mov zero_pad, cx
    mov al, Y[si]
    mov number, al
    
    push si
    call single_number_multiply_X

    mov array_offset, offset buffer
    add array_offset, di
    mov ax, buffer_size
    mov array_length, ax
    inc array_length
    call asciify

    inc print_row
    call rtl_print
    
    call numberify
    
    call sum_buffer_result    
    
    ; print + -----
    mov dl, print_col
    mov cx, max_width
    sub dl, cl
    mov dh, print_row
    mov bh, 0
    mov ah, 2
    int 10h

    mov ah, 2
    mov dl, '+'
    int 021h

        
    pop si
    dec si
    cmp si, -1
    jne multiply_loop

; draw equation line -----------------------------------------------------

inc print_row
mov cl, print_col
mov line_start_col, cl
mov ax, max_width
dec ax
sub line_start_col, al
mov cl, print_row
mov line_start_row, cl
mov ax, max_width
mov line_length, ax
mov line_char, '-'
call draw_horizontal_line

; print result -----------------------------------------------------------

mov array_offset, offset result
mov ax, max_width
mov array_length, ax
call asciify

inc print_row
call rtl_print

ret

; helper functions -------------------------------------------------------

proc sum_buffer_result
    call refresh_registers
    mov carry, 0
    mov di, max_width
    dec di
 
    sbr_sum_loop:
        mov ax, 0
        mov al, result[di]
        add al, buffer[di]
        add al, carry
        div ten        
        mov result[di], ah
        mov carry, al

        dec di
        cmp di, -1 
        jne sbr_sum_loop
 
    ret
sum_buffer_result endp 


proc single_number_multiply_X
    call refresh_registers
    mov di, max_width
    dec di
    mov si, X_length
    dec si
    mov carry, 0

    cmp zero_pad, 0
    je snmx_multiply_loop
    mov cx, 0
    snmx_adding_zero_pad:
        mov buffer[di], 0
        dec di
        inc cx
        cmp cx, zero_pad
        jne snmx_adding_zero_pad
    
    mov cx, 0
    snmx_multiply_loop:
        mov al, X[si]
        mul number
        add al, carry
        div ten        
        mov buffer[di], ah
        mov carry, al
        dec di
        dec si
        inc cx
        cmp cx, X_length
        jne snmx_multiply_loop
    
    cmp carry, 0
    je snmx_increase_pointer
    mov al, carry
    mov buffer[di], al 
    jmp snmx_end
    
    snmx_increase_pointer:
        inc di
       
    snmx_end:
    mov ax, max_width       
    mov buffer_size, ax
    dec buffer_size
    sub buffer_size, di
    ret
single_number_multiply_X endp

proc rtl_print
    mov cl, 0
    mov di, array_offset
    add di, array_length
    dec di

    rtlp_loop:
        mov dl, print_col
        mov dh, print_row
        sub dl, cl
        mov bh, 0
        mov ah, 2
        int 10h
        inc cl
        
        mov ah, 2
        mov dl, [di]
        int 021h
        dec di
        
        cmp di, array_offset
        jge rtlp_loop          
    ret    
rtl_print endp

proc asciify
    call refresh_registers

    mov di, array_offset
    mov ax, array_offset
    add ax, array_length

    asf_loop:
        add [di], '0'
        inc di
        cmp di, ax
        jl asf_loop  
    ret        
asciify endp

proc numberify        
    call refresh_registers

    mov di, array_offset
    mov ax, array_offset
    add ax, array_length

    nuf_loop:
        sub [di], '0'
        inc di
        cmp di, ax
        jl nuf_loop  
    ret
numberify endp

proc draw_rectangle
    call refresh_registers
    
    ; draw top horizontal line
    mov line_char, '-'
    mov cl, rectangle_col1
    mov line_start_col, cl
    mov cl, rectangle_row1
    mov line_start_row, cl
 
    mov cl, rectangle_col2 ; calculate line_length
    sub cl, rectangle_col1
    mov ch, 0
    mov line_length, cx
    
    call draw_horizontal_line

    ; draw bottom horizontal line
    mov cl, rectangle_col1
    mov line_start_col, cl
    mov cl, rectangle_row2
    mov line_start_row, cl

    call draw_horizontal_line
    
    ; draw left horizontal line
    mov line_char, '|'
    mov cl, rectangle_col1
    mov line_start_col, cl
    mov cl, rectangle_row1
    mov line_start_row, cl
 
    mov cl, rectangle_row2 ; calculate line_length 
    sub cl, rectangle_row1
    mov ch, 0
    mov line_length, cx
    inc line_length
    
    call draw_vertical_line
    
    ; draw right horizontal line
    mov cl, rectangle_col2
    mov line_start_col, cl
    mov cl, rectangle_row1
    mov line_start_row, cl
    

    call draw_vertical_line    
    ret
draw_rectangle endp
       
proc draw_horizontal_line
    call refresh_registers
    mov dl, line_start_col
    mov dh, line_start_row
    mov bh, 0
    mov ah, 2
    int 10h
    
    dhl_loop:
        mov ah, 02
        mov dl, line_char
        int 021h
        
        inc si  
        cmp si, line_length
        jne dhl_loop       
    ret

draw_horizontal_line endp


proc draw_vertical_line
    call refresh_registers 
    dvl_loop:
        mov dl, line_start_col
        mov dh, line_start_row
        add dh, cl
        mov bh, 0
        mov ah, 2
        int 10h
        
        mov ah, 2
        mov dl, line_char
        int 021h
        
        inc cl  
        cmp cx, line_length
        jne dvl_loop       
    ret
draw_vertical_line endp


proc refresh_registers
    mov ax, 0
    mov bx, 0
    mov cx, 0
    mov dx, 0
    mov si, 0
    mov di, 0
    ret
refresh_registers endp
    