# Expense Tracker

A local-first Flutter expense tracker with a polished dark/light UI, onboarding, live analytics, budgeting, shared currency management, and offline persistence.

This project is built as a production-shaped mobile app shell with modular feature folders, reusable theme primitives, and a simple BLoC-style state layer centered around local persistence.

## Screenshots

| Onboarding | Add Expense |
| --- | --- |
| ![Onboarding](assets/design_concept/Background.png) | ![Add Expense](assets/design_concept/Add%20expense.png) |

| Expense Screen | Budget / Group Concept |
| --- | --- |
| ![Expense Screen](assets/design_concept/expense%20screen.png) | ![Design Concept](assets/design_concept/group%20expense.png) |

> Note: The app is implemented as native Flutter UI. The images in `assets/design_concept/` are design references used during development.

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
