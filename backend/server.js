const express = require('express');
const cors = require('cors');
const fs = require('fs').promises;
const path = require('path');
const logger = require('./logger');
const multer = require('multer');

const app = express();
const port = 8000;
const DATA_DIR = 'data_source';
const IMAGES_DIR = path.join(__dirname, '..', DATA_DIR, 'images');

// Konfiguracja multer do obsługi przesyłania plików
const storage = multer.diskStorage({
  destination: async function (req, file, cb) {
    try {
      // Upewniamy się że katalog images istnieje
      await fs.mkdir(IMAGES_DIR, { recursive: true });
      cb(null, IMAGES_DIR);
    } catch (error) {
      cb(error);
    }
  },
  filename: function (req, file, cb) {
    // Używamy oryginalnej nazwy pliku
    cb(null, file.originalname);
  }
});

// Filtr akceptujący tylko obrazki
const fileFilter = (req, file, cb) => {
  const allowedTypes = ['image/jpeg', 'image/png', 'image/gif'];
  if (allowedTypes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error('Nieprawidłowy typ pliku. Dozwolone są tylko obrazki (JPEG, PNG, GIF)'));
  }
};

const upload = multer({ 
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: 5 * 1024 * 1024 // Limit 5MB
  }
});

app.use(cors());
app.use(express.json());

// Middleware do logowania wszystkich żądań
app.use((req, res, next) => {
  logger.request(req);
  next();
});

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
      },
      '/images': {
        methods: {
          GET: 'Pobieranie listy obrazków',
          POST: 'Dodawanie nowego obrazka'
        },
        request: 'multipart/form-data',
        response: 'application/json'
      },
      '/images/:filename': {
        methods: {
          GET: 'Pobieranie obrazka',
          DELETE: 'Usuwanie obrazka'
        },
        response: 'image/jpeg, image/png, image/gif'
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
      logger.error('Nie znaleziono pliku CSV');
      return res.status(404).json({ error: 'Nie znaleziono pliku CSV' });
    }

    const filePath = path.join(dataDir, csvFile);
    logger.info(`Odczytujemy plik CSV: ${filePath}`);
    
    res.setHeader('Content-Type', 'text/csv');
    res.sendFile(filePath, (err) => {
      if (err) {
        logger.error('Błąd wysyłania pliku CSV:', err);
        res.status(500).json({ error: 'Błąd podczas wysyłania pliku CSV' });
      }
    });
  } catch (error) {
    logger.error('Błąd podczas odczytu pliku CSV:', error);
    res.status(500).json({ error: 'Błąd podczas odczytu pliku CSV' });
  }
});

// Pobieranie danych użytkownika
app.get('/user-data', async (req, res) => {
  try {
    const exists = await fs.access(userDataPath).then(() => true).catch(() => false);
    
    if (!exists) {
      logger.info('Tworzenie nowego pliku user_data.json');
      await fs.writeFile(userDataPath, JSON.stringify({}, null, 2));
      return res.json({});
    }

    const userData = await fs.readFile(userDataPath, 'utf8');
    logger.info('Pobrano dane użytkownika');
    res.json(JSON.parse(userData));
  } catch (error) {
    logger.error('Błąd odczytu danych użytkownika:', error);
    res.status(500).json({ error: 'Błąd odczytu danych użytkownika' });
  }
});

// Zapisywanie danych użytkownika
app.post('/user-data', async (req, res) => {
  try {
    const userData = req.body;
    logger.info('Zapisywanie danych użytkownika:', userData);
    await fs.writeFile(userDataPath, JSON.stringify(userData, null, 2));
    res.json({ message: 'Dane użytkownika zostały zapisane' });
  } catch (error) {
    logger.error('Błąd podczas zapisywania danych użytkownika:', error);
    res.status(500).json({ error: 'Błąd podczas zapisywania danych użytkownika' });
  }
});

// Endpoint do dodawania obrazka
app.post('/images', upload.single('image'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'Nie przesłano pliku' });
    }

    logger.info(`Dodano nowy obrazek: ${req.file.filename}`);
    res.json({ 
      message: 'Obrazek został dodany',
      filename: req.file.filename
    });
  } catch (error) {
    if (error.code === 'LIMIT_FILE_SIZE') {
      return res.status(400).json({ error: 'Plik jest za duży (max 5MB)' });
    }
    logger.error('Błąd podczas dodawania obrazka:', error);
    res.status(500).json({ error: 'Błąd podczas dodawania obrazka' });
  }
});

// Endpoint do pobierania obrazka
app.get('/images/:filename', async (req, res) => {
  try {
    const filename = req.params.filename;
    const imagePath = path.join(IMAGES_DIR, filename);

    // Sprawdzamy czy plik istnieje
    try {
      await fs.access(imagePath);
    } catch {
      logger.error(`Nie znaleziono obrazka: ${filename}`);
      return res.status(404).json({ error: 'Nie znaleziono obrazka' });
    }

    logger.info(`Pobrano obrazek: ${filename}`);
    res.sendFile(imagePath);
  } catch (error) {
    logger.error('Błąd podczas pobierania obrazka:', error);
    res.status(500).json({ error: 'Błąd podczas pobierania obrazka' });
  }
});

// Endpoint do usuwania obrazka
app.delete('/images/:filename', async (req, res) => {
  try {
    const filename = req.params.filename;
    const imagePath = path.join(IMAGES_DIR, filename);

    // Sprawdzamy czy plik istnieje
    try {
      await fs.access(imagePath);
    } catch {
      logger.error(`Nie znaleziono obrazka do usunięcia: ${filename}`);
      return res.status(404).json({ error: 'Nie znaleziono obrazka' });
    }

    // Usuwamy plik
    await fs.unlink(imagePath);
    logger.info(`Usunięto obrazek: ${filename}`);
    res.json({ message: 'Obrazek został usunięty' });
  } catch (error) {
    logger.error('Błąd podczas usuwania obrazka:', error);
    res.status(500).json({ error: 'Błąd podczas usuwania obrazka' });
  }
});

// Endpoint do listowania obrazków
app.get('/images', async (req, res) => {
  try {
    // Upewniamy się że katalog images istnieje
    await fs.mkdir(IMAGES_DIR, { recursive: true });
    
    const files = await fs.readdir(IMAGES_DIR);
    logger.info(`Pobrano listę ${files.length} obrazków`);
    res.json({ images: files });
  } catch (error) {
    logger.error('Błąd podczas listowania obrazków:', error);
    res.status(500).json({ error: 'Błąd podczas listowania obrazków' });
  }
});

app.listen(port, () => {
  logger.info(`Serwer uruchomiony na porcie ${port}`);
});
