const http = require('http');
const { spawn } = require('child_process');
const path = require('path');

// Funkcja sprawdzająca czy serwer działa
function checkServer(retries = 0, maxRetries = 10) {
    return new Promise((resolve, reject) => {
        http.get('http://localhost:8000', (res) => {
            if (res.statusCode === 200) {
                console.log('Serwer już działa');
                resolve(true);
            } else {
                resolve(false);
            }
        }).on('error', () => {
            if (retries < maxRetries) {
                setTimeout(() => {
                    checkServer(retries + 1, maxRetries).then(resolve);
                }, 1000);
            } else {
                resolve(false);
            }
        });
    });
}

// Funkcja uruchamiająca serwer
function startServer() {
    console.log('Uruchamiam serwer...');
    const server = spawn('node', ['server.js'], {
        cwd: __dirname,
        stdio: 'inherit'
    });

    server.on('error', (err) => {
        console.error('Błąd podczas uruchamiania serwera:', err);
    });

    return new Promise((resolve) => {
        setTimeout(() => {
            checkServer().then(resolve);
        }, 1000);
    });
}

// Funkcja uruchamiająca Flutter
function startFlutter() {
    console.log('Uruchamiam aplikację Flutter...');
    const flutter = spawn('flutter', ['run', '-d', 'chrome'], {
        cwd: path.join(__dirname, '..'),
        stdio: 'inherit',
        shell: true
    });

    flutter.on('error', (err) => {
        console.error('Błąd podczas uruchamiania Fluttera:', err);
    });
}

// Główna funkcja startowa
async function start() {
    const serverRunning = await checkServer();
    
    if (!serverRunning) {
        const started = await startServer();
        if (!started) {
            console.error('Nie udało się uruchomić serwera');
            process.exit(1);
        }
    }

    startFlutter();
}

start();
