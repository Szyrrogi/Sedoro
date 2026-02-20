#Nazwa #Koszt #Art #Opis #(rodzaj, Opis2), na kogo,  efekt

#0 - Na używajacego karty
#1 - wybrany przeciwnik
#2 - Wszyscy przeciwnicy
#3 - Losowy przecwnik

const CARDS = { 
	0 : ["Kopniak", 2, "0", "Zadaj 4 obrażenia", [1,"Zdaj 2 obrażenia", [0,2]], 0, [0, 4]],
	1 : ["Punch", 1, "1", "Zadaj 1 obrażenia", [], 0, [0,1]],
	2 : ["Kopniak Alternatywny", 2, "0", "Zadaj 4 obrażenia", [2,"Zdaj 2 obrażenia", [0,2]], 0, [0,4]],
}




# 0 - zadawanie obrażeń (0, 4) <-- 4 obrazenia
# 1 - Zyskanie Pancerza (1, 5) <-- Zyskuje 5 pancerze
# 2 - Dpboeranie Kart (2 , 1) <-- Dobranie 1 Karty
