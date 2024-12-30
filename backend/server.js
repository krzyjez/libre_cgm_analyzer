const express = require('express');
const cors = require('cors');
const fs = require('fs').promises;
const path = require('path');

const app = express();
const port = 8000;

app.use(cors());
app.use(express.json());

// Ścieżka do pliku z danymi użytkownika
const userDataPath = path.join(__dirname, 'data', 'user_data.json');

// Włączamy CORS dla wszystkich źródeł
// Endpoint główny
app.get('/', (req, res) => {
  res.json({ message: 'API działa!' });
});

// Endpoint zwracający plik CSV
app.get('/data/glucose.csv', (req, res) => {
  const filePath = path.join(__dirname, '..', 'data_source', 'KrzysztofJeż_glucose_12-12-2024.csv');
  res.setHeader('Content-Type', 'text/csv');
  res.setHeader('Content-Disposition', 'attachment; filename=glucose.csv');
  res.sendFile(filePath);
});

// Pobieranie danych użytkownika
app.get('/data/user', async (req, res) => {
  try {
    const exists = await fs.access(userDataPath).then(() => true).catch(() => false);
    
    if (!exists) {
      // Jeśli plik nie istnieje, zwróć domyślne dane
      const defaultData = {
        treshold: 140,
        days: []
      };
      await fs.writeFile(userDataPath, JSON.stringify(defaultData, null, 2));
      return res.json(defaultData);
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
