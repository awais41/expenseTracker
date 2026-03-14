# Expense Tracker

A local-first Flutter expense tracker with a polished dark/light UI, onboarding, live analytics, budgeting, shared currency management, and offline persistence.

This project is built as a production-shaped mobile app shell with modular feature folders, reusable theme primitives, and a simple BLoC-style state layer centered around local persistence.

## Screenshots

| Dashboard | Add Expense |
| --- | --- |
| ![Dashboard](assets/design_concept/dashboard%20screen.png) | ![Add Expense](assets/design_concept/add%20expense%20screen.png) |

| Analytics | Budget |
| --- | --- |
| ![Analytics](assets/design_concept/Analytics%20screen.png) | ![Budget](assets/design_concept/budget%20screen.png) |

| New User Dashboard | Settings |
| --- | --- |
| ![New User Dashboard](assets/design_concept/new%20user%20dashboard%20screen.png) | ![Settings](assets/design_concept/setting%20screen.png) |

> Note: The app is implemented as native Flutter UI. The files in `assets/design_concept/` are design references used during development.

## Features

- Onboarding flow with first-use gating
- Home dashboard with:
  - empty-state guidance for new users
  - recent transactions
  - spending summaries
  - monthly budget overview
- Add Expense flow with:
  - amount, category, date, note, and payment method
  - first-time currency selection
  - add-category option directly from the form
  - disabled receipt area marked `Coming soon`
- Spending Analytics screen with:
  - weekly trend view
  - category breakdown
  - insight card
- Budget screen with:
  - monthly budget editing
  - per-category budget editing
  - add/delete category support
  - shared category source with Add Expense
- Settings screen with:
  - currency change
  - local app preferences
  - theme switching
- Local persistence using `shared_preferences`
- Currency conversion using latest available exchange rates with cached fallback

## Tech Stack

- Flutter
- Dart
- `shared_preferences`
- Material 3
- Feature-based modular structure

## Project Structure

```text
lib/src
├── app.dart
├── core
│   ├── currency
│   ├── errors
│   ├── result
│   ├── state
│   ├── theme
│   └── widgets
├── experimental
│   ├── api
│   ├── auth_sync
│   ├── groups_prototype
│   └── online_groups
└── features
    ├── add_expense
    ├── analytics
    ├── budget
    ├── dashboard
    ├── expenses
    ├── navigation
    ├── onboarding
    └── settings
```

## Implemented Modules

### Onboarding

- First-run experience using local design assets
- Completion is persisted so it does not block every launch

### Dashboard

- Starts empty for new users
- Updates live after expenses are added
- Reads the active currency and monthly budget from persisted state

### Add Expense

- User enters their own data only, with no seeded demo transactions
- First expense requires currency selection
- Categories are shared with the Budget module

### Analytics

- Native Flutter UI based on the provided design direction
- Uses live expense data instead of fixed mock totals

### Budget

- Monthly budget is editable
- Category budgets are editable
- Custom categories can be created and removed

### Settings

- Currency can be changed at any time
- Changing currency converts persisted expense and budget values using current rates
- Theme preference is stored locally

## Persistence

The app stores data locally with `shared_preferences`.

Persisted data includes:

- onboarding completion
- selected currency
- expenses
- monthly budget
- category budgets
- custom categories
- hidden/deleted budget categories
- cached exchange-rate pairs
- theme mode

## Currency Conversion

Currency changes convert existing saved values instead of only changing the symbol.

Current behavior:

- latest rate fetched from a free exchange-rate provider
- fallback provider used if the primary request fails
- cached rates reused when offline

Notes:

- conversion depends on the latest available daily rates, not live intraday FX pricing
- initial fetch for a currency pair requires network access

## Design Notes

The app UI is based on local design assets under `assets/design_concept/`. The shipped screens are implemented as native Flutter UI rather than embedding static screenshots.

## Experimental / Future Work

This repository also contains isolated experimental work under `lib/src/experimental/` for future backend-connected and shared-expense features.

Those modules are intentionally not part of the shipped open-source runtime.

## What Is Not Implemented Yet

- authentication / sign-in in the public app
- cloud sync / backup
- receipt upload
- server-backed data storage
- export/import
- push notifications

## Getting Started

### Prerequisites

- Flutter SDK
- Dart SDK
- Android Studio or Xcode for device/emulator targets

### Install

```bash
flutter pub get
```

### Run

```bash
flutter run
```

### Analyze

```bash
flutter analyze
```

### Test

```bash
flutter test
```

## Testing

The project includes widget and state tests covering:

- onboarding flow
- bottom navigation
- first-time currency selection
- saving expenses
- monthly budget state
- shared category behavior
- category deletion behavior
- currency conversion behavior
- theme behavior

## Android Notes

The Android app manifest includes internet access for currency-rate requests.

## Roadmap

- migrate persistence to a stronger local database if data complexity grows
- add edit/delete for saved expenses
- add filters and search
- expand analytics and reporting
- add receipt upload
- add backup/sync when product requirements are clearly defined
- revisit shared expenses as a future experimental track

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE).
