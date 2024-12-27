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

## Uruchomienie

Szczegółowe instrukcje znajdują się w [doc/preparations.md](doc/preparations.md)

## Funkcje

- Wyświetlanie danych pomiarowych z pliku CSV
- Analiza trendów glukozy
- Wizualizacja danych na wykresach

## Rozwój

1. Sklonuj repozytorium
2. Zainstaluj zależności (backend + frontend)
3. Uruchom w trybie deweloperskim

Szczegółowe instrukcje w [doc/preparations.md](doc/preparations.md)