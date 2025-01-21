# Libre CGM Analyzer

An application for analyzing data from the FreeStyle Libre Continuous Glucose Monitoring system. It enables importing, analyzing, and visualizing measurement data from the FreeStyle Libre system.

The default Libre View system is very rigid and makes it practically impossible to achieve the goals behind using FreeStyle Libre CGM. My goals are:
1. I want to attach photos to the documentation because this is the only way to accurately document meals and analyze their impact on glucose levels. The standard application doesn't provide this capability.
2. I want to analyze and quantify exceedances of the safe glucose level - above 140 mg/dL (it's known that exceeding 140 already affects nerve cell degeneration). I want to pay special attention to those moments and meals that trigger exceedances to avoid them in the future. The standard application isn't interested in the 140 level - it focuses on 300 because it's designed for people with more serious problems than insulin resistance.

## Key Features

- Import data from CSV files exported from FreeStyle Libre
- Analyze glucose trends and detect exceedances
- Advanced data visualization through charts
- Ability to add notes and photos to measurements
- Automatic cloud data backup
- Responsive interface working on both computers and mobile devices

## Technologies

### Frontend
- **Framework**: Flutter Web
- **Language**: Dart
- **Charts**: fl_chart
- **Serialization**: json_serializable
- **State Management**: Provider

### Backend
- **.NET 8.0**: Modern REST API
- **Azure Blob Storage**: Secure data storage
- **Azure App Service**: Application hosting
- **Serilog**: Advanced logging

## Project Structure

```
libre_cgm_analyzer/
├── backend-dotnet/                # Backend .NET
│   └── LibreCgmAnalyzer.Api/     # REST API
├── lib/                          # Frontend Flutter
│   ├── models/                   # Data models
│   ├── services/                 # Services
│   ├── widgets/                  # UI Components
│   └── version.dart             # Version information
└── .github/                      # GitHub Actions
    └── workflows/               # CI/CD
```

## Local Development

### Requirements
- .NET SDK 8.0
- Flutter SDK
- Visual Studio Code or Visual Studio 2022
- Azure Storage Emulator (Azurite) for development

### Steps
1. Clone the repository
2. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```
3. Generate serialization code:
   ```bash
   flutter pub run build_runner build
   ```
4. Run backend:
   ```bash
   cd backend-dotnet/LibreCgmAnalyzer.Api
   dotnet run
   ```
5. Run frontend:
   ```bash
   flutter run -d chrome
   ```

## Deployment

The application is hosted on Azure:
- Backend: Azure App Service
- Storage: Azure Blob Storage
- CI/CD: GitHub Actions

## Development

1. Create a new branch for your feature
2. Make changes
3. Run tests
4. Create a Pull Request

## License

This project is licensed under Apache 2.0. See the [LICENSE](LICENSE) file for details.