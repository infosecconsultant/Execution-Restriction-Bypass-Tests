; Execute calc.exe in Assembly (MASM)
.MODEL small
.STACK 100h
.DATA
    cmd DB 'calc.exe$', 0
    fileName DB 'BasicExecution.txt', 0
.CODE
main PROC
    mov ax, @data
    mov ds, ax
    lea dx, cmd
    mov ah, 4Bh
    int 21h
    
    lea dx, fileName
    mov ah, 3Ch  ; Create file
    int 21h
    jc  fileExists
    call writeFile
    jmp done
fileExists:
    lea dx, fileName
    mov ah, 3Dh  ; Open file
    mov al, 02h  ; Open for write
    int 21h
    call writeFile
done:
    mov ah, 4Ch
    int 21h

writeFile PROC
    lea dx, cmd
    mov ah, 40h  ; Write to file
    int 21h
    ret
writeFile ENDP
main ENDP
END main
