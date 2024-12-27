# konfiguracja fluttera
1. Po utworzeniiu projektu musimy ustawić rodzaj wynikowej aplikacji - jeśli chcemy by aplikacja otwarła się w chrome powinniśmy dać komendę flutter config --enable-web
2. Wybierz przeglądarkę jako urządzenie docelowe
W dolnym pasku stanu Visual Studio Code znajdziesz menu urządzeń (zwykle po prawej stronie). Kliknij na to menu i wybierz przeglądarkę, np. Chrome

# Przygotowanie środowiska deweloperskiego

## Wymagania
- Node.js (wersja 14 lub nowsza)
- Flutter SDK
- Chrome (do uruchomienia aplikacji webowej)

## Konfiguracja projektu

### Backend (Node.js)

1. Przejdź do katalogu backend:
```bash
cd backend
```

2. Zainstaluj zależności:
```bash
npm install
```

3. Uruchom serwer:
```bash
node server.js
```

Serwer będzie dostępny pod adresem: http://localhost:8000

### Frontend (Flutter)

1. Upewnij się, że masz zainstalowane wszystkie zależności:
```bash
flutter pub get
```

2. Uruchom aplikację w trybie debug:
```bash
flutter run -d chrome
```

## Uruchamianie całej aplikacji

Możesz uruchomić całą aplikację (backend + frontend) na dwa sposoby:

1. Przez VS Code:
   - Otwórz zakładkę "Run and Debug" (Ctrl+Shift+D)
   - Wybierz konfigurację "Full Stack"
   - Naciśnij F5 lub kliknij zielony przycisk play

2. Przez terminal:
   - Przejdź do katalogu backend
   - Uruchom: `node start.js`

Skrypt automatycznie:
- Sprawdzi czy serwer jest uruchomiony
- Jeśli nie, uruchomi go
- Uruchomi aplikację Flutter w Chrome

## Testowanie API

Możesz przetestować API używając przeglądarki lub narzędzia curl:

1. Sprawdź status API:
```bash
curl http://localhost:8000
```

2. Pobierz dane CSV:
```bash
curl http://localhost:8000/data/glucose.csv
```