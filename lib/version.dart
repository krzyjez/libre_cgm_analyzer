/// Aktualna wersja aplikacji
const String appVersion = '4.0.26';

/* Historia zmian:

4.0.26 (2025-01-16)
    Ulepszenia wykresu w karcie dnia:
    - Przeniesiono logikę wykresu do osobnego pliku day_chart_builder.dart
    - Dodano nową serię danych pokazującą punkty maksymalne w okresach przekroczenia
    - Punkty maksymalne są wyświetlane na czerwono z wartością punktową
    - Zoptymalizowano kod i poprawiono czytelność implementacji wykresu

4.0.25 (2025-01-15)
    Poprawki wizualne dla ukrytych dni:
    - Uproszczono wygląd ukrytych dni do pojedynczej szarej karty
    - Usunięto zbędne potwierdzenia przy ukrywaniu/przywracaniu dni
    - Ujednolicono marginesy i zaokrąglenia kart

4.0.24 (2025-01-15)
    Dodano możliwość ukrywania dni z błędnymi pomiarami:
    - Przycisk kosza na belce karty dnia do ukrycia dnia
    - Ukryte dni pokazywane jako szary pasek z datą
    - Możliwość przywrócenia ukrytego dnia przyciskiem

4.0.23 (2025-01-15)
    Ulepszono wyświetlanie obrazków w notatkach:
    - Dodano ikony obrazków przy notatkach
    - Dodano podgląd obrazka po kliknięciu w ikonę
    - Dostosowano rozmiar podglądu do wielkości ekranu
    - Dodano intuicyjne zamykanie podglądu przez kliknięcie

4.0.22 (2025-01-15)
    Zmieniono nazwy plików obrazków na unikalne. 
    Zapobiega to konfliktom nazw i ułatwia identyfikację daty utworzenia

4.0.21 (2025-01-15)
- Naprawiono:
  1. Błąd z zapisywaniem obrazków w notatkach:
    - Dodano prawidłową serializację listy obrazków w klasie Note
    - Obrazki są teraz poprawnie zachowywane w strukturze notatki
    - Naprawiono problem z edycją notatek

4.0.20 (2025-01-09)
- Dodano:
  1. Serwer FastAPI:
    - Endpointy do zarządzania notatkami (/notes)
    - Endpointy do zarządzania obrazkami (/images)
    - Obsługa uploadowania plików
    - Obsługa pobierania plików
    - Walidacja typów plików (tylko obrazki)
    - Bezpieczne przechowywanie plików
- 2. Integracja z API:
    - Klasa ApiService do komunikacji z serwerem
    - Metody do zarządzania notatkami (CRUD)
    - Metody do zarządzania obrazkami (upload/download/delete)
    - Obsługa błędów i timeoutów
    - Logowanie operacji
- 3. Zarządzanie obrazkami w notatkach:
    - Dodawanie obrazków przez przycisk "Dodaj obrazek"
    - Wyświetlanie miniatur w siatce (3 kolumny)
    - Hybrydowy system wyświetlania:
      * Image.network dla istniejących obrazków
      * Image.memory dla nowo dodanych (przed zapisem)
    - Usuwanie obrazków (z pamięci lub serwera)
    - Bezpieczne zapisywanie - obrazki wysyłane tylko przy zapisie notatki
- 4. Usprawnienia UI:
    - Przeniesienie pola czasu nad zakładki
    - Usunięcie zbędnych etykiet
    - Zaokrąglone rogi miniatur
    - Przyciski usuwania na miniaturach
    - Responsywny układ siatki
- Do zrobienia w następnej wersji:
  1. Podgląd obrazka w pełnym rozmiarze


4.0.19
- Dodano możliwość usuwania komentarzy
- Poprawiono wyświetlanie komentarzy - nie pokazują się gdy są puste
- Uproszczono interfejs komentarzy

4.0.18
- Dodano możliwość ukrywania notatek systemowych
- Poprawiono zachowanie przy usuwaniu notatek użytkownika które nakładają się na systemowe
- Zaktualizowano serializację notatek aby obsługiwała ukryte notatki

4.0.17
- Dodano możliwość usuwania notatek użytkownika (ale nie systemowych)
- Poprawiono wygląd przycisków w dialogach
- Zunifikowano sposób wyświetlania i obsługi przycisków w dialogach

4.0.16
- Naprawiono wyświetlanie notatek dodanych przez użytkownika
- Dodano system logowania na serwerze (osobne pliki dla każdego dnia)

4.0.15
- Dodano możliwość dodawania nowych notatek (przycisk "Dodaj notatkę")
- Dodano możliwość zmiany czasu dla istniejących notatek
- Znane problemy: nie wszystkie funkcje związane z notatkami działają poprawnie:
  - edycja czasu nie działa - nie zmienia się czas notatki
  - dodawanie nowej notatki nie ziała - nie dodaje się nowa notatka,
  - dialog dodawania nowej notatki ma błędy format domyślnego czasu notatki - jest on w formacie PM a powinien być w 24H


4.0.14
- Dodano możliwość edycji notatek systemowych
- Notatki edytowane przez użytkownika są wyświetlane w kolorze granatowym
- Notatki z tym samym czasem są łączone w jedną notatkę
- Dodano obsługę klawisza ESC do zamykania dialogów

4.0.13
- Przeniesiono dialogi do osobnych plików w katalogu dialogs/
- Dodano bazową klasę BaseDialog dla spójnego wyglądu i zachowania dialogów
- Uproszczono kod w DayCardBuilder przez wydzielenie logiki dialogów

4.0.12
- Usunięto nieużywany widget _buildDailyComments
- Poprawiono wyświetlanie komentarzy użytkownika - usunięto zielone tło i dodano odpowiednie marginesy

4.0.11
- Dodano możliwość dodawania komentarzy do dni
- Komentarze są wyświetlane w zielonym polu pod nagłówkiem
- Dodano przycisk do szybkiego dodawania komentarzy w nagłówku karty

4.0.10
- Optymalizacja UI: usunięto wyświetlanie pustego kontenera gdy nie ma notatek
- Wykorzystano collection if do warunkowego renderowania widgetów

4.0.9
- Naprawiono wyświetlanie polskich znaków w komentarzach przez prawidłowe dekodowanie UTF-8

4.0.8
- Naprawiono odświeżanie wykresu po zmianie offsetu
- Dodano StatefulBuilder do karty dnia dla lepszego zarządzania stanem
- Wykres teraz prawidłowo uwzględnia offset w wyświetlanych wartościach

4.0.7
- Poprawiono endpointy API (/csv-data i /user-data)
- Dodano dokumentację API dostępną pod adresem /
- Dodano endpoint POST /user-data do zapisywania danych użytkownika
- Dodano lepsze logowanie operacji na serwerze

4.0.6
- Dodano możliwość ustawiania offsetu dla pomiarów z danego dnia
- Dodano obsługę klawiszy (Enter - akceptacja, Escape - anulowanie) w dialogu offsetu
- Zmieniono renderer na CanvasKit dla lepszej obsługi web
- Znane problemy: 
  1. W przeglądarce występują problemy z focusem na polu tekstowym dialogu offsetu - gdy edit uzyska focus i 
  poruszamy się nad nim myszką to wyskakuje błąd "The targeted input element must be the active input element"  
  Więcej na ten temat: https://chatgpt.com/share/67782418-0cf8-8004-a98e-f300600162ad

*/
