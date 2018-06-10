''***************************************************************************
''* Tracing clock generator
''* Copyright (C) 2018 Jac Goudsmit
''*
''* TERMS OF USE: MIT License. See bottom of file.                                                            
''***************************************************************************
''
'' The API of this module is the same as the ClockGen module but instead of
'' generating the clock with a timer, it starts a cog that uses the TXX
'' module to send current status to the PC on every cycle.
''
OBJ
  hw:           "Hardware"      ' Constants for hardware
  txx:          "Txx"           ' High speed serial transmitter                        

PUB Init(frequency)
'' Initialize the clock generator.
''
  
  ' Initialize the clock and SDA pins as output, and set them both high for now,
  ' so that the 6502 access cogs can ready themselves by waiting for CLK0 to go low.
  outa[hw#pin_SDA]~~                                    '
  dira[hw#pin_SDA]~~                                    ' The SDA pin must remain high so the EEPROM doesn't get activated.
  outa[hw#pin_CLK0]~~                                   ' Override the clock with a high signal for now
  dira[hw#pin_CLK0]~~                                   ' Set CLK0 pin to output for Phase 0 clock

  g_pcmd := txx.Start(hw#pin_TX, 1_000_000)
  g_halfperiod := (clkfreq / frequency) >> 1
  txx.Str(string("Trace cog active",13))
  txx.Wait
  cognew(@tracecog, @@0)
  
PUB Activate

  outa[hw#pin_CLK0]~                                    ' Remove override for the clock

DAT

                        org     0
tracecog
                        mov     DIRA, mask_CLK0

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
ins_init                add     pointertable, PAR
                        add     ins_init, d1
                        djnz    pointertable_len, #ins_init

                        ' Get pointer to the command for the TXX module
                        rdlong  g_pcmd, p_pcmd
                        
mainloop
                        ' Wait for half period 
                        mov     timestamp, CNT
                        add     timestamp, g_halfperiod
                        waitcnt timestamp, #0

                        ' Just before pulling the clock down, take a sample
                        mov     data, INA

                        ' Make the clock output low
                        mov     OUTA, #0

                        ' Wait until clock actually goes low in case it's on hold
                        waitpeq zero, mask_CLK0

                        ' Take a timestamp
                        mov     timestamp, CNT
                        add     timestamp, g_halfperiod
                        
                        ' Print the end-of-line
                        call    #wait_txx
                        wrlong  cmd_str_CRLF, g_pcmd

                        ' Print R or W depending on R/!W
                        call    #wait_txx
                        test    data, mask_RW wz
              if_z      wrlong  cmd_str_W, g_pcmd
              if_nz     wrlong  cmd_str_R, g_pcmd

                        ' Write the address to the hub
                        mov     g_value, data
                        shr     g_value, #hw#pin_A0
                        call    #wait_txx
                        wrword  g_value, p_value
                        wrlong  cmd_hex_word_value, g_pcmd

                        ' Write space
                        call    #wait_txx
                        wrlong  cmd_str_space, g_pcmd

                        ' Write data bus
                        mov     g_value, data
                        'shr    g_value, #hw#pin_D0
                        call    #wait_txx
                        wrbyte  g_value, p_value
                        wrlong  cmd_hex_byte_value, g_pcmd

                        ' Wait for end of Phi0 
                        waitcnt timestamp, #0                                    
                                        
                        ' Make the clock high
                        or      OUTA, mask_CLK0

                        ' Next cycle
                        jmp     #mainloop

                        ' Wait until TXX is ready
wait_txx                        
                        rdlong  cmd, g_pcmd wz
              if_nz     jmp     #wait_txx
wait_txx_ret
                        ret              

                        ' Communication between hub and cog
g_pcmd                  long    0
g_value                 long    0
g_halfperiod            long    0           

                        ' Pointer table; these are corrected by the PASM code
pointertable                        
p_pcmd                  long    @g_pcmd
p_value                 long    @g_value
cmd_hex_long_value      long    txx#mask_LONG_HEX | txx#mask_SINGLE | @g_value
cmd_hex_word_value      long    txx#mask_WORD_HEX | txx#mask_SINGLE | @g_value
cmd_hex_byte_value      long    txx#mask_BYTE_HEX | txx#mask_SINGLE | @g_value
cmd_str_CRLF            long    @str_CRLF
cmd_str_R               long    @str_R
cmd_str_W               long    @str_W
cmd_str_space           long    txx#mask_CHAR | txx#mask_SINGLE | @str_space                                 
pointertable_len        long    $ - pointertable                        

                        ' Constants
zero                    long    0
d1                      long    |< 9             
mask_CLK0               long    |< hw#pin_CLK0
mask_RW                 long    |< hw#pin_RW

                        ' Cog variables overlap the following hub data
data                    res     1
cmd                     res     1
timestamp               res     1

                        ' This data is not used in the cog, only in the hub
str_CRLF                byte    13, 0
str_R                   byte    "R ", 0
str_W                   byte    "W ", 0
str_SPACE               byte    " "        

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