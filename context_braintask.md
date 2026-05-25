# Braintask AI Context

**App**: Braintask (Q&A educational app for students).
**Stack**: Flutter (Dart), Supabase, `image_picker`, `file_picker`.

## Architecture (MVVM + Riverpod)
- `lib/presentation/` (View): UI/Widgets. Uses `ConsumerWidget`/`ConsumerStatefulWidget`. NO business logic.
- `lib/logic/` (ViewModel / State): Riverpod Notifiers. Bridges View & Model. Manages state/intents.
- `lib/data/` (Model): DTOs & Repositories. Handles all Supabase DB calls.
- `lib/auth/`: Auth-specific MVVM.

## Conventions
- **State**: Riverpod (Generator style preferred).
- **Generation**: STRICTLY use `dart run build_runner build -d`. Never use deprecated `flutter pub run`. If `dart run` fails, prompt user to add Flutter `bin` to PATH.
- **Errors**: Catch DB exceptions in Repositories; expose `AsyncValue` or custom states in Notifiers.
- **Code**: Strict null safety, early returns, avoid `!`.
- **Tests**: Unit test all Notifiers (mock repos). Widget test critical UI (`Given -> When -> Then` pattern).

## AI & Agent Rules
- **DB Strictness**: NEVER assume Supabase schema. STOP and ask user for exact table/schema details if unknown.
- **UI Autonomy**: Do NOT halt for minor UI details (colors/paddings). Use Material defaults or mimic existing codebase.
- **Efficiency**:
  - Read files ONCE per turn. No repetitive `cat` commands.
  - Plan and batch tool calls. No incremental read/write cycles for minor tweaks.
  - Restrict scope strictly to user-provided files. Do not read unrelated files.
  - Generate standard Flutter/Riverpod implementations directly in one block without over-analyzing state.