''***************************************************************************
'' Serial / Keyboard / Terminal
'' (C) 2013-2014 Jac Goudsmit
'' Terms of use: MIT license, see bottom of file.
''
'' This module combines input from the keyboard and serial port, and
'' generates output to the serial port and a screen buffer viewport.
''***************************************************************************


OBJ
  ser:          "FullDuplexSerial"
  kb:           "Keyboard"
  vp:           "ScreenBufferText"
  
PUB Start(rxpin, txpin, kbdatapin, kbclkpin, baudrate, screenbuf, screencols, screenrows, viewcols, viewrows, viewleft, viewtop)

  ser.Start(rxpin, txpin, 0, baudrate)
  kb.Start(kbdatapin, kbclkpin)
  vp.Start(screenbuf, screencols, screenrows, viewcols, viewrows, viewleft, viewtop, vp#CRLF_CR_LF) 
  
PUB str(s)

  ser.str(s)
  vp.str(s)

PUB dec(v)

  ser.dec(v)
  vp.dec(v)


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
  vp.chr(c)

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
  vp.bin(v,n)

PUB hex(v,n)

  ser.hex(v,n)
  vp.hex(v,n)

PUB rxcheck | c

  c := ser.rxcheck
  if c <> -1
    return c

  if kb.gotkey <> 0
    return kb.getkey

  return -1

PUB cls

  vp.cls