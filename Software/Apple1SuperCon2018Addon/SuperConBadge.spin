''***************************************************************************
'' Terminal module for Prop Plug and SuperCon 2018 Badge
'' (C) 2013-2018 Jac Goudsmit
'' Terms of use: MIT license, see bottom of file.
''
'' This module combines serial input and output from the Prop Plug and the
'' Hackaday Supercon 2018 Badge.
''***************************************************************************
''
'' This module was specifically written for the Badge Add-On version of the
'' L-Star project. See https://hackaday.io/project/3620-l-star-software-defined-6502-computer/log/155608-l-star-as-a-supercon2018-badge-add-on
''
'' I wanted to compete in the badge hack competition but unfortunately I
'' misread the schematic of the badge and connected the serial port to the
'' wrong pins. By the time I figured this out, it was too late to fix it.
''
'' There were also some minor problems with the software on the badge;
'' for example it expects to see a line feed to go to the start of the next
'' line on the screen (which is reasonable) but in Apple 1 land and in
'' Propeller land, the end of a line is a Carriage Return (which is very
'' non-traditional but that's the way it is).
''
'' Also, at the time of the conference, the badge would generate lower-case
'' ASCII by default and had no Caps Lock, and the Enter key on the badge
'' generated a Line Feed (to match the way the output to the screen worked)
'' and you had to hold shift to send a carriage return. This has been fixed
'' in my commit here: https://github.com/jacgoudsmit/2018-Supercon-Badge/commit/b8718f6039a63543cffd2e73b12ac075f06f7696
'' The previous commit in my Github repo is also needed because it turns the
'' terminal demonstration program for the badge into a full-duplex terminal
'' and resets the UART at startup time. Without resetting the UART, the
'' badge would get stuck because there was some garbage on the RX pin of the
'' badge that would cause the UART to go into error mode and stop working.

OBJ
  ser:          "FullDuplexSerial"
  badge:        "FullDuplexSerial"
  hw:           "Hardware"              
  
PUB Start(baudrate, badgebaudrate)

  ser.Start(hw#pin_RX, hw#pin_TX, 0, baudrate)
  badge.Start(hw#pin_RXBADGE, hw#pin_TXBADGE, 0, badgebaudrate)
  
PUB str(s)

  ' Send a string by calling the character routine for each serial
  ' port separately. This way, the badge has enough time to catch the
  ' incoming traffic. If you send the entire string to the Prop plug
  ' and then send the string to the badge, the badge's UART overruns and
  ' goes into error state. 
  repeat strsize(s)
    tx(byte[s++])

PUB dec(v)

  ser.dec(v)
  badge.dec(v)

PUB rxtime(ms) | t, rxbyte

  t := cnt
  repeat until (cnt - t) / (clkfreq / 1000) > ms
    rxbyte := ser.rxcheck
    if rxbyte <> -1
      return rxbyte
    rxbyte := badge.rxcheck
    if rxbyte <> -1
      return rxbyte    
    
  return 0

PUB rxflush

  ser.rxflush
  badge.rxflush

PUB tx(c)

  ser.tx(c)
  ' Badge ignores CR but handles LF as CR+LF
  if c == 13
    c := 10
  badge.tx(c)

PUB rx | rxbyte

  repeat
    rxbyte := ser.rxcheck
    if rxbyte <> -1
      return rxbyte
    rxbyte := badge.rxcheck
    if rxbyte <> -1
      return rxbyte

PUB stop

  ser.stop
  badge.stop

PUB bin(v,n)

  ser.bin(v,n)
  badge.bin(v,n)

PUB hex(v,n)

  ser.hex(v,n)
  badge.hex(v,n)

PUB rxcheck | c

  c := ser.rxcheck
  if c <> -1
    return c
  c := badge.rxcheck
  if c <> -1
    return c

  return -1
