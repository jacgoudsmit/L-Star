''***************************************************************************
''* Keyboard emulation
''* Superboard III firmware
''* Copyright (C) 2013 Jac Goudsmit, Vince Briel
''*
''* Based upon the PS/2 Keyboard Driver v1.0.1 by Chip Gracey, from the
''* Propeller library; (C) 2004 Parallax, Inc.
''*
''* TERMS OF USE: MIT License. See bottom of file.                                                            
''***************************************************************************
''
'' The OSI Keyboard Emulator is mostly the same as the PS/2 keyboard driver
'' from the Propeller library, but it has some extra functionality to
'' emulate the Ohio Scientific keyboard at the same time.
''
'' The original OSI keyboard hardware was a polled keyboard: whenever the
'' 6502 would write to address $DF00 (really any address between $DF00-$DFFF)
'' it would set and reset the latches that control the voltages on the rows
'' of the keyboard. Pressing a key on the keyboard would connect one of the
'' rows to one of the columns, and by reading address $DF00, the 6502 could
'' read the columns to find out which keys were pressed. 
''
'' The module consists of two cogs: the keyboard communicator cog and the
'' 6502 access cog. The spin code and the communicator cog are mostly the
'' same as the original keyboard driver. We just added some code to set and
'' reset bits in a table that represents the OSI keyboard matrix.
''
'' The 6502 access cog continuously monitors which addresses are being
'' accessed by the 6502. When the 6502 writes to the keyboard, the access
'' cog sets an index register. When the 6502 reads from the keyboard, it
'' gets the byte from the matrix according to the index.
''
'' The original keyboard layout is somewhat different from the usual PS/2
'' keyboard layout (Note: BREAK on the original keyboard resets the system):
''
'' 1! 2" 3# 4$ 5% 6& 7' 8( 9) 0@ :* -= RUB
'' ESC Q W E R T Y U I O P LF CR
'' CTRL A S D F G H J K L ;+ LOCK RPT BREAK
'' L-SH  Z X C V B N M ,< .> /? R-SH
''
'' The shift-lock button is the only one that's not a momentary switch on the
'' original hardware.
''
'' The regular keys (0-9, A-Z) are emulated normally but for the other keys
'' there is some quirkiness to how they're handled. For some keys such as
'' Esc and Return, it makes sense to emulate them because the key has the
'' same name as on the OSI; for other keys it makes more sense to emulate
'' the keys on OSI keyboard by the PS/2 keys that are in the same location.
'' For example the OSI has an LF and CR key to the right of the P, but it
'' doesn't have "[" or "]" so the emulator uses "[" and "]" for line feed
'' and carriage return.
''
'' Overview of the "oddities" in the emulation:
'' - ESC is emulated by Esc (for compatibility) as well as Tab (for position)
'' - RPT is emulated by Alt to prevent compatibility problems: RPT is
''   probably used in combination with other keys, and Alt is intended for
''   that purpose too, so all keyboards will be compatible with any 
''   conceivable combinations of keys with Alt. 
'' - LF is emulated by Enter on numeric pad
'' - RUBOUT is emulated by Backspace
'' - ":/*" is emulated by "-/_" and ":/=" is emulated by "=/+" because they
''   are in corresponding positions to the right of the 0.
'' - The numeric keypad emulates the same keys as the corresponding keys on
''   the main keyboard (0123456789/*-+) but for + and * the OSI requires
''   holding down Shift.
'' - The "[/{" and "]/}" keys emulate LF and CR for positional reasons
'' - The joysticks are not emulated.
  

CON

  ' Bits for lock setup
  ' See startx for more info
  #0
  lock_INIT_SCROLLLOCK
  lock_INIT_CAPSLOCK
  lock_INIT_NUMLOCK
  lock_DISABLE_SCROLLLOCK
  lock_DISABLE_CAPSLOCK
  lock_DISABLE_NUMLOCK
  lock_DISABLE_SHIFT

  ' Bitmasks based on above
  mask_INIT_SCROLLLOCK    = |< lock_INIT_SCROLLLOCK
  mask_INIT_CAPSLOCK      = |< lock_INIT_CAPSLOCK
  mask_INIT_NUMLOCK       = |< lock_INIT_NUMLOCK
  mask_DISABLE_SCROLLLOCK = |< lock_DISABLE_SCROLLLOCK
  mask_DISABLE_CAPSLOCK   = |< lock_DISABLE_CAPSLOCK
  mask_DISABLE_NUMLOCK    = |< lock_DISABLE_NUMLOCK
  mask_DISABLE_SHIFT      = |< lock_DISABLE_SHIFT

  ' Auto repeat setup bitmasks
  ' See startx for more info
  ' Choose one delay and one rate 
  mask_REPEAT_DELAY_250MS  = %00_00000
  mask_REPEAT_DELAY_500MS  = %01_00000
  mask_REPEAT_DELAY_750MS  = %10_00000
  mask_REPEAT_DELAY_1S     = %11_00000
  '  
  mask_REPEAT_RATE_30CPS   = %00_00000
  mask_REPEAT_RATE_26_7CPS = %00_00001
  mask_REPEAT_RATE_24_0CPS = %00_00010
  mask_REPEAT_RATE_21_8CPS = %00_00011
  mask_REPEAT_RATE_20_7CPS = %00_00100
  mask_REPEAT_RATE_18_5CPS = %00_00101
  mask_REPEAT_RATE_17_1CPS = %00_00110
  mask_REPEAT_RATE_16_0CPS = %00_00111
  mask_REPEAT_RATE_15_0CPS = %00_01000
  mask_REPEAT_RATE_13_3CPS = %00_01001
  mask_REPEAT_RATE_12CPS   = %00_01010
  mask_REPEAT_RATE_10_9CPS = %00_01011
  mask_REPEAT_RATE_10CPS   = %00_01100
  mask_REPEAT_RATE_9_2CPS  = %00_01101
  mask_REPEAT_RATE_8_6CPS  = %00_01110
  mask_REPEAT_RATE_8_0CPS  = %00_01111
  mask_REPEAT_RATE_7_5CPS  = %00_10000
  mask_REPEAT_RATE_6_7CPS  = %00_10001
  mask_REPEAT_RATE_6CPS    = %00_10010
  mask_REPEAT_RATE_5_5CPS  = %00_10011
  mask_REPEAT_RATE_5CPS    = %00_10100
  mask_REPEAT_RATE_4_6CPS  = %00_10101
  mask_REPEAT_RATE_4_3CPS  = %00_10110
  mask_REPEAT_RATE_4CPS    = %00_10111
  mask_REPEAT_RATE_3_7CPS  = %00_11000
  mask_REPEAT_RATE_3_3CPS  = %00_11001
  mask_REPEAT_RATE_3_0CPS  = %00_11010
  mask_REPEAT_RATE_2_7CPS  = %00_11011
  mask_REPEAT_RATE_2_5CPS  = %00_11100
  mask_REPEAT_RATE_2_3CPS  = %00_11101
  mask_REPEAT_RATE_2_1CPS  = %00_11110
  mask_REPEAT_RATE_2CPS    = %00_11111

  ' Length of fields in instance array
  len_states = 8
  len_matrix = 2
  len_keys   = 8
  
  ' Indexes in instance array. Directions are from Spin's point of view
  #0
  idx_tail                      ' key buffer tail       read/write; must be first item
  idx_head                      ' key buffer head       read-only
  idx_present                   ' keyboard present      read-only
  idx_states[len_states]        ' key states (256 bits) read-only
  idx_matrix[len_matrix]        ' key matrix (8 bytes)  read-only
  idx_keys[len_keys]            ' key buffer (16 words) read-only
  ' Last value declares size of table
  idx_num

  ' Indexes in instance array that are erased in PASM code on reset 
  idx_resetstart = idx_head
  idx_resetend = idx_num

  ' Indexes in instance array to copy from cog to hub
  idx_copystart = idx_head
  idx_copyend = idx_num
  
OBJ
  hw:   "Hardware"              ' Constants for hardware

VAR

  long  kbcog
  long  accesscog

  ' Instance array, see section above for index values
  long  instance[idx_num]

PUB start(par_dpin, par_cpin, par_addrmask, par_addrmatch) : okay

'' Start keyboard driver - starts a cog
'' returns false if no cog available
''
''   par_dpin  = data signal on PS/2 jack
''   par_cpin  = clock signal on PS/2 jack
''
''     use 100-ohm resistors between pins and jack
''     use 10K-ohm resistors to pull jack-side signals to VDD
''     connect jack-power to 5V, jack-gnd to VSS
''
'' all lock-keys will be enabled, NumLock will be initially 'on',
'' and auto-repeat will be set to 30cps with a delay of 250ms

  okay := startx(par_dpin, par_cpin, mask_INIT_NUMLOCK, mask_REPEAT_DELAY_250MS | mask_REPEAT_RATE_30CPS, par_addrmask, par_addrmatch)


PUB startx(par_dpin, par_cpin, par_locks, par_auto, par_addrmask, par_addrmatch) : okay

'' Like start, but allows you to specify lock settings and auto-repeat
''
''   par_locks = lock setup
''           bit 6 disallows shift-alphas (case set soley by CapsLock)
''           bits 5..3 disallow toggle of NumLock/CapsLock/ScrollLock state
''           bits 2..0 specify initial state of NumLock/CapsLock/ScrollLock
''           (eg. %0_001_100 = disallow ScrollLock, NumLock initially 'on')
''
''   par_auto  = auto-repeat setup
''           bits 6..5 specify delay (0=.25s, 1=.5s, 2=.75s, 3=1s)
''           bits 4..0 specify repeat rate (0=30cps..31=2cps)
''           (eg %01_00000 = .5s delay, 30cps repeat)

  stop
  ' Fill hub 
  _dpin  := par_dpin
  _cpin  := par_cpin
  _locks := par_locks
  _auto  := par_auto
  okay := kbcog := cognew(@KbCogEntry, @instance) + 1

  if okay  
    addr := @instance[idx_matrix]
    addrmask := par_addrmask
    addrmatch := par_addrmatch
    okay := accesscog := cognew(@AccessCogEntry, @@0) + 1
    if not okay
      stop  

PUB stop

'' Stop keyboard driver - frees a cog

  if accesscog
    cogstop(accesscog~ - 1)
    
  if kbcog
    cogstop(kbcog~ - 1)
    
  longfill(@instance, 0, idx_num)


PUB present : truefalse

'' Check if keyboard present - valid ~2s after start
'' returns t|f

  truefalse := -instance[idx_present]


PUB key : keycode

'' Get key (never waits)
'' returns key (0 if buffer empty)

  if instance[idx_tail] <> instance[idx_head]
    keycode := word[@instance[idx_keys]][instance[idx_tail]]
    instance[idx_tail] := ++instance[idx_tail] & $F


PUB getkey : keycode

'' Get next key (may wait for keypress)
'' returns key

  repeat until (keycode := key)


PUB newkey : keycode

'' Clear buffer and get new key (always waits for keypress)
'' returns key

  instance[idx_tail] := instance[idx_head]
  keycode := getkey


PUB gotkey : truefalse

'' Check if any key in buffer
'' returns t|f

  truefalse := instance[idx_tail] <> instance[idx_head]


PUB clearkeys

'' Clear key buffer

  instance[idx_tail] := instance[idx_head]


PUB keystate(k) : state

'' Get the state of a particular key
'' returns t|f

  state := -(instance[idx_states+(k >> 5)] >> k & 1)


PUB getmatrix

  result := @instance[idx_matrix]
  
DAT

'******************************************
'* Assembly language PS/2 keyboard driver *
'******************************************

                        org
'
'
' Entry
'
KBCogEntry
                        mov     dmask,#1                'set pin masks
                        shl     dmask,_dpin
                        mov     cmask,#1
                        shl     cmask,_cpin

                        test    _dpin,#$20      wc      'modify port registers within code
                        muxc    _d1,dlsb
                        muxc    _d2,dlsb
                        muxc    _d3,#1
                        muxc    _d4,#1

                        test    _cpin,#$20      wc
                        muxc    _c1,dlsb
                        muxc    _c2,dlsb
                        muxc    _c3,#1

                        mov     _inst+idx_head,#0       'reset output parameter _head
'
'
' Reset keyboard
'
reset                   mov     dira,#0                 'reset directions
                        mov     dirb,#0

                        movd    :par,#_inst+idx_resetstart 'reset instance
                        mov     x,#idx_resetend-idx_resetstart
:par                    mov     0,#0
                        add     :par,dlsb
                        djnz    x,#:par

resetmatrix
                        movd    :par,#_inst+idx_matrix  'reset matrix to all ones
                        mov     x,#len_matrix
:par                    mov     0,mask_FFFFFFFF
                        add     :par,dlsb
                        djnz    x,#:par

                        mov     stat,#8                 'set reset flag
'
'
' Update parameters
'
update                  movd    :par,#_inst+idx_copystart 'update hub instance from cog
                        mov     x,par
                        add     x,#idx_copystart*4
                        mov     y,#idx_copyend-idx_copystart
:par                    wrlong  0,x
                        add     :par,dlsb
                        add     x,#4
                        djnz    y,#:par

                        test    stat,#8         wc      'if reset flag, transmit reset command
        if_c            mov     data,#$FF
        if_c            call    #transmit
'
'
' Get scancode
'
newcode                 mov     stat,#0                 'reset state

:same                   call    #receive                'receive byte from keyboard

                        cmp     data,#$83+1     wc      'scancode?

        if_nc           cmp     data,#$AA       wz      'powerup/reset?
        if_nc_and_z     jmp     #configure

        if_nc           cmp     data,#$E0       wz      'extended?
        if_nc_and_z     or      stat,#1
        if_nc_and_z     jmp     #:same

        if_nc           cmp     data,#$F0       wz      'released?
        if_nc_and_z     or      stat,#2
        if_nc_and_z     jmp     #:same

        if_nc           jmp     #newcode                'unknown, ignore
'
'
' Translate scancode and enter into buffer
'
                        shl     data,#1                 'data = scancode * 2
                        test    stat,#1         wc
                        rcl     data,#1                 'data = scancode * 4 + extendedflag
                        call    #look

                        cmp     data,#0         wz      'if unknown, ignore
        if_z            jmp     #newcode

                        mov     t,_inst+idx_states+6             'remember lock keys in _states

                        mov     x,data                  'set/clear key bit in _states
                        shr     x,#5
                        add     x,#_inst+idx_states
                        movd    :reg,x
                        mov     y,#1
                        shl     y,data
                        test    stat,#2         wc
:reg                    muxnc   0,y

                        shr     longdata,#16            'set/clear key bit in matrix
                        test    stat,#1         wc      'extended?
        if_c            shr     longdata,#8             'get high matrix byte
                        and     longdata,#$FF
                        mov     x,longdata
                        shr     x,#5
                        add     x,#_inst+idx_matrix
                        movd    :reg2,x
                        mov     y,#1
                        shl     y,longdata
                        test    stat,#2         wc
:reg2                   muxc    0,y                     'reset on make, set on break                                                
                        
        if_nc           cmpsub  data,#$F0       wc      'if released or shift/ctrl/alt/win, done
        if_c            jmp     #update

                        mov     y,_inst+idx_states+7    'get shift/ctrl/alt/win bit pairs
                        shr     y,#16

                        cmpsub  data,#$E0       wc      'translate keypad, considering numlock
        if_c            test    _locks,#%100    wz
        if_c_and_z      add     data,keypad1offset
        if_c_and_nz     add     data,keypad2offset
        if_c            call    #look
        if_c            jmp     #:flags

                        cmpsub  data,#$DD       wc      'handle scrlock/capslock/numlock
        if_c            mov     x,#%001_000
        if_c            shl     x,data
        if_c            andn    x,_locks
        if_c            shr     x,#3
        if_c            shr     t,#29                   'ignore auto-repeat
        if_c            andn    x,t             wz
        if_c            xor     _locks,x
        if_c            add     data,#$DD
        if_c_and_nz     or      stat,#4                 'if change, set configure flag to update leds

                        test    y,#%11          wz      'get shift into nz

        if_nz           cmp     data,#$60+1     wc      'check shift1
        if_nz_and_c     cmpsub  data,#$5B       wc
        if_nz_and_c     add     data,shift1offset
        if_nz_and_c     call    #look
        if_nz_and_c     andn    y,#%11

        if_nz           cmp     data,#$3D+1     wc      'check shift2
        if_nz_and_c     cmpsub  data,#$27       wc
        if_nz_and_c     add     data,shift2offset
        if_nz_and_c     call    #look
        if_nz_and_c     andn    y,#%11

                        test    _locks,#%010    wc   'check shift-alpha, considering capslock
                        muxnc   :shift,#$20
                        test    _locks,#$40     wc
        if_nz_and_nc    xor     :shift,#$20
                        cmp     data,#"z"+1     wc
        if_c            cmpsub  data,#"a"       wc
:shift  if_c            add     data,#"A"
        if_c            andn    y,#%11

:flags                  ror     data,#8                 'add shift/ctrl/alt/win flags
                        mov     x,#4                    '+$100 if shift
:loop                   test    y,#%11          wz      '+$200 if ctrl
                        shr     y,#2                    '+$400 if alt
        if_nz           or      data,#1                 '+$800 if win
                        ror     data,#1
                        djnz    x,#:loop
                        rol     data,#12

                        rdlong  x,par                   'if room in buffer and key valid, enter
                        sub     x,#1
                        and     x,#$F
                        cmp     x,_inst+idx_head wz
        if_nz           test    data,#$FF       wz
        if_nz           mov     x,par
        if_nz           add     x,#idx_keys*4
        if_nz           add     x,_inst+idx_head
        if_nz           add     x,_inst+idx_head
        if_nz           wrword  data,x
        if_nz           add     _inst+idx_head,#1
        if_nz           and     _inst+idx_head,#$F

                        test    stat,#4         wc      'if not configure flag, done
        if_nc           jmp     #update                 'else configure to update leds
'
'
' Configure keyboard
'
configure               mov     data,#$F3               'set keyboard auto-repeat
                        call    #transmit
                        mov     data,_auto
                        and     data,#%11_11111
                        call    #transmit

                        mov     data,#$ED               'set keyboard lock-leds
                        call    #transmit
                        mov     data,_locks
                        rev     data,#-3 & $1F
                        test    data,#%100      wc
                        rcl     data,#1
                        and     data,#%111
                        call    #transmit

                        mov     x,_locks             'insert locks into _states
                        and     x,#%111
                        shl     _inst+idx_states+7,#3
                        or      _inst+idx_states+7,x
                        ror     _inst+idx_states+7,#3

                        mov     _inst+idx_present,#1    'set _present

                        test    _locks, #$2     wc
                        muxc    _inst+idx_matrix,#1     'set matrix bit for row 0 col 0 according to capslock

                        jmp     #update                 'done
'
'
' Lookup byte in table
'
look                    ror     data,#2                 'perform lookup
                        movs    :reg,data
                        add     :reg,#table
                        shr     data,#27
                        mov     x,data
:reg                    mov     data,0
                        mov     longdata,data
                        shr     data,x

                        jmp     #rand                   'isolate byte
'
'
' Transmit byte to keyboard
'
transmit
_c1                     or      dira,cmask              'pull clock low
                        movs    napshr,#13              'hold clock for ~128us (must be >100us)
                        call    #nap
_d1                     or      dira,dmask              'pull data low
                        movs    napshr,#18              'hold data for ~4us
                        call    #nap
_c2                     xor     dira,cmask              'release clock

                        test    data,#$0FF      wc      'append parity and stop bits to byte
                        muxnc   data,#$100
                        or      data,dlsb

                        mov     x,#10                   'ready 10 bits
transmit_bit            call    #wait_c0                'wait until clock low
                        shr     data,#1         wc      'output data bit
_d2                     muxnc   dira,dmask
                        mov     wcond,c1                'wait until clock high
                        call    #wait
                        djnz    x,#transmit_bit         'another bit?

                        mov     wcond,c0d0              'wait until clock and data low
                        call    #wait
                        mov     wcond,c1d1              'wait until clock and data high
                        call    #wait

                        call    #receive_ack            'receive ack byte with timed wait
                        cmp     data,#$FA       wz      'if ack error, reset keyboard
        if_nz           jmp     #reset

transmit_ret            ret
'
'
' Receive byte from keyboard
'
receive                 test    _cpin,#$20      wc      'wait indefinitely for initial clock low
                        waitpne cmask,cmask
receive_ack
                        mov     x,#11                   'ready 11 bits
receive_bit             call    #wait_c0                'wait until clock low
                        movs    napshr,#16              'pause ~16us
                        call    #nap
_d3                     test    dmask,ina       wc      'input data bit
                        rcr     data,#1
                        mov     wcond,c1                'wait until clock high
                        call    #wait
                        djnz    x,#receive_bit          'another bit?

                        shr     data,#22                'align byte
                        test    data,#$1FF      wc      'if parity error, reset keyboard
        if_nc           jmp     #reset
rand                    and     data,#$FF               'isolate byte

look_ret
receive_ack_ret
receive_ret             ret
'
'
' Wait for clock/data to be in required state(s)
'
wait_c0                 mov     wcond,c0                '(wait until clock low)

wait                    mov     y,tenms                 'set timeout to 10ms

wloop                   movs    napshr,#18              'nap ~4us
                        call    #nap
_c3                     test    cmask,ina       wc      'check required state(s)
_d4                     test    dmask,ina       wz      'loop until got state(s) or timeout
wcond   if_never        djnz    y,#wloop                '(replaced with c0/c1/c0d0/c1d1)

                        tjz     y,#reset                'if timeout, reset keyboard
wait_ret
wait_c0_ret             ret


c0      if_c            djnz    y,#wloop                '(if_never replacements)
c1      if_nc           djnz    y,#wloop
c0d0    if_c_or_nz      djnz    y,#wloop
c1d1    if_nc_or_z      djnz    y,#wloop
'
'
' Nap
'
nap                     rdlong  t,#0                    'get clkfreq
napshr                  shr     t,#18/16/13             'shr scales time
                        min     t,#3                    'ensure waitcnt won't snag
                        add     t,cnt                   'add cnt to time
                        waitcnt t,#0                    'wait until time elapses (nap)

nap_ret                 ret
'
'
' Initialized data
'
'
dlsb                    long    1 << 9
tenms                   long    10_000 / 4
'
'
' Column:  7    6    5    4    3    2    1    0      Byte offset in matrix table
'         -------------------------------------- 
' Row 7:   1!   2"   3#   4$   5%   6&   7'          $38
' Row 6:   8(   9)   0@   :*   -=   RUB              $30
' Row 5:   .>   L    O    LF   CR                    $28
' Row 4:   W    E    R    T    Y    U    I           $20
' Row 3:   S    D    F    G    H    J    K           $18
' Row 2:   X    C    V    B    N    M    ,<          $10
' Row 1:   Q    A    Z    SP   /?   ;+   P           $08
' Row 0:   RPT  CTRL ESC            L-SH R-SH LOCK   $00
'
' Lookup table
' The following table is used to convert scan codes. 
' Each entry contains 4 bytes, shown here as a long. From LSB to MSB, these
' are the values of each byte:
' - ASCII code for the scan code
' - ASCII code for the extended scan code (preceded by E0 when received from
'   the keyboard)
' - Matrix code for the scan code (see below)          
' - Matrix code for the extended scan code (see below)
'
' The matrix codes represent a position in the OSI keyboard matrix, using
' 3 bits for the row and 3 bits for the column. For example, a value of
' $1F (%011_101) represents row 3 (%011) column 5 (%101), i.e. "F".
' Value 0 is used to indicate scan codes that aren't used, in the ASCII.
' bytes as well as in the matrix bytes. Note that the matrix position for
' row 0 col 0 is actually a valid key, but it's the shift-lock key which
' is handled in a different way because it needs to be emulated as a
' non-momentary switch: push it once to turn it on and push it again to
' turn it off.
' 
'                             matrix/ascii  scan    extkey  regkey  ()=keypad
'
table                   long    $00000000   '00
                        long    $000000D8   '01             F9
                        long    $00000000   '02
                        long    $000000D4   '03             F5
                        long    $000000D2   '04             F3
                        long    $000000D0   '05             F1
                        long    $000000D1   '06             F2
                        long    $000000DB   '07             F12
                        long    $00000000   '08
                        long    $000000D9   '09             F10
                        long    $000000D7   '0A             F8
                        long    $000000D5   '0B             F6
                        long    $000000D3   '0C             F4
                        long    $00050009   '0D             Tab
                        long    $00000060   '0E             `
                        long    $00000000   '0F
                        long    $00000000   '10
                        long    $0707F5F4   '11     Alt-R   Alt-L
                        long    $000200F0   '12             Shift-L
                        long    $00000000   '13
                        long    $0606F3F2   '14     Ctrl-R  Ctrl-L
                        long    $000F0071   '15             q
                        long    $003F0031   '16             1
                        long    $00000000   '17
                        long    $00000000   '18
                        long    $00000000   '19
                        long    $000D007A   '1A             z
                        long    $001F0073   '1B             s
                        long    $000E0061   '1C             a
                        long    $00270077   '1D             w
                        long    $003E0032   '1E             2
                        long    $0000F600   '1F     Win-L
                        long    $00000000   '20
                        long    $00160063   '21             c
                        long    $00170078   '22             x
                        long    $001E0064   '23             d
                        long    $00260065   '24             e
                        long    $003C0034   '25             4
                        long    $003D0033   '26             3
                        long    $0000F700   '27     Win-R
                        long    $00000000   '28
                        long    $000C0020   '29             Space
                        long    $00150076   '2A             v
                        long    $001D0066   '2B             f
                        long    $00240074   '2C             t
                        long    $00250072   '2D             r
                        long    $003B0035   '2E             5
                        long    $0000CC00   '2F     Apps
                        long    $00000000   '30
                        long    $0013006E   '31             n
                        long    $00140062   '32             b
                        long    $001B0068   '33             h
                        long    $001C0067   '34             g
                        long    $00230079   '35             y
                        long    $003A0036   '36             6
                        long    $0000CD00   '37     Power
                        long    $00000000   '38
                        long    $00000000   '39
                        long    $0012006D   '3A             m
                        long    $001A006A   '3B             j
                        long    $00220075   '3C             u
                        long    $00390037   '3D             7
                        long    $00370038   '3E             8
                        long    $0000CE00   '3F     Sleep
                        long    $00000000   '40
                        long    $0011002C   '41             ,
                        long    $0019006B   '42             k
                        long    $00210069   '43             i
                        long    $002D006F   '44             o
                        long    $00350030   '45             0
                        long    $00360039   '46             9
                        long    $00000000   '47
                        long    $00000000   '48
                        long    $002F002E   '49             .
                        long    $0B0BEF2F   '4A     (/)     /
                        long    $002E006C   '4B             l
                        long    $000A003B   '4C             ;
                        long    $00090070   '4D             p
                        long    $0034002D   '4E             -
                        long    $00000000   '4F
                        long    $00000000   '50
                        long    $00000000   '51
                        long    $00000027   '52             '
                        long    $00000000   '53
                        long    $002C005B   '54             [
                        long    $0033003D   '55             =
                        long    $00000000   '56
                        long    $00000000   '57
                        long    $004000DE   '58             CapsLock
                        long    $000100F1   '59             Shift-R
                        long    $2C2BEB0D   '5A     (Enter) Enter
                        long    $002B005D   '5B             ]
                        long    $00000000   '5C
                        long    $0000005C   '5D             \
                        long    $0000CF00   '5E     WakeUp
                        long    $00000000   '5F
                        long    $00000000   '60
                        long    $00000000   '61
                        long    $00000000   '62
                        long    $00000000   '63
                        long    $00000000   '64
                        long    $00000000   '65
                        long    $003200C8   '66             BackSpace
                        long    $00000000   '67
                        long    $00000000   '68
                        long    $003FC5E1   '69     End     (1)
                        long    $00000000   '6A
                        long    $003CC0E4   '6B     Left    (4)
                        long    $0039C4E7   '6C     Home    (7)
                        long    $00000000   '6D
                        long    $00000000   '6E
                        long    $00000000   '6F
                        long    $0035CAE0   '70     Insert  (0)
                        long    $002FC9EA   '71     Delete  (.)
                        long    $003EC3E2   '72     Down    (2)
                        long    $003B00E5   '73             (5)
                        long    $003AC1E6   '74     Right   (6)
                        long    $0037C2E8   '75     Up      (8)
                        long    $000500CB   '76             Esc
                        long    $000000DF   '77             NumLock
                        long    $000000DA   '78             F11
                        long    $000A00EC   '79             (+)
                        long    $003DC7E3   '7A     PageDn  (3)
                        long    $003300ED   '7B             (-)
                        long    $0034DCEE   '7C     PrScr   (*)
                        long    $0036C6E9   '7D     PageUp  (9)
                        long    $004100DD   '7E             ScrLock
                        long    $00000000   '7F
                        long    $00000000   '80
                        long    $00000000   '81
                        long    $00000000   '82
                        long    $000000D6   '83             F7
                                     
keypad1                 byte    $CA, $C5, $C3, $C7, $C0, 0, $C1, $C4, $C2, $C6, $C9, $0D, "+-*/"

keypad2                 byte    "0123456789.", $0D, "+-*/"

shift1                  byte    "{|}", 0, 0, "~"

shift2                  byte    $22, 0, 0, 0, 0, "<_>?)!@#$%^&*(", 0, ":", 0, "+"

keypad1offset           long    @keypad1-@table
keypad2offset           long    @keypad2-@table
shift1offset            long    @shift1-@table
shift2offset            long    @shift2-@table

mask_FFFFFFFF           long    $FFFFFFFF

' Constants stored at init time
_dpin                   long    0       'read-only at start
_cpin                   long    0       'read-only at start
_locks                  long    0       'read-only at start
_auto                   long    0       'read-only at start
        
'
'
' Uninitialized data
'
dmask                   res     1
cmask                   res     1
stat                    res     1
data                    res     1
longdata                res     1
x                       res     1
y                       res     1
t                       res     1

' Instance data, copied from here to hub location set by PAR
_inst                   res     idx_num

                        fit
''
''
''      _________
''      Key Codes
''
''      00..DF  = keypress and keystate
''      E0..FF  = keystate only
''
''
''      09      Tab
''      0D      Enter
''      20      Space
''      21      !
''      22      "
''      23      #
''      24      $
''      25      %
''      26      &
''      27      '
''      28      (
''      29      )
''      2A      *
''      2B      +
''      2C      ,
''      2D      -
''      2E      .
''      2F      /
''      30      0..9
''      3A      :
''      3B      ;
''      3C      <
''      3D      =
''      3E      >
''      3F      ?
''      40      @       
''      41..5A  A..Z
''      5B      [
''      5C      \
''      5D      ]
''      5E      ^
''      5F      _
''      60      `
''      61..7A  a..z
''      7B      {
''      7C      |
''      7D      }
''      7E      ~
''
''      80-BF   (future international character support)
''
''      C0      Left Arrow
''      C1      Right Arrow
''      C2      Up Arrow
''      C3      Down Arrow
''      C4      Home
''      C5      End
''      C6      Page Up
''      C7      Page Down
''      C8      Backspace
''      C9      Delete
''      CA      Insert
''      CB      Esc
''      CC      Apps
''      CD      Power
''      CE      Sleep
''      CF      Wakeup
''
''      D0..DB  F1..F12
''      DC      Print Screen
''      DD      Scroll Lock
''      DE      Caps Lock
''      DF      Num Lock
''
''      E0..E9  Keypad 0..9
''      EA      Keypad .
''      EB      Keypad Enter
''      EC      Keypad +
''      ED      Keypad -
''      EE      Keypad *
''      EF      Keypad /
''
''      F0      Left Shift
''      F1      Right Shift
''      F2      Left Ctrl
''      F3      Right Ctrl
''      F4      Left Alt
''      F5      Right Alt
''      F6      Left Win
''      F7      Right Win
''
''      FD      Scroll Lock State
''      FE      Caps Lock State
''      FF      Num Lock State
''
''      +100    if Shift
''      +200    if Ctrl
''      +400    if Alt
''      +800    if Win
''
''      eg. Ctrl-Alt-Delete = $6C9
''
''
'' Note: Driver will buffer up to 15 keystrokes, then ignore overflow.

DAT
                        org     0
AccessCogEntry
                        ' Copy the code to address $100 in the cog so we can
                        ' generate a table at the start of the cog memory
:movemem                mov     $100, StartAccessCog
                        add     :movemem, d1s1
                        djnz    movesize, #:movemem
                        jmp     #$100

                        ' These variables have to be in the "org 0" area
d1s1                    long    %1_000000001            ' One in source, One in destination                        
movesize                long    EndAccessCog - StartAccessCog

StartAccessCog
                        org     $100

                        ' Generate the lookup table that represents the
                        ' index in the matrix table based on a bit pattern.
                        '
                        ' The matrix that's updated by the keyboard
                        ' communication cog, represents the key(s) that is
                        ' or are depressed in real-time. Each byte in the
                        ' matrix represents the columns for one row.
                        ' The task of the keyboard access cog is to decode
                        ' which row the 6502 wants to "see".
                        ' In theory, it's possible for the 6502 to select
                        ' multiple rows by writing a bit pattern that has
                        ' multiple bits set. However, we can't emulate that
                        ' because we would have to OR the selected rows
                        ' together, which would simply take too long.
                        '
                        ' Instead, we do a "best effort" implementation:
                        ' whenever the 6502 writes a value, the highest
                        ' significant bit determines which row is read.
                        ' For example: if the 6502 writes %1001, we pretend
                        ' that it wrote %1000 so when the 6502 reads the
                        ' columns back, it will get the columns for row 3
                        ' (not the columns for row 3 or 1). This might cause
                        ' some problems in rare situations, but should be
                        ' acceptable in normal cases.
                        '
                        ' We do this by building a table that converts every
                        ' possible value of a byte (the data that was written
                        ' by the 6502) to a row number. Basically this is a
                        ' table of base-2 log table for values between 1
                        ' and 255.
                        '
                        ' Note: The indexes in the table are inversed (i.e.
                        ' xor'ed with $FF.
                        ' So entry %1111_1110 = &_matrix[0]    (1 entry)
                        '          %1111_110* = &_matrix[1]    (2 entries)
                        '          %1111_10** = &_matrix[2]    (4 entries)
                        '          %1111_0*** = &_matrix[3]    (8 entries)
                        '          %1110_**** = &_matrix[4]   (16 entries)
                        '          %110*_**** = &_matrix[5]   (32 entries)
                        '          %10**_**** = &_matrix[6]   (64 entries)
                        '          %0***_**** = &_matrix[7]   (128 entries)
                        ' When the 65C02 writes %1111_1111 (no columns activated),
                        ' it always reads %1111_1111. This is accomplished by
                        ' modifying the rdbyte instruction to have an if_never
                        ' condition.
                        '
:buildtable             mov     $FE, addr               ' addr is set to @matrix                             
                        sub     :buildtable, d1
                        djnz    counter, #:buildtable
                        
                        shl     oneshift, #1
                        cmp     oneshift, #$100 wz
        if_nz           add     addr, #1
        if_nz           mov     counter, oneshift
        if_nz           jmp     #:buildtable                          

                        ' MAIN LOOP
WaitForPhi2
                        ' Wait until clock goes high
                        waitpne zero, mask_CLK0

WaitForPhi1
                        ' Wait until clock goes low
                        waitpeq zero, mask_CLK0
' t=0
                        ' Take any previous data off the bus while we wait
                        ' for the address bus to settle (tADS < 40ns)
                        andn    DIRA, #hw#con_mask_DATA
' t=4
                        ' Get the inputs
                        mov     addr, INA
                        test    addr, mask_RW wc        ' C=0 when 6502 is writing
                        shr     addr, #hw#pin_A0        ' Shift address bus to bottom bits
' t=12
                        and     addr, addrmask
                        cmp     addr, addrmatch wz
                        mov     databus, #$FF           ' Default databus write-back value
        if_nz           jmp     #WaitForPhi2
' t=28        
                        ' Wait until clock goes high
                        waitpne zero, mask_CLK0
' t=40                        
        if_nc           jmp     #Write
' t=44
                        ' The 6502 is reading
                        ' Put the value from the table on the data bus
                        ' If the 6502 wrote FF, the next instruction will have been
                        ' changed to if_never, otherwise, if_always
readins
        if_always       rdbyte  databus, 0              ' Source is replaced on write                                                                     
' t=52..67
                        mov     OUTA, databus
                        mov     DIRA, #hw#con_mask_DATA
                        jmp     #WaitForPhi1
' t=60..75                        

Write
' t=44
                        ' The 6502 is writing databus
                        ' The jump instruction that brought us here should have
                        ' taken us past the data setup time (tMDS < 40ns) too.                        
                        mov     databus, INA
                        and     databus, #hw#con_mask_DATA
                        cmp     databus, #$FF wz        ' When writing FF, always read FF
                        muxnz   readins, mux_never_always                        
' t=60                        
                        ' Store the byte as the cog address for all subsequent reads
                        movs    readins, databus
                        jmp     #WaitForPhi1
' t=68                                                        

addr                    long    0                       ' Initialized to @matrix by Spin
addrmask                long    0                       ' Initialized to address mask by Spin
addrmatch               long    0                       ' Initialized to address to match by Spin

databus                 long    0
counter                 long    1
oneshift                long    1        

                        ' Constants
mux_never_always        long    %000000_0000_1111_000000000_000000000                        
zero                    long    0                        
d1                      long    |<9
mask_CLK0               long    |< hw#pin_CLK0
mask_RW                 long    |< hw#pin_RW


EndAccessCog            fit                                                                               

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