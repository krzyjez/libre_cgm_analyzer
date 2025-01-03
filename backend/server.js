const express = require('express');
const cors = require('cors');
const fs = require('fs').promises;
const path = require('path');

const app = express();
const port = 8000;
const DATA_DIR = 'data_source';

app.use(cors());
app.use(express.json());

// Ścieżka do pliku z danymi użytkownika
const userDataPath = path.join(__dirname, '..', DATA_DIR, 'user_data.json');

// Włączamy CORS dla wszystkich źródeł
// Endpoint główny
app.get('/', (req, res) => {
  res.json({ message: 'API działa!' });
});

// Endpoint zwracający plik CSV
app.get('/data/glucose.csv', async (req, res) => {
  try {
    const dataDir = path.join(__dirname, '..', DATA_DIR);
    const files = await fs.readdir(dataDir);
    const csvFile = files.find(file => file.toLowerCase().endsWith('.csv'));
    
    if (!csvFile) {
      return res.status(404).json({ error: 'Nie znaleziono pliku CSV' });
    }

    const filePath = path.join(dataDir, csvFile);
    // wypisujemy informacje logowania o tym jaki plik próbujemy czytać
    console.log(`Odczytujemy plik CSV: ${filePath}`);
    res.setHeader('Content-Type', 'text/csv');
    res.sendFile(filePath, (err) => {
      if (err) {
        console.error('Błąd wysyłania pliku:', err);
        res.status(500).json({ error: 'Błąd podczas wysyłania pliku CSV' });
      }
    });
  } catch (error) {
    console.error('Błąd:', error);
    res.status(500).json({ error: 'Błąd podczas odczytu pliku CSV' });
  }
});

// Pobieranie danych użytkownika
app.get('/data/user', async (req, res) => {
  try {
    const exists = await fs.access(userDataPath).then(() => true).catch(() => false);
    
    if (!exists) {
      // Jeśli plik nie istnieje, zwróć pusty obiekt
      await fs.writeFile(userDataPath, JSON.stringify({}, null, 2));
      return res.json({});
    }

    const userData = await fs.readFile(userDataPath, 'utf8');
    res.json(JSON.parse(userData));
  } catch (error) {
    res.status(500).json({ error: 'Błąd odczytu danych użytkownika' });
  }
});

// Zapisywanie danych użytkownika
app.post('/data/user', async (req, res) => {
  try {
    const newData = req.body;
    await fs.writeFile(userDataPath, JSON.stringify(newData, null, 2));
    res.json({ message: 'Dane zapisane pomyślnie', data: newData });
  } catch (error) {
    res.status(500).json({ error: 'Błąd zapisu danych użytkownika' });
  }
});

app.listen(port, () => {
  console.log(`Serwer działa na http://localhost:${port}`);
});
