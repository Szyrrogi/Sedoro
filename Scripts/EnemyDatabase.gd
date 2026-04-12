class_name EnemyDatabase
extends Node

const HORD_TYPE1 = { 
	0 : [0, 0, 0],
	1 : [1, 1],
	2 : [0, 1],
}

const HORD_TYPE2 = {
	0 : [2, 2],
	1 : [3, 4],
	2 : [2, 3],
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
	0 : ["Wąż","Enemy1", 10, [101,101,102], 5],
	1 : ["Wąż","Enemy2", 10, [101,102],     8],
##PLACEHOLDERY:
	2 : ["Wąż","Enemy3", 10, [101,101,102], 6],
	3 : ["Wąż","Enemy4", 10, [101,102],     9],
	4 : ["Wąż","Enemy5", 10, [101,101,102], 7],
	5 : ["Wąż","Enemy6", 10, [101,102],    10],
	6 : ["Wąż","Enemy7", 10, [101,101,102], 8],
	7 : ["Wąż","Enemy8", 10, [101,102],    12],
	8 : ["Wąż","Enemy9", 10, [101,101,102],11],
	9 : ["Wąż","Enemy10",10, [101,102],    15],
}
