# Braintask - AI Context & Guidelines

## 🎯 App Purpose
- **What is Braintask?**: An educational tool where students can ask questions and get answers for academic topics.
- **Target Audience**: Students

## 🛠 Tech Stack
- **Framework**: Flutter (Dart)
- **Backend/Database**: Supabase
- **Key Packages**: `image_picker` (for camera/gallery), `file_picker` (for documents).

## 🏗 Architecture (MVC + Riverpod)
We use a **Model-View-Controller (MVC)** pattern implemented with **Riverpod**:

1. **View (`lib/presentation/`)**: 
   - **Contains**: UI elements, Screens, Widgets.
   - **Rules**: Uses `ConsumerWidget` or `ConsumerStatefulWidget` to listen to providers. NO business logic.

2. **Controller (`lib/logic/`)**:
   - **Contains**: Riverpod Notifiers (Providers) and business workflows.
   - **Rules**: Acts as the bridge between View and Model. Manages the state and handles user intents.

3. **Model (`lib/data/`)**:
   - **Contains**: Data models (DTOs) and Repositories.
   - **Rules**: All `supabase_flutter` database interactions go here. Repositories provide clean methods for the Controllers to consume.

4. **`lib/auth/`**:
   - **Contains**: Authentication-specific logic (Model/Controller) and UI (View).

## 🔄 Data Flow (Riverpod-driven)
1. **View** (Widget) watches a **Controller** (Provider).
2. User triggers an action in the **View**, calling a method in the **Controller**.
3. **Controller** calls the **Model** (Repository) to fetch or save data.
4. **Model** returns data/result from Supabase.
5. **Controller** updates the state; **View** rebuilds automatically.

## 🧑‍💻 Coding Conventions & Rules
- **State Management**: **Riverpod** (Functional/Generator style preferred).
- **Code Generation**: Use `riverpod_generator` and `build_runner`.
- **Error Handling**: Catch Supabase exceptions in the Repository (Model) and expose `AsyncValue` or custom error states in the Notifier (Controller).
- **Null Safety**: Rely on strict null safety. Use early returns and avoid the `!` operator where possible.
- **Testing Rules**: Every Notifier in `lib/logic/` must have a unit test. Mock repositories for logic tests. Critical UI flows must have widget tests using the `Given -> When -> Then` naming pattern.