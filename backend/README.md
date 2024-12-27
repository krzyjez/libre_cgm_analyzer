# Libre CGM Analyzer Backend

Backend dla aplikacji Libre CGM Analyzer napisany w FastAPI.

## Wymagania
- Python 3.8+
- pip (menedżer pakietów Pythona)

## Instalacja

1. Zainstaluj wymagane pakiety:
```bash
pip install -r requirements.txt
```

2. Uruchom serwer:
```bash
python main.py
```

Serwer zostanie uruchomiony na http://localhost:8000

## API Endpoints

- GET / - Podstawowy endpoint testowy
- POST /measurements/ - Dodawanie pomiarów
- GET /measurements/ - Pobieranie wszystkich pomiarów

## Dokumentacja API

Po uruchomieniu serwera, dokumentacja API jest dostępna pod:
- http://localhost:8000/docs - Dokumentacja Swagger
- http://localhost:8000/redoc - Dokumentacja ReDoc
