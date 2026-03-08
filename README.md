# Expense Tracker

A local-first Flutter expense tracker with a polished dark UI, onboarding, live analytics, budgeting, shared currency management, and offline persistence.

This project is built as a production-shaped mobile app shell with modular feature folders, reusable theme primitives, and a simple BLoC-style state layer centered around local persistence.

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
  - app preferences only, no sign-in/account flow
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
│   ├── theme
│   └── widgets
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

- User enters their own data only, no seeded demo transactions
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

## Persistence

The app currently stores data locally with `shared_preferences`.

Persisted data includes:

- onboarding completion
- selected currency
- expenses
- monthly budget
- category budgets
- custom categories
- hidden/deleted budget categories
- cached exchange-rate pairs

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

The app UI is based on local design assets under [`assets/design_concept/`](/Users/awais/Documents/Development/F_Projects/expense%20Tracker/assets/design_concept/), with `Background.png` used for onboarding. The rest of the app is implemented as native Flutter UI rather than embedding static screenshots.

## What Is Not Implemented Yet

- authentication / sign-in
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

## Android Notes

The Android app manifest includes internet access for currency-rate requests.

## Roadmap

- migrate persistence to a stronger local database if data complexity grows
- add edit/delete for saved expenses
- add filters and search
- expand analytics and reporting
- add receipt upload
- add backup/sync when product requirements are defined

## License

This repository currently has no explicit license. Add one before public distribution.
