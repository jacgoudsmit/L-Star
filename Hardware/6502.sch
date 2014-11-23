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
Sheet 4 6
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
L GND #PWR013
U 1 1 5339E09A
P 4950 5900
F 0 "#PWR013" H 4950 5900 30  0001 C CNN
F 1 "GND" H 4950 5830 30  0001 C CNN
F 2 "" H 4950 5900 60  0000 C CNN
F 3 "" H 4950 5900 60  0000 C CNN
	1    4950 5900
	1    0    0    -1  
$EndComp
$Comp
L C C401
U 1 1 5339E0A6
P 6900 4900
F 0 "C401" H 6900 5000 40  0000 L CNN
F 1 "100n" H 6906 4815 40  0000 L CNN
F 2 "~" H 6938 4750 30  0000 C CNN
F 3 "~" H 6900 4900 60  0000 C CNN
	1    6900 4900
	1    0    0    -1  
$EndComp
$Comp
L 65(C)02 IC401
U 1 1 5339E0CA
P 4950 4400
F 0 "IC401" H 4600 5750 60  0000 C CNN
F 1 "WDC 65C02" H 5250 3050 60  0000 C CNN
F 2 "~" H 4950 4400 60  0000 C CNN
F 3 "~" H 4950 4400 60  0000 C CNN
	1    4950 4400
	1    0    0    -1  
$EndComp
Text HLabel 4350 3200 0    50   BiDi ~ 0
D0
Text HLabel 4350 3300 0    50   BiDi ~ 0
D1
Text HLabel 4350 3400 0    50   BiDi ~ 0
D2
Text HLabel 4350 3500 0    50   BiDi ~ 0
D3
Text HLabel 4350 3600 0    50   BiDi ~ 0
D4
Text HLabel 4350 3700 0    50   BiDi ~ 0
D5
Text HLabel 4350 3800 0    50   BiDi ~ 0
D6
Text HLabel 4350 3900 0    50   BiDi ~ 0
D7
Text HLabel 4350 4100 0    50   3State ~ 0
A0
Text HLabel 4350 4200 0    50   3State ~ 0
A1
Text HLabel 4350 4300 0    50   3State ~ 0
A2
Text HLabel 4350 4400 0    50   3State ~ 0
A3
Text HLabel 4350 4500 0    50   3State ~ 0
A4
Text HLabel 4350 4600 0    50   3State ~ 0
A5
Text HLabel 4350 4700 0    50   3State ~ 0
A6
Text HLabel 4350 4800 0    50   3State ~ 0
A7
Text HLabel 4350 4900 0    50   3State ~ 0
A8
Text HLabel 4350 5000 0    50   3State ~ 0
A9
Text HLabel 4350 5100 0    50   3State ~ 0
A10
Text HLabel 4350 5200 0    50   3State ~ 0
A11
Text HLabel 4350 5300 0    50   3State ~ 0
A12
Text HLabel 4350 5400 0    50   3State ~ 0
A13
Text HLabel 4350 5500 0    50   3State ~ 0
A14
Text HLabel 4350 5600 0    50   3State ~ 0
A15
Text HLabel 6550 5200 2    50   Input ~ 0
CLK0
Text HLabel 6550 3800 2    50   Output ~ 0
R/~W
Text HLabel 6550 3200 2    50   Input ~ 0
~RESET
$Comp
L VCC #PWR014
U 1 1 5346220A
P 4950 2500
F 0 "#PWR014" H 4950 2600 30  0001 C CNN
F 1 "VCC" H 4950 2600 30  0000 C CNN
F 2 "" H 4950 2500 60  0000 C CNN
F 3 "" H 4950 2500 60  0000 C CNN
	1    4950 2500
	1    0    0    -1  
$EndComp
Wire Wire Line
	4950 2500 4950 3100
Wire Wire Line
	4950 5700 4950 5900
Connection ~ 4950 5800
Wire Wire Line
	6900 5800 6900 5100
Wire Wire Line
	4950 2550 6900 2550
Connection ~ 4950 2550
Wire Wire Line
	5550 3200 6550 3200
Wire Wire Line
	5550 4400 6550 4400
Wire Wire Line
	5550 3300 6550 3300
Wire Wire Line
	5550 3400 6550 3400
Wire Wire Line
	5550 3500 6550 3500
Wire Wire Line
	5550 3600 6550 3600
Wire Wire Line
	5550 3800 6550 3800
Wire Wire Line
	4950 5800 6900 5800
Wire Wire Line
	5600 2600 5600 2550
Connection ~ 5600 2550
Wire Wire Line
	6900 2550 6900 4700
Wire Wire Line
	5600 3100 5600 3300
Connection ~ 5600 3300
Wire Wire Line
	5550 5200 6550 5200
Wire Wire Line
	6200 3100 6200 3200
Connection ~ 6200 3200
Wire Wire Line
	6200 2600 6200 2550
Connection ~ 6200 2550
$Comp
L R R401
U 1 1 547A3955
P 5600 2850
F 0 "R401" V 5680 2850 40  0000 C CNN
F 1 "3K3" V 5607 2851 40  0000 C CNN
F 2 "~" V 5530 2850 30  0000 C CNN
F 3 "~" H 5600 2850 30  0000 C CNN
	1    5600 2850
	1    0    0    -1  
$EndComp
$Comp
L R R402
U 1 1 547A3964
P 6200 2850
F 0 "R402" V 6280 2850 40  0000 C CNN
F 1 "3K3" V 6207 2851 40  0000 C CNN
F 2 "~" V 6130 2850 30  0000 C CNN
F 3 "~" H 6200 2850 30  0000 C CNN
	1    6200 2850
	1    0    0    -1  
$EndComp
Wire Wire Line
	5700 3300 5700 3400
Connection ~ 5700 3400
Connection ~ 5700 3300
Wire Wire Line
	5800 3400 5800 3500
Connection ~ 5800 3500
Connection ~ 5800 3400
Wire Wire Line
	5900 3500 5900 3600
Connection ~ 5900 3600
Connection ~ 5900 3500
Wire Wire Line
	6000 3600 6000 4400
Connection ~ 6000 4400
Connection ~ 6000 3600
NoConn ~ 5550 4600
NoConn ~ 5550 4700
NoConn ~ 5550 5300
NoConn ~ 5550 5400
NoConn ~ 5550 3900
$EndSCHEMATC
