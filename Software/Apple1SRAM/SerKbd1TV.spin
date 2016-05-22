''***************************************************************************
'' Serial / Keyboard / Terminal
'' (C) 2013-2016 Jac Goudsmit
'' Terms of use: MIT license, see bottom of file.
''
'' This module combines input from the keyboard and serial port, and
'' generates output to the serial port and a 1-pin TV driver.
''***************************************************************************


OBJ
  ser:          "FullDuplexSerial"
  kb:           "1PinKBD"
  tv:           "Debug_1pinTV"

var
  long havekb
    
PUB Start(rxpin, txpin, kbdatapin, tvpin, baudrate) | t

  ser.Start(rxpin, txpin, 0, baudrate)
  tv.Start(tvpin)

  if (kbdatapin => 0)
    str(string("Hit SPACE on the PS/2 keyboard..."))
    t := kb.calckbdtime(kbdatapin)
    kb.start(kbdatapin, t & $FFFF, t >> 16)
    havekb := 1 

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
    if havekb and kb.rxavail
      return kb.in
    
  return 0

PUB rxflush | x

  ser.rxflush
  if havekb
    repeat while kb.rxavail
      x := kb.in

PUB tx(c)

  ser.tx(c)
  tv.chr(c)

PUB rx | rxbyte

  repeat
    rxbyte := ser.rxcheck
    if rxbyte <> -1
      return rxbyte
    if havekb and kb.rxavail
      return kb.in

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

  if havekb and kb.rxavail
    return kb.in

  return -1

PUB cls

  tv.clear

PUB GotoXY(x, y)

  tv.GotoXY(x, y)
  