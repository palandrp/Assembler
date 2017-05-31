;http://www.cyberforum.ru/assembler-dos/thread738365.html

code    segment
    assume  cs:code, ds:data
 
ReadFile    proc
    mov ah,3Fh      ;функция чтения
    mov bx,handlefile   ;файловый номер
    mov cx,128      ;длина записи
    lea dx,buffer2  ;буфер для чтения
    int 21h
    ret
ReadFile    endp
 
print   proc            ;печать сообщения
    mov ah,40h      ;dx - указатель на начало
    mov bx,2        ;cx - количество байт
    int 21h
    ret
print   endp
 
;Процедура выводит в шестнадцетиричном виде 
;число находящиеся в dl
Hex proc
    push    bx  ;сохранение
    push    ds  ;регистров
    mov ax,data
    mov ds,ax
    push    dx
    lea bx,table1
    mov ax,0
    mov al,dl
    clc
    shr al,1
    shr al,1
    shr al,1
    shr al,1
    xlat        ;старший полубайт
    mov dl,al
    call    PutS
    pop ax
    and al,00001111b
    xlat        ;младший полубайт
    mov dl,al
    call    Puts
    pop ds  ;восстановление
    pop bx  ;регистров
    ret
Hex endp
 
PutS    proc            ;печать 1 символа
    mov ah,2        ;из dl
    int 21h
    ret
PutS    endp
 
newline proc            ;возврат каретки
    mov dl,13       ;и перевод строки
    call    PutS
    mov dl,10
    call    PutS
    ret
newline endp
 
newline_    proc            ;возврат каретки
    mov cx,6
Lop:
    mov dl,13       ;и перевод строки
    call    PutS
    mov dl,10
    call    PutS
    loop    lop
    ret
newline_    endp
 
NextHex proc            ;вспомогательная подпрограмма
    mov dl,[si]     ;вывода HEX чисел
    call    Hex
    mov dl,' '
    call    PutS
    inc si
    ret
NextHex endp
;Процедура выводит в двоичном виде 
;число находящиеся в dl
WriteBin    proc
    push    cx
    push    bx
    mov bl, dl ; в bx хранится символ
    mov ah, 0
    xor cx,cx ; очищение cx
    mov bx,ax
    mov cx,8
    shl bx,8
    a10:
    mov dl,'0'
    shl bx,1
    jnc a20
    ;jc a20
    
    ;mov dl,'0'
    add dl,1
    ;jmp    a30
    a20:
    ;mov    dl,'1'
    ;a30:
    mov     ah,2         ;вывод символа на экран
    int     21h      ;из регистра DL
    loop a10
    pop bx
    pop cx
    ret
 
WriteBin    endp
 
NextBin proc            ;вспомогательная подпрограмма
    mov al,[si]     ;печати Bin чисел
    call    WriteBin
    mov dl,' '
    call    PutS
    inc si
    ret
NextBin endp
 
wait13  proc            ;ожидание нажатия клавиши
wait_:  mov ah,8        ;Enter
    int 21h 
    cmp al,13
    jne wait_
    ret
wait13  endp
 
;Основная программа
start:  
    mov ax,data     
    mov ds,ax
 
    lea dx,msg      ;Вывод приглашения
    mov cx,17
    call    print
 
;Чтение имени файла
    mov dx,offset buffer
    mov ah,0Ah
    int 21h
 
    mov bx,offset nampath
    mov si,offset buffer
    inc si
 
;Перевести в переменную nampath имя файла без лишних символов
    mov cx,0
    mov cl,[si]
lp_:
    inc si
    mov al,[si]
    mov [bx],al
    inc bx
    loop    lp_
    mov [bx],0
        
    mov ah,3Dh
    mov al,0        ;только чтение
    lea dx,nampath
    int 21h
    cmp ax,0002h 
    jne er
    lea dx,errormsg      ;Вывод ошибки
    mov cx,18
    call    print
    call    start
er: 
    jc  err
    jmp nextline
err:
    mov ax,4C00h
    int 21h
nextline:
 
    mov handlefile,ax   ;файловый номер
 
    mov ah,1Ah      ;установка буффера
    lea dx,buffer2
    int 21h
 
    call    newline
    call    newline
 
l3:
    call    ReadFile    ;считать 128 байт
    jc  ext     ;если ошибка
    cmp ax,0        ;в ax - число
    je  ext     ;прочитанных байтов
 
    push    ax
 
    lea dx,Binm     ;вывод сообщения
    mov cx,6
    call    print
 
 
    lea si,buffer2  ;Вывод 128 байт
    mov cx,6        ;Bin таблицы
l_4:    push    cx
    mov cx,19
l_5:    call    NextBin
    loop    l_5
 
    call    newline
 
    pop cx
    loop    l_4
 
    mov cx,14
l_6:    call    NextBin
    loop    l_6
 
    call    newline     ;Перевод строки
    call    newline
 
    lea dx,Hexm     ;вывод сообщения
    mov cx,6
    call    print
 
    lea si,buffer2  ;Вывод 128 байт
    mov cx,6        ;HEX таблицы
l4: push    cx
    mov cx,19
l5: call    NextHex
    loop    l5
    call    newline
    pop cx
    loop    l4
    mov cx,14
l6: call    NextHex
    loop    l6
 
 
    call    newline
    call    newline
    lea dx,msg_Enter
    mov cx,8
    call    print
    call    newline_
 
    call    wait13
 
    pop ax      ;Если был считано
    cmp ax,128      ;меньше 128 байт
    je  l3      ;завершить работу
 
;Закрыть открытый файл
    mov ah,3Eh
    mov bx,handlefile
    int 21h
 
ext:    mov ax,4C00h
    int 21h
code    ends
 
data    segment
 buffer     db  14,14 dup(0)
 buffer2    db  128 dup(?)
 
 Hexm       db  'HEX:',13,10
 Binm       db  'BIN:',13,10
 msg        db  'Enter file name: '
 msg_Enter  db  'Enter up' 
 errormsg   db  13,10,'File not found',13,10
 
 table      db  '0123456789'
 table1     db  '0123456789ABCDEF'
 nampath    db  14 dup(?)
 handlefile dw  0
data    ends
end start