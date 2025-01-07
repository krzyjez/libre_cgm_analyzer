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
  res.json({
    message: 'API działa!',
    endpoints: {
      '/': {
        method: 'GET',
        description: 'Lista dostępnych endpointów API'
      },
      '/csv-data': {
        method: 'GET',
        description: 'Pobieranie danych CSV z pomiarami glukozy',
        response: 'text/csv'
      },
      '/user-data': {
        methods: {
          GET: 'Pobieranie danych użytkownika',
          POST: 'Zapisywanie danych użytkownika'
        },
        request: 'application/json',
        response: 'application/json'
      }
    }
  });
});

// Endpoint zwracający plik CSV
app.get('/csv-data', async (req, res) => {
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
app.get('/user-data', async (req, res) => {
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
app.post('/user-data', async (req, res) => {
  try {
    const userData = req.body;
    await fs.writeFile(userDataPath, JSON.stringify(userData, null, 2));
    res.json({ message: 'Dane użytkownika zostały zapisane' });
    console.log('Dane użytkownika zostały zapisane');
  } catch (error) {
    console.error('Błąd podczas zapisywania danych użytkownika:', error);
    res.status(500).json({ error: 'Błąd podczas zapisywania danych użytkownika' });
  }
});

app.listen(port, () => {
  console.log(`Serwer działa na http://localhost:${port}`);
});
