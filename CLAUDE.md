# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Language Requirement

**Must respond in Korean (한국어) for all responses** - per project .cursorrules

## Project Overview

Minimo (우물/Oomool) is a pet fish aquarium management platform built with Flutter frontend and PocketBase backend. The app helps users track aquarium care, health records, schedules, and participate in community Q&A.

## Development Commands

### Flutter Frontend
```bash
# Run app in debug mode
flutter run

# Run on specific device
flutter run -d chrome    # web
flutter run -d ios       # iOS simulator
flutter run -d android   # Android emulator

# Build for release
flutter build web --release
flutter build ios --release
flutter build apk --release

# Run tests
flutter test

# Run single test file
flutter test test/widget_test.dart

# Analyze code
flutter analyze

# Get dependencies
flutter pub get
```

### PocketBase Backend (in backend/ directory)
```bash
# Local development
./pocketbase serve --http=0.0.0.0:8080

# Deploy to Fly.io
cd backend && fly deploy
```

## Architecture

### Tech Stack
- **Frontend**: Flutter 3.10.4+ / Dart with Material Design 3
- **Backend**: PocketBase 0.23.x (Go-based BaaS) on Fly.io
- **State Management**: Provider + MVVM pattern
- **Frontend Hosting**: Vercel (Flutter web)

### Layer Structure (Clean Architecture)

```
lib/
├── data/
│   ├── services/          # PocketBase API integration (Singletons)
│   └── repositories/      # Abstraction layer over services
├── domain/
│   └── models/            # Business entities with enums
├── presentation/
│   ├── screens/           # Page-level widgets
│   ├── viewmodels/        # ChangeNotifier-based state
│   └── widgets/           # Reusable UI components
└── theme/                 # AppColors, AppTextStyles, AppTheme
```

### Service Pattern
All services use singleton pattern: `ServiceName.instance`
```dart
// Example usage
final client = PocketBaseService.instance.client;
final isLoggedIn = AuthService.instance.isLoggedIn;
await NotificationService.instance.initialize();
```

### Backend URL
Hardcoded in `lib/data/services/pocketbase_service.dart`:
```dart
static const String serverUrl = 'https://minimo-pocketbase.fly.dev';
```

### Key PocketBase Collections
- `aquariums` - User's aquariums
- `records` - Maintenance/health records
- `schedules` - Maintenance schedules with alarm support
- `creatures` - User's pets in aquariums
- `creature_catalog` - Master species database
- `questions` / `community_posts` - Community Q&A
- `gallery_photos` - Photo albums per aquarium

### Routing
Named routes defined in `lib/main.dart`. Navigation via:
```dart
Navigator.pushNamed(context, '/aquarium/register');
// Arguments via ModalRoute.settings.arguments
```

### Design System
- Custom font: WantedSans (weights 400-900)
- Colors: `lib/theme/app_colors.dart`
- Typography: `lib/theme/app_text_styles.dart`
- Components: `lib/presentation/widgets/common/` (AppButton, AppChip, etc.)

## Key Patterns

### Adding New Features
1. Create domain model in `domain/models/`
2. Add service in `data/services/` (singleton pattern)
3. Add repository in `data/repositories/` if needed
4. Create viewmodel in `presentation/viewmodels/`
5. Build screens in `presentation/screens/`
6. Register route in `main.dart`

### Async Pattern
```dart
try {
  final result = await someService.fetchData();
  // handle result
} catch (e) {
  debugPrint('Error: $e');
  // handle error
}
```

### ViewModel Updates
```dart
class MyViewModel extends ChangeNotifier {
  void updateData() {
    // ... modify state
    notifyListeners();  // triggers UI rebuild
  }
}
```

## Deployment

### Frontend (Vercel)
- Build: `flutter/bin/flutter build web --release`
- Output: `build/web`
- Config: `vercel.json`

### Backend (Fly.io)
- App: `minimo-pocketbase`
- Region: `nrt` (Tokyo)
- Config: `backend/fly.toml`
- Persistent volume: `pb_data` mounted at `/pb/pb_data`
- Migrations: `backend/pb_migrations/`
- Hooks: `backend/pb_hooks/`
