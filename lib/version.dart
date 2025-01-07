/// Aktualna wersja aplikacji
const String appVersion = '4.0.9';

/* Historia zmian:
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
