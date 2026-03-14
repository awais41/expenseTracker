# Expense Tracker

A local-first Flutter expense tracker focused on personal budgeting, clean visuals, and practical day-to-day expense management.

This open-source version ships as a standalone personal finance app with onboarding, a home dashboard, analytics, budgeting, theme switching, currency conversion, and local persistence. Shared/group expense work is intentionally kept out of the public runtime and parked as future experimental work.

## Highlights

- Local-first personal expense tracking
- Premium dark/light UI built with native Flutter widgets
- Onboarding shown once on first launch
- Home dashboard with monthly spending overview
- Analytics screen with trends and category breakdowns
- Monthly and per-category budgeting
- Shared category management between Budget and Add Expense
- Currency selection with conversion of saved values
- Local persistence using `shared_preferences`

## Public App Scope

The public app ships with:

- `Home`
- `Analytics`
- `Budget`
- `Settings`
- pushed `Add Expense` flow

The following are not part of the shipped open-source app:

- sign in / authentication
- cloud sync
- group expense sharing
- backend-connected Splitwise-style flows
- export/import
- notifications

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

## Design Notes

- The UI is based on local concept assets under `assets/design_concept/`.
- `Background.png` is used in onboarding.
- Screens are built as native Flutter UI, not embedded screenshots.

## Persistence

The public app stores data locally with `shared_preferences`.

Persisted values include:

- onboarding completion
- selected currency
- expenses
- monthly budget
- category budgets
- custom categories
- hidden/deleted categories
- cached exchange-rate data
- theme mode

## Currency Behavior

- The first expense requires a currency selection.
- Later currency changes happen from Settings.
- Changing currency converts saved expense and budget values.
- Cached exchange rates are used as a fallback when the network is unavailable.

## Experimental Work

You will find non-shipping collaboration and backend work under `lib/src/experimental/`.

That code is intentionally isolated from the public app runtime so the open-source release stays coherent and easy to understand. See [FUTURE_FEATURES.md](/Users/awais/Documents/Development/F_Projects/expenseTracker-clean/FUTURE_FEATURES.md) for details.

## Getting Started

### Prerequisites

- Flutter SDK
- Dart SDK
- Android Studio and/or Xcode for emulator/device targets

### Install dependencies

```bash
flutter pub get
```

### Run the app

```bash
flutter run
```

### Static analysis

```bash
flutter analyze
```

### Tests

```bash
flutter test
```

## Development Notes

- The public runtime does not depend on any backend configuration.
- Experimental API/client code is kept out of the shipping app path.
- Expense values in the local app use the existing personal expense domain model.
- Experimental online group modules use backend-style IDs and minor-unit money handling.

## Testing Coverage

The current test suite covers:

- onboarding entry
- public shell navigation
- theme switching
- category budget behavior
- currency conversion behavior
- experimental shared-expense balance logic

## Roadmap

- stronger local persistence if data complexity grows
- transaction editing and filtering improvements
- richer analytics
- export/import support
- revisit shared expense flows as a future experimental track

## License

This project is released under the MIT License. See [LICENSE](/Users/awais/Documents/Development/F_Projects/expenseTracker-clean/LICENSE).
