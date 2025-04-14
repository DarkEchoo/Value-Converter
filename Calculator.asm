INCLUDE C:\Irvine\Irvine32.inc
INCLUDELIB C:\Irvine\Irvine32.lib

.386
.model flat,stdcall
.stack 4096
ExitProcess PROTO, dwExitCode:DWORD

.data
; Prompts and message strings
menuPrompt      BYTE "Menu Options:", 0Dh, 0Ah
                BYTE "  (1) Decimal", 0Dh, 0Ah
                BYTE "  (2) Hexadecimal", 0Dh, 0Ah
                BYTE "  (3) Binary", 0Dh, 0Ah
                BYTE "  (4) Clear Screen", 0Dh, 0Ah
                BYTE "  (5) Exit", 0Dh, 0Ah
                BYTE "Please choose one of the menu options (1-5): ", 0
invalidMsg      BYTE "Invalid input please try again.", 0Dh, 0Ah, 0
decimalPrompt   BYTE "Please enter a 32-bit Decimal integer: ", 0
resultsMsg      BYTE 0Dh, 0Ah, "Conversion Results:", 0Dh, 0Ah, 0
hexPrompt BYTE "Please enter a 32-bit Hexadecimal Value: ", 0
binaryPrompt BYTE "Please enter a 32-bit Binary Value: ", 0
decimalLabel    BYTE "Decimal Value (Signed): ", 0
hexLabel        BYTE "Hexadecimal Value: ", 0
binLabel        BYTE "Binary Value: ", 0
binaryBuffer BYTE 100 DUP(0) 

; Variables 
userInput       SDWORD ?
menuChoice      DWORD ?

; **********************************************************************;
; Functional description of the main program                            ;
; Inputs: User input, 1-5                                               ;
; Outputs: Converts user choice into binary, decimal, or hexadecimal    ;
; Registers used: EAX stores menu input                                 ;
;                 EDX points to string messages for display             ;
; Memory locations used: menuChoice - stores user menu choice           ;
; Functional details: Shows menu options and reads selection using      ;
; ReadInt then jumps to the proper user choice. Invalid inputs restarts ;
; loop.                                                                 ;
; **********************************************************************;

.code
main PROC

menu:
    mov edx, OFFSET menuPrompt           ; Loads EDX with menuPrompt
    call WriteString                     ; Displays the menuPrompt
    call ReadInt                         ; Reads input as an integer
    mov menuChoice, eax                  ; Stores choice in menuChoice
    cmp eax, 1                           ; Checks if user entered 1
    je GetDecimalInput                   ; Jumps to GetDecimalInput if 1
    cmp eax, 2                           ; Checks if user entered 2
    je GetHexInput                       ; Jumps to GetHexInput if 2
    cmp eax, 3                           ; Checks if user entered 3
    je GetBinaryInput                    ; Jumps to GetBinaryInput if 3
    cmp eax, 4                           ; Checks if user entered 4
    je clearScreen                       ; Jumps to clearScreen logic if 4
    cmp eax, 5                           ; Checks if user entered 5
    je exitProgram                       ; Jump to exit if choice is 5
    mov edx, OFFSET invalidMsg           ; Loads EDX with invalidMsg
    call WriteString                     ; Displays invalidMsg
    jmp menu                             ; Jumps back to start of menu


; **********************************************************************;
; Procedure: GetHexInput                                                ;
; Functional description: Hexadecimal Handler, allows 8 digit user      ;
; input then converting it to decimal and binary                        ;
; Inputs: User string up to 8 digits, with or without spaces            ;
; Outputs: Displays hexadecimal, decimal, and binary                    ;
; Registers used: EAX used as accumulator and result register           ;
;                 EBX used to hold hex digits                           ;
;                 ECX used for input indexing                           ;
;                 ESI used for hex digit counter                        ;
; Memory locations used: binaryBuffer used to store input string        ;
;                        userInput used to store parsed results         ;
; Functional details: Reads and validates each hex character, validates ;
; length, prints proper format for each conversion                      ;
; **********************************************************************;

GetHexInput:
    mov edx, OFFSET hexPrompt             ; Moves hexPrompt message address into EDX
    call WriteString                      ; Prints the hex input prompt
    mov edx, OFFSET binaryBuffer          ; Moves address of binaryBuffer into EDX for storing input
    mov ecx, 100                          ; Sets ECX to the maximum input length
    call ReadString                       ; Reads the user input into binaryBuffer
    xor eax, eax                          ; Clears EAX to build the hex value
    xor ecx, ecx                          ; Clears ECX to use as input index
    mov esi, 0                            ; Sets ESI to count valid hex digits

parseHexLoop:                             ; Loop to process each character
    mov bl, binaryBuffer[ecx]             ; Moves current character into BL
    cmp bl, 0                             ; Compares BL with null terminator
    je checkLength                        ; Jumps to checkLength if end of string
    cmp bl, ' '                           ; Compares BL with space
    je skipHexChar                        ; Jumps to skipHexChar if space found
    shl eax, 4                            ; Shifts EAX left by 4 bits (for next nibble)
    cmp bl, '0'                           ; Compares BL with '0'
    jb invalidHex                         ; Jumps to invalidHex if invalid
    cmp bl, '9'                           ; Compares BL with '9'
    jbe fromDigit                         ; Jumps to fromDigit if digit is 0–9
    cmp bl, 'A'                           ; Compares BL with 'A'
    jb invalidHex                         ; Jumps to invalidHex if invalid
    cmp bl, 'F'                           ; Compares BL with 'F'
    jbe fromUpper                         ; Jumps to fromUpper if A–F
    cmp bl, 'a'                           ; Compares BL with 'a'
    jb invalidHex                         ; Jumps to invalidHex if invalid
    cmp bl, 'f'                           ; Compares BL with 'f'
    ja invalidHex                         ; Jumps to invalidHex if invalid

fromUpper:                                ; Converts A–F to 10–15
    sub bl, 'A' - 10                      ; Converts ASCII 'A'–'F' to value 10–15
    jmp storeNibble                       ; Jumps to storeNibble

fromDigit:                                ; Converts 0–9 to actual number
    sub bl, '0'                           ; Converts ASCII digit to numeric value
    jmp storeNibble                       ; Jumps to storeNibble

storeNibble:                              ; Store 4-bit hex value
    and ebx, 0Fh                          ; Masks upper bits to keep only 4 bits
    or eax, ebx                           ; Combines this digit into EAX
    inc esi                               ; Increments hex digit counter
    cmp esi, 8                            ; Compares ESI with 8
    ja invalidHex                         ; Jumps to invalidHex if too many digits

skipHexChar:                              ; Skip space or continue
    inc ecx                               ; Increments ECX to move to next character
    jmp parseHexLoop                      ; Jumps to parseHexLoop

checkLength:                              ; Check if at least one hex digit entered
    cmp esi, 1                            ; Compares ESI with 1
    jb invalidHex                         ; Jumps to invalidHex if none
    mov userInput, eax                    ; Moves final hex result into userInput
    mov edx, OFFSET resultsMsg            ; Moves resultsMsg into EDX
    call WriteString                      ; Prints "Conversion Results:"
    mov edx, OFFSET hexLabel              ; Moves hexLabel into EDX
    call WriteString                      ; Prints "Hexadecimal Value:"
    mov eax, userInput                    ; Moves userInput into EAX
    call WriteHexGrouped                  ; Prints hex value in XXXX XXXX format
    call Crlf                             ; New line
    mov edx, OFFSET decimalLabel          ; Moves decimalLabel into EDX
    call WriteString                      ; Prints "Decimal Value (Signed):"
    mov eax, userInput                    ; Moves userInput into EAX
    call WriteSignedInt                   ; Prints signed decimal value
    call Crlf                             ; New line
    mov edx, OFFSET binLabel              ; Moves binLabel into EDX
    call WriteString                      ; Prints "Binary Value:"
    mov eax, userInput                    ; Moves userInput into EAX
    call WriteBinGrouped                  ; Prints binary value in 4-bit groups
    call Crlf                             ; New line
    jmp menu                              ; Jumps to menu

invalidHex:                               ; Invalid input handler
    mov edx, OFFSET invalidMsg            ; Moves invalidMsg into EDX
    call WriteString                      ; Prints error message
    jmp menu                              ; Jumps to menu


; **********************************************************************;
; Procedure: WriteHexGrouped                                            ;
; Functional description: Prints 32-bit hex value formatted             ;
; Inputs: EAX - contains value to print                                 ;
; Outputs: 8-digit hex                                                  ;
; Registers used: EAX used for halves                                   ;
;                 EDX used to store original value                      ;
; Memory locations used: None                                           ;
; Functional details: Splits input into upper and lower 16 bits,        ;
; formats each as 4-digit hex, and adds a space between groups          ;
; **********************************************************************;

WriteHexGrouped PROC
    push eax                      ; Save original 32-bit value on stack
    push edx                      ; Save EDX in case we need to reuse it
    mov edx, eax                  ; Backup full 32-bit value into EDX
    mov eax, edx                  ; Move original value into EAX
    shr eax, 16                   ; Shift right to isolate upper 16 bits
    and eax, 0FFFFh               ; Mask to ensure we only keep the top 16 bits
    call PrintHex4Digits          ; Print upper 4-digit hex group
    mov al, ' '                   ; Load space character into AL
    call WriteChar                ; Print space between hex groups
    mov eax, edx                  ; Restore original value into EAX
    and eax, 0FFFFh               ; Mask to get only lower 16 bits
    call PrintHex4Digits          ; Print lower 4-digit hex group
    pop edx                       ; Restore EDX
    pop eax                       ; Restore original EAX
    ret                           ; Return back to caller
WriteHexGrouped ENDP

; **********************************************************************;
; Procedure: PrintHex4Digits                                            ;
; Functional description: Prints hexadecimal in proper format in groups ;
; of 4                                                                  ;
; Inputs: EAX (0–FFFF)                                                  ;
; Outputs: Prints 4 hexadecimal characters                              ;
; Registers used: EAX used for nibble value                             ;
;                 ECX used for loop counter                             ;
;                 EDX used for shifting buffer                          ;
; Memory locations used: None                                           ;
; Functional details: Examines EAX and extracts the 4-bit chunks, then  ;
; it formats it for proper output                                       ;
; **********************************************************************;

PrintHex4Digits PROC
    push eax                      ; Pushes EAX to save the original value
    push ecx                      ; Pushes ECX to save loop counter
    push edx                      ; Pushes EDX for shifting
    mov ecx, 4                    ; Sets ECX to 4
    mov edx, eax                  ; Copies input value from EAX into EDX

printLoop:
    shl edx, 4                    ; Shifts EDX left by 4
    mov eax, edx                  ; Moves shifted EDX into EAX
    shr eax, 16                   ; Shifts EAX right to move nibble down
    and eax, 0Fh                  ; Masks EAX to keep only the lowest 4 bits
    cmp eax, 0Ah                  ; Compares EAX with 10
    jb digit                      ; Jumps to digit if it's 0–9
    add al, 'A' - 10              ; Converts values 10–15 to ASCII letters A–F
    jmp show                      ; Jumps to show to print the character

digit:
    add al, '0'                   ; Converts values 0–9 to ASCII characters

show:
    call WriteChar                ; Prints the current hex digit
    loop printLoop                ; Jumps to printLoop if not zero
    pop edx                       ; Restores EDX
    pop ecx                       ; Restores ECX
    pop eax                       ; Restores EAX
    ret                           ; Returns to the caller
PrintHex4Digits ENDP

; **********************************************************************;
; Functional description: Handles decimal input and conversions         ;
; Inputs: User entered decimal value                                    ;
; Outputs: User inputted decimal, hexadecimal, and binary conversions   ;
; Registers used: EAX used to hold result and calculations              ;
;                 EBX used to hold individual values                    ;
;                 ECX used for string parsing and overflow checker      ;
;                 ESI used as sign multiplier                           ;
; Memory locations used: binaryBuffer - stores user input string        ;
;                        userInput - stores parsed and validated result ;
; Functional details: Parses input string, checks for valid decimal     ;
; value, checks overflow, stores in EAX, and displays the conversions   ;
; **********************************************************************;

GetDecimalInput:
    mov edx, OFFSET decimalPrompt        ; Moves decimalPrompt into EDX
    call WriteString                     ; Prints decimalPrompt
    mov edx, OFFSET binaryBuffer         ; Moves binaryBuffer address into EDX
    mov ecx, 100                         ; Sets ECX to maximum 100 characters
    call ReadString                      ; Reads user input into binaryBuffer
    xor eax, eax                         ; Clears EAX to store decimal value
    xor ebx, ebx                         ; Clears EBX to hold current digit
    xor ecx, ecx                         ; Clears ECX to use as input string index
    mov esi, 1                           ; Assumes the input is positive
    mov bl, binaryBuffer[ecx]            ; Moves to first character from the input
    cmp bl, '-'                          ; Compares BL with '-'
    jne checkPlus                        ; Jumps to checkPlus if not a minus sign
    mov esi, -1                          ; Sets sign to negative
    inc ecx                              ; Increments ECX to move to next character
    jmp parseDec                         ; Jumps to parseDec

checkPlus:
    cmp bl, '+'                          ; Compares BL with +
    jne parseDec                         ; Jumps to parseDec if it's not a plus
    inc ecx                              ; Increments ECX to skip the + sign

parseDec:
    mov bl, binaryBuffer[ecx]            ; Gets the next character from the string
    cmp bl, 0                            ; Compares BL with null
    je applySign                         ; Jumps to applySign if end of string
    cmp bl, '0'                          ; Compares BL with 0
    jb invalidDecimal                    ; Jumps to invalidDecimal if less than 0
    cmp bl, '9'                          ; Compares BL with 9
    ja invalidDecimal                    ; Jumps to invalidDecimal if more than 9
    sub bl, '0'                          ; Converts ASCII digit to numbers
    mov edi, eax                         ; Copies value from EAX to EDI
    cmp edi, 214748364                   ; Compares EDI with max safe threshold
    ja overflowDetected                  ; Jumps to overflowDetected if too large
    jne continueParse                    ; Jumps to continueParse if safe so far
    cmp esi, 1                           ; Compares ESI with 1 
    je checkPosLimit                     ; Jumps to checkPosLimit if positive
    cmp bl, 8                            ; Compares BL with 8
    ja overflowDetected                  ; Jumps to overflowDetected if too large
    jmp continueParse                    ; Jumps to continueParse

checkPosLimit:
    cmp bl, 7                            ; Compares BL with 7
    ja overflowDetected                  ; Jumps to overflowDetected if too large

continueParse:
    imul eax, 10                         ; Multiplies EAX by 10
    add eax, ebx                         ; Adds value to the result
    inc ecx                              ; Increments ECX
    jmp parseDec                         ; Jumps to parseDec

overflowDetected:
    mov edx, OFFSET invalidMsg           ; Moves invalidMsg into EDX
    call WriteString                     ; Prints invalidMsg
    jmp menu                             ; Jumps to menu

applySign:
    imul eax, esi                        ; Applies sign multiplier to result
    mov userInput, eax                   ; Moves userInput into userInput
    mov edx, OFFSET resultsMsg           ; Moves resultsMsg into EDX
    call WriteString                     ; Prints resultsMsg
    mov edx, OFFSET decimalLabel         ; Moves decimalLabel into EDX
    call WriteString                     ; Prints decimalLabel
    mov eax, userInput                   ; Moves userInput into EAX
    call WriteSignedInt                  ; Prints signed decimal value
    call Crlf                            ; New line
    mov edx, OFFSET hexLabel             ; Moves hexLabel into EDX
    call WriteString                     ; Prints hexLabel
    mov eax, userInput                   ; Moves userInput into EAX
    call WriteHexGrouped                 ; Prints hex value in proper format
    call Crlf                            ; New line
    mov edx, OFFSET binLabel             ; Moves binLabel into EDX
    call WriteString                     ; Prints binLabel
    mov eax, userInput                   ; Moves userInput into EAX
    call WriteBinGrouped                 ; Prints binary value in proper format
    call Crlf                            ; New line
    jmp menu                             ; Jumps to menu

invalidDecimal:
    mov edx, OFFSET invalidMsg           ; Moves invalidMsg into EDX
    call WriteString                     ; Prints invalidMsg
    jmp menu                             ; Jumps to menu


; **********************************************************************;
; Procedure: WriteBinGrouped                                            ;
; Functional description: Prints binary grouped as 4                    ;
; Inputs: EAX - integer to convert and display                          ;
; Outputs: Binary string grouped by 4                                   ;
; Registers used: EAX used as current bit check index                   ;
;                 ECX used for loop counter                             ;
;                 EDX used for input value                              ;
; Memory locations used: None                                           ;
; Functional details: Loops through each bits of input from, saves      ;
; every bit, then adds a space every 4 bits                             ;
; **********************************************************************;

WriteBinGrouped PROC
    push eax                    ; Preserves EAX
    push ecx                    ; Preserves ECX
    push edx                    ; Preserves EDX 
    mov ecx, 32                 ; Sets ECX to 32 bits
    mov edx, eax                ; Copies input value into EDX

NextBit:
    mov eax, ecx                ; Moves current loop counter (ecx) into EAX
    dec eax                     ; Decrements EAX
    bt edx, eax                 ; Tests the bit at that position in EDX
    jc PrintOne                 ; Jumps to PrintOne if the bit is 1
    mov al, '0'                 ; Loads ASCII 0 into AL if bit is 0
    jmp PrintBit                ; Jumps to PrintBit

PrintOne:
    mov al, '1'                 ; Loads ASCII 1 into AL

PrintBit:
    call WriteChar              ; Prints the current bit character
    mov eax, ecx                ; Moves loop counter into EAX
    dec eax                     ; Decrements EAX to match index
    and eax, 11b                ; Masks lower 2 bits to check 4-bit group
    cmp eax, 0                  ; Compares result with 0
    jne SkipSpace               ; Jumps to SkipSpace
    cmp ecx, 1                  ; Compares ECX with 1 to check for last bit
    je SkipSpace                ; Jumps to SkipSpace if it's the last bit
    mov al, ' '                 ; Loads a space into AL
    call WriteChar              ; Prints the space after every 4 bits

SkipSpace:
    loop NextBit                ; Decrements ECX and loops if not zero
    pop edx                     ; Restores EDX
    pop ecx                     ; Restores ECX
    pop eax                     ; Restores EAX
    ret                         ; Returns to the caller
WriteBinGrouped ENDP


; **********************************************************************;
; Procedure: GetBinaryInput                                             ;
; Functional description: Allows for the user to input binary values    ;
; then converting it to hexadecimal and decimal, displaying formatted   ;
; conversions                                                           ;
; Inputs: binaryBuffer - stores input string from user                  ;
; Outputs: User inputted binary , hexadecimal , and decimal converted   ;
; Registers used: EAX used to store the final 32-bit value              ;
;                 EBX used to hold current char from input              ;
;                 ECX used to index for input loop                      ;
;                 ESI used for the total of valid bits                  ;
; Memory locations used: binaryBuffer - raw input string                ;
;                        userInput - final parsed and validated value   ;
; Functional details: Skips spaces, validates input, then prints        ;
; properly formatted result if valid                                    ;
; **********************************************************************;

GetBinaryInput:
    mov edx, OFFSET binaryPrompt         ; Moves binaryPrompt into EDX
    call WriteString                     ; Prints the binary input prompt
    mov edx, OFFSET binaryBuffer         ; Moves binaryBuffer address into EDX
    mov ecx, 100                         ; Sets ECX to max 100 characters
    call ReadString                      ; Reads user input into binaryBuffer
    xor eax, eax                         ; Clears EAX to start building binary value
    xor esi, esi                         ; Clears ESI to count valid bits
    xor ecx, ecx                         ; Clears ECX to use as input string index

parseLoop:
    mov bl, binaryBuffer[ecx]            ; Moves current character into BL
    cmp bl, 0                            ; Compares BL to 0 (null terminator)
    je validateBitCount                  ; Jumps to validateBitCount if end of string
    cmp bl, ' '                          ; Compares BL to space character
    je skipChar                          ; Jumps to skipChar if it's a space
    shl eax, 1                           ; Shifts EAX left by 1 to make room for next bit
    cmp bl, '1'                          ; Compares BL to '1'
    je setBit                            ; Jumps to setBit if it's '1'
    cmp bl, '0'                          ; Compares BL to '0'
    je incBitCount                       ; Jumps to incBitCount if it's '0'
    jmp invalidInput                     ; Jumps to invalidInput if not '0', '1', or space

setBit:
    or eax, 1                            ; Sets the least significant bit of EAX to 1

incBitCount:
    inc esi                              ; Increments ESI (bit counter)
    cmp esi, 32                          ; Compares ESI to 32
    ja invalidInput                      ; Jumps to invalidInput if more than 32 bits

skipChar:
    inc ecx                              ; Increments ECX to move to next character
    jmp parseLoop                        ; Jumps back to parseLoop to check next character

invalidInput:
    mov edx, OFFSET invalidMsg           ; Moves invalidMsg into EDX
    call WriteString                     ; Prints the invalid input error
    jmp menu                             ; Jumps to menu

validateBitCount:
    cmp esi, 1                           ; Compares ESI to 1
    jb invalidInput                      ; Jumps to invalidInput if no bits entered
    mov userInput, eax                   ; Moves final binary value into userInput
    mov edx, OFFSET resultsMsg           ; Moves resultsMsg into EDX
    call WriteString                     ; Prints resultsMsg
    mov edx, OFFSET binLabel             ; Moves binLabel into EDX
    call WriteString                     ; Prints binLabel
    mov eax, userInput                   ; Moves userInput into EAX
    call WriteBinGrouped                 ; Prints WriteBinGrouped
    call Crlf                            ; New line
    mov edx, OFFSET hexLabel             ; Moves hexLabel into EDX
    call WriteString                     ; Prints hexLabel
    mov eax, userInput                   ; Moves userInput into EAX
    call WriteHexGrouped                 ; Prints WriteHexGrouped
    call Crlf                            ; New line
    mov edx, OFFSET decimalLabel         ; Moves decimalLabel into EDX
    call WriteString                     ; Prints decimalLabel
    mov eax, userInput                   ; Moves userInput into EAX
    call WriteSignedInt                  ; Prints WriteSignedInt
    call Crlf                            ; New line
    jmp menu                             ; Jumps to menu

; **********************************************************************;
; Procedure: WriteSignedInt                                             ;
; Functional description: Prints signed integer                         ;
; Inputs: EAX - signed integer to print                                 ;
; Outputs: Properly formatted number string                             ;
; Registers used: EAX used for input and absolute value                 ;
;                 EDX used for WriteChar                                ;
; Memory locations used: None                                           ;
; Functional details: Checks if EAX is negative and adds minus sign if  ;
; appropriate                                                           ;
; **********************************************************************;

WriteSignedInt PROC
    push eax                   ; Pushes EAX
    push edx                   ; Pushes EDX
    cmp eax, 0                 ; Compares EAX with 0
    jge PrintPositive          ; Jumps to PrintPositive if EAX is not negative
    mov al, '-'                ; Loads minus sign into AL
    call WriteChar             ; Prints the minus sign
    neg eax                    ; Negates EAX to make it positive
    call WriteDec              ; Prints the absolute value
    jmp DonePrint              ; Jumps to DonePrint

PrintPositive:
    call WriteDec              ; Prints the positive value

DonePrint:
    pop edx                    ; Restores EDX
    pop eax                    ; Restores EAX
    ret                        ; Return
WriteSignedInt ENDP


; Clear Screen for user choice 4
clearScreen:
    call Clrscr                ; Clears the console screen
    jmp menu                   ; Jump to menu

exitProgram:
    INVOKE ExitProcess, 0

main ENDP
END main
