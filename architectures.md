# 🧱 Swift Space: Architecture & Development Guideline

This document serves as the **Absolute Source of Truth** for the Swift Space Flutter project structure. All future developments, whether by humans or AI, must strictly adhere to these rules.

---

## 🏛️ 1. Core Philosophy: Feature-First Clean Architecture

We use a modular, feature-based approach combined with Clean Architecture principles. Every feature is a self-contained unit that can be developed, tested, and maintained independently.

### Root Structure (`lib/`)
- `core/`: Infrastructure, global services, and brand constants.
- `shared/`: Reusable UI widgets and common models.
- `features/`: The heart of the app, organized by functional modules.
- `main.dart`: Global entry point and provider initialization.

---

## 📂 2. Feature Internal Structure

Each feature folder (e.g., `lib/features/property/`) should follow this standard layout. Layers are added **as needed**:

```
feature_name/
├── data/           # Remote & Local data handling
│   ├── datasources/
│   ├── models/    # Data Transfer Objects (DTOs)
│   └── repositories/ # Implementation of domain contracts
├── domain/         # Pure Business Logic (No Flutter imports)
│   ├── entities/  # Clean business objects
│   ├── repositories/ # Abstract contracts
│   └── usecases/  # Functional application actions
├── presentation/   # UI and State
│   ├── pages/     # Screens/Full views
│   ├── widgets/   # Feature-specific components
│   └── state/     # Providers (ChangeNotifiers)
└── di/             # Feature-level dependency injection
```

---

## 🛑 3. Strict Architectural Rules

### I. Layer Isolation
- **Domain stays Pure**: The `domain/` layer must NEVER import `package:flutter`. It is pure Dart logic.
- **Data stays Abstract**: `data/` implements the interfaces defined in `domain/`.
- **Presentation stays Visual**: Business logic logic belongs in `usecases` or `providers`, never in the UI builders.

### II. Import Policy (Mandatory)
- **Absolute Imports ONLY**: Always use `package:swiftspace/...`.
- **No Relative Imports**: Never use `../../`. This prevents fragile paths and maintains modularity.

### III. State Management (Provider)
- Use `ChangeNotifier` and `Provider`.
- Place providers in `features/<feature>/presentation/state/`.
- Register global providers in `main.dart`. Feature-specific scoping is encouraged where appropriate.

---

## 🎨 4. Coding & Naming Standards

| Type | Naming Convention | Example |
| :--- | :--- | :--- |
| **Pages/Screens** | `*_screen.dart` | `explore_screen.dart` |
| **Providers** | `*_provider.dart` | `negotiation_provider.dart` |
| **States** | `*_state.dart` | `property_state.dart` |
| **Widgets** | `*_widget.dart` or Descriptive | `property_card.dart` |
| **Constants** | `App*` classes | `AppColors`, `AppStrings` |

---

## 🚦 5. Asynchronous Process Handling

To ensure a consistent UX and robust error handling, all async operations must follow the **Result/State Pattern**.

### I. State Modeling
Use **Sealed Classes** (Dart 3+) for feature states instead of multiple booleans (`isLoading`, `isError`).

```dart
sealed class RemoteState<T> {}
class Initial<T> extends RemoteState<T> {}
class Loading<T> extends RemoteState<T> {}
class Success<T> extends RemoteState<T> { final T data; Success(this.data); }
class Failure<T> extends RemoteState<T> { final String message; Failure(this.message); }
```

### II. Implementation Rules
- **Never leave a UI in limbo**: Always handle the `Loading` and `Error` states.
- **Fail Fast**: Catch exceptions in the `data` layer and convert them into meaningful `Failure` objects for the `domain` and `presentation` layers.

---

## 📦 6. Package Selection Policy

When adding new dependencies to `pubspec.yaml`:

1. **Efficiency First**: Prefer packages with minimal transitive dependencies and low binary size impact.
2. **Standardization**: Use established packages already in the project (e.g., `provider`, `lucide_icons`) before introducing alternatives.
3. **Platform Check**: Ensure the package is truly cross-platform.
4. **Dart-Native**: Favor native Dart/Flutter solutions over platform-specific plugins when possible.

---

## 🤖 7. Protocol for AI Assistants (Read Before Coding)

If you are an AI assistant helping with this project, you **MUST**:

1. **Read this file** before suggesting any structural changes.
2. **Verify paths**. Check `lib/core/constants/app_constants.dart` for branding values before hardcoding strings or colors.
3. **Respect the Layers**. If adding a backend feature, create `data` and `domain` folders even if they are currently empty.
4. **Clean up**. Do not leave orphaned files or unused imports. Standardize imports to `package:swiftspace/...` immediately.
5. **Branding First**. Always use `AppColors`, `AppAssets`, and `AppStrings` for any UI elements.

---

## 🚀 8. Roadmap for New Features

When adding a new feature (e.g., `virtual_tour`):
1. Create the folder in `lib/features/virtual_tour`.
2. Start with `presentation/pages/` and `presentation/state/`.
3. If data persistence or API calls are needed, scaffold `domain/` and `data//` layers.
4. Update `main.dart` if a global provider is required.

---

**Last Updated**: April 2026  
**Status**: ACTIVE GUIDELINE
