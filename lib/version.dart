/// Aktualna wersja aplikacji
const String appVersion = '4.0.6';

/* Historia zmian:
4.0.6
- Dodano możliwość ustawiania offsetu dla pomiarów z danego dnia
- Dodano obsługę klawiszy (Enter - akceptacja, Escape - anulowanie) w dialogu offsetu
- Zmieniono renderer na CanvasKit dla lepszej obsługi web
- Znane problemy: 
  * W przeglądarce występują problemy z focusem na polach tekstowych w dialogach
  * Dialog offsetu czasami traci focus po kliknięciu

4.0.5
- Wersja aplikacji w formacie semantycznym (major.minor.patch)
