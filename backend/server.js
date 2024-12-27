const express = require('express');
const cors = require('cors');
const path = require('path');

const app = express();
const port = 8000;

// Włączamy CORS dla wszystkich źródeł
app.use(cors());

// Endpoint główny
app.get('/', (req, res) => {
  res.json({ message: 'Libre CGM Analyzer API' });
});

// Endpoint zwracający plik CSV
app.get('/data/glucose.csv', (req, res) => {
  const filePath = path.join(__dirname, '..', 'data_source', 'KrzysztofJeż_glucose_12-12-2024.csv');
  res.setHeader('Content-Type', 'text/csv');
  res.setHeader('Content-Disposition', 'attachment; filename=glucose.csv');
  res.sendFile(filePath);
});

app.listen(port, () => {
  console.log(`Serwer działa na http://localhost:${port}`);
});
