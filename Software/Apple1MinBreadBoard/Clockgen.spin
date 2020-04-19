''***************************************************************************
''* Clock generator for L-Star project
''* Copyright (C) 2014 Jac Goudsmit
''*
''* TERMS OF USE: MIT License. See bottom of file.                                                            
''***************************************************************************
''
'' The clock for the 65C02 is generated on the same pin as the I2C clock for
'' the EEPROM. The EEPROM won't activate and won't interfere, as long as we
'' keep the SDA line high.
''
OBJ
  hw:           "Hardware"      ' Constants for hardware
  freq:         "Synth"         ' Frequency synthesizer from Propeller library 
  
PUB Init(frequency)
'' Initialize the clock generator.
''
'' If the Propeller is running at 80MHz (5MHz crystal), the maximum frequency
'' for the 65C02 is 1MHz (1_000_000). If you use a faster crystal, you can
'' run the 65C02 at a faster frequency too. For example, a 6.25MHz crystal
'' runs the Propeller at 100MHz (25% overclocked), you can run the 65C02
'' at 1.25MHz (1_250_000).

  ' Initialize the clock and SDA pins as output, and set them both high for now,
  ' so that the 6502 access cogs can ready themselves by waiting for CLK0 to go low.
  outa[hw#pin_SDA]~~                                    '
  dira[hw#pin_SDA]~~                                    ' The SDA pin must remain high so the EEPROM doesn't get activated.
  outa[hw#pin_CLK0]~~                                   ' Override the clock with a high signal for now
  dira[hw#pin_CLK0]~~                                   ' Set CLK0 pin to output for Phase 0 clock

  ' Start the clock
  if frequency <> 0
    freq.Synth("A", hw#pin_CLK0, frequency)

  ' To save a little bit of space (34 longs at the time of this writing), you
  ' can remove the Synth module and use the following hard-coded commands
  ' instead to generate 1MHz.
  'ctra := %00100_000 << 23 + 1 << 9 + hw#pin_CLK0
  'frqa := $333_0000

PUB Activate

  outa[hw#pin_CLK0]~                                    ' Remove override for the clock

PUB Deactivate

  outa[hw#pin_CLK0]~~                                   ' Override for the clock to high
  
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