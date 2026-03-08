#Nazwa #Koszt #Art #Opis #(rodzaj, Opis2), na kogo,  efekt, co aktywuje

#0 - wybrany przeciwnik
#1 - Na używajacego karty
#2 - Wszyscy przeciwnicy
#3 - Losowy przecwnik

const CARDS = { 
	0 : ["Cios Piescią", 2, "CiosPiescia", "Zadaj 4 obrażenia", [1,"Zdaj 2 obrażenia", [0,2]], 0, [0, 4],0],
	1 : ["Blok", 1, "Blok", "4 Armora", [], 1, [1,4],0],
	2 : ["Mega blok", 3, "Blok2", "8 Armora", [1,"3 Armora", [1,3]], 1, [1,8],0],
	3 : ["Cios Ogonem", 3, "CiosOgonem", "Zadaj 6 obrażeń", [2,"Zadaj 2 obrażeń", [0,2]], 0, [0, 6],1],
	4 : ["Zamachniecie", 2, "Art0", "Zadaj 3 obrażenia", [], 0, [0, 3],0],
	5 : ["Bieg", 2, "Art0", "dobierz 2 karty", [1,"Dobierz Karte", [2,1]], 1, [2, 2],2],
	6 : ["Szerokie Cięcie", 2, "Art0", "Zadaj wszystkim 1 obrażeń", [2,"Zadaj wszystkim 2 obrażeń", [0,2]], 2, [0, 1],0],
	
	101 : ["Kęs", 2, "Art0", "", [], 0, [0, 3],0],
	102 : ["ArmorUp", 2, "Art0", "", [], 1, [1, 3],0],
}





# 0 - zadawanie obrażeń (0, 4) <-- 4 obrazenia
# 1 - Zyskanie Pancerza (1, 5) <-- Zyskuje 5 pancerze
# 2 - Dpboeranie Kart (2 , 1) <-- Dobranie 1 Karty
# 3 - zadawanie obrażeń (3, 4) <-- 4 leczenia
