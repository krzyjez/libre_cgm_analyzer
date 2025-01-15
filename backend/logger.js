const fs = require('fs').promises;
const path = require('path');

class Logger {
    constructor() {
        this.logDir = path.join(__dirname, 'logs');
        this.currentDate = null;
        this.currentLogFile = null;
        this.ensureLogDir();
    }

    async ensureLogDir() {
        try {
            await fs.access(this.logDir);
        } catch {
            await fs.mkdir(this.logDir, { recursive: true });
        }
    }

    getLogFileName() {
        const now = new Date();
        const year = now.getFullYear();
        const month = String(now.getMonth() + 1).padStart(2, '0');
        const day = String(now.getDate()).padStart(2, '0');
        return `${year}-${month}-${day}.log`;
    }

    async updateLogFile() {
        const today = new Date().toDateString();
        if (this.currentDate !== today) {
            this.currentDate = today;
            this.currentLogFile = path.join(this.logDir, this.getLogFileName());
        }
    }

    async log(type, message, data = null) {
        await this.updateLogFile();
        const timestamp = new Date().toISOString();
        let logEntry = `[${timestamp}] ${type}: ${message}`;
        
        if (data) {
            // Jeśli data jest stringiem i jest zbyt długi, ucinamy go
            if (typeof data === 'string' && data.length > 1000) {
                logEntry += `\nData: ${data.substring(0, 1000)}... (truncated)`;
            }
            // Jeśli data jest obiektem, serializujemy go z limitem głębokości
            else {
                const safeStringify = (obj, depth = 2) => {
                    const seen = new Set();
                    return JSON.stringify(obj, (key, value) => {
                        if (typeof value === 'object' && value !== null) {
                            if (seen.has(value)) return '[Circular]';
                            seen.add(value);
                            if (depth === 0) return '[Object]';
                            return Object.fromEntries(
                                Object.entries(value).map(([k, v]) => [k, safeStringify(v, depth - 1)])
                            );
                        }
                        if (typeof value === 'string' && value.length > 1000) {
                            return value.substring(0, 1000) + '... (truncated)';
                        }
                        return value;
                    }, 2);
                };
                logEntry += `\nData: ${safeStringify(data)}\n`;
            }
        }
        logEntry += '\n';

        try {
            await fs.appendFile(this.currentLogFile, logEntry);
            console.log(logEntry); // Wyświetlamy też w konsoli
        } catch (error) {
            console.error('Błąd podczas zapisywania do pliku logów:', error);
            // Spróbujmy utworzyć katalog i spróbować ponownie
            await this.ensureLogDir();
            try {
                await fs.appendFile(this.currentLogFile, logEntry);
            } catch (retryError) {
                console.error('Ponowny błąd podczas zapisywania do pliku logów:', retryError);
            }
        }
    }

    info(message, data = null) {
        return this.log('INFO', message, data);
    }

    error(message, data = null) {
        return this.log('ERROR', message, data);
    }

    request(req, message = 'Otrzymano żądanie') {
        const requestData = {
            method: req.method,
            url: req.url,
            headers: req.headers,
            body: req.body,
            query: req.query,
            params: req.params
        };
        return this.log('REQUEST', message, requestData);
    }

    // Metoda pomocnicza do listowania plików logów
    async listLogFiles() {
        try {
            const files = await fs.readdir(this.logDir);
            return files.filter(file => file.endsWith('.log'))
                       .sort()
                       .reverse(); // Najnowsze pliki pierwsze
        } catch (error) {
            console.error('Błąd podczas listowania plików logów:', error);
            return [];
        }
    }
}

module.exports = new Logger();
