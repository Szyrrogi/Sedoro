#Nazwa #Koszt #Art #Opis #(rodzaj, Opis2), na kogo,  efekt

#0 - Na używajacego karty
#1 - wybrany przeciwnik
#2 - Wszyscy przeciwnicy
#3 - Losowy przecwnik

const CARDS = { 
	0 : ["Kopniak", 2, "0", "Zadaj 4 obrażenia", [1,"Zdaj 2 obrażenia", [0,2]], 0, [0, 4]],
	1 : ["Punch", 1, "1", "Zadaj 6 obrażenia", [], 0, [0,6]],
	2 : ["armorUp", 0, "0", "daje 3 Armora", [2,"Zdaj 2 obrażenia", [0,2]], 1, [1,3]],
	3 : ["Przepotężny Healek", 2, "0", "Wylecz 4 HP", [1,"Wylecz 67 obrażeń", [3,67]], 1, [3, 4]],
}




# 0 - zadawanie obrażeń (0, 4) <-- 4 obrazenia
# 1 - Zyskanie Pancerza (1, 5) <-- Zyskuje 5 pancerze
# 2 - Dpboeranie Kart (2 , 1) <-- Dobranie 1 Karty
# 3 - zadawanie obrażeń (3, 4) <-- 4 leczenia
