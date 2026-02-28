#Nazwa #Koszt #Art #Opis #(rodzaj, Opis2), na kogo,  efekt

#0 - wybrany przeciwnik
#1 - Na używajacego karty
#2 - Wszyscy przeciwnicy
#3 - Losowy przecwnik

const CARDS = { 
	0 : ["Kopniak", 2, "0", "Zadaj 4 obrażenia", [1,"Zdaj 2 obrażenia", [0,2]], 0, [0, 4]],
	1 : ["Blok", 1, "1", "4 Armora", [], 1, [1,4]],
	2 : ["Mega blok", 3, "0", "6 Armora", [1,"3 Armora", [1,3]], 1, [1,6]],
	3 : ["Pchnięcie", 4, "0", "Zadaj 5 obrażeń", [2,"Zadaj 1 obrażeń", [3,67]], 0, [0, 5]],
	4 : ["Zamachniecie", 2, "0", "Zadaj 2 obrażenia", [], 0, [0, 2]],
	5 : ["Bieg", 2, "0", "dobierz 2 karty", [1,"Dobierz Karte", [2,1]], 1, [2, 2]],
	6 : ["Szerokie Cięcie", 3, "0", "Zadaj wszystkim 1 obrażeń", [2,"Zadaj wszystkim 1 obrażeń", [3,67]], 2, [0, 1]],
}




# 0 - zadawanie obrażeń (0, 4) <-- 4 obrazenia
# 1 - Zyskanie Pancerza (1, 5) <-- Zyskuje 5 pancerze
# 2 - Dpboeranie Kart (2 , 1) <-- Dobranie 1 Karty
# 3 - zadawanie obrażeń (3, 4) <-- 4 leczenia
