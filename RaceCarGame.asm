;MINAHIL BASALAT 24L-3082
;IMAN ABID 24L-0707
[org 0x0100]
jmp start

; ============================================================
; =================== DATA FOR ESC FUNCTIONALITY =============
; ============================================================
old_keyboard_isr dd 0
esc_pressed db 0
exit_confirmed db 0

; Exit confirmation messages
ExitConfirmMsg db "Are you sure you want to exit the game? (Y/N)", 0
ExitScoreMsg db "Final Score: ", 0
ExitThankYouMsg db "Thank you for playing!", 0

; ============================================================
; =================== KEYBOARD INTERRUPT HANDLER =============
; ============================================================
keyboard_isr:
    push ax
    push es
    
    in al, 0x60
    
    cmp al, 0x01
    jne .not_esc
    
    mov byte [cs:esc_pressed], 1
    
    mov al, 0x20
    out 0x20, al
    
    pop es
    pop ax
    iret

.not_esc:
    pop es
    pop ax
    jmp far [cs:old_keyboard_isr]

; ============================================================
; =================== ESC EXIT FUNCTIONALITY =================
; ============================================================
install_keyboard_handler:
    push ax
    push es
    
    xor ax, ax
    mov es, ax
    mov ax, [es:9*4]
    mov [cs:old_keyboard_isr], ax
    mov ax, [es:9*4+2]
    mov [cs:old_keyboard_isr+2], ax
    
    cli
    mov word [es:9*4], keyboard_isr
    mov [es:9*4+2], cs
    sti
    
    pop es
    pop ax
    ret
	
restore_keyboard_handler:
    push ax
    push es
    
    xor ax, ax
    mov es, ax
    cli
    mov ax, [cs:old_keyboard_isr]
    mov [es:9*4], ax
    mov ax, [cs:old_keyboard_isr+2]
    mov [es:9*4+2], ax
    sti
    
    pop es
    pop ax
    ret

check_esc_exit:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push es
    
    cmp byte [cs:esc_pressed], 1
    jne .done
    
    mov byte [cs:esc_pressed], 0
    
    call show_exit_confirmation
    
    cmp byte [cs:exit_confirmed], 1
    jne .done
    
    mov byte [cs:GameActive], 0
    call show_exit_score_screen
    
.done:
    pop es
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

show_exit_confirmation:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push es
    push ds

    push ds
    mov ax, 0xb800
    mov ds, ax
    xor si, si
    
    push es
    mov ax, cs
    mov es, ax
    mov di, ScreenBuffer
    mov cx, 2000
    rep movsw
    pop es
    pop ds
	
    mov ax, 0xb800
    mov es, ax
    xor di, di
    mov cx, 2000
    mov ax, 0x0020      
    rep stosw

    mov di, (8*80 + 22)*2
    mov al, 201         
    mov ah, 0x0E       
    stosw
    mov al, 205        
    mov cx, 34
.top_border:
    stosw
    loop .top_border
    mov al, 187         
    stosw
    mov cx, 5
    mov bx, 9
.draw_sides:
    push cx
    mov ax, bx
    mov cx, 80
    mul cx
    add ax, 22
    shl ax, 1
    mov di, ax
    mov al, 186         
    mov ah, 0x0E
    stosw
    
    add di, 68          
    stosw
    
    inc bx
    pop cx
    loop .draw_sides

    mov di, (14*80 + 22)*2
    mov al, 200         
    mov ah, 0x0E
    stosw
    mov al, 205         
    mov cx, 34
.bottom_border:
    stosw
    loop .bottom_border
    mov al, 188         
    stosw

    mov di, (9*80 + 38)*2
    mov al, '/'
    mov ah, 0x0C        
    stosw
    mov al, '!'
    stosw
    mov al, '\'
    stosw

    mov di, (10*80 + 37)*2
    mov al, '/'
    mov ah, 0x0C
    stosw
    mov al, ' '
    mov ah, 0x00
    stosw
    mov al, '!'
    mov ah, 0x0C
    stosw
    mov al, ' '
    mov ah, 0x00
    stosw
    mov al, '\'
    mov ah, 0x0C
    stosw
	
    mov di, (11*80 + 27)*2
    mov si, .msg1
    mov ah, 0x0F        
.display_msg1:
    lodsb
    test al, al
    jz .display_msg2
    stosw
    jmp .display_msg1

.display_msg2:
    mov di, (12*80 + 31)*2
    mov si, .msg2
    mov ah, 0x0B       
.display_loop2:
    lodsb
    test al, al
    jz .display_prompt
    stosw
    jmp .display_loop2

.display_prompt:
    mov di, (13*80 + 33)*2
    mov si, .prompt
    mov ah, 0x0E        
.display_loop3:
    lodsb
    test al, al
    jz .add_keys
    stosw
    jmp .display_loop3

.add_keys:
    mov di, (13*80 + 45)*2
    mov al, 'Y'
    mov ah, 0x2F        
    stosw
    
    mov di, (13*80 + 47)*2
    mov al, '/'
    mov ah, 0x0E
    stosw
    
    mov di, (13*80 + 48)*2
    mov al, 'N'
    mov ah, 0x4F      
    stosw

.get_input:
    mov ah, 0
    int 16h

    or al, 0x20         
    cmp al, 'y'
    je .confirm_exit
    cmp al, 'n'
    je .cancel_exit
    jmp .get_input

.confirm_exit:
    mov byte [cs:exit_confirmed], 1
    jmp .done

.cancel_exit:
    mov byte [cs:exit_confirmed], 0
    mov ax, cs
    mov ds, ax
    mov si, ScreenBuffer
    mov ax, 0xb800
    mov es, ax
    xor di, di
    mov cx, 2000
    rep movsw

.done:
    pop ds
    pop es
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

.msg1 db 'Are you sure you want to', 0
.msg2 db 'leave the race?', 0
.prompt db 'Press', 0

show_exit_score_screen:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push es
    
    mov ax, 0xb800
    mov es, ax
	
    mov di, 0
    mov cx, 2000
    mov ax, 0x0020      
    rep stosw

    mov di, (5*80 + 33)*2
    mov al, '*'
    mov ah, 0x0E       
    stosw
    stosw
    
    mov di, (5*80 + 37)*2
    mov al, 3           
    mov ah, 0x0C      
    stosw
    stosw
    stosw
    
    mov di, (5*80 + 42)*2
    mov al, '*'
    mov ah, 0x0E        
    stosw
    stosw

    mov di, (7*80 + 30)*2
    mov al, 196         
    mov ah, 0x0E        
    mov cx, 20
.top_line:
    stosw
    loop .top_line

    mov di, (9*80 + 21)*2      
    mov si, .thanks1
    mov cx, 50
    call .draw_banner_line
    
    mov di, (10*80 + 21)*2     
    mov si, .thanks2
    mov cx, 50
    call .draw_banner_line
    
    mov di, (11*80 + 21)*2     
    mov si, .thanks3
    mov cx, 50
    call .draw_banner_line
    
    mov di, (12*80 + 21)*2     
    mov si, .thanks4
    mov cx, 50
    call .draw_banner_line
    
    mov di, (13*80 + 21)*2    
    mov si, .thanks5
    mov cx, 50
    call .draw_banner_line

    mov di, (15*80 + 30)*2
    mov al, 196        
    mov ah, 0x0E        
    mov cx, 20
.bottom_line:
    stosw
    loop .bottom_line

    mov di, (17*80 + 28)*2
    mov al, 201        
    mov ah, 0x0A        
    stosw
    mov al, 205        
    mov cx, 22
.score_top:
    stosw
    loop .score_top
    mov al, 187        
    stosw

    mov di, (18*80 + 28)*2
    mov al, 186         
    mov ah, 0x0A
    stosw
    
    mov di, (18*80 + 31)*2
    mov si, .score_label
    mov ah, 0x0E        
.show_label:
    lodsb
    test al, al
    jz .show_number
    stosw
    jmp .show_label
    
.show_number:
    mov ax, [cs:Score]
    call DisplayNumber
    
    mov di, (18*80 + 51)*2
    mov al, 186         
    mov ah, 0x0A
    stosw

    mov di, (19*80 + 28)*2
    mov al, 200         
    mov ah, 0x0A
    stosw
    mov al, 205        
    mov cx, 22
.score_bottom:
    stosw
    loop .score_bottom
    mov al, 188         
    stosw
	
    mov di, (17*80 + 25)*2
    mov al, '*'
    mov ah, 0x0E      
    stosw
    mov di, (17*80 + 53)*2
    stosw
    mov di, (19*80 + 24)*2
    stosw
    mov di, (19*80 + 54)*2
    stosw
	
    mov di, (21*80 + 34)*2     
    mov si, .drive_msg
    mov ah, 0x0B        
.show_drive:
    lodsb
    test al, al
    jz .show_prompt
    stosw
    jmp .show_drive

.show_prompt:
    mov di, (23*80 + 27)*2
    mov si, .press_key
    mov ah, 0x0F        
.show_key_prompt:
    lodsb
    test al, al
    jz .wait_exit
    stosw
    jmp .show_key_prompt
    
.wait_exit:
    mov ah, 0
    int 16h
    
    pop es
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
	
.draw_banner_line:
    push cx
.banner_loop:
    lodsb
    cmp al, '#'
    je .draw_block
    mov al, ' '
    mov ah, 0x00
    jmp .store_banner
.draw_block:
    mov al, 219        
    mov ah, 0x0D        
.store_banner:
    stosw
    loop .banner_loop
    pop cx
    ret

.thanks1 db '##### #   #  ###  #   # #   #  ####              '
.thanks2 db '  #   #   # #   # ##  # #  #  #                  '
.thanks3 db '  #   ##### ##### # # # ###    ###               '
.thanks4 db '  #   #   # #   # #  ## #  #      #              '
.thanks5 db '  #   #   # #   # #   # #   # ####               '
.score_label db 'YOUR SCORE: ', 0
.drive_msg db 'Drive Safe!', 0
.press_key db '[ Press Any Key to Exit ]', 0

; ============================================================
; =================== LOADING SCREEN =========================
; ============================================================

game_title1 db '##### #   # ####  ####   ###      ####  #   # #### #   #'
game_title1_len equ 57

game_title2 db '  #   #   # #   # #   # #   #     #   # #   # #    #   #'
game_title2_len equ 57

game_title3 db '  #   #   # ####  ####  #   #     ####  #   # #### #####'
game_title3_len equ 57

game_title4 db '  #   #   # #   # #   # #   #     #  #  #   #    # #   #'
game_title4_len equ 57

game_title5 db '  #    ###  #   # ####   ###      #   #  ###  #### #   #'
game_title5_len equ 57

name1 db 'IMAN ABID (24L-0707)'
name1_len equ 20

name2 db 'MINAHIL BASALAT (24L-3082)'
name2_len equ 26

section_info db 'BSSE-3B FALL-25'
section_info_len equ 15

loading_text db 'LOADING...'
loading_text_len equ 10

press_any_key_msg db 'Press Any Key to Start'
press_any_key_len equ 22

long_delay:
    push cx
    mov cx, 3
long_delay_outer:
    push cx
    mov cx, 0FFFFh
long_delay_inner:
    dec cx
    jnz long_delay_inner
    pop cx
    loop long_delay_outer
    pop cx
    ret

; =============================================
;  Loading Screen
; =============================================
show_loading_screen:
    push ax
    push bx
    push cx
    push dx
    push di
    push si
    push es
    
    mov ax, 0B800h
    mov es, ax
    
    xor di, di
    mov cx, 2000
    mov ax, 1120h
    rep stosw
    
    mov di, (8 * 80 + 12) * 2
    mov si, game_title1
    mov cx, game_title1_len
    call draw_title_line
    
    mov di, (9 * 80 + 12) * 2
    mov si, game_title2
    mov cx, game_title2_len
    call draw_title_line
    
    mov di, (10 * 80 + 12) * 2
    mov si, game_title3
    mov cx, game_title3_len
    call draw_title_line
    
    mov di, (11 * 80 + 12) * 2
    mov si, game_title4
    mov cx, game_title4_len
    call draw_title_line
    
    mov di, (12 * 80 + 12) * 2
    mov si, game_title5
    mov cx, game_title5_len
    call draw_title_line

    mov di, (15 * 80 + 35) * 2
    mov si, loading_text
    mov cx, loading_text_len
display_loading:
    lodsb
    mov ah, 1Fh
    stosw
    loop display_loading
	
    mov di, (19 * 80 + 20) * 2
    mov al, 176
    mov ah, 18h
    mov cx, 40
draw_bar_bg:
    stosw
    loop draw_bar_bg
    call animate_loading_bar_with_flag
    mov di, (21 * 80 + 30) * 2
    mov si, name1
    mov cx, name1_len
display_name1:
    lodsb
    mov ah, 17h
    stosw
    loop display_name1
    
    mov di, (22 * 80 + 27) * 2
    mov si, name2
    mov cx, name2_len
display_name2:
    lodsb
    mov ah, 17h
    stosw
    loop display_name2
    
    ; Display section info (BSSE-3B FALL-25)
    mov di, (23 * 80 + 30) * 2
    mov si, section_info
    mov cx, section_info_len
display_section:
    lodsb
    mov ah, 17h  ; Same color as names
    stosw
    loop display_section
    
    mov di, (24 * 80 + 27) * 2
    mov si, press_any_key_msg
    mov cx, press_any_key_len
display_press_key:
    lodsb
    mov ah, 1Eh
    stosw
    loop display_press_key
    
    pop es
    pop si
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; =============================================
; Draw Title Line
; =============================================
draw_title_line:
    push ax
    push cx
draw_title_loop:
    lodsb
    cmp al, '#'
    je draw_solid_block
    cmp al, ' '
    je draw_space_block
    mov al, ' '
    mov ah, 11h
    jmp store_char
draw_solid_block:
    mov al, 219     
    mov ah, 1Eh     
    jmp store_char
draw_space_block:
    mov al, ' '
    mov ah, 11h     
store_char:
    stosw
    loop draw_title_loop
    pop cx
    pop ax
    ret

draw_flag_at_position:
    push ax
    push bx
    push cx
    push di
    
    mov ax, 16
    mov cx, 80
    mul cx
    add ax, bx
    shl ax, 1
    mov di, ax
    
    mov al, 219
    mov ah, 1Fh    
    stosw
    stosw
    mov ah, 10h     
    stosw
    stosw
    
    mov ax, 17
    mov cx, 80
    mul cx
    add ax, bx
    shl ax, 1
    mov di, ax
    
    mov al, 219
    mov ah, 10h    
    stosw
    stosw
    mov ah, 1Fh     
    stosw
    stosw
    
    mov ax, 18
    mov cx, 80
    mul cx
    add ax, bx
    shl ax, 1
    mov di, ax
    
    mov al, 219
    mov ah, 1Fh     
    stosw
    stosw
    mov ah, 10h    
    stosw
    stosw
    
    pop di
    pop cx
    pop bx
    pop ax
    ret

clear_flag_at_position:
    push ax
    push bx
    push cx
    push di
   
    mov ax, 16
    mov cx, 80
    mul cx
    add ax, bx
    shl ax, 1
    mov di, ax
    
    mov al, ' '
    mov ah, 11h   
    stosw
    stosw
    stosw
    stosw
    
    mov ax, 17
    mov cx, 80
    mul cx
    add ax, bx
    shl ax, 1
    mov di, ax
    
    mov al, ' '
    mov ah, 11h
    stosw
    stosw
    stosw
    stosw
    
    mov ax, 18
    mov cx, 80
    mul cx
    add ax, bx
    shl ax, 1
    mov di, ax
    
    mov al, ' '
    mov ah, 11h
    stosw
    stosw
    stosw
    stosw
    
    pop di
    pop cx
    pop bx
    pop ax
    ret

; =============================================
; Animated Loading Bar with Moving Flag
; =============================================
animate_loading_bar_with_flag:
    push ax
    push bx
    push cx
    push di
    mov bx, 20    
    mov cx, 40      
    
animate_bar_loop:
    push cx
    call draw_flag_at_position
	
    mov ax, 19
    push cx
    mov cx, 80
    mul cx
    pop cx
    add ax, bx
    shl ax, 1
    mov di, ax
    
    mov al, 219
    mov ah, 1Ah     
    stosw
    call long_delay
    call clear_flag_at_position
    inc bx
    pop cx
    loop animate_bar_loop

    call draw_flag_at_position
    
    pop di
    pop cx
    pop bx
    pop ax
    ret

; ============================================================
; =================== DATA SECTION ===========================
; ============================================================

GameOverMsg db "GAME OVER! Final Score: ",0
PressAnyKeyMsg db "Press any key to exit",0

offset dw 0
TreeOffsets dw 2408, 3226, 1106, 2528, 3346
TreeCount equ 5

Lane1Offsets dw 62,222,382,542,702,862,1022,1182,1342,1502,1662,1822,1982,2142,2302,2462,2622,2782,2942,3102,3262,3422,3582,3742,3902
Lane2Offsets dw 90,250,410,570,730,890,1050,1210,1370,1530,1690,1850,2010,2170,2330,2490,2650,2810,2970,3130,3290,3450,3610,3770,3930
LaneCount equ 25

RockOffsets dw (9*80 + 15), (14*80 + 15), (9*80 + 63), (14*80 + 63)
RockCount equ 4

RiverRow equ 12
RowBuffer times 160 db 0
ScreenBuffer times 4000 db 0   ; 80*25*2 = 4000 bytes

; ===================== PLAYER CAR STATE ======================

PLAYER_CAR_WIDTH equ 7
PLAYER_CAR_HEIGHT equ 6
CAR_MIN_COL equ 26
CAR_MAX_COL equ 48
CAR_STEP equ 11
CarCol dw 37

; ===================== GAME STATE ===========================
Score dw 0
GameActive db 1

LeftEnemy1Active db 0
LeftEnemy1Y dw 0
LeftEnemy2Active db 0
LeftEnemy2Y dw 0

MidEnemy1Active db 0
MidEnemy1Y dw 0
MidEnemy2Active db 0
MidEnemy2Y dw 0

RightEnemy1Active db 0
RightEnemy1Y dw 0
RightEnemy2Active db 0
RightEnemy2Y dw 0

LaneState db 0
SpawnTimer dw 0

LARGE_CAR_WIDTH equ 7
LARGE_CAR_HEIGHT equ 6

LANE_LEFT_COL equ 26
LANE_MID_COL equ 37
LANE_RIGHT_COL equ 48

MIN_VERTICAL_GAP equ 15
MIN_HORIZONTAL_GAP equ 3
BASE_SPAWN_DELAY equ 5

RandomSeed dw 0x1234
; TIMER ISR VARIABLES
old_timer_isr   dd 0          
GameTick        db 0       
TickCounter     dw 0          

BonusActive db 0
BonusRow dw 0
BonusCol dw 0
BonusSpawnCounter dw 0
BONUS_SPAWN_RATE equ 60     
BONUS_CHAR equ '$'
BONUS_COLOR equ 0x0E          

; Car drawing parameters
car_row dw 0
car_col dw 0  
car_color db 0
; Music variables
MusicCounter dw 0
MUSIC_DELAY equ 10  

draw_car:
    pusha
    mov ax, 0B800h
    mov es, ax
    mov bx, 80
    mov ax, [car_row]
    mul bx
    add ax, [car_col]
    shl ax, 1
    mov di, ax
    mov al, 219
    mov ah, [car_color]
    mov cx, 5
draw_car_row0:
    mov [es:di], ax
    add di, 2
    loop draw_car_row0
    mov ax, [car_row]
    inc ax
    mul bx
    add ax, [car_col]
    dec ax
    shl ax, 1
    mov di, ax
    mov al, '0'
    mov ah, 0Fh
    mov [es:di], ax
    add di, 2
    mov al, 219
    mov ah, 00h
    mov cx, 5
draw_car_row1_body:
    mov [es:di], ax
    add di, 2
    loop draw_car_row1_body
    mov al, '0'
    mov ah, 0Fh
    mov [es:di], ax
    mov cx, 2
    mov si, 2
draw_car_rows2_3:
    mov ax, [car_row]
    add ax, si
    mul bx
    add ax, [car_col]
    shl ax, 1
    mov di, ax
    mov al, 219
    mov ah, [car_color]
    mov dx, 5
draw_car_body_loop:
    mov [es:di], ax
    add di, 2
    dec dx
    jnz draw_car_body_loop
    inc si
    loop draw_car_rows2_3
	
    mov ax, [car_row]
    add ax, 4
    mul bx
    add ax, [car_col]
    dec ax
    shl ax, 1
    mov di, ax
    mov al, '0'
    mov ah, 0Fh
    mov [es:di], ax
    add di, 2
    mov al, 219
    mov ah, 00h
    mov cx, 5
draw_car_row4_body:
    mov [es:di], ax
    add di, 2
    loop draw_car_row4_body
    mov al, '0'
    mov ah, 0Fh
    mov [es:di], ax

    mov ax, [car_row]
    add ax, 5
    mul bx
    add ax, [car_col]
    shl ax, 1
    mov di, ax
    mov al, 219
    mov ah, [car_color]
    mov cx, 5
draw_car_row5:
    mov [es:di], ax
    add di, 2
    loop draw_car_row5

    popa
    ret

; ============================================================
; ================= GAME SCREEN SUBROUTINES ==================
; ============================================================

ClearScreen:
    push ax
    push cx
    push di
    mov di, 0
    mov cx, 80*25
    mov ah, 0x07
    mov al, ' '
    rep stosw
    pop di
    pop cx
    pop ax
    ret

DrawLeftLandscape:
    mov cx, 25
    xor di, di
row_loop_left:
    mov bx, 20
col_loop_left:
    mov al, 177
    mov ah, 0x02
    stosw
    dec bx
    jnz col_loop_left
    add di, (80-20)*2
    loop row_loop_left
    ret

DrawRightLandscape:
    mov cx, 25
    xor si, si
row_loop_right:
    mov ax, si
    mov bx, 80
    mul bx
    add ax, 60
    shl ax, 1
    mov di, ax
    mov bx, 20
col_loop_right:
    mov al, 177
    mov ah, 0x02
    stosw
    dec bx
    jnz col_loop_right
    inc si
    loop row_loop_right
    ret

DrawBlackMiddle:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push es

    mov ax, 0xb800
    mov es, ax

    mov cx, 25                  
    xor si, si                  
    mov word [cs:offset], 0     

row_loop:
    mov bx, 20                 
    mov ax, si
    mov di, 80
    mul di
    add ax, bx
    shl ax, 1
    mov di, ax

col_loop:
    mov dx, bx
    sub dx, 20                  
    
    cmp dx, 0
    je road_border
    
    cmp dx, 39
    je road_border
    
    cmp dx, 13
    je lane_bar
    
    cmp dx, 26
    je lane_bar
    
    jmp road_body

road_border:
    mov ax, si
    add ax, [cs:offset]
    and ax, 1
    test ax, ax
    jz border_red
    mov al, 219
    mov ah, 0Fh             
    jmp write_cell

border_red:
    mov al, 219
    mov ah, 04h               
    jmp write_cell

lane_bar:
    mov al, 179                
    mov ah, 07h                
    jmp write_cell

road_body:
    mov al, 176               
    mov ah, 08h                
    jmp write_cell

write_cell:
    mov [es:di], ax
    add di, 2
    inc bx
    cmp bx, 60                  
    jl col_loop
    
    inc si
    loop row_loop

    pop es
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
	
DrawAllTrees:
    push cx
    push si
    mov cx, TreeCount
    mov si, TreeOffsets
DrawTreesLoop:
    mov ax, [si]
    call DrawTree
    add si, 2
    loop DrawTreesLoop
    pop si
    pop cx
    ret
DrawAllRocks:
    push cx
    push si
    mov cx, RockCount
    mov si, RockOffsets
DrawRocksLoop:
    mov ax, [si]
    call DrawRock
    add si, 2
    loop DrawRocksLoop
    pop si
    pop cx
    ret
DrawRock:
    push ax
    push di
    mov di, ax
    shl di, 1
    mov ah, 0x02
    mov al, 177
    stosw
    pop di
    pop ax
    ret

DrawTree:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    mov di, ax
    mov bx, di
    mov ah, 0x2E
    mov al, '^'
    stosw
    mov si, bx
    add si, 160
    sub si, 2
    mov di, si
    mov cx, 3
    mov ah, 0x2E
    mov al, '^'
row2_loop:
    stosw
    loop row2_loop
    mov si, bx
    add si, 320
    sub si, 4
    mov di, si
    mov cx, 5
    mov ah, 0x2E
    mov al, '^'
row3_loop:
    stosw
    loop row3_loop
    mov si, bx
    add si, 480
    sub si, 6
    mov di, si
    mov cx, 7
    mov ah, 0x2E
    mov al, '^'
row4_loop:
    stosw
    loop row4_loop
    mov si, bx
    add si, 640
    mov di, si
    mov al, '|'
    mov ah, 0x6E
    stosw
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

DrawAllLanes:
    mov cx, LaneCount
LaneLoop:
    mov ax, [si]
    call DrawLane
    add si, 2
    loop LaneLoop
    ret

DrawLane:
    push ax
    push di
    mov di, ax
    mov ah, 0x0F
    mov al, '|'
    stosw
    pop di
    pop ax
    ret

; ============================================================
; ===================== CAR DRAWING ==========================
; ============================================================

DrawGameCar:
    push ax
    push bx
    push cx
    push dx
    push di
    mov ax, 0xb800
    mov es, ax
    
    mov word [car_row], 18
    mov ax, [cs:CarCol]
    mov word [car_col], ax
    mov byte [car_color], 0x0F  
    call draw_car
    
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

ClearCarAtCurrentPosition:
    push ax
    push bx
    push cx
    push dx
    push di
    push si
    mov ax, 0xb800
    mov es, ax
    mov bx, [cs:CarCol]
    mov cx, 6
    mov dx, 18  
clear_car_rows:
    push cx
    push dx
    
    ; Calculate row position
    mov ax, dx
    mov cx, 80
    mul cx
    add ax, bx
    dec ax  
    shl ax, 1
    mov di, ax
    
    mov si, bx
    dec si  
    mov cx, 7
clear_car_cols:
    push cx
    push di
    push si
    
    ; Determine road pattern based on column
    mov ax, si  ; current column
    sub ax, 20 
    
    cmp ax, 0
    je .car_border
    cmp ax, 39
    je .car_border
    cmp ax, 13
    je .car_lane_marker
    cmp ax, 26
    je .car_lane_marker
    jmp .car_road_body
    
.car_border:
    mov cx, dx
    add cx, [cs:offset]
    and cx, 1
    jz .car_red_border
    mov ax, 0x0FDB  
    jmp .car_draw
    
.car_red_border:
    mov ax, 0x04DB 
    jmp .car_draw
    
.car_lane_marker:
    mov ax, 0x07B3 
    jmp .car_draw
    
.car_road_body:
    mov ax, 0x08B0  
    
.car_draw:
    mov [es:di], ax
    
    pop si
    pop di
    pop cx
    
    add di, 2
    inc si
    loop clear_car_cols
    
    pop dx
    pop cx
    inc dx
    loop clear_car_rows
    
    pop si
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret
; ============================================================
; ================= SCORE DISPLAY ============================
; ============================================================

UpdateScoreDisplay:
    push ax
    push bx
    push cx
    push di
    mov ax, 0xb800
    mov es, ax
    mov di, (0*80 + 2)*2
    mov ah, 0x0F
    mov al, 'S'
    stosw
    mov al, 'c'
    stosw
    mov al, 'o'
    stosw
    mov al, 'r'
    stosw
    mov al, 'e'
    stosw
    mov al, ':'
    stosw
    mov al, ' '
    stosw
    mov ax, [cs:Score]
    call DisplayNumber
    pop di
    pop cx
    pop bx
    pop ax
    ret

DisplayNumber:
    push ax
    push bx
    push cx
    push dx
    mov bx, 10
    mov cx, 0
    cmp ax, 0
    jne .convert
    mov ah, 0x0F
    mov al, '0'
    stosw
    jmp .done
.convert:
    xor dx, dx
    div bx
    add dl, '0'
    push dx
    inc cx
    test ax, ax
    jnz .convert
.display:
    pop ax
    mov ah, 0x0F
    stosw
    loop .display
.done:
    pop dx
    pop cx
    pop bx
    pop ax
    ret

IncrementScore:
    push ax
    mov ax, [cs:Score]
    inc ax
    mov [cs:Score], ax
    call UpdateScoreDisplay
	call SoundScore
    pop ax
    ret

; ============================================================
; ================= GAME OVER SCREEN =========================
; ============================================================

ShowGameOver:
    push ax
    push bx
    push cx
    push dx
    push di
    push si
    push es
    call SoundGameOver
    mov ax, 0xb800
    mov es, ax
	
    mov di, 0
    mov cx, 2000
    mov ax, 0x0020 
    rep stosw
    
    ; Line 1 of GAME OVER (row 7)
    mov di, (7*80 + 12)*2
    mov si, .game_over_line1
    call .draw_game_over_line
    
    ; Line 2 (row 8)
    mov di, (8*80 + 12)*2
    mov si, .game_over_line2
    call .draw_game_over_line
    
    ; Line 3 (row 9)
    mov di, (9*80 + 12)*2
    mov si, .game_over_line3
    call .draw_game_over_line
    
    ; Line 4 (row 10)
    mov di, (10*80 + 12)*2
    mov si, .game_over_line4
    call .draw_game_over_line
    
    ; Line 5 (row 11)
    mov di, (11*80 + 12)*2
    mov si, .game_over_line5
    call .draw_game_over_line
	
    mov di, (14*80 + 25)*2
    mov al, 201  
    mov ah, 0x0C 
    stosw
    mov al, 205  
    mov cx, 28
.top_border:
    stosw
    loop .top_border
    mov al, 187  
    stosw
    mov di, (15*80 + 25)*2
    mov al, 186
    mov ah, 0x0C
    stosw
    mov di, (15*80 + 54)*2
    stosw
    mov di, (16*80 + 25)*2
    mov al, 200  
    mov ah, 0x0C
    stosw
    mov al, 205
    mov cx, 28
.bottom_border:
    stosw
    loop .bottom_border
    mov al, 188  
    stosw
    mov di, (15*80 + 28)*2
    mov si, .final_score_text
    mov ah, 0x0E  
.display_score_text:
    lodsb
    cmp al, 0
    je .display_score_value
    stosw
    jmp .display_score_text
    
.display_score_value:
    mov ax, [cs:Score]
    call DisplayNumber
    mov di, (19*80 + 27)*2
    mov si, .press_key_text
    mov ah, 0x0F  
.display_press:
    lodsb
    cmp al, 0
    je .add_decorations
    stosw
    jmp .display_press
    
.add_decorations:
    mov di, (19*80 + 24)*2
    mov al, 02h  ; smiley face symbol
    mov ah, 0x0C  
    stosw
    
    mov di, (19*80 + 52)*2
    stosw
    
    ; Add stars around
    mov di, (6*80 + 20)*2
    mov al, '*'
    mov ah, 0x0E  
    stosw
    mov di, (6*80 + 60)*2
    stosw
    mov di, (12*80 + 18)*2
    stosw
    mov di, (12*80 + 62)*2
    stosw
    
    mov di, (13*80 + 15)*2
    mov al, 'X'
    mov ah, 0x0C  
    stosw
    mov di, (13*80 + 65)*2
    stosw
    
.wait_key:
    mov ah, 0
    int 16h
    pop es
    pop si
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

.draw_game_over_line:
    push cx
    mov cx, 56  
.draw_loop:
    lodsb
    cmp al, '#'
    je .draw_block
    cmp al, ' '
    je .draw_space
    mov al, ' '
    mov ah, 0x00
    jmp .store
.draw_block:
    mov al, 219  
    mov ah, 0x0C  
    jmp .store
.draw_space:
    mov al, ' '
    mov ah, 0x00
.store:
    stosw
    loop .draw_loop
    pop cx
    ret

.game_over_line1 db ' ####   ###  #   # ####    ###  #   # #### ####    '
.game_over_line2 db '#     #   # ## ## #      #   # #   # #    #   #    '
.game_over_line3 db '#  ## ##### # # # ####   #   # #   # #### ####     '
.game_over_line4 db '#   # #   # #   # #      #   #  # #  #    #  #     '
.game_over_line5 db ' #### #   # #   # ####    ###    #   #### #   #    '
.final_score_text db 'FINAL SCORE: ', 0
.press_key_text db 'Press Any Key to Exit', 0

; ============================================================
; ================= SMART SPAWN SYSTEM =======================
; ============================================================

InitSpawnSystem:
    push ax
    push bx
    mov ah, 0x00
    int 0x1A
    mov [cs:RandomSeed], dx
    mov byte [cs:LaneState], 0
    mov word [cs:SpawnTimer], 0
    mov byte [cs:LeftEnemy1Active], 0
    mov byte [cs:LeftEnemy2Active], 0
    mov byte [cs:MidEnemy1Active], 0
    mov byte [cs:MidEnemy2Active], 0
    mov byte [cs:RightEnemy1Active], 0
    mov byte [cs:RightEnemy2Active], 0
    pop bx
    pop ax
    call InitBonusSystem
    ret

GetRandom:
    push dx
    push cx
    push bx
    mov ax, [cs:RandomSeed]
    mov cx, 75
    mul cx
    add ax, 74
    mov [cs:RandomSeed], ax
    pop bx
    pop cx
    pop dx
    ret

GetRandomLane:
    push ax
    push dx
    call GetRandom
    xor dx, dx
    mov cx, 3
    div cx
    mov bl, dl
    pop dx
    pop ax
    ret

SpawnEnemyCars:
    push ax
    push bx
    push cx
    mov ax, [cs:SpawnTimer]
    cmp ax, 0
    jle .trySpawn
    dec word [cs:SpawnTimer]
    jmp .done
.trySpawn:
    call GetRandomLane
    cmp bl, 0
    je .tryLeft
    cmp bl, 1
    je .tryMid
    jmp .tryRight
.tryLeft:
    call TrySpawnInLeftLane
    cmp al, 1
    je .spawnSuccess
    jmp .tryAnother
.tryMid:
    call TrySpawnInMidLane
    cmp al, 1
    je .spawnSuccess
    jmp .tryAnother
.tryRight:
    call TrySpawnInRightLane
    cmp al, 1
    je .spawnSuccess
    jmp .tryAnother
.tryAnother:
    call GetRandom
    and ax, 0x0F
    add ax, 5
    mov [cs:SpawnTimer], ax
    jmp .done
.spawnSuccess:
    call GetRandom
    and ax, 0x1F
    add ax, BASE_SPAWN_DELAY
    mov [cs:SpawnTimer], ax
.done:
    pop cx
    pop bx
    pop ax
    ret

TrySpawnInLeftLane:
    push bx
    cmp byte [cs:LeftEnemy1Active], 1
    jne .trySlot1
    cmp byte [cs:LeftEnemy2Active], 1
    jne .trySlot2
    mov al, 0
    jmp .done
.trySlot1:
    cmp byte [cs:LeftEnemy2Active], 0
    je .checkHorizontal1
    mov ax, [cs:LeftEnemy2Y]
    cmp ax, MIN_VERTICAL_GAP
    jl .trySlot2
    jmp .checkHorizontal1
.trySlot2:
    cmp byte [cs:LeftEnemy1Active], 0
    je .checkHorizontal2
    mov ax, [cs:LeftEnemy1Y]
    cmp ax, MIN_VERTICAL_GAP
    jl .cannotSpawn
    jmp .checkHorizontal2
.checkHorizontal1:
    call CheckHorizontalSpacing
    cmp al, 0
    je .trySlot2
    mov byte [cs:LeftEnemy1Active], 1
    mov word [cs:LeftEnemy1Y], -6 
    mov al, 1
    jmp .done
.checkHorizontal2:
    call CheckHorizontalSpacing
    cmp al, 0
    je .cannotSpawn
    mov byte [cs:LeftEnemy2Active], 1
    mov word [cs:LeftEnemy2Y], -6  
    mov al, 1
    jmp .done
.cannotSpawn:
    mov al, 0
.done:
    pop bx
    ret

TrySpawnInMidLane:
    push bx
    cmp byte [cs:MidEnemy1Active], 1
    jne .trySlot1
    cmp byte [cs:MidEnemy2Active], 1
    jne .trySlot2
    mov al, 0
    jmp .done
.trySlot1:
    cmp byte [cs:MidEnemy2Active], 0
    je .checkHorizontal1
    mov ax, [cs:MidEnemy2Y]
    cmp ax, MIN_VERTICAL_GAP
    jl .trySlot2
    jmp .checkHorizontal1
.trySlot2:
    cmp byte [cs:MidEnemy1Active], 0
    je .checkHorizontal2
    mov ax, [cs:MidEnemy1Y]
    cmp ax, MIN_VERTICAL_GAP
    jl .cannotSpawn
    jmp .checkHorizontal2
.checkHorizontal1:
    call CheckHorizontalSpacing
    cmp al, 0
    je .trySlot2
    mov byte [cs:MidEnemy1Active], 1
    mov word [cs:MidEnemy1Y], -6 
    mov al, 1
    jmp .done
.checkHorizontal2:
    call CheckHorizontalSpacing
    cmp al, 0
    je .cannotSpawn
    mov byte [cs:MidEnemy2Active], 1
    mov word [cs:MidEnemy2Y], -6  
    mov al, 1
    jmp .done
.cannotSpawn:
    mov al, 0
.done:
    pop bx
    ret

TrySpawnInRightLane:
    push bx
    cmp byte [cs:RightEnemy1Active], 1
    jne .trySlot1
    cmp byte [cs:RightEnemy2Active], 1
    jne .trySlot2
    mov al, 0
    jmp .done
.trySlot1:
    cmp byte [cs:RightEnemy2Active], 0
    je .checkHorizontal1
    mov ax, [cs:RightEnemy2Y]
    cmp ax, MIN_VERTICAL_GAP
    jl .trySlot2
    jmp .checkHorizontal1
.trySlot2:
    cmp byte [cs:RightEnemy1Active], 0
    je .checkHorizontal2
    mov ax, [cs:RightEnemy1Y]
    cmp ax, MIN_VERTICAL_GAP
    jl .cannotSpawn
    jmp .checkHorizontal2
.checkHorizontal1:
    call CheckHorizontalSpacing
    cmp al, 0
    je .trySlot2
    mov byte [cs:RightEnemy1Active], 1
    mov word [cs:RightEnemy1Y], -6  
    mov al, 1
    jmp .done
.checkHorizontal2:
    call CheckHorizontalSpacing
    cmp al, 0
    je .cannotSpawn
    mov byte [cs:RightEnemy2Active], 1
    mov word [cs:RightEnemy2Y], -6  
    mov al, 1
    jmp .done
.cannotSpawn:
    mov al, 0
.done:
    pop bx
    ret

CheckHorizontalSpacing:
    push bx
    push cx
    mov cx, 0
    cmp byte [cs:LeftEnemy1Active], 1
    jne .checkLeft2
    mov ax, [cs:LeftEnemy1Y]
    cmp ax, MIN_HORIZONTAL_GAP
    jge .checkLeft2
    cmp ax, 0
    jl .checkLeft2
    inc cx
.checkLeft2:
    cmp byte [cs:LeftEnemy2Active], 1
    jne .checkMid1
    mov ax, [cs:LeftEnemy2Y]
    cmp ax, MIN_HORIZONTAL_GAP
    jge .checkMid1
    cmp ax, 0
    jl .checkMid1
    inc cx
.checkMid1:
    cmp byte [cs:MidEnemy1Active], 1
    jne .checkMid2
    mov ax, [cs:MidEnemy1Y]
    cmp ax, MIN_HORIZONTAL_GAP
    jge .checkMid2
    cmp ax, 0
    jl .checkMid2
    inc cx
.checkMid2:
    cmp byte [cs:MidEnemy2Active], 1
    jne .checkRight1
    mov ax, [cs:MidEnemy2Y]
    cmp ax, MIN_HORIZONTAL_GAP
    jge .checkRight1
    cmp ax, 0
    jl .checkRight1
    inc cx
.checkRight1:
    cmp byte [cs:RightEnemy1Active], 1
    jne .checkRight2
    mov ax, [cs:RightEnemy1Y]
    cmp ax, MIN_HORIZONTAL_GAP
    jge .checkRight2
    cmp ax, 0
    jl .checkRight2
    inc cx
.checkRight2:
    cmp byte [cs:RightEnemy2Active], 1
    jne .evaluate
    mov ax, [cs:RightEnemy2Y]
    cmp ax, MIN_HORIZONTAL_GAP
    jge .evaluate
    cmp ax, 0
    jl .evaluate
    inc cx
.evaluate:
    cmp cx, 2
    jge .cannotSpawn
    mov al, 1
    jmp .done
.cannotSpawn:
    mov al, 0
.done:
    pop cx
    pop bx
    ret

UpdateEnemyCars:
    push ax
    push bx
    push cx
    cmp byte [cs:LeftEnemy1Active], 1
    jne .skipLeft1
    inc word [cs:LeftEnemy1Y]
    mov ax, [cs:LeftEnemy1Y]
    cmp ax, 25
    jge .killLeft1
    mov bx, LANE_LEFT_COL
    call DrawLargeEnemy
    jmp .skipLeft1
.killLeft1:
    mov byte [cs:LeftEnemy1Active], 0
    call IncrementScore
.skipLeft1:
    cmp byte [cs:LeftEnemy2Active], 1
    jne .skipLeft2
    inc word [cs:LeftEnemy2Y]
    mov ax, [cs:LeftEnemy2Y]
    cmp ax, 25
    jge .killLeft2
    mov bx, LANE_LEFT_COL
    call DrawLargeEnemy
    jmp .skipLeft2
.killLeft2:
    mov byte [cs:LeftEnemy2Active], 0
    call IncrementScore
.skipLeft2:
    cmp byte [cs:MidEnemy1Active], 1
    jne .skipMid1
    inc word [cs:MidEnemy1Y]
    mov ax, [cs:MidEnemy1Y]
    cmp ax, 25
    jge .killMid1
    mov bx, LANE_MID_COL
    call DrawLargeEnemy
    jmp .skipMid1
.killMid1:
    mov byte [cs:MidEnemy1Active], 0
    call IncrementScore
.skipMid1:
    cmp byte [cs:MidEnemy2Active], 1
    jne .skipMid2
    inc word [cs:MidEnemy2Y]
    mov ax, [cs:MidEnemy2Y]
    cmp ax, 25
    jge .killMid2
    mov bx, LANE_MID_COL
    call DrawLargeEnemy
    jmp .skipMid2
.killMid2:
    mov byte [cs:MidEnemy2Active], 0
    call IncrementScore
.skipMid2:
    cmp byte [cs:RightEnemy1Active], 1
    jne .skipRight1
    inc word [cs:RightEnemy1Y]
    mov ax, [cs:RightEnemy1Y]
    cmp ax, 25
    jge .killRight1
    mov bx, LANE_RIGHT_COL
    call DrawLargeEnemy
    jmp .skipRight1
.killRight1:
    mov byte [cs:RightEnemy1Active], 0
    call IncrementScore
.skipRight1:
    cmp byte [cs:RightEnemy2Active], 1
    jne .skipRight2
    inc word [cs:RightEnemy2Y]
    mov ax, [cs:RightEnemy2Y]
    cmp ax, 25
    jge .killRight2
    mov bx, LANE_RIGHT_COL
    call DrawLargeEnemy
    jmp .skipRight2
.killRight2:
    mov byte [cs:RightEnemy2Active], 0
    call IncrementScore
.skipRight2:
    pop cx
    pop bx
    pop ax
    ret

DrawLargeEnemy:
    push ax
    push bx
    push cx
    push dx
    push di
    push es
    mov dx, ax  
    mov ax, 0xb800
    mov es, ax
    
    mov word [car_row], dx
    mov word [car_col], bx
    
    cmp bx, LANE_LEFT_COL
    je .red_car
    cmp bx, LANE_MID_COL
    je .blue_car
    mov byte [car_color], 0x0D
    jmp .draw_enemy
.red_car:
    mov byte [car_color], 0x04
    jmp .draw_enemy
.blue_car:
    mov byte [car_color], 0x01 
    
.draw_enemy:
    call draw_car
    
    pop es
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; ============================================================
; ================= COLLISION DETECTION ======================
; ============================================================

CheckCollisions:
    push ax
    push bx
    push cx
    push dx
    
    mov bx, [cs:CarCol]  
    cmp byte [cs:LeftEnemy1Active], 1
    jne .checkLeft2
    cmp bx, LANE_LEFT_COL
    jne .checkLeft2
    mov ax, [cs:LeftEnemy1Y]
    call CheckCarOverlap
    cmp cx, 1
    je .collision
    
.checkLeft2:
    cmp byte [cs:LeftEnemy2Active], 1
    jne .checkMid1
    cmp bx, LANE_LEFT_COL
    jne .checkMid1
    mov ax, [cs:LeftEnemy2Y]
    call CheckCarOverlap
    cmp cx, 1
    je .collision
    
.checkMid1:
    cmp byte [cs:MidEnemy1Active], 1
    jne .checkMid2
    cmp bx, LANE_MID_COL
    jne .checkMid2
    mov ax, [cs:MidEnemy1Y]
    call CheckCarOverlap
    cmp cx, 1
    je .collision
    
.checkMid2:
    cmp byte [cs:MidEnemy2Active], 1
    jne .checkRight1
    cmp bx, LANE_MID_COL
    jne .checkRight1
    mov ax, [cs:MidEnemy2Y]
    call CheckCarOverlap
    cmp cx, 1
    je .collision
    
.checkRight1:
    cmp byte [cs:RightEnemy1Active], 1
    jne .checkRight2
    cmp bx, LANE_RIGHT_COL
    jne .checkRight2
    mov ax, [cs:RightEnemy1Y]
    call CheckCarOverlap
    cmp cx, 1
    je .collision
    
.checkRight2:
    cmp byte [cs:RightEnemy2Active], 1
    jne .safe
    cmp bx, LANE_RIGHT_COL
    jne .safe
    mov ax, [cs:RightEnemy2Y]
    call CheckCarOverlap
    cmp cx, 1
    je .collision
    jmp .safe
    
.collision:
    call SoundCollision
    mov byte [cs:GameActive], 0
    
.safe:
    pop dx
    pop cx
    pop bx
    pop ax
    ret

CheckCarOverlap:
    push ax
    push bx
    push dx
	
    ; Player car is at rows 18-23 (height = 6)
    ; Enemy car is at rows AX to AX+5 (height = 6)
	
    mov bx, ax
    add bx, 5
    
    cmp bx, 18
    jl .noCollision
    
    cmp ax, 23
    jg .noCollision

    mov cx, 1
    jmp .done
    
.noCollision:
    mov cx, 0
    
.done:
    pop dx
    pop bx
    pop ax
    ret

; ============================================================
; ================= SCROLLING SUBROUTINE =====================
; ============================================================
ScrollScreen:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push es
    push ds
    cld
    mov ax, 0xb800
    mov es, ax
    mov ds, ax
    call ClearAllEnemyCars

    mov si, (24*80)*2
    mov cx, 80
    push es
    mov ax, cs
    mov es, ax
    mov di, RowBuffer
    rep movsw
    pop es
    
    mov bx, [cs:CarCol]
    push es
    mov ax, cs
    mov es, ax
    mov di, RowBuffer
    shl bx, 1
    add di, bx
    dec di
    dec di
	
    mov cx, PLAYER_CAR_WIDTH
    mov si, bx
    shr si, 1  ;
    dec si 
	
.fix_car_area:
    push cx
    push si
    mov dx, si
    sub dx, 20  
    
    cmp dx, 0
    je .is_border
    cmp dx, 39
    je .is_border
    cmp dx, 13
    je .is_lane_bar
    cmp dx, 26
    je .is_lane_bar
    
    ; Regular road body
    mov ax, 0x08B0 
    jmp .store_it
    
.is_border:
    mov ax, 0x04DB  
    jmp .store_it
    
.is_lane_bar:
    mov ax, 0x07B3  
    jmp .store_it
    
.store_it:
    mov [es:di], ax
    add di, 2
    pop si
    inc si
    pop cx
    loop .fix_car_area
    pop es
    
    mov bx, [cs:CarCol]
    mov si, (23*80 + 0)*2
    mov di, (24*80 + 0)*2
    mov cx, bx
    dec cx
    rep movsw
    add si, PLAYER_CAR_WIDTH*2
    add di, PLAYER_CAR_WIDTH*2
    mov cx, 80
    sub cx, bx
    sub cx, PLAYER_CAR_WIDTH
    inc cx
    rep movsw
    
    mov bx, [cs:CarCol]
    mov si, (22*80 + 0)*2
    mov di, (23*80 + 0)*2
    mov cx, bx
    dec cx
    rep movsw
    add si, PLAYER_CAR_WIDTH*2
    add di, PLAYER_CAR_WIDTH*2
    mov cx, 80
    sub cx, bx
    sub cx, PLAYER_CAR_WIDTH
    inc cx
    rep movsw
    
    mov bx, [cs:CarCol]
    mov si, (21*80 + 0)*2
    mov di, (22*80 + 0)*2
    mov cx, bx
    dec cx
    rep movsw
    add si, PLAYER_CAR_WIDTH*2
    add di, PLAYER_CAR_WIDTH*2
    mov cx, 80
    sub cx, bx
    sub cx, PLAYER_CAR_WIDTH
    inc cx
    rep movsw
    
    mov bx, [cs:CarCol]
    mov si, (20*80 + 0)*2
    mov di, (21*80 + 0)*2
    mov cx, bx
    dec cx
    rep movsw
    add si, PLAYER_CAR_WIDTH*2
    add di, PLAYER_CAR_WIDTH*2
    mov cx, 80
    sub cx, bx
    sub cx, PLAYER_CAR_WIDTH
    inc cx
    rep movsw
    
    mov bx, [cs:CarCol]
    mov si, (19*80 + 0)*2
    mov di, (20*80 + 0)*2
    mov cx, bx
    dec cx
    rep movsw
    add si, PLAYER_CAR_WIDTH*2
    add di, PLAYER_CAR_WIDTH*2
    mov cx, 80
    sub cx, bx
    sub cx, PLAYER_CAR_WIDTH
    inc cx
    rep movsw
    
    mov bx, [cs:CarCol]
    mov si, (18*80 + 0)*2
    mov di, (19*80 + 0)*2
    mov cx, bx
    dec cx
    rep movsw
    add si, PLAYER_CAR_WIDTH*2
    add di, PLAYER_CAR_WIDTH*2
    mov cx, 80
    sub cx, bx
    sub cx, PLAYER_CAR_WIDTH
    inc cx
    rep movsw
    
    std
    mov si, (17*80 + 79)*2
    mov di, (18*80 + 79)*2
    mov cx, 18*80
    rep movsw
    cld
    
    push ds
    mov ax, cs
    mov ds, ax
    mov si, RowBuffer
    mov di, (1*80)*2
    mov cx, 80
    rep movsw
    pop ds
    
    call DrawGameCar
    pop ds
    pop es
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
 
ClearAllEnemyCars:
    push ax
    push bx
    push cx
    push dx
    push di
    mov ax, 0xb800
    mov es, ax
    cmp byte [cs:LeftEnemy1Active], 1
    jne .skipLeft1
    mov ax, [cs:LeftEnemy1Y]
    cmp ax, 0
    jl .skipLeft1
    cmp ax, 24
    jg .skipLeft1
    mov bx, LANE_LEFT_COL
    call ClearLargeCarArea
.skipLeft1:
    cmp byte [cs:LeftEnemy2Active], 1
    jne .skipLeft2
    mov ax, [cs:LeftEnemy2Y]
    cmp ax, 0
    jl .skipLeft2
    cmp ax, 24
    jg .skipLeft2
    mov bx, LANE_LEFT_COL
    call ClearLargeCarArea
.skipLeft2:
    cmp byte [cs:MidEnemy1Active], 1
    jne .skipMid1
    mov ax, [cs:MidEnemy1Y]
    cmp ax, 0
    jl .skipMid1
    cmp ax, 24
    jg .skipMid1
    mov bx, LANE_MID_COL
    call ClearLargeCarArea
.skipMid1:
    cmp byte [cs:MidEnemy2Active], 1
    jne .skipMid2
    mov ax, [cs:MidEnemy2Y]
    cmp ax, 0
    jl .skipMid2
    cmp ax, 24
    jg .skipMid2
    mov bx, LANE_MID_COL
    call ClearLargeCarArea
.skipMid2:
    cmp byte [cs:RightEnemy1Active], 1
    jne .skipRight1
    mov ax, [cs:RightEnemy1Y]
    cmp ax, 0
    jl .skipRight1
    cmp ax, 24
    jg .skipRight1
    mov bx, LANE_RIGHT_COL
    call ClearLargeCarArea
.skipRight1:
    cmp byte [cs:RightEnemy2Active], 1
    jne .done
    mov ax, [cs:RightEnemy2Y]
    cmp ax, 0
    jl .done
    cmp ax, 24
    jg .done
    mov bx, LANE_RIGHT_COL
    call ClearLargeCarArea
    
.done:
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

ClearLargeCarArea:
    push ax
    push bx
    push cx
    push dx
    push di
    push si
    mov dx, ax  
    mov cx, LARGE_CAR_HEIGHT
	
.clearRows:
    push cx
    cmp dx, 0
    jl .nextRow
    cmp dx, 24
    jg .nextRow
    
    ; Calculate screen position
    push ax
    push dx
    mov ax, dx
    push bx
    mov bx, 80
    mul bx
    pop bx
    add ax, bx
    dec ax 
    shl ax, 1
    mov di, ax
    pop dx
    pop ax
    mov si, bx
    dec si  
    mov cx, LARGE_CAR_WIDTH
	
.clear_cols:
    push cx
    push di
    push si
    
    ; Skip if outside road area 
    cmp si, 20
    jl .skip_clear
    cmp si, 59
    jg .skip_clear
    mov ax, si 
    sub ax, 20  
    
    cmp ax, 0
    je .draw_border
    cmp ax, 39
    je .draw_border
    cmp ax, 13
    je .draw_lane_marker
    cmp ax, 26  
    je .draw_lane_marker
    jmp .draw_road_body
    
.draw_border:
    mov cx, dx
    add cx, [cs:offset]
    and cx, 1
    jz .red_border
    mov ax, 0x0FDB  ; white block
    jmp .draw_cell
    
.red_border:
    mov ax, 0x04DB  ; red block
    jmp .draw_cell
    
.draw_lane_marker:
    mov ax, 0x07B3  ; light gray vertical bar
    jmp .draw_cell
    
.draw_road_body:
    mov ax, 0x08B0  ; dark gray road texture
    
.draw_cell:
    mov [es:di], ax
    jmp .continue_clear
    
.skip_clear:
    
.continue_clear:
    pop si
    pop di
    pop cx
    
    add di, 2
    inc si
    loop .clear_cols
    
.nextRow:
    inc dx
    pop cx
    loop .clearRows
    
    pop si
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; ============================================================
; ================= GAME LOOP WITH SCROLLING =================
; ============================================================

GameLoop:
    cmp byte [cs:GameActive], 0
    je GameOver
    call check_esc_exit
    cmp byte [cs:GameActive], 0
    je ExitGame

    mov ah, 1
    int 16h
    jz ContinueScroll
    mov ah, 0
    int 16h
    cmp ah, 1
    je ExitGame
    cmp al, 0
    je .ext
    cmp al, 0xE0
    je .ext
    cmp al, 'a'
    je MoveLeft
    cmp al, 'A'
    je MoveLeft
    cmp al, 'd'
    je MoveRight
    cmp al, 'D'
    je MoveRight
    jmp ContinueScroll
.ext:
    cmp ah, 4Bh
    je MoveLeft
    cmp ah, 4Dh
    je MoveRight
    jmp ContinueScroll

ContinueScroll:
    call ScrollScreen
    call SpawnEnemyCars
    call UpdateEnemyCars
    call CheckCollisions
    call SpawnBonus
    call UpdateBonusObject
    call WaitForTick
    jmp GameLoop

MoveLeft:
    call ClearCarAtCurrentPosition
    mov bx, [cs:CarCol]
    cmp bx, CAR_MIN_COL
    jle ContinueScroll
    sub bx, CAR_STEP
    mov [cs:CarCol], bx
	call SoundMove
    jmp ContinueScroll

MoveRight:
    call ClearCarAtCurrentPosition
    mov bx, [cs:CarCol]
    cmp bx, CAR_MAX_COL
    jge ContinueScroll
    add bx, CAR_STEP
    mov [cs:CarCol], bx
	call SoundMove
    jmp ContinueScroll

WaitForTick:
    push ax
    mov byte [cs:GameTick], 0          
.wait:
    cmp byte [cs:GameTick], 1
    jne .wait
    pop ax
    ret

GameOver:
    call ShowGameOver
    jmp ExitGame

ExitGame:
    call restore_keyboard_handler
    call restore_timer_handler      
    mov ax, 0x0003
    int 0x10
    mov ax, 0x4C00
    int 0x21
	
; ============================================================
; =================== TIMER INTERRUPT HANDLER (60 FPS) =======
; ============================================================

timer_isr:
    push ax
    push ds

    mov ax, cs
    mov ds, ax

    mov al, 0x20
    out 0x20, al

    inc word [cs:TickCounter]
    cmp word [cs:TickCounter], 3
    jb .no_game_tick
    mov word [cs:TickCounter], 0
    mov byte [cs:GameTick], 1        

.no_game_tick:
    ; Chain to original timer handler
    pop ds
    pop ax
    jmp far [cs:old_timer_isr]

; ============================================================
; Install / Restore Timer Handler
; ============================================================

install_timer_handler:
    push ax
    push es

    xor ax, ax
    mov es, ax
    mov eax, [es:8*4]                
    mov [cs:old_timer_isr], eax

    cli
    mov word [es:8*4], timer_isr
    mov [es:8*4+2], cs
    sti

    mov al, 0x36
    out 0x43, al
    mov ax, 59659           ; 1193182 / 59659 ≈ 20 Hz → every 3rd = 60 Hz
    out 0x40, al
    mov al, ah
    out 0x40, al

    mov word [cs:TickCounter], 0
    mov byte [cs:GameTick], 1          

    pop es
    pop ax
    ret

restore_timer_handler:
    push ax
    push es

    xor ax, ax
    mov es, ax
    cli
    mov eax, [cs:old_timer_isr]
    mov [es:8*4], eax
    sti

    mov al, 0x36
    out 0x43, al
    xor al, al
    out 0x40, al
    out 0x40, al

    pop es
    pop ax
    ret
	
; ============================================================
; ================= BONUS SYSTEM =============================
; ============================================================

InitBonusSystem:
    push ax
    mov byte [cs:BonusActive], 0
    mov word [cs:BonusSpawnCounter], BONUS_SPAWN_RATE
    pop ax
    ret
	
SpawnBonus:
    push ax
    push bx
    push cx
    
    ; Only spawn if no bonus is active
    cmp byte [cs:BonusActive], 1
    je .done
    
    ; Decrement spawn counter
    dec word [cs:BonusSpawnCounter]
    jnz .done
    
    ; Reset counter for next spawn
    mov word [cs:BonusSpawnCounter], BONUS_SPAWN_RATE
    mov cx, 10  
    
.tryAgain:
    ; Pick random lane (0, 1, or 2)
    call GetRandomLane  
    cmp bl, 0
    je .checkLeft
    cmp bl, 1
    je .checkMid
    jmp .checkRight
    
.checkLeft:
    cmp byte [cs:LeftEnemy1Active], 1
    jne .checkLeft2
    mov ax, [cs:LeftEnemy1Y]
    cmp ax, 8
    jl .tryNext
    
.checkLeft2:
    cmp byte [cs:LeftEnemy2Active], 1
    jne .leftSafe
    mov ax, [cs:LeftEnemy2Y]
    cmp ax, 8
    jl .tryNext
    
.leftSafe:
    mov ax, LANE_LEFT_COL
    jmp .setSpawn
    
.checkMid:
    cmp byte [cs:MidEnemy1Active], 1
    jne .checkMid2
    mov ax, [cs:MidEnemy1Y]
    cmp ax, 8
    jl .tryNext
    
.checkMid2:
    cmp byte [cs:MidEnemy2Active], 1
    jne .midSafe
    mov ax, [cs:MidEnemy2Y]
    cmp ax, 8
    jl .tryNext
    
.midSafe:
    mov ax, LANE_MID_COL
    jmp .setSpawn
    
.checkRight:
    cmp byte [cs:RightEnemy1Active], 1
    jne .checkRight2
    mov ax, [cs:RightEnemy1Y]
    cmp ax, 8
    jl .tryNext
    
.checkRight2:
    cmp byte [cs:RightEnemy2Active], 1
    jne .rightSafe
    mov ax, [cs:RightEnemy2Y]
    cmp ax, 8
    jl .tryNext
    
.rightSafe:
    mov ax, LANE_RIGHT_COL
    jmp .setSpawn
    
.tryNext:
    dec cx
    jz .done  
    jmp .tryAgain  
    
.setSpawn:
    mov [cs:BonusCol], ax
    mov word [cs:BonusRow], 1   
    mov byte [cs:BonusActive], 1
    
.done:
    pop cx
    pop bx
    pop ax
    ret

UpdateBonusObject:
    push ax
    push bx
    push cx
    push dx
    push di
    push es
    
    cmp byte [cs:BonusActive], 0
    je .done
    mov ax, 0xb800
    mov es, ax
    
    mov ax, [cs:BonusRow]
    inc ax
    mov [cs:BonusRow], ax
    
    cmp ax, 24
    jg .deactivate
    
    ; Check collision with player car (rows 18-23)
    cmp ax, 18
    jl .draw
    cmp ax, 23
    jg .draw
    
    mov bx, [cs:CarCol]
    mov cx, [cs:BonusCol]
    cmp bx, cx
    jne .draw
    
    ; Add 5 points at collision
    mov ax, [cs:Score]
    add ax, 5
    mov [cs:Score], ax
    call UpdateScoreDisplay
	call SoundBonus
    mov byte [cs:BonusActive], 0
    jmp .done
    
.draw:
    mov ax, [cs:BonusRow]
    mov bx, 80
    mul bx
    add ax, [cs:BonusCol]
    shl ax, 1
    mov di, ax
    
    mov al, BONUS_CHAR
    mov ah, BONUS_COLOR
    stosw
    
    jmp .done
    
.deactivate:
    mov byte [cs:BonusActive], 0
    
.done:
    pop es
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret
	
; ============================================================
; ================= SOUND EFFECTS SYSTEM =====================
; ============================================================

; Input: AX = frequency in Hz, CX = duration in milliseconds
PlayTone:
    push ax
    push bx
    push cx
    push dx
    
    mov bx, ax             
    mov dx, 1193180 / 65536 
    mov ax, 1193180 % 65536
    div bx                 
    
    mov bx, ax            
    mov al, 0B6h           
    out 43h, al
    mov al, bl            
    out 42h, al
    mov al, bh              
    out 42h, al
    
    ; Enable speaker
    in al, 61h
    or al, 03h              
    out 61h, al
    
    ; Wait for duration
    call DelayMS
    
    ; Disable speaker
    in al, 61h
    and al, 0FCh            
    out 61h, al
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret
	
DelayMS:
    push ax
    push cx
    push dx
    
.outer:
    push cx
    mov cx, 1000            
	
.inner:
    loop .inner
    pop cx
    loop .outer
    
    pop dx
    pop cx
    pop ax
    ret

; ============================================================
; ================= GAME-SPECIFIC SOUND EFFECTS ==============
; ============================================================

SoundMove:
    push ax
    push cx
    
    mov ax, 1200
    mov cx, 20
    call PlayTone
    
    mov ax, 900
    mov cx, 15
    call PlayTone
    
    pop cx
    pop ax
    ret

SoundCollision:
    push ax
    push cx
    
    mov ax, 800
    mov cx, 100
    call PlayTone
    
    mov ax, 400
    mov cx, 100
    call PlayTone
   
    mov ax, 200
    mov cx, 200
    call PlayTone
    
    pop cx
    pop ax
    ret

SoundScore:
    push ax
    push cx
    mov ax, 1200           
    mov cx, 50              
    call PlayTone
    pop cx
    pop ax
    ret

SoundBonus:
    push ax
    push cx
    
    mov ax, 800
    mov cx, 60
    call PlayTone
    
    mov ax, 1200
    mov cx, 60
    call PlayTone
    
    mov ax, 1600
    mov cx, 80
    call PlayTone
    
    pop cx
    pop ax
    ret

SoundGameStart:
    push ax
    push cx
    mov ax, 300
    mov cx, 100           
    call PlayTone
    pop cx
    pop ax
    ret

SoundGameOver:
    push ax
    push cx
    
    mov ax, 800
    mov cx, 200
    call PlayTone
    
    mov ax, 600
    mov cx, 200
    call PlayTone
    
    mov ax, 400
    mov cx, 300
    call PlayTone
    
    mov ax, 200
    mov cx, 400
    call PlayTone
    
    pop cx
    pop ax
    ret
	
; ============= BACKGROUND ENGINE SOUND =============
TireSoundCounter db 0   
MusicNotes dw 200, 280, 400, 520, 650, 520, 400, 280 
MusicIndex db 0
TirePhase db 0          

; ============================================================
; =================== MAIN PROGRAM ============================
; ============================================================

start:
    call install_keyboard_handler
    call install_timer_handler
    call show_loading_screen
    mov ah, 0
    int 16h
    call SoundGameStart
    mov ax, 0xb800
    mov es, ax
    
    call ClearScreen
    call DrawLeftLandscape
    call DrawBlackMiddle
    call DrawRightLandscape
	
    call DrawAllTrees
    call DrawAllRocks
    call DrawGameCar
    
    mov word [cs:Score], 0
    mov byte [cs:GameActive], 1
    call UpdateScoreDisplay
    
    call InitSpawnSystem
    call InitBonusSystem
    jmp GameLoop