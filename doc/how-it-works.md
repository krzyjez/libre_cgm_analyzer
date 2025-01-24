# Notatki
Notatki mają dwa źródla - pierwszy to importowane są z pliku cvs - czyli dodawane są na telefonie w czasie pomiarów. Drugi to notatki tworzone później w aplikacji webowej. Notatki z telefonu będę nazywał dalej systemowymi a notatki dodane przez aplikację weobową notatkami użytkownika. Notatki użytkownika przechowywane są tam gdzie wszystkie dane użytkownika - plik json. Notatki systemowe przechowywane są w bazie csv i są niemodyfikowalne.

Notatki wyświetlane są pod wykresem. Kolor notatki wskazuje czy jest to notatka systemowa czy notatka użytkownika. Do notatki można podłączyć jeden lub więcej obrazków (jpg, png)

## Edycja notatek systemowych
Jeśli notatka użytkownika ma taki sam czas jak notatka systemowa, to wyświetlamy tylko notatkę użytkownika. Jest to więc sposób na modyfikację notatek systemowych. Użytkownik w interfejsie działa tak jakby modyfikował notatkę systemową a tymczasem tworzona jest notatka użytkownika o takim samym czasie i zawartości jak systemowa. Program wyświetla tylko notatkę użytkownika więc można ją edytować.

## Usuwanie notatek systemowych
Ponieważ nie można usuwać notatek systemowych trzeba utworzyć notatkę użytkownika w której tekst (pole note) będzie miał wartość null. Taka notatka przykryje notatkę systemową - nie będzie więc żadna wyświetlana.

## Zmiana czasu notatki systemowej
Sprawa wygląda podobnie jak z edycją - po zmianie czasu utworzona jest nowa notatka o wskazanym czasie i takiej samej zawartości jak stara notatka systemowa. Jednocześnie tworzona jest druga notatka użytkownika z tym samym czasem co notatka systemowa i z polem note=null. To ukryje notatkę systemową.

## Kolejność notatek
Kolejność notatek powinna być zgodna z ich czasem (timestamp). Problem może się pojawić wtedy gdy notatka jest podpięta w godzinach od 00:00 do 4:00 - ponieważ doba w programie nie zaczyna się od 00:00 ale od 4:00. Takie notatki powinny być wyświetlane na końcu listy a nie na początku.