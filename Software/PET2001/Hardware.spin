''***************************************************************************
''* Hardware constants for TV/1-pin keyboard/SRAM use
''* Copyright (C) 2016 Jac Goudsmit
''*
''* TERMS OF USE: MIT License. See bottom of file.                                                            
''***************************************************************************
''
'' This version of the Hardware module corresponds to the L-Star Plus
'' with jumpers placed as follows:
''
'' +-+-+-+-+-+
'' |#|#|#| | |
'' +#+#+#+-+-+
'' |#|#|#|###|
'' +-+-+-+-+-+
'' | | | | | |
'' +-+-+-+-+-+
'' | | | | | |
'' +-+-+-+-+-+
'' | | | | | |
'' +-+-+-+-+-+
'' | | | | | |
'' +-+-+-+-+-+
'' | | | | | |
'' +-+-+-+-+-+
'' P25 P26 P27
''

CON

  '==========================================================================
  ' Pin definitions
  '==========================================================================
  
  #0                            ' Start enumeration from 0
  ' P0
  pin_D0                        ' \                        
  pin_D1                        '  |
  pin_D2                        '  |
  pin_D3                        '  | [In/Out] Data bus of the 6502
  ' P4                          '  |
  pin_D4                        '  |
  pin_D5                        '  |
  pin_D6                        '  |
  pin_D7                        ' /
  ' P8
  pin_A0                        ' \
  pin_A1                        ' |
  pin_A2                        ' |
  pin_A3                        ' |
  ' P12                         ' |
  pin_A4                        ' |
  pin_A5                        ' | [In] Address bus from 6502
  pin_A6                        ' |
  pin_A7                        ' |
  ' P16                           |
  pin_A8                        ' |
  pin_A9                        ' |
  pin_A10                       ' |
  pin_A11                       ' |
  ' P20                         ' |
  pin_A12                       ' |
  pin_A13                       ' |
  pin_A14                       ' |
  pin_A15                       '/
  ' P24 
  pin_RW                        ' [In]  R/!W from 6502
  pin_TV                        ' [Out] Video out (monochrome TV)
  pin_KBDATA                    ' [In]  Keyboard data (1-pin keyboard)
  pin_RAMENB                    ' [Out] LOW to enable RAM
  ' P28
  pin_CLK0                      ' [Out] CLK0 to 6502 (shared with SCL on EEPROM)
  pin_SDA                       ' [Out] SDA on EEPROM
  pin_TX                        ' [Out] Serial port Tx out from Propeller
  pin_RX                        ' [In]  Serial port Rx in to Propeller


  '==========================================================================
  ' BitMasks
  '==========================================================================
  
  ' Data bus
  con_mask_DATA = (|<pin_D0) | (|<pin_D1) | (|<pin_D2) | (|<pin_D3) | (|<pin_D4) | (|<pin_D5) | (|<pin_D6) | (|<pin_D7)

  ' Address bus
  con_mask_ADDR = (|<pin_A0) | (|<pin_A1) | (|<pin_A2) | (|<pin_A3) | (|<pin_A4) | (|<pin_A5) | (|<pin_A6) | (|<pin_A7) | (|<pin_A8) | (|<pin_A9) | (|<pin_A10) | (|<pin_A11) | (|<pin_A12) | (|<pin_A13) | (|<pin_A14) | (|<pin_A15)

  ' Address bus and R/!W
  con_mask_RW_ADDR = (|<pin_RW) | con_mask_ADDR

PUB dummy
  ' Every module must have at least one PUB function otherwise it won't compile

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