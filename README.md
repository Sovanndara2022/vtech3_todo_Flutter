## Getting Started (Flutter)

Run the project (ZIP)

1. Unzip the project

2. In the project root (`vtech_todo/`), copy env file:

   * Rename `.env.example` → `.env`

3. Install dependencies:

```bash
flutter pub get
```

4. Verify toolchain (recommended):

```bash
flutter doctor -v
```

5. Run on **Android**:

### Option A: Android Emulator

1. Start an emulator from Android Studio (Device Manager)
2. Confirm the device is visible:

```bash
flutter devices
```

3. Run:

```bash
flutter run -d <android-device-id>
```

Example:

```bash
flutter run -d emulator-5554
```

### Option B: Physical Android device

1. Enable **Developer Options** → **USB debugging**
2. Plug in via USB and allow the prompt
3. Confirm:

```bash
flutter devices
```

4. Run:

```bash
flutter run -d <android-device-id>
```

---

# VTech Todo Challenge (Flutter + Dart)

Built in **Dart** using **Flutter** with **Provider** state management. Supports switching between **Dummy** (in-memory) and **Live** (Supabase) modes. Live mode can stream realtime changes via Supabase Realtime.

## Tech Stack

* Flutter + Dart
* Provider (state management)
* Supabase (Postgres + Realtime) for **Live** mode
* In-memory repository for **Dummy** mode
* flutter_dotenv for env vars
* shared_preferences for persisting selected mode
* uuid for IDs

## Features

* Create / Update / Delete todos
* Prevent empty + duplicate todos (validation)
* Edit uses the same input field
* Filter list while typing
* Toggle completion (Completed / Incomplete)
* Dummy vs Live storage (Supabase)
* Live mode realtime updates (multi-user / multi-device)

## Project Structure (key files)

* Entry: `lib/main.dart`
* App shell: `lib/app.dart`
* UI:

  * `lib/ui/todo_page.dart`
  * `lib/ui/widgets/todo_input.dart`
  * `lib/ui/widgets/todo_tile.dart`
* State:

  * `lib/state/todo_store.dart` (validation, filtering, optimistic updates, realtime handling)
  * `lib/state/app_controller.dart` (mode switch + persistence)
* Repositories:

  * `lib/repository/todo_repository.dart`
  * `lib/repository/dummy_todo_repository.dart`
  * `lib/repository/supabase_todo_repository.dart`
* Model:

  * `lib/models/todo_item.dart`

## Dummy vs Live Mode

This app supports 2 backends:

### Dummy (default)

* In-memory storage
* No external setup required

### Live (Supabase)

Requires `.env` with:

```env
TODO_MODE=dummy
SUPABASE_URL=...
SUPABASE_ANON_KEY=...
```

> You can switch modes in the app UI. The selection is persisted using `shared_preferences`.

## Supabase Table

Live mode expects a `todos` table with (at minimum):

* `id` (text/uuid, primary key)
* `text` (text)
* `is_completed` (bool)
* `created_at` (timestamp, default now)
* `updated_at` (timestamp, optional)

The app orders by `created_at` ascending.

## Live Mode + Realtime Demo (Multi-user)

1. Set valid `SUPABASE_URL` and `SUPABASE_ANON_KEY` in `.env`
2. Run the app on **two devices** (example: emulator + physical device, or emulator + Chrome)
3. Switch both to **Live** mode in the UI
4. Create/edit/toggle/delete a todo on Device A
5. Device B should refresh automatically via Supabase realtime events


## Time spent (estimate)
- Total hours: 18h