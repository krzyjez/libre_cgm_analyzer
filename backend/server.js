const express = require('express');
const cors = require('cors');
const fs = require('fs');
const fsPromises = require('fs').promises;
const path = require('path');
const logger = require('./logger');
const multer = require('multer');
const util = require('util');

const app = express();
const port = 8000;
const DATA_DIR = 'data_source';
const IMAGES_DIR = path.join(__dirname, '..', DATA_DIR, 'images');

// Upewniamy się, że katalog images istnieje
(async () => {
  try {
    await fsPromises.mkdir(IMAGES_DIR, { recursive: true });
    logger.info(`Utworzono katalog dla obrazków: ${IMAGES_DIR}`);
  } catch (error) {
    logger.error(`Błąd podczas tworzenia katalogu dla obrazków: ${error}`);
  }
})();

// Konfiguracja multer do obsługi przesyłania plików
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    logger.info(`Próba zapisu pliku w katalogu: ${IMAGES_DIR}`);
    // Sprawdzamy czy katalog istnieje synchronicznie
    if (!fs.existsSync(IMAGES_DIR)) {
      fs.mkdirSync(IMAGES_DIR, { recursive: true });
    }
    cb(null, IMAGES_DIR);
  },
  filename: function (req, file, cb) {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    const ext = path.extname(file.originalname);
    const filename = path.basename(file.originalname, ext) + '-' + uniqueSuffix + ext;
    logger.info(`Generowanie nazwy pliku: ${filename}`);
    cb(null, filename);
  }
});

// Filtr akceptujący tylko obrazki
const fileFilter = (req, file, cb) => {
  const allowedTypes = ['image/jpeg', 'image/png', 'image/gif'];
  logger.info(`Sprawdzanie typu pliku: ${file.mimetype}`);
  if (allowedTypes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error(`Nieprawidłowy typ pliku. Dozwolone są tylko obrazki (JPEG, PNG, GIF). Otrzymano: ${file.mimetype}`));
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
  const contentType = req.headers['content-type'] || '';
  
  // Logujemy podstawowe informacje o żądaniu
  logger.info('REQUEST:', {
    method: req.method,
    url: req.url,
    headers: req.headers
  });

  // Dla multipart/form-data logujemy tylko metadane
  if (contentType.includes('multipart/form-data')) {
    logger.info('Multipart form data request');
  } else if (contentType.includes('application/json')) {
    logger.info('JSON data:', req.body);
  }

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
    const files = await fsPromises.readdir(dataDir);
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
    const exists = await fsPromises.access(userDataPath).then(() => true).catch(() => false);
    
    if (!exists) {
      logger.info('Tworzenie nowego pliku user_data.json');
      await fsPromises.writeFile(userDataPath, JSON.stringify({}, null, 2));
      return res.json({});
    }

    const userData = await fsPromises.readFile(userDataPath, 'utf8');
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
    logger.info('json: ', JSON.stringify(req.body));
    await fsPromises.writeFile(userDataPath, JSON.stringify(req.body));
    res.json({ message: 'Dane użytkownika zostały zapisane' });
  } catch (error) {
    logger.error('Błąd podczas zapisywania danych użytkownika:', error);
    res.status(500).json({ error: 'Błąd podczas zapisywania danych użytkownika' });
  }
});

// Endpoint do dodawania obrazka
app.post('/images', (req, res, next) => {
  logger.info('Przed multer:', {
    contentType: req.headers['content-type'],
    contentLength: req.headers['content-length']
  });
  
  upload.single('file')(req, res, (err) => {
    if (err) {
      logger.error('Błąd multer:', {
        name: err.name,
        message: err.message,
        code: err.code,
        field: err.field,
        storageError: err.storageErrors
      });

      if (err.code === 'LIMIT_FILE_SIZE') {
        return res.status(400).json({ error: 'Plik jest za duży (max 5MB)' });
      }
      if (err instanceof multer.MulterError) {
        return res.status(400).json({ error: `Błąd przetwarzania pliku: ${err.message}` });
      }
      return res.status(500).json({ error: `Błąd podczas przetwarzania pliku: ${err.message}` });
    }
    
    logger.info('Po multer:', {
      file: req.file,
      body: req.body
    });

    if (!req.file) {
      logger.error('Nie przesłano pliku lub błąd przetwarzania');
      return res.status(400).json({ error: 'Nie przesłano pliku lub błąd przetwarzania' });
    }

    logger.info(`Dodano nowy obrazek: ${req.file.filename}`, {
      originalname: req.file.originalname,
      mimetype: req.file.mimetype,
      size: req.file.size,
      path: req.file.path
    });

    res.json({ 
      message: 'Obrazek został dodany',
      filename: req.file.filename
    });
  });
});

// Endpoint do pobierania obrazka
app.get('/images/:filename', async (req, res) => {
  try {
    const filename = req.params.filename;
    const imagePath = path.join(IMAGES_DIR, filename);

    logger.info(`Próba pobrania obrazka: ${filename}`, {
      path: imagePath
    });

    // Sprawdzamy czy plik istnieje
    try {
      await fsPromises.access(imagePath);
    } catch {
      logger.error(`Nie znaleziono obrazka: ${filename}`, {
        path: imagePath
      });
      return res.status(404).json({ error: 'Nie znaleziono obrazka' });
    }

    logger.info(`Pobrano obrazek: ${filename}`);
    res.sendFile(imagePath);
  } catch (error) {
    logger.error('Błąd podczas pobierania obrazka:', error);
    res.status(500).json({ error: `Błąd podczas pobierania obrazka: ${error.message}` });
  }
});

// Endpoint do usuwania obrazka
app.delete('/images/:filename', async (req, res) => {
  try {
    const filename = req.params.filename;
    const imagePath = path.join(IMAGES_DIR, filename);

    logger.info(`Próba usunięcia obrazka: ${filename}`, {
      path: imagePath
    });

    try {
      await fsPromises.access(imagePath);
    } catch {
      logger.error(`Nie znaleziono obrazka do usunięcia: ${filename}`, {
        path: imagePath
      });
      return res.status(404).json({ error: 'Nie znaleziono obrazka' });
    }

    await fsPromises.unlink(imagePath);
    logger.info(`Usunięto obrazek: ${filename}`);
    res.json({ message: 'Obrazek został usunięty' });
  } catch (error) {
    logger.error('Błąd podczas usuwania obrazka:', error);
    res.status(500).json({ error: `Błąd podczas usuwania obrazka: ${error.message}` });
  }
});

// Endpoint do listowania obrazków
app.get('/images', async (req, res) => {
  try {
    // Upewniamy się że katalog images istnieje
    await fsPromises.mkdir(IMAGES_DIR, { recursive: true });
    
    const files = await fsPromises.readdir(IMAGES_DIR);
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
