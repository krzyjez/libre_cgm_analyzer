# Libre CGM Analyzer

Aplikacja do analizy danych z systemu Libre Continuous Glucose Monitoring.

## Struktura projektu

```
libre_cgm_analyzer/
├── backend/              # Serwer Node.js
│   ├── server.js        # Główny plik serwera
│   └── start.js         # Skrypt startowy (serwer + flutter)
├── data_source/         # Źródłowe pliki CSV
├── lib/                 # Kod źródłowy Flutter
└── doc/                 # Dokumentacja
    └── preparations.md  # Instrukcje konfiguracji
```

## Technologie

- **Backend**: Node.js + Express.js
- **Frontend**: Flutter Web
- **Dane**: Format CSV
- **Serializacja**: json_serializable dla automatycznej generacji kodu JSON

## Uruchomienie

Szczegółowe instrukcje znajdują się w [doc/preparations.md](doc/preparations.md)

## Funkcje

- Wyświetlanie danych pomiarowych z pliku CSV
- Analiza trendów glukozy
- Wizualizacja danych na wykresach

## Rozwój

1. Sklonuj repozytorium
2. Zainstaluj zależności (backend + frontend)
3. Wygeneruj kod dla serializacji JSON:
   ```bash
   # Jednorazowe wygenerowanie kodu
   flutter pub run build_runner build

   # LUB uruchom w trybie watch (automatyczna generacja przy zmianach)
   flutter pub run build_runner watch
   ```
4. Uruchom w trybie deweloperskim

> **Ważne**: Po każdej zmianie w klasach oznaczonych `@JsonSerializable()` musisz ponownie wygenerować kod używając jednej z powyższych komend.

Szczegółowe instrukcje w [doc/preparations.md](doc/preparations.md)