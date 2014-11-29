''***************************************************************************
'' Serial / Keyboard / Terminal
'' (C) 2013-2014 Jac Goudsmit
'' Terms of use: MIT license, see bottom of file.
''
'' This module combines input from the keyboard and serial port, and
'' generates output to the serial port and a 1-pin TV driver.
''***************************************************************************


OBJ
  ser:          "FullDuplexSerial"
  kb:           "Keyboard"
  tv:           "Debug_1pinTV"
  
PUB Start(rxpin, txpin, kbdatapin, kbclkpin, tvpin, baudrate)

  ser.Start(rxpin, txpin, 0, baudrate)
  kb.StartX(kbdatapin, kbclkpin, %0_000_110, %01_00000) ' Caps Lock / Num Lock on, quickest repeat
  tv.Start(tvpin) 

PUB str(s)

  ser.str(s)
  tv.str(s)

PUB dec(v)

  ser.dec(v)
  tv.dec(v)


PUB rxtime(ms) | t, rxbyte

  t := cnt
  repeat until (cnt - t) / (clkfreq / 1000) > ms
    rxbyte := ser.rxcheck
    if rxbyte <> -1
      return rxbyte
    if kb.gotkey<>0
      return kb.getkey
    
  return 0

PUB rxflush

  ser.rxflush
  kb.clearkeys

PUB tx(c)

  ser.tx(c)
  tv.chr(c)

PUB rx | rxbyte

  repeat
    rxbyte := ser.rxcheck
    if rxbyte <> -1
      return rxbyte
    if kb.gotkey <> 0
      return kb.getkey

PUB stop

  kb.stop
  ser.stop

PUB bin(v,n)

  ser.bin(v,n)
  tv.bin(v,n)

PUB hex(v,n)

  ser.hex(v,n)
  tv.hex(v,n)

PUB rxcheck | c

  c := ser.rxcheck
  if c <> -1
    return c

  if kb.gotkey <> 0
    return kb.getkey

  return -1

PUB cls

  tv.clear

PUB GotoXY(x, y)

  tv.GotoXY(x, y)