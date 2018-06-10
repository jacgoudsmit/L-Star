''***************************************************************************
''* SRAM Chip Control Cog for L-Star project
''* Copyright (C) 2016 Jac Goudsmit
''*
''* TERMS OF USE: MIT License. See bottom of file.                                                            
''***************************************************************************
''
'' This module can be used to control a static RAM chip such as the one on
'' the L-Star Plus circuit board. 
''
'' The module starts a cog that first builds a table in cog RAM, and then
'' controls the hw#pin_RAMEN pin to turn the SRAM chip on and off.
''
'' The table that the cog uses has a resolution of 16 addresses. So you can
'' control the enabling of the RAM in blocks of 16 bytes, as seen from the
'' 6502. Reading and writing are controlled separately.  

CON
  ' The following are commands that are sent to the PASM code during setup.
  ' Some commands are OR'ed with parameter values; the PASM code only checks
  ' the lowest bits to match the command. See remarks elsewhere for more
  ' information.
  #0
  cmd_NONE                      ' No command, must be 0
  cmd_ADD_READ                  ' Add area to enable for reading
  cmd_ADD_WRITE                 ' Add area to enable for writing
  cmd_RUN                       ' Start controlling the SRAM chip
  cmd_RUNNING                   ' Cog sets this value when running                                                 

  con_RESOLUTION_BITS = 4       ' This number of bits in address is block size
  con_MASK_RESOLUTION = $FFFF & !((|< con_RESOLUTION_BITS) - 1) ' Address resolution of the cog
  con_MASK_CMD        = $F      ' Mask to get command; should not overlap resolution
    
OBJ
  hw:   "Hardware"              ' Constants for hardware

VAR
  ' Cmd contains the following bit pattern:
  ' LLLLLLLLLLLL****AAAAAAAAAAAA*RCC
  ' Where: L=upper bits of length
  '        *=ignored
  '        A=upper bits of start address
  '        R=is set when main loop running
  '        C=command
  long  Cmd                     ' Data to the cog, must follow Response
  byte  MyCogId                 ' Cog ID + 1; 0=stopped  
  
PUB Init(RamLenParm) 
'' Start an SRAM control cog
''
'' Parameters:
'' - RamLen: word
''   Allows configuring a contiguous block of addresses starting at $0000
''   to map as RAM (read/write). The value must be a multiple of 16 ($10).
''   The rest of the address space is not mapped to the RAM chip (neither
''   for read, nor for write).
''
'' Result: True if successful

  ' Stop first, in case we're already started 
  Stop

  Cmd := cmd_RUNNING

  MyCogId := cognew(@SRAMCtrlCog, @Cmd) + 1

  if (MyCogId)
    repeat until Cmd == 0 ' The cog resets Cmd
    
    AddRam(0, RamLenParm)    

PUB Stop
'' Stops the cog if it is running.

  if MyCogId~~
    cogstop(MyCogId~~ - 1)
    MyCogId := 0
    Cmd := 0

PUB AddRam(StartAddress, Length)
'' Add a read-write area for which the RAM chip should be enabled.
'' This only works if the cog has been started but is not in Run mode.
'' The area cannot wrap around the 64K border. 
''
'' Parameters:
'' - StartAddress: word
''   Address in 6502 address space. Must be a multiple of 16.
'' - Length: word
''   Address in 6502 address space. Must be a multiple of 16.   

  if (MyCogId <> 0) and (Cmd == cmd_NONE) and (StartAddress + Length < $1_0000)
    Cmd := cmd_ADD_WRITE | (StartAddress & con_MASK_RESOLUTION) | ((Length & con_MASK_RESOLUTION) << 16)

    repeat
    until Cmd == cmd_NONE

    ' We added the area for writing, now add it for reading  
    AddRom(StartAddress, Length)
    
PUB AddRom(StartAddress, Length)
'' Add a read-only area for which the RAM chip should be enabled.
'' This only works if the cog has been started but is not in Run mode.
'' The area cannot wrap around the 64K border. 
''
'' Parameters:
'' - StartAddress: word
''   Address in 6502 address space. Must be a multiple of 16.
'' - Length: word
''   Address in 6502 address space. Must be a multiple of 16.   

  if (MyCogId <> 0) and (Cmd == cmd_NONE) and (StartAddress + Length < $1_0000)
    Cmd := cmd_ADD_READ | (StartAddress & con_MASK_RESOLUTION) | ((Length & con_MASK_RESOLUTION) << 16)

    repeat
    until Cmd == cmd_NONE

PUB Start
'' Switch the RAM control cog to run mode. It will start controlling
'' the SRAM chip based on the table in cog RAM.
'' Afterwards, the table can no longer be altered.

  if (MyCogId <> 0) and (Cmd == cmd_NONE)
    Cmd := cmd_RUN

    repeat
    until Cmd <> cmd_RUN

DAT
                        org     0
                        ' The code relocates itself to make space for a
                        ' table that represents what the output should be
                        ' for each block of 6502 memory space. Each bit
                        ' represents a block of addresses. During the main
                        ' loop, the Propeller probes the address bus and
                        ' the R/~W pin of the 6502 to calculate an index
                        ' into the table and a bit number within the long
                        ' word stored there. The R/~W pin value is used as
                        ' an and extra bit on top of the address bus, so
                        ' the lower half of the table is for write access
                        ' and the upper half of the table is for read
                        ' access (from the viewpoint of the 6502).
SRamCtrlCog
                                   
                        ' Relocate code to make space for the table                        
RelocLoop
RelocStep               mov     RelocEnd, RelocEnd - (RelocDestination - RelocSource)
                        sub     RelocStep, RelocOneOne           
                        djnz    RelocCounter, #RelocLoop

                        jmp     #RelocDestination

RelocOneOne             long    %1_000000001            ' One in source, one in destination        
RelocCounter            long    RelocDestination - RelocSource             
RelocSource
                        org     256
RelocDestination

'============================================================================
' Command interpreter

                         ' Set the pin to output and disable the SRAM chip
                        mov     OUTA, mask_RAMENB
                        mov     DIRA, mask_RAMENB

                        ' Initialize the table with value $FFFFFFFF to
                        ' disable the RAM chip everywhere
ClearLoop                        
ClearStep               mov     0, FFFFFFFF
                        add     ClearStep, D1
                        djnz    counter, #ClearLoop                        

                        ' Reset the command to let Spin know we're ready
EndCmd                        
                        wrlong  zero, PAR

                        ' Wait for a new command
CmdLoop
                        rdlong  addr, PAR       wz
        if_z            jmp     #CmdLoop

                        ' Extract the command
                        mov     data, addr              ' Make a copy
                        and     data, #con_mask_CMD
                        
                        ' The Run command doesn't have parameters
                        cmp     data, #cmd_RUN  wz
        if_e            jmp     #Handle_Run

                        ' Extract Length parameter from upper 16 bits
                        mov     counter, addr           ' Make a copy                         
                        shr     counter, #(16 + con_RESOLUTION_BITS) wz ' Number of blocks to enable
        if_z            jmp     #EndCmd                 ' Nothing to do

                        ' Extract address parameter from lower 16 bits
                        and     addr, mask_FFFF         ' addr is address in 6502 space
                        shr     addr, #con_RESOLUTION_BITS ' addr is block number

                        ' Process commands with parameters
                        cmp     data, #cmd_ADD_WRITE wz
        if_e            jmp     #Handle_AddWrite
                        cmp     data, #cmd_ADD_READ wz
        if_ne           jmp     #EndCmd                 ' Unknown command

                        ' Handle ADD_READ command
                        ' The index in the table is based on the R/~W bit
                        ' which is expected to be on a pin adjacent to A15.
                        ' In other words: the lower half of the table is
                        ' for when the 6502 is writing, and the upper half
                        ' is for when it's reading.  
Handle_AddRead
                        or      addr, mask_RW_SHIFTED
                        ' Fall through to AddWrite handler

                        ' Handle ADD_WRITE command
Handle_AddWrite
ModifyLoop
                        ' Calculate index and bit index
                        mov     data, addr 
                        mov     bitindex, data 
                        and     bitindex, #$1F
                        shr     data, #5

                        ' Modify the instruction that modifies the entry from the table
                        movd    ModifyEntry, data

                        ' We need one instruction between the modifying code
                        ' and the modified code, so set up the bit mask here
                        shl     mask, bitindex
ModifyEntry
                        andn    (0-0), mask             ' Reset the requested bit

                        ' Reset the bit mask
                        mov     mask, #1

                        ' Next bit
                        add     addr, #1
                        djnz    counter, #ModifyLoop

                        ' Done
                        jmp     #EndCmd                          

'============================================================================
' Run mode

Handle_Run
                        ' Let Spin know we're running
                        mov     data, #cmd_RUNNING
                        wrlong  data, PAR

                        ' Wait until clock goes high
                        waitpne zero, mask_CLK0
                        ' Fall through to main loop

MainLoop
                        ' Wait until clock goes low
                        waitpeq zero, mask_CLK0
' t=0
                        ' Take any previous data off the bus while we wait
                        ' for the address bus to settle (tADS < 40ns)
                        or      OUTA, mask_RAMENB
' t=4
                        ' Get the address and R/!W bit
                        mov     addr, INA
                        shr     addr, #(hw#pin_A0 + con_RESOLUTION_BITS)
                        and     addr, mask_RW_ADDR_SHIFTED ' addr is block number
' t=16
                        ' Split the address between long-index and bit-index
                        mov     bitindex, addr
                        and     bitindex, #$1F          ' bitindex now contains bit index in long in table
                        shr     addr, #5                ' addr now contains index in table
' t=28
                        ' Modify the instruction that reads the entry from
                        ' the table
                        movs    LoadEntry, addr
' t=32
                        ' We need one instruction between the modifying code
                        ' and the modified code, so set up the bit mask here
                        shl     mask, bitindex
LoadEntry
                        mov     data, (0-0)             ' Load the entry from the table
                        test    data, mask      wz      ' Z=1 if SRAM should be enabled
' t=40
                        ' Wait until clock goes high, in case it's running
                        ' slower than 1Mhz      
                        waitpne zero, mask_CLK0
' t=46
                        ' Enable the SRAM chip if necessary
        if_z            andn    OUTA, mask_RAMENB

                        ' Reset the bit mask
                        mov     mask, #1            
' t=54        
                        jmp     #MainLoop
' t=58

'============================================================================
' Constants

zero                    long    0                       ' 0
FFFFFFFF                long    $FFFFFFFF               ' $FFFFFFFF                                           
mask_FFFF               long    $FFFF                   ' $FFFF
d1                      long    (|<9)                   ' 1 in destination field
mask_RAMENB             long    (|<hw#pin_RAMENB)       ' Output pin mask
mask_CLK0               long    (|<hw#pin_CLK0)         ' Clock pin mask
mask_RW_ADDR_SHIFTED    long    $1_FFFF >> con_RESOLUTION_BITS ' Mask for R/!W pin and address
mask_RW_SHIFTED         long    $1_0000 >> con_RESOLUTION_BITS ' Bitmask for R/!W for table setup        

'============================================================================
' Data

counter                 long    256                     ' Counter for table setup
addr                    long    0
data                    long    0
bitindex                long    0
mask                    long    1

'============================================================================
' End

RelocEnd
                        fit

CON     
''***************************************************************************
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
