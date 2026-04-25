class_name EnemyDatabase
extends Node

const HORD_TYPE1 = { 
	0 : [0, 0, 0],
	1 : [1, 1],
	2 : [2, 2],
	3 : [3, 2],
	4 : [4],
	5 : [5],
	6 : [6],
	7 : [7],
	8 : [8],
	9 : [9],
	10 : [10],
	11 : [11]
}

const HORD_TYPE2 = {
	0 : [16, 16],
	1 : [17, 17],
}

const HORD_TYPE3 = {
	0 : [5, 6],
	1 : [7, 8],
	2 : [6, 9],
}

# Typ 4 = Sklep  → brak przeciwników
# Typ 5 = Event  → brak przeciwników

# Format: ["Nazwa", "Obrazek", Zdrowie, [Talia], Złoto]
const ENEMY = {
	# --- SŁABE (Trudność: Słaby) ---
	# ID 0: SłabyWąż - Atak+, reszta minus
	0 : ["SłabyWąż",        "Enemy1",  12, [200, 200, 201],         3],
 
	# ID 1: WężołudzĘ - Atak+, Zbroja+
	1 : ["WężołudzĘ",       "Enemy2",  14, [200, 201, 202],         4],
 
	# ID 2: ŚlimaczyWąż - Atak+, Leczenie+
	2 : ["ŚlimaczyWąż",     "Enemy3",  13, [200, 203],              3],
 
	# ID 3: CierniemyWąż - Atak+, Ciernie+
	3 : ["CierniemyWąż",    "Enemy4",  13, [200, 204],              4],
 
	# --- ŚREDNIE (Trudność: Średni) ---
	# ID 4: DwugłowyWąż - Atak+, Zbroja+, Ciernie+, Trucizna+ | W każdej turze robi 2 rzeczy
	4 : ["DwugłowyWąż",     "Enemy5",  22, [205, 205, 202, 204],    6],
 
	# ID 5: JadowyWąż - Atak-, Zbroja+, Trucizna+ | Odporny na truciznę
	5 : ["JadowyWąż",       "Enemy6",  20, [206, 202],              6],
 
	# ID 6: WybuchającyWąż - Atak-, Zbroja-, Trucizna- | W 3 turze wybucha
	6 : ["WybuchającyWąż",  "Enemy7",  18, [207, 208],              5],
 
	# ID 7: MagicznyWąż - Atak-, Zbroja-, Trucizna+, Leczenie+ | Leczy węże
	7 : ["MagicznyWąż",     "Enemy8",  20, [203, 209],              6],
 
	# ID 8: GrzybowyWąż - Atak-, Zbroja-, Ciernie+, Trucizna- | Zatruwa pole walki
	8 : ["GrzybowyWąż",     "Enemy9",  22, [210, 210, 204],         7],
 
	# ID 9: PancernyWąż - Atak+, Zbroja+, Ciernie-, Trucizna- | Może być jedynym celem
	9 : ["PancernyWąż",     "Enemy10", 24, [200, 202, 211],         7],
 
	# ID 10: POTĘŻNYWąż - Atak+, Zbroja- | Ładuje się, atakuje i wzmacnia
	10: ["POTĘŻNYWąż",      "Enemy11", 30, [212, 212, 200],         9],
 
	# ID 11: Pasożyt - Atak-, Zbroja-, Ciernie+, Trucizna+ | Kradnie pancerz gracza
	11: ["Pasożyt",         "Enemy12", 18, [213, 213],              8],
 
	# --- CIĘŻKIE (Trudność: Ciężki) ---
	# ID 12: MrocznyWąż - Atak+, Zbroja+, Ciernie+, Trucizna+ | Rzuca klątwami
	12: ["MrocznyWąż",      "Enemy13", 35, [214, 202, 204, 206],    11],
 
	# ID 13: WypływaczWęży - Atak-, Zbroja-, Trucizna+, Leczenie+ | Wypływa węże
	13: ["WypływaczWęży",   "Enemy14", 28, [215, 203],              10],
 
	# ID 14: WyplutWąż - Atak+ (Słaby*) | Wypluty przez WypływaczWęży
	14: ["WyplutWąż",       "Enemy15", 10, [200, 200],              2],
 
	# ID 15: ZłotyWąż - Atak- (Słaby*) | Niewidoczny, zadaje truciznę z dystansu
	15: ["ZłotyWąż",        "Enemy16", 12, [216, 216],              12],
 
	# ID 16: WężowaKula - Atak+, Zbroja+, Ciernie+, Trucizna+, Leczenie+ | Losowe zachowanie
	16: ["WężowaKula",      "Enemy17", 40, [200, 202, 204, 206, 203], 13],
 
	# ID 17: Pożeracz - Atak+, Zbroja-, Ciernie-, Trucizna-, Leczenie+ | Zjada kapłana
	17: ["Pożeracz",        "Enemy18", 38, [217, 200],              14],
 
	# ID 18: WężowyKapłan - Atak-, Zbroja-, Ciernie-, Trucizna+, Leczenie+ | Para z Pożeraczem
	18: ["WężowyKapłan",    "Enemy19", 26, [218, 203],              12],
 
	# ID 19: WążZabójca - Atak+, Zbroja-, Ciernie+, Trucizna- | Niewidzialność, atak obszarowy
	19: ["WążZabójca",      "Enemy20", 32, [219, 219, 204],         13],
 
	# ID 20: Lamia - Atak-, Zbroja+, Ciernie+, Trucizna+, Leczenie+ | Zauroczenie - nie można atakować
	20: ["Lamia",           "Enemy21", 45, [220, 202, 206],         15],
 
	# ID 21: Chimera - Atak+, Zbroja+, Trucizna+, Leczenie+ | Co turę robi 3 rzeczy
	21: ["Chimera",         "Enemy22", 50, [221, 221, 221],         16],
 
	# ID 22: StaryWąż - Atak+, Zbroja+, Ciernie+, Trucizna- | Im mniej HP, tym silniejszy
	22: ["StaryWąż",        "Enemy23", 35, [222, 202, 204],         14],
 
	# ID 23: ZombieWąż - Atak+, Zbroja-, Ciernie-, Trucizna+, Leczenie- | Zmartwychwstaje raz
	23: ["ZombieWąż",       "Enemy24", 28, [223, 200, 206],         13],
}
