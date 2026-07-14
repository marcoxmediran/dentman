# Project Coding Rules & Guidelines (DentMan)

This document contains mandatory rules and guidelines for any AI agent or developer modifying the DentMan codebase. Follow these conventions strictly to maintain codebase health, type safety, and visual quality.

---

## 1. Directory & File Organization

We follow a **Layer-based directory structure** matching the existing codebase. Group files by their functional layer:

*   **Screens**: Place screen entry points in `lib/screens/<feature_name>/` (e.g., `lib/screens/dentists/dentists_screen.dart`).
*   **Screen-Specific Widgets**: Screen-specific sub-widgets (extracted for cleaner file structure) must go in `lib/screens/<feature_name>/widgets/` (e.g., `lib/screens/dentists/widgets/dentist_roster_card.dart`).
*   **Global/Shared Widgets**: Place reusable widgets shared across multiple features in `lib/widgets/common/` (e.g., `lib/widgets/common/appointment_status_badge.dart`).
*   **Models**: Place data models in `lib/models/` (e.g., `lib/models/treatment.dart`).
*   **Repositories**: Database access and repository files must go in `lib/repositories/`.
*   **Providers**: Riverpod providers and state injection must go in `lib/providers/`.
*   **Theme**: General style tokens go in `lib/theme/`.

---

## 2. Database & Repository Layer

All database queries and mutations must flow through our abstract repository system:

1.  **Unified Interface**: All operations must be defined in the abstract interface `DatabaseRepository` in `lib/repositories/database_repository.dart`.
2.  **Dual Implementation**: Any operation added to the interface **must** be implemented in both concrete classes:
    *   `MockDatabaseRepository` (`lib/repositories/mock_database_repository.dart`): In-memory mock database using Broadcast `StreamController`s. Essential for offline testing and fast development. Always ensure events push to stream controllers (e.g., calling notification helpers like `_notifyAllTreatments()`).
    *   `FirestoreDatabaseRepository` (`lib/repositories/firestore_database_repository.dart`): Live Firebase/Firestore implementation.
3.  **No Direct Queries**: Never query Firestore (`FirebaseFirestore.instance`) directly from views, widgets, or controllers. All operations must pass through the injected repository.

---

## 3. State Management (Riverpod)

We use **standard, non-codegen Riverpod providers** for state mapping and repository injection:

1.  **Suffix Naming Convention**: Standardize provider names using suffix names:
    *   `*StreamProvider` for streams (e.g., `patientsStreamProvider`).
    *   `*FutureProvider` for futures (e.g., `patientAppointmentsFutureProvider`).
    *   `*Provider` for read-only injections (e.g., `databaseRepositoryProvider`).
2.  **No Code Generation**: Do not introduce code-generation annotations (`@riverpod`) or run `build_runner` for provider definitions. Keep definitions clean and manually declared in `lib/providers/database_provider.dart`.

---

## 5. UI Layout & Design System

1.  **Theme Tokens**: Always use the brand palette and styles defined in `AppTheme` (in `lib/theme/app_theme.dart`). Do not use raw hex colors or inline custom TextStyles.
2.  **Text Styling**: Access text styles via the MaterialApp text theme: `Theme.of(context).textTheme.titleMedium` (or other appropriate sizes).
3.  **Visual Safety (Text Overflow)**:
    *   Always prevent text wrapping and vertical height mismatch bugs on currency amounts, prices, or numbers.
    *   Wrap variable-length text/numbers (e.g., Peso amounts like `₱12,500.00` in metric cards) inside a `FittedBox` constraint set to `fit: BoxFit.scaleDown` and `alignment: Alignment.centerLeft`.
    *   For text that may overflow, use `maxLines` and `overflow: TextOverflow.ellipsis`.

---

## 6. Coding Style & Quality Assurance

1.  **Explicit Type Declarations**: Always use explicit types for variable declarations (e.g., `final Dentist dentist = dentists[index];` or `final Treatment treatment = filtered[index];`), especially within builders, list view items, loops, and stream mapping. This prevents unused import warnings and ensures strict compile-time safety.
2.  **Static Analysis**: Code changes must be warning-free. Always verify updates by running `flutter analyze`. Address any unused imports, deprecated properties, or type mismatches immediately.
3.  **Unit & Widget Testing**: Ensure that any changes do not break widget or unit tests. Run `flutter test` before completing tasks.
