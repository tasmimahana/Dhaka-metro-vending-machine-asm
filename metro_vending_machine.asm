.DATA
welcome_msg db 0Dh, 0Ah, "Welcome to Farmgate Metro Station", 0Dh, 0Ah, "$"
menu db 0Dh, 0Ah, "Select Your Destination:", 0Dh, 0Ah
     db "1. Karwan Bazar - 20tk", 0Dh, 0Ah
     db "2. Shahbagh - 30tk", 0Dh, 0Ah
     db "3. Motijheel - 40tk", 0Dh, 0Ah
     db "4. Uttara North - 50tk", 0Dh, 0Ah
     db "5. Uttara Center - 60tk", 0Dh, 0Ah
     db "6. Uttara South - 70tk", 0Dh, 0Ah
     db "7. Pallabi - 80tk", 0Dh, 0Ah
     db "8. Mirpur 11 - 90tk", 0Dh, 0Ah
     db "9. Mirpur 10 - 100tk", 0Dh, 0Ah
     db "*. Exit", 0Dh, 0Ah, "$"

prompt_dest db 0Dh, 0Ah, "Enter destination number (1-9) or '*' to exit: $"
prompt_ticket db 0Dh, 0Ah, "Enter number of tickets (1-20): $"
invalid_msg db 0Dh, 0Ah, "Invalid selection. Try again.", 0Dh, 0Ah, "$"
total_msg db 0Dh, 0Ah, "Your total is: $"
money_prompt db 0Dh, 0Ah, "Enter money received: $"
insufficient_money_msg db 0Dh, 0Ah, "Insufficient amount.", 0Dh, 0Ah, "$"
change_returned_msg db 0Dh, 0Ah, "Change to be returned: $"
thank_you_msg db 0Dh, 0Ah, "Thank you :D !", 0Dh, 0Ah, "$"
goodbye_msg db 0Dh, 0Ah, "Thank you for using Farmgate Metro Station! Goodbye!", 0Dh, 0Ah, "$"
discount_msg db 0Dh, 0Ah, "Congratulations! You have earned a 5% discount on your total.", 0Dh, 0Ah, "$"
tickets_left_msg db 0Dh, 0Ah, "Tickets left: $", 0Dh, 0Ah, "$"
no_tickets_available_msg db 0Dh, 0Ah, "No tickets available.", 0Dh, 0Ah, "$"  ; Added message

newline db 0Dh, 0Ah, "$"

prices db 20, 30, 40, 50, 60, 70, 80, 90, 100  ; Prices for destinations
total dw 0               ; Total price (16-bit word)
money_received dw 0      ; Amount of money received (16-bit word)
change dw 0              ; Change to be returned (16-bit word)
discount dw 0            ; Discount amount (16-bit word)
tickets_available db 20  ; Total number of tickets available

.CODE
ReadNumber PROC
    PUSH BX
    PUSH CX
    PUSH DX
    
    MOV CX, 0       ; Clear number
    MOV BX, 10      ; Multiplier

read_loop:
    MOV AH, 01H
    INT 21H
    
    CMP AL, 0DH     ; Check for Enter key
    JE read_done
    
    SUB AL, '0'     ; Convert from ASCII
    MOV AH, 0
    PUSH AX         ; Save digit
    
    MOV AX, CX
    MUL BX          ; Multiply current number by 10
    MOV CX, AX
    
    POP AX
    ADD CX, AX      ; Add new digit
    
    JMP read_loop

read_done:
    MOV AX, CX      ; Return value in AX
    
    POP DX
    POP CX
    POP BX
    RET
ReadNumber ENDP

DisplayNumber PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    MOV CX, 0       ; Digit counter
    MOV BX, 10      ; Divisor

divide_loop:
    MOV DX, 0
    DIV BX          ; Divide by 10
    PUSH DX         ; Save remainder
    INC CX          ; Increment counter
    
    CMP AX, 0       ; Check if done
    JNE divide_loop

display_loop:
    POP DX          ; Get digit
    ADD DL, '0'     ; Convert to ASCII
    MOV AH, 02H
    INT 21H
    LOOP display_loop
    
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DisplayNumber ENDP

MAIN PROC
    ; Initialize DS and SS
    MOV AX, @DATA
    MOV DS, AX
    MOV SS, AX
    MOV SP, 100H             

display_welcome:
    LEA DX, welcome_msg
    MOV AH, 09H
    INT 21H

menu_display:
    ; Reset all variables before new transaction
    MOV [total], 0
    MOV [money_received], 0
    MOV [change], 0
    MOV [discount], 0

    LEA DX, menu
    MOV AH, 09H
    INT 21H

destination_input:
    LEA DX, prompt_dest
    MOV AH, 09H
    INT 21H

    MOV AH, 01H
    INT 21H
    CMP AL, '*'              
    JE exit_program          

    SUB AL, '0'              
    MOV BL, AL               

    CMP BL, 1
    JL invalid_selection     
    CMP BL, 9
    JG invalid_selection     

    DEC BL                   
    MOV AL, [prices + BX]    
    MOV BH, AL               

ticket_input:
    LEA DX, prompt_ticket
    MOV AH, 09H
    INT 21H

    MOV AH, 01H
    INT 21H
    SUB AL, '0'              
    MOV CL, AL               

    CMP CL, 1
    JL invalid_selection     
    CMP CL, 20
    JG invalid_selection     

    ; Check if enough tickets are available
    MOV AL, [tickets_available]
    CMP AL, CL
    JL no_tickets_available

    ; Decrease the number of available tickets
    SUB [tickets_available], CL

    ; Display the number of tickets left
    LEA DX, tickets_left_msg
    MOV AH, 09H
    INT 21H
    MOV AL, [tickets_available]
    CALL DisplayNumber
    LEA DX, newline
    MOV AH, 09H
    INT 21H

calculate_total:
    MOV AL, BH              
    MUL CL                   
    MOV [total], AX          

    ; Apply discount if 5 or more tickets
    CMP CL, 5
    JL no_discount

    ; Display discount message
    LEA DX, discount_msg
    MOV AH, 09H
    INT 21H
    ; Calculate 5% discount using the formula (total * 5) / 100
    MOV AX, [total]         ; Load the total price
    MOV BX, 5               ; Discount percentage
    MUL BX                  ; Multiply total by 5
    MOV CX, 100             ; Load 100 into CX for division
    DIV CX                  ; Divide the result by 100 to get the discount
    MOV [discount], AX      ; Store the discount amount

    ; Subtract the discount from the total
    MOV AX, [total]
    SUB AX, [discount]      ; Subtract the discount
    MOV [total], AX         ; Store the new total price after discount


no_discount:

display_total:
    LEA DX, total_msg
    MOV AH, 09H
    INT 21H

    MOV AX, [total]
    CALL DisplayNumber

    LEA DX, newline
    MOV AH, 09H
    INT 21H

money_input:
    LEA DX, money_prompt
    MOV AH, 09H
    INT 21H

    CALL ReadNumber         
    MOV [money_received], AX

compare_amounts:
    MOV BX, [money_received]
    MOV AX, [total]
    
    ; Compare money received with total
    CMP BX, AX
    JB insufficient_money   
    JA calculate_change     
    JMP exact_payment       

calculate_change:
    SUB BX, AX             
    MOV [change], BX       

    LEA DX, change_returned_msg     
    MOV AH, 09H
    INT 21H

    MOV AX, [change]       
    CALL DisplayNumber

    LEA DX, newline
    MOV AH, 09H
    INT 21H
    JMP menu_display

exact_payment:
    LEA DX, thank_you_msg
    MOV AH, 09H
    INT 21H
    JMP menu_display

insufficient_money:
    LEA DX, insufficient_money_msg
    MOV AH, 09H
    INT 21H
    JMP menu_display

no_tickets_available:
    LEA DX, no_tickets_available_msg  
    MOV AH, 09H
    INT 21H
    JMP menu_display

invalid_selection:
    LEA DX, invalid_msg
    MOV AH, 09H
    INT 21H
    JMP menu_display

exit_program:
    LEA DX, goodbye_msg     
    MOV AH, 09H
    INT 21H

    MOV AX, 4C00H          
    INT 21H

MAIN ENDP
END MAIN
