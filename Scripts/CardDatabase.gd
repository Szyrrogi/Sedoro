# ============================================================
# SYSTEM EFEKTÓW - LEGENDA
# ============================================================
# [0, X]       - Zadaj X obrażeń wybranemu przeciwnikowi
# [1, X]       - Zyskaj X pancerza
# [2, X]       - Dobierz X kart
# [3, X]       - Lecz się o X
# [4, X]       - Zyskaj X regeneracji
# [5, X]       - Zyskaj X cierni
# [6, e1, e2]  - Połącz wiele efektów
# [7]          - Zyskaj ciernie = twój pancerz
# [8]          - Zadaj obrażenia = pancerz gracza (dla wroga)
# [9]          - Stracisz połowę HP, podwój pancerz
# [10]         - Wszyscy wrogowie obrywają tyle co pancerz gracza
# [11]         - draw_reduction +1, +3 pancerza (pasywna)
# [12, X]      - Uderz za X jeśli masz ciernie≥1, pancerz≥1, regen≥1
# [13, dmg, min_armor, mana_refund] - Uderz za dmg, jeśli armor≥min_armor zwróć manę
# [14, X]      - Dodaj X pancerza graczowi (cel = gracz)
# [15, X]      - Nałóż X osłabienia
# [16, X]      - Nałóż X trucizny na cel
# [17, X]      - Nałóż X trucizny na WSZYSTKICH wrogów
# [18]         - Aktywuj natychmiastowe obrażenia z trucizny celu
# [19, X]      - Nałóż X trucizny na siebie
# [20]         - Podwój truciznę celu
# [21]         - Wszyscy wrogowie dostają tyle trucizny ile ma wybrany wróg
# [22, X]      - Nałóż X trucizny + 1 za każde 3 trucizny już na celu
# [23]         - Nałóż truciznę = twój pancerz
# [24]         - Zamiast obrażeń, nakładaj truciznę (do końca tury)
# [25, X, min_poison] - Zyskaj X pancerza, kosztuje 2 mniej jeśli wróg ma ≥min_poison trucizny (obsługiwane w CardManager)
# [26, X]      - Uderz za X. 100 pancerza, ale za 2 tury umierasz (debuff na gracza)
# [27]         - Pasywna co turę: nałóż 2 trucizny na wrogów
#
# STRUKTURA KARTY:
# ID: [Nazwa, Koszt, Art, Opis, [warunek_kolor, Opis2, efekt2], cel, efekt, kolor_aktywowany, rzadkość, exhaust]
#   cel: 0=wybrany wróg, 1=gracz/siebie, 2=wszyscy wrogowie, 3=losowy wróg
#   exhaust: 0=wraca do talii, 1=znika po zagraniu (jednorazowa)
#   pasywna: karta z efektem [27,...] - aktywuje się co turę, exhaust=1
#
# WARUNEK KOLORU (indeks 4): [kolor, Opis2, efekt2]
#   kolor: "R"=czerwony, "G"=zielony, "F"=fioletowy, "g"=szary
#   Jeśli karta ma pasujący kolor aktywowany (indeks 7), efekt2 zastępuje efekt

const CARDS = {
	# ============================================================
	# ISTNIEJĄCE KARTY (oryginalne + naprawione)
	# ============================================================
	0 : ["???",           2, "CiosPiescia",  "Zadaj 4 obrażenia",                          [1,"Zadaj 2 obrażenia",[0,2]],     0, [0,4],     0,   0, 0],
	1 : ["Blok",          1, "Blok",         "4 Armora",                                   [],                               1, [1,4],     0,   0, 0],
	2 : ["Mega blok",     3, "Blok2",        "8 Armora",                                   [1,"3 Armora",[1,3]],             1, [1,8],     0,   0, 0],
	3 : ["Cios Ogonem",   3, "CiosOgonem",   "Zadaj 6 obrażeń",                            [2,"Zadaj 2 obrażeń",[0,2]],     0, [0,6],     1,   0, 0],
	4 : ["Cios Piescią",  2, "CiosPiescia",  "Zadaj 3 obrażenia",                          [],                               0, [0,3],     0,   0, 0],
	5 : ["Zbieranie Aury",2, "ZbieranieAury","Dobierz 2 karty",                            [1,"Dobierz Kartę",[2,1]],        1, [2,2],     2,   0, 0],
	6 : ["Wymach Ogonem", 2, "WymachOgonem", "Zadaj wszystkim 1 obrażeń",                  [2,"Zadaj wszystkim 2 obrażeń",[0,2]], 2, [0,1], 0,   0, 0],
	7 : ["Kolec",         3, "Blok",         "Leczysz się o 3 i dostajesz ciernie 3",      [],                               1, [6,[3,3],[5,3]], 0, 1, 0],

	# ============================================================
	# KARTY PANCERZA / OBRONY (z Excela, IDs 8-21)
	# ============================================================
	# ID 8 -> Excel row 8: Cierniowa zbroja
	8 : ["Cierniowa Zbroja",   4, "Blok1", "Zyskujesz ciernie równe twojemu pancerzowi",       [], 1, [7],         0, 1, 0],
	# ID 9 -> Excel row 9: Taran
	9 : ["Taran",              3, "Blok1", "Zadaj tyle obrażeń ile masz pancerza",              [], 0, [8],         0, 1, 0],
	# ID 10 -> Excel row 10: Krwawa Zbroja
	10: ["Krwawa Zbroja",      3, "Blok1", "Tracisz połowę życia, podwajasz pancerz",           [], 1, [9],         0, 3, 0],
	# ID 11 -> Excel row 11: Wyładowanie
	11: ["Wyładowanie",        2, "Blok1", "Tracisz cały pancerz i zadajesz go jako obrażenia", [], 2, [10],        0, 2, 0],
	# ID 12 -> Excel row 12: Twarda Głowa (PASYWNA)
	12: ["Twarda Głowa",       1, "Blok1", "Pasywna: co turę dobierasz 1 mniej kartę i dostajesz 3 pancerza", [], 1, [11], 1, 2, 1],
	# ID 13 -> Excel row 13: Osłona (EXHAUST)
	13: ["Osłona",             3, "Blok1", "Dostajesz 15 pancerza (jednorazowa)",               [], 1, [1,15],      0, 1, 1],
	# ID 14 -> Excel row 14: Wzmocnienie Pancerza
	14: ["Wzmocnienie Pancerza",2,"Blok1", "3 Armora",                                          [2,"3 Armora",[1,3]], 1, [1,3], 0, 1, 0],
	# ID 15 -> Excel row 15: Rażące Żądło
	15: ["Rażące Żądło",       2, "Blok1", "Dostajesz 4 ciernie",                              [1,"1 ciernie więcej",[5,1]], 1, [5,4], 0, 1, 0],
	# ID 16 -> Excel row 16: Cios Chwały
	16: ["Cios Chwały",        3, "Blok1", "Jeżeli masz min 1 cierni, 1 pancerza, 1 regen - uderz za 20", [], 0, [12,20], 0, 0, 0],
	# ID 17 -> Excel row 17: (bez nazwy) Przełamanie
	17: ["Przełamanie",        5, "Blok1", "Uderz za 8. Jeśli masz min 8 pancerza, kosztuje 3 mniej", [], 0, [13,8,8,3], 0, 1, 0],
	# ID 18 -> Excel row 18: Kolczasty Cios
	18: ["Kolczasty Cios",     2, "Blok1", "Zadaj 1 obrażeń i zyskaj 3 pancerza",              [3,"Zadaj 1 i 3 pancerza",[6,[0,1],[14,3]]], 0, [6,[0,1],[14,3]], 0, 2, 0],
	# ID 19 -> Excel row 19: Zasłona
	19: ["Zasłona",            3, "Blok1", "5 Pancerza i dobierz kartę",                        [], 1, [6,[1,5],[2,1]], 1, 1, 0],
	# ID 20 -> Excel row 20: Osłabiający Cios
	20: ["Osłabiający Cios",   1, "Blok1", "Nałóż 3 osłabienia na przeciwnika",                [], 0, [15,3],      0, 1, 0],
	# ID 21 -> Excel row 21: Szaleństwo
	21: ["Szaleństwo",         2, "Blok1", "100 pancerza, ale umierasz za 2 tury",              [], 1, [26,100],    0, 2, 0],

	# ============================================================
	# KARTY TRUCIZNY (z Excela, IDs 22-36)
	# ============================================================
	# ID 22 -> Excel row 22: Poison (Zatrucie)
	22: ["Zatrucie",           2, "Poison1", "Nałóż 3 trucizny",                               [2,"Nałóż 2 trucizny",[16,2]], 0, [16,3],  0, 1, 0],
	# ID 23 -> Excel row 23: Trująca Kombinacja
	23: ["Trujący Cios",       3, "Poison1", "Zadaj 4 obrażeń i nałóż 4 trucizny",             [], 0, [6,[0,4],[16,4]], 0, 1, 0],
	# ID 24 -> Excel row 24: Skryta Trucizna
	24: ["Skryta Trucizna",    1, "Poison1", "Nałóż 2 trucizny",                               [], 0, [16,2],     2, 1, 0],
	# ID 25 -> Excel row 25: Epidemia
	25: ["Epidemia",           3, "Poison1", "Nałóż 5 trucizny na WSZYSTKICH wrogów",          [], 2, [17,5],     0, 2, 0],
	# ID 26 -> Excel row 26: Podwójne Zatrucie
	26: ["Podwójne Zatrucie",  4, "Poison1", "Podwój truciznę na przeciwniku",                 [], 0, [20],       0, 2, 0],
	# ID 27 -> Excel row 27: Zaraza
	27: ["Zaraza",             3, "Poison1", "Wszyscy wrogowie dostają tyle trucizny ile ma wybrany", [], 2, [21], 0, 1, 0],
	# ID 28 -> Excel row 28: Detonacja Trucizny
	28: ["Detonacja Trucizny", 2, "Poison1", "Aktywuj natychmiastowe obrażenia z trucizny",    [], 0, [18],       0, 1, 0],
	# ID 29 -> Excel row 29: Trujące Pancerze
	29: ["Trujące Pancerze",   3, "Poison1", "Nałóż tyle trucizny ile masz pancerza",          [], 0, [23],       0, 2, 0],
	# ID 30 -> Excel row 30: Narastające Zatrucie
	30: ["Narastające Zatrucie",2,"Poison1", "Nałóż 3 trucizny + 1 za każde 3 trucizny na celu", [], 0, [22,3],  0, 1, 0],
	# ID 31 -> Excel row 31: Samozatrucie
	31: ["Samozatrucie",       1, "Poison1", "Nałóż na siebie 4 trucizny i zyskaj 10 pancerza", [], 1, [6,[19,4],[1,10]], 0, 2, 0],
	# ID 32 -> Excel row 32: Trująca Tarcza
	32: ["Trująca Tarcza",     2, "Poison1", "Zyskaj 3 pancerza i nałóż 2 trucizny",           [], 0, [6,[1,3],[16,2]], 0, 1, 0],
	# (self armor part handled via target=1 in card_manager)
	# ID 33 -> Excel row 33: Zatruta Talia
	33: ["Zatruta Talia",      2, "Poison1", "Nałóż 1 trucizny za każdą dobraną kartę w tej turze", [], 0, [28], 0, 1, 0],
	# ID 34 -> Excel row 34: Trujące Ostrze (tryb tury)
	34: ["Trujące Ostrze",     1, "Poison1", "Do końca tury zamiast obrażeń nakładasz truciznę", [], 1, [24],     0, 2, 0],
	# ID 35 -> Excel row 35: Trująca Osłona
	35: ["Trująca Osłona",     3, "Poison1", "Zyskaj 5 pancerza (kosztuje 2 mniej jeśli wróg ma ≥5 trucizny)", [], 1, [25,5,5], 0, 2, 0],
	# ID 36 -> Excel row 36: Trujące Aura (PASYWNA - exhaust)
	36: ["Trująca Aura",       4, "Poison1", "Pasywna: co turę nałóż 2 trucizny na wszystkich wrogów", [], 2, [27,2], 0, 2, 1],

	# ============================================================
	# STARTERY / SPECJALNE
	# ============================================================
	67: ["Mikstura Życia",  2, "Blok",  "Zyskujesz Regenerację 3",  [], 1, [4,3],  0, 0, 0],
	68: ["Kolczasta Zbroja",2, "Blok",  "Zyskujesz Ciernie 3",      [], 1, [5,3],  0, 0, 0],

	101: ["Kęs",    2, "Art0", "Zadaj 3 obrażenia", [], 0, [0,3],  0, 0, 0],
	102: ["ArmorUp",2, "Art0", "3 Armora",           [], 1, [1,3],  0, 0, 0],
}

# ============================================================
# INDEKS KART PASYWNYCH
# Karty pasywne aktywują się co turę i znikają po wejściu do gry (exhaust=1).
# Ich efekt jest przechowywany w PassiveManager i odpala się na start_turn.
# ============================================================
# ID 12 - Twarda Głowa:  co turę draw_reduction+1 i +3 pancerza
# ID 36 - Trująca Aura:  co turę 2 trucizny na wszystkich wrogów
