# Funkcja sprawdzająca czy port 8000 jest zajęty (czy serwer działa)
function Test-ServerRunning {
    $result = Test-NetConnection -ComputerName localhost -Port 8000 -WarningAction SilentlyContinue
    return $result.TcpTestSucceeded
}

# Funkcja uruchamiająca serwer Python
function Start-PythonServer {
    Write-Host "Uruchamiam serwer Python..."
    $pythonPath = "python"
    $serverScript = "backend/main.py"
    
    # Sprawdź czy wirtualne środowisko jest aktywne
    if (-not (Test-Path "backend/venv")) {
        Write-Host "Tworzę wirtualne środowisko Python..."
        & $pythonPath -m venv backend/venv
    }
    
    # Aktywuj wirtualne środowisko
    & "backend/venv/Scripts/Activate.ps1"
    
    # Zainstaluj wymagane pakiety
    Write-Host "Instaluję wymagane pakiety..."
    & pip install -r backend/requirements.txt
    
    # Uruchom serwer w tle
    Start-Process -FilePath $pythonPath -ArgumentList $serverScript -NoNewWindow
    
    # Poczekaj na uruchomienie serwera
    $attempts = 0
    while (-not (Test-ServerRunning) -and $attempts -lt 10) {
        Start-Sleep -Seconds 1
        $attempts++
    }
    
    if (Test-ServerRunning) {
        Write-Host "Serwer Python został uruchomiony pomyślnie"
    } else {
        Write-Host "Nie udało się uruchomić serwera Python"
        exit 1
    }
}

# Główna logika skryptu
if (-not (Test-ServerRunning)) {
    Start-PythonServer
}

# Uruchom aplikację Flutter
Write-Host "Uruchamiam aplikację Flutter..."
flutter run -d chrome
