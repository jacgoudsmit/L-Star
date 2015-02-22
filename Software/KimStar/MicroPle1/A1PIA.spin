''***************************************************************************
''* Propeddle Terminal module (modified for use in the "A1" project)
''* Copyright (C) 2014 Jac Goudsmit
''*
''* TERMS OF USE: MIT License                                                            
''*
''* Permission is hereby granted, free of charge, to any person obtaining a
''* copy of this software and associated documentation files (the
''* "Software"), to deal in the Software without restriction, including
''* without limitation the rights to use, copy, modify, merge, publish,
''* distribute, sublicense, and/or sell copies of the Software, and to permit
''* persons to whom the Software is furnished to do so, subject to the
''* following conditions:
''*
''* The above copyright notice and this permission notice shall be included
''* in all copies or substantial portions of the Software.
''*
''* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
''* OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
''* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
''* IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
''* CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT
''* OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR
''* THE USE OR OTHER DEALINGS IN THE SOFTWARE.
''***************************************************************************
''
'' This module partially emulates the video and keyboard of the Apple 1.
''
'' The assembly code in this module starts a cog that maps 4 bytes of 6502
'' memory space. The memory map is compatible with the 6820 PIA, as used in
'' the Apple 1:
'' --------------------------------------------------------------------------
'' | Address | Mode  | Function                                             |
'' --------------------------------------------------------------------------
'' | base+0  | Read  | Gets the ASCII code of the last key pressed on the   |
'' |         |       | keyboard, with the msb set.                          |
'' |         |       | When reading this address, the msb in base+1 gets    |
'' |         |       | reset until a new code is available.                 |
'' |         ----------------------------------------------------------------
'' |         | Write | Ignored                                              |
'' --------------------------------------------------------------------------
'' | base+1  | Read  | msb is set to 1 when a new key is available. The msb |
'' |         |       | is reset when base+0 is read.                        |
'' |         ----------------------------------------------------------------
'' |         | Write | Ignored                                              |
'' --------------------------------------------------------------------------
'' | base+2  | Read  | Reads the byte last stored here by the 6502. The msb |
'' |         |       | is reset as soon as the byte has been sent to the    |
'' |         |       | display.                                             |
'' |         ----------------------------------------------------------------
'' |         | Write | If the msb is set, the byte is sent to the display.  |
'' |         |       | after the byte has been processed, the msb is reset. |
'' --------------------------------------------------------------------------
'' | base +3 | Read  | Ignored (only mapped for compatibility)              |
'' |         ----------------------------------------------------------------
'' |         | Write | Ignored (only mapped for compatibility)              |
'' --------------------------------------------------------------------------
''
'' Remarks:
'' - Directions in the table are from the viewpoint of the 6502.

OBJ

  hw:           "Hardware"


PUB Start(MapPtr)
'' Starts a cog that provides access to the terminal for the 6502.
''
'' Parameters:
'' - MapPtr:            First 6502 address to map (must end in %00)
                                                   
  Stop

  g_MapPtr := MapPtr

  result := cognew(@TermCog, @@0) => 0

  if result
    repeat until g_CogId ' The cog stores its own ID + 1


PUB Stop
'' Stops the cog if it is running.

  if g_CogId
    cogstop(g_CogId~ - 1)


PUB SendKey(key) | t
'' This sends a key to the 6502

  ' The Spin code is responsible for:
  ' - Setting bit 7 of the key code
  ' - Making sure that the top 24 bits of the key are different from before
  '   the function was called.
  t := ((g_Key + $100) & $FFFFFF00) | key | $80 
  result := (g_Key := t) & $7F   


PUB RcvDisp | t
'' This gets a character from the 6502
'' If a new character is available, the result is 0 or greater

  ' Note, the 6502 _sets_ bit 7 when there is a new character and we have to
  ' _reset_ it here when we pick it up.
  ' We invert bit 7 (so 0..127 indicates a new charcter) and then sign-extend
  ' the result for easy comparison.
  result := g_Display ^ $80  ' 
  if ~result => 0
    g_Display &= $7F

    
DAT

'============================================================================
' Hub access cog
'
' NOTE: This code cheats a little on the timing. It listens for the 6502 to
' read from or write to the addresses that the module is configured for,
' but when that happens, it takes two cycles to do its processing in some
' cases. Obviously, it has to handle the read or write immediately, but if
' there are too many things to do, this happens during the next 6502 cycle
' (the one AFTER the 6502 reads or writes an address in our memory area).
'
' The reason we can get away with this, is that there are only a few
' situations where the 6502 might access the same location twice:
' 1. When it retrieves a one-byte instruction to execute, it reads the
'    instruction byte from memory twice.
' 2. When it executes a read-modify-write instruction (INC or DEC), the
'    location is read in one cycle and written in the next cycle.
'
' It doesn't make much sense to execute code from an I/O location, and it
' also doesn't make much sense to increment or decrement the location where
' I/O happens, so if we stay off the databus, we can safely ignore the 6502
' to do some extra processing.


                        org     0
TermCog
                        ' Adjust the hub pointers. PAR should contain @@0.
                        '
                        ' The problem we're solving here is that the Spin
                        ' compiler writes module-relative values whenever the
                        ' @ operator is used in a DAT section, instead of
                        ' absolute hub locations. The Spin language has the
                        ' @@ operator to work around this (it converts a
                        ' module-relative pointer to an absolute pointer) so
                        ' @@0 represents the offset of the current module
                        ' which we can use to convert any pointers. It's much
                        ' more efficient to convert an entire pointer table
                        ' in Assembler than in Spin. Doing it in Assembler
                        ' also prevents problems such as accidentally doing
                        ' the conversion twice.
AdjustPtrTable                        
                        add     pointertable, PAR
                        add     AdjustPtrTable, d1
                        djnz    pointertable_len, #AdjustPtrTable

                        ' Initialize jump table at start of cog
                        ' This overwrites the initialization code
                        mov     0, #ReadWrite0
                        mov     1, #ReadWrite1
                        mov     2, #ReadWrite2
                        mov     3, #ReadWrite3
                                                             
                        ' Let caller know we're running by storing cogid + 1
                        cogid   g_CogId
                        add     g_CogId, #1
                        wrlong  g_CogId, pCogId

                        ' Wait until the clock is low, to
                        ' synchronize with the main program
                        waitpne mask_CLK0, mask_CLK0    ' Wait until CLK0 goes low
'tp=0
                        ' Nothing to do for one instruction, use this time to
                        ' jump to the main loop. 
                        jmp     #TermLoop


'============================================================================
' Data

' The following are used as both hub variables as well as local variables.
g_CogId                 long    0               ' Cog ID plus one       
g_MapPtr                long    0               ' 6502 address of data                                              
g_Key                   long    0               ' Key from keyboard (Hub->Cog only)
g_Display               long    0               ' Byte sent to terminal (Hub<->Cog)

' Pointers to hub version of the above which can be used in rdxxxx/wrxxxx
' instructions
pointertable
pCogId                  long    @g_CogId        ' Pointer to cogid
pMapPtr                 long    @g_MapPtr       ' Pointer to map pointer
pKey                    long    @g_Key          ' Pointer to keyboard byte
pDisplay                long    @g_Display      ' Pointer to display byte
pointertable_len        long    (@pointertable_len - @pointertable) >> 2

' Constants
mask_CLK0               long    (|< hw#pin_CLK0)
mask_RW                 long    (|< hw#pin_RW)
mask_ADDR               long    hw#con_mask_ADDR

d1                      long    (|< 9)          ' 1 in destination field
        
' Variables
addr                    long    0               ' Current address
data                    long    0               ' Various data

KeyFlag                 long    0               ' Bit 7 set when new kbd data available

'============================================================================
' Main Loop

TermLoop
'tp=4
                        ' Switch data bus bits back to input mode in case
                        ' we were writing data to it during the previous
                        ' cycle.                        
                        andn    DIRA, #hw#con_mask_DATA ' Take data off the data bus
'tp=8
                        ' Get the address bus, and check if we should
                        ' activate.
                        mov     addr, INA
                        and     addr, mask_ADDR         ' Remove unwanted bits
                        shr     addr, #hw#pin_A0        ' Shift in place
                        xor     addr, g_MapPtr          ' If in range, result is 0..3
                        cmp     addr, #4 wc             ' C=1 when active
'tp=28
                        ' If we're active, store the address
                        ' into the jump instruction                        
        if_c            movs    JmpIns, addr
'tp=36
                        ' There has to be at least one instruction between
                        ' modifying the jump instruction and executing it,
                        ' so check for read/write here.        
                        test    mask_RW, INA wz         ' Z=1 when 6502 is writing    
'tp=40                                                
JmpIns                        
        if_c            jmp     (0)                     ' Indirect jump based on address bus                                                                          
'tp=44
TermLoopPhi2
ReadWrite3
                        ' To jump here, tp must be 74 or lower
                        waitpne mask_CLK0, mask_CLK0    ' Wait until CLK0 goes low
'tp=0
                        jmp     #TermLoop


'============================================================================
' Accessing base+0: Read/write key code
'
' In write mode (Z=1) there's nothing to do here

 
'tp=44
ReadWrite0
                        ' In read mode, get the current key from the hub
                        ' The Spin code sets bit 7
        if_nz           rdlong  data, pKey             ' Get latest key from hub
        
'tp=52..67 read / tp=48 write
                        ' Put the key on the data bus
                        ' It 's okay if some extra bits get set, the DIRA register
                        ' will keep them from reaching the output port or from
                        ' causing any harm.
        if_nz           mov     OUTA, data
        if_nz           or      DIRA, #hw#con_mask_DATA
'tp=60..79 read / tp=52 write
                        ' In read mode as well as write mode, wait until the
                        ' next clock cycle
                        waitpne mask_CLK0, mask_CLK0    ' Wait until CLK0 goes low

                        '====================================================
                        ' Next cycle
'tp=0..5
                        ' In the best case, where hub instruction didn't delay
                        ' the wait instruction too much, we have to hold the data
                        ' on the data bus for just a few nanoseconds.
                        '
                        ' We can use this time to reset the new-key flag
        if_nz           andn    KeyFlag, #$80
'tp=4..9                                                
                        ' In the worst case where the cycle time is 80 prop clocks
                        ' and the hub instruction took the maximum time, we're now 5
                        ' clocks into the next 6502 cycle.
                        ' We have to get off the data bus NOW (possibly one cycle
                        ' later than usual, that's no big deal)
        if_nz           andn    DIRA, #hw#con_mask_DATA
'tp=8..13
                        ' Copy the new key for future comparison
        if_nz           mov     g_Key, data
'tp=12..17                        
                        ' Wait until the end of this cycle, and then go on with our
                        ' regular business.                        
                        waitpeq mask_CLK0, mask_CLK0    ' Wait until CLK0 goes high
'tp=40
                        jmp     #TermLoopPhi2

                                    
'============================================================================
' Accessing base+1: Read/write key flag
'
' In write mode (Z=1) there's nothing to do here


'tp=44
ReadWrite1
                        ' Put the key flag on the databus when in read mode
        if_nz           mov     OUTA, KeyFlag
        if_nz           or      DIRA, #hw#con_mask_DATA
'tp=52
                        ' Wait until the clock is low again.
                        waitpne mask_CLK0, mask_CLK0    ' Wait until CLK0 goes low

                        '====================================================
                        ' Next cycle
'tp=0
                        ' In write mode, we're done
        if_z            jmp     #TermLoop
'tp=4
                        ' Take the data off the data bus
                        andn    DIRA, #hw#con_mask_DATA
'tp=12
                        ' Get the current key from the hub
                        ' The Spin code sets bit 7 for compatibility,
                        rdlong  data, pKey             ' Get latest key from hub
'tp=20..35
                        ' Wait for the clock to go high
                        waitpeq mask_CLK0, mask_CLK0    ' Wait until CLK0 goes high
'tp=40                                                
                        ' Check if new key is different from the old one.
                        ' If so, set the new-key flag and store the new value.
                        ' The flag is only reset when the 6502 reads base+0.
                        cmp     g_Key, data wz
        if_nz           or      KeyFlag,  #$80          ' Set new-key bit if different
        if_nz           mov     g_Key, data             ' Store the new key
'tp=52
                        jmp     #TermLoopPhi2                        

                                    
'============================================================================
' Accessing base+2: Read/write display output


ReadWrite2
'tp=44
                        ' Jump to the write code if necessary
        if_z            jmp     #WriteDisplay
'tp=48        
                        ' In read mode, get the data from the hub
                        rdbyte  g_Display, pDisplay
'tp=52..67                        
                        ' Put the data on the data bus
                        mov     OUTA, g_Display
                        or      DIRA, #hw#con_mask_DATA
'tp=60..75
                        ' Wait until the clock is low again.
                        waitpne mask_CLK0, mask_CLK0    ' Wait until CLK0 goes low

                        '====================================================
                        ' Next cycle
'tp=0..1
                        ' In the best case, where hub instruction didn't delay
                        ' the wait instruction too much, we have to hold the data
                        ' on the data bus for just a few nanoseconds.
                        nop
'tp=4..5                        
                        ' In the worst case, we're running one cycle late.
                        ' We need to take the data off the data bus but that
                        ' leaves us no time to monitor the address bus during
                        ' this cycle. That's okay, we just wait for the next
                        ' cycle.
                        andn    DIRA, #hw#con_mask_DATA
'tp=8..9
                        ' Wait until CLK0 goes high
                        waitpeq mask_CLK0, mask_CLK0
'tp=40
                        jmp     #TermLoopPhi2
                        

                        '====================================================
                        ' Write code for base+2

WriteDisplay
'tp=48
                        ' Get data from the data bus and set the msb to let
                        ' the spin code know that this is a new value.
                        mov     g_Display, INA
                        or      g_Display, #$80
'tp=52
                        wrbyte  g_Display, pDisplay     ' Discard top 24 bits
'tp=60..75
                        jmp     #TermLoopPhi2                                                



                        fit
                   