1 ' Definerer IO
2 '
3 ' INPUTS
4 Def Inte CappingDone
5 CappingDone = 6
6 Def Inte RFIDBlack
7 RFIDBlack = 7
8 Def Inte RFIDRed
9 RFIDRed = 4
10 Def Inte VektFerdig
11 VektFerdig = 3
12 Def Inte VektOk
13 VektOk = 5
14 Def Inte OrdreFerdig
15 OrdreFerdig = 1
16 Def Inte ResetRobot
17 ResetRobot = 2
18 Def Inte FotoCellePickup
19 FotoCellePickup = 9
20 Def Inte FotoCelleDiscard
21 FotoCelleDiscard = 8
22 '
23 ' OUTPUTS
24 Def Inte JarAtRFID
25 JarAtRFID = 3
26 Def Inte JarAtWeighing
27 JarAtWeighing = 6
28 Def Inte SequenceDone
29 SequenceDone = 0
30 Def Inte TraysFull
31 TraysFull = 2
32 Def Inte TrashFull
33 TrashFull = 5
34 Def Inte CupSentToTrash
35 CupSentToTrash = 1
36 Def Inte ConveyorForward
37 ConveyorForward = 8
38 '
39 Def Inte CounterBlack
40 CounterBlack% = 0 ' Counter som går fra 1-6
41 Def Inte CounterRed
42 CounterRed% = 6	' Counter som går fra 7-12
43 Dim PMAG(12)            ' definerer en array kalt PMAG med størrelse 12 (12 fordi det er 12 posisjoner på brettene totalt)
44 Def Inte RfidTimer
45 If M_In(OrdreFerdig) = 1 Then GoTo *WAITRESET
46 Mvs Psafe_1	' gå ut av sikker posisjon
47 '
48 *START
49 Mov pWait
50 Dly(0.1)
51 M_Out(CupSentToTrash) = 0
52 M_Out(SequenceDone) = 0
53 If M_In(OrdreFerdig) = 1 Then GoTo *FULL ' Sjekker om ordren er fullført
54 HOpen 1              ' Forsikrer at griperen er åpen før start
55 M_Out(JarAtRFID) = 0
56 M_Out(JarAtWeighing) = 0
57 If M_In(FotoCellePickup) = 0 Then M_Out(ConveyorForward) = 1 Else GoTo *CUP
58 Dly(0.1)               ' vent 2 sekunder hvis det ikke er en kopp på båndet
59 If M_In(OrdreFerdig) = 1 Then GoTo *FULL ' Sjekker om ordren er fullført
60 '
61 *CUP
62 If M_In(FotoCellePickup) = 0 Then GoTo *START
63 Mov pGet, -70            ' Flytt ulineært (raskt) til 70 mm over pGet (Z-offset)
64 Dly(0.3)
65 M_Out(ConveyorForward) = 0
66 Mvs pGet              ' Flytt lineært til der hvor griperen henter en kopp på transportbåndet (pGet)
67 Dly(0.1)
68 HClose 1
69 Dly(0.1)
70 Mov pWait             ' Flytt ulineært (raskt) til pWait
71 M_Out(ConveyorForward) = 1
72 Mov pRFID, -10            ' Flytt ulineært (raskt) til 10 mm over pRFID
73 Mvs pRFID             ' Beveg lineært til RFID leser
74 M_Out(JarAtRFID) = 1
75 '
76 *WAIT_RFID
77 RfidTimer = 0
78 *WAIT_RFID_LOOP		' Sjekker fargen til RFID helt til PLSen gir et svar
79 If M_In(RFIDBlack) = 1 Then GoTo *RFID_Black
80 If M_In(RFIDRed) = 1 Then GoTo *RFID_Red
81 Dly(0.1)
82 RfidTimer = RfidTimer + 1		' Timer inkrementeres med 0.1 sekunder
83 If RfidTimer < 50 Then GoTo *WAIT_RFID_LOOP
84 Mov pUp, -30
85 GoTo *DISCARD_RFID
86 '
87 *RFID_Black
88 If CounterBlack% >= 6 Then GoTo *FULL
89 M_Out(JarAtRFID) = 0
90 HOpen 1
91 Mvs pWeight             ' Beveg lineært til posisjonen til veiecelle (pWeight)
92 Dly(0.1)
93 Mvs pWeight_2            ' Beveg lineært litt til høyre slik at armen ikke er i kontakt med koppen under veiing (pWeight_2)
94 Dly(1.5)
95 M_Out(JarAtWeighing) = 1
96 Wait M_In(VektFerdig) = 1
97 M_Out(JarAtWeighing) = 0            ' Robot sier til PLS "det er ingenting på vekta"
98 If M_In(VektOk) = 1 Then GoTo *MAG_BLACK Else GoTo *DISCARD_FULL
99 '
100 *RFID_Red
101 If CounterRed% >= 12 Then GoTo *FULL
102 M_Out(JarAtRFID) = 0
103 HOpen 1
104 Mvs pWeight             ' Beveg linrært til posisjonen til veiecelle (pWeight)
105 Dly(0.1)
106 Mvs pWeight_2            ' Beveg lineært litt til høyre slik at armen ikke er i kontakt med koppen under veiing (pWeight_2)
107 Dly(1.5)
108 M_Out(JarAtWeighing) = 1
109 Wait M_In(VektFerdig) = 1
110 M_Out(JarAtWeighing) = 0            ' Robot sier til PLS "det er ingenting på vekta"
111 If M_In(VektOk) = 1 Then GoTo *MAG_RED Else GoTo *DISCARD_FULL
112 '
113 *DISCARD_FULL
114 Mvs pUP              ' Beveg lineært til pUP (litt utenfor vekten hvor koppen blir løftet opp igjen og frem til brett / kast)
115 If M_In(FotoCelleDiscard) = 1 Then GoTo *FULL	' Hvis søppel er full så stopp og gå til sikker posisjon så operatør kan tømme og resette
116 Dly(0.1)
117 HClose 1
118 *DISCARD_RFID
119 M_Out(JarAtRFID) = 0
120 Mov pDisc, -60            ' Beveg ulineært (raskt) til 60 mm over pDisc (Z-offset)
121 Mvs pDisc              ' Beveg lineært til pDisc
122 Dly(0.1)
123 HOpen 1
124 Mov pDisc, -60            ' Beveg ulineært (raskt) til 60 mm over pDisc (Z-offset)
125 Mov pGet, -70            ' Beveg ulineært (raskt) til 7 mm over pGet
126 M_Out(CupSentToTrash) = 1
127 M_Out(SequenceDone) = 1
128 GoTo *START            ' Kopp med feil vekt er nå kastet, går tilbake til *START
129 '
130 *MAG_BLACK
131 Mvs pUP              ' Beveg lineært til pUp (ved siden av vekta)
132 Dly(0.1)
133 HClose 1
134 Dly(0.1)
135 Mvs pUP, -40             ' Flytter 40 mm opp fra pUP (Z-offset)
136 CounterBlack% = CounterBlack% + 1
137 Mov PMAG(CounterBlack%), -80        ' Beveg ulineært (raskt) til 80 mm over PMAG(Counter%) (Z-offset)
138 Mvs PMAG(CounterBlack%)
139 Dly(0.1)
140 HOpen 1
141 Mvs PMAG(CounterBlack%), -60         ' Flytter 60 mm opp fra PMAG(Counter%) (Z-offset)
142 M_Out(SequenceDone) = 1
143 If CounterBlack% >= 6 And CounterRed% >= 12 Then GoTo *FULL ' Sjekker om begge trays er fulle samtidig, siden da skal programmet avsluttes / vente på reset
144 'If M_In(OrdreFerdig) = 1 Then GoTo *FULL ' Sjekker om ordren er fullført
145 GoTo *START
146 '
147 *MAG_RED
148 Mvs pUP              ' Beveg lineært til pUp (ved siden av vekta)
149 Dly(0.1)
150 HClose 1
151 Dly(0.1)
152 Mvs pUP, -40             ' Flytter 40 mm opp fra pUP (Z-offset)
153 CounterRed% = CounterRed% + 1
154 Mov PMAG(CounterRed%), -80        ' Beveg ulineært (raskt) til 80 mm over PMAG(Counter%) (Z-offset)
155 Mvs PMAG(CounterRed%)          ' Beveg lineært til PMAG med indeksen til counterRed
156 Dly(0.1)
157 HOpen 1
158 Mvs PMAG(CounterRed%), -60         ' Flytter 60 mm opp fra PMAG(Counter%) (Z-offset)
159 M_Out(SequenceDone) = 1
160 If CounterBlack% >= 6 And CounterRed% >= 12 Then GoTo *FULL ' Sjekker om begge trays er fulle samtidig, siden da skal programmet avsluttes / vente på reset
161 'If M_In(OrdreFerdig) = 1 Then GoTo *FULL ' Sjekker om ordren er fullført
162 GoTo *START
163 '
164 *FULL
165 M_Out(TraysFull) = 1
166 M_Out(JarAtRFID) = 0
167 M_Out(JarAtWeighing) = 0
168 HOpen 1	' Slipper koppen den holder på RFID leseren før armen går i SAFE posisjon
169 Mov pSafe_1
170 Mvs PSafe
171 *WAITRESET
172 Wait M_In(ResetRobot) = 1	' Her må operatøren tømme brettene / RFID leser for kopper slik at alt er tomt, så kan man trykke reset, og programmet starter på nytt
173 CounterBlack% = 0
174 CounterRed% = 6
175 M_Out(TraysFull) = 0
176 Mvs Psafe_1
177 GoTo *START
pDisc=(153.690,366.340,294.120,-179.970,-0.010,-179.960)(7,0)
pGet=(147.620,280.690,292.340,-177.840,0.920,-180.000)(7,0)
pRFID=(-118.030,357.960,341.310,179.890,-0.320,176.550)(7,0)
pSafe=(-264.910,217.790,444.390,178.590,0.920,179.930)(7,0)
pSafe_1=(-151.020,217.790,444.390,178.600,0.920,179.930)(7,0)
pUP=(11.670,349.560,334.080,-179.990,0.000,-179.960)(7,0)
pWait=(150.050,280.240,415.770,-177.850,0.920,179.990)(7,0)
pWeight=(-45.630,357.020,333.590,-179.950,-0.060,179.610)(7,0)
pWeight_2=(-49.020,357.020,333.580,-179.950,-0.060,179.610)(7,0)
PMAG(1)=(175.120,-44.450,290.940,179.000,4.000,97.320)(7,0)
PMAG(2)=(165.700,63.210,287.050,179.000,4.000,97.320)(7,0)
PMAG(3)=(152.920,155.430,286.410,178.670,0.130,97.310)(7,0)
PMAG(4)=(261.830,-36.040,285.440,179.000,4.000,97.320)(7,0)
PMAG(5)=(250.020,69.440,285.120,179.000,4.000,97.320)(7,0)
PMAG(6)=(237.560,166.510,284.790,178.890,1.890,97.320)(7,0)
PMAG(7)=(296.450,73.970,294.820,179.000,4.000,97.320)(7,0)
PMAG(8)=(285.130,176.860,294.010,179.000,4.000,97.320)(7,0)
PMAG(9)=(272.670,265.190,294.980,178.460,-0.170,97.300)(7,0)
PMAG(10)=(376.370,73.480,296.110,178.710,1.750,97.310)(7,0)
PMAG(11)=(368.600,176.370,294.660,178.710,1.750,97.310)(7,0)
PMAG(12)=(356.950,276.350,296.110,178.710,1.750,97.310)(7,0)
