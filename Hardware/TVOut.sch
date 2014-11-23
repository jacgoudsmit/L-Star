EESchema Schematic File Version 2
LIBS:jac
LIBS:Propeddle-cache
LIBS:ttl_ieee
LIBS:power
LIBS:propeller
LIBS:crystal
LIBS:conn
EELAYER 27 0
EELAYER END
$Descr A4 11693 8268
encoding utf-8
Sheet 6 6
Title "Propeddle"
Date "23 nov 2014"
Rev "11"
Comp "(C) 2014 Jac Goudsmit"
Comment1 "Software-Defined 6502 Computer"
Comment2 "http://www.propeddle.com"
Comment3 ""
Comment4 ""
$EndDescr
$Comp
L CONN_2 P601
U 1 1 53432796
P 6250 3900
F 0 "P601" V 6200 3900 40  0000 C CNN
F 1 "TV OUT" V 6300 3900 40  0000 C CNN
F 2 "~" H 6250 3900 60  0000 C CNN
F 3 "~" H 6250 3900 60  0000 C CNN
	1    6250 3900
	1    0    0    1   
$EndComp
$Comp
L GND #PWR018
U 1 1 534327AA
P 5900 4150
F 0 "#PWR018" H 5900 4150 30  0001 C CNN
F 1 "GND" H 5900 4080 30  0001 C CNN
F 2 "" H 5900 4150 60  0000 C CNN
F 3 "" H 5900 4150 60  0000 C CNN
	1    5900 4150
	1    0    0    -1  
$EndComp
Wire Wire Line
	5900 4150 5900 4000
$Comp
L R R601
U 1 1 534327CD
P 5550 3600
F 0 "R601" V 5630 3600 40  0000 C CNN
F 1 "270" V 5557 3601 40  0000 C CNN
F 2 "~" V 5480 3600 30  0000 C CNN
F 3 "~" H 5550 3600 30  0000 C CNN
	1    5550 3600
	0    1    1    0   
$EndComp
Wire Wire Line
	5900 3600 5800 3600
Text HLabel 5300 3600 0    50   Input ~ 0
TV0
Wire Wire Line
	5900 3800 5900 3600
$EndSCHEMATC
