#Nazwa #Koszt #Art #Opis #(rodzaj, Opis2), na kogo,  efekt, co aktywuje, rzadkość

#0 - wybrany przeciwnik
#1 - Na używajacego karty
#2 - Wszyscy przeciwnicy
#3 - Losowy przecwnik

const CARDS = { 
	0 : ["???", 2, "CiosPiescia", "Zadaj 4 obrażenia", [1,"Zdaj 2 obrażenia", [0,2]], 0, [0, 4],0,0],
	1 : ["Blok", 1, "Blok", "4 Armora", [], 1, [1,4],0,0],
	2 : ["Mega blok", 3, "Blok2", "8 Armora", [1,"3 Armora", [1,3]], 1, [1,8],0,0],
	3 : ["Cios Ogonem", 3, "CiosOgonem", "Zadaj 6 obrażeń", [2,"Zadaj 2 obrażeń", [0,2]], 0, [0, 6],1,0],
	4 : ["Cios Piescią", 2, "CiosPiescia", "Zadaj 3 obrażenia", [], 0, [0, 3],0,0],
	5 : ["Zbieranie Aury", 2, "ZbieranieAury", "dobierz 2 karty", [1,"Dobierz Karte", [2,1]], 1, [2, 2],2,0],
	6 : ["Wymach Ogonem", 2, "WymachOgonem", "Zadaj wszystkim 1 obrażeń", [2,"Zadaj wszystkim 2 obrażeń", [0,2]], 2, [0, 1],0,0],
	7 : ["Kolec", 3,"Blok" , "Leczysz się o 3 i dostajesz ciernie 3", [], 1, [6,[3,3],[5,3]],0,1],
	# NOWE KARTY
	8 : ["Cierniowa zbroja", 4, "Blok1", "Otrzymujesz ciernie równe twojemu pancerzowi", [], 1, [7], 0, 0, 0],
	9 : ["Uderzenie tarczą", 3, "Blok1", "Zadaj tyle obrażeń, ile masz armora", [], 0, [8], 0, 0, 0],
	10: ["Krwawy Pancerz", 3, "Blok1", "Tracisz połowę życia, podwajasz armor", [], 1, [9], 0, 0, 0],
	11: ["Wybuch Pancerza", 2, "Blok1", "Tracisz cały armor i zadajesz tyle obrażeń oponentom", [], 2, [10], 0, 0, 0],
	12: ["Klątwa Ochronna", 1, "Blok1", "Do końca walki dobierasz 1 mniej karte i otrzymujesz 3 armora", [], 1, [11], 0, 0, 0],
	13: ["Bastion", 3, "Blok1", "Dostajesz 15 armora (max 1 użycie na walkę)", [], 1, [1, 15], 0, 0, 1], # <--- Exhaust = 1
	14: ["Mała Tarcza", 2, "Blok1", "3 Armora", [], 1, [1, 3], 0, 0, 0],
	15: ["Kolczatka", 2, "Blok1", "Dostajesz 4 ciernie", [], 1, [5, 4], 0, 0, 0],
	16: ["Mistrzowskie Combo", 3, "Blok1", "Jeżeli masz min 1 cierni, 1 pancerza, 1 regeneracji, uderz za 20", [], 0, [12, 20], 0, 0, 0],
	17: ["Przełamanie", 5, "Blok1", "Uderz za 8. Jeśli masz min 8 armora, odzyskujesz 3 many.", [], 0, [13, 8, 8, 3], 0, 0, 0],
	18: ["Kolczasty Cios", 2, "Blok1", "Zadaj 1 obrażeń i zyskaj 3 armora", [], 0, [6, [0, 1], [14, 3]], 0, 0, 0],
	19: ["Zasłona", 3, "Blok1", "5 Armora i dobierz karte", [], 1, [6, [1, 5], [2, 1]], 0, 0, 0],
	20: ["Osłabiający Cios", 1, "Blok1", "Nałóż 3 osłabienia na przeciwnika", [], 0, [15, 3], 0, 0, 0],

	
	67 : ["Mikstura Życia", 2, "Blok", "Zyskujesz Regenerację 3", [], 1, [4, 3], 0,0],
	68 : ["Kolczasta Zbroja", 2, "Blok", "Zyskujesz Ciernie 3", [], 1, [5, 3], 0,0],
	
	101 : ["Kęs", 2, "Art0", "", [], 0, [0, 3],0,0],
	102 : ["ArmorUp", 2, "Art0", "", [], 1, [1, 3],0,0],
}


# 0 - zadawanie obrażeń (0, 4) <-- 4 obrazenia
# 1 - Zyskanie Pancerza (1, 5) <-- Zyskuje 5 pancerze
# 2 - Dpboeranie Kart (2 , 1) <-- Dobranie 1 Karty
# 3 - zadawanie obrażeń (3, 4) <-- 4 leczenia
# 4 - Regeneracja (4, 3) <-- Nadaje 3 ładunki regeneracji
# 5 - Ciernie (5, 3) <-- Nadaje 3 ładunki cierni 
# 6 - Łączenie efektów (6,(1,5),(2,1)) <-- łączy dwa efekty, 5 pancerza i draw
