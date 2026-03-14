# Project Context

## What this repository ships

This repository is published as a local-first Flutter expense tracker.

The shipped app experience is:

- onboarding on first launch
- home dashboard
- analytics
- budget management
- settings
- pushed add-expense flow

The public build is intentionally focused on personal finance tracking and does not ship backend-connected collaboration features.

## Product principles

- Maintainable over clever
- Native Flutter UI over screenshot embedding
- Local persistence first
- Shared state kept simple and centralized
- No demo/seed expense data in the public runtime

## Core runtime behavior

### Expenses

- Users create their own expenses from scratch.
- Expenses are stored locally.
- Home starts empty for new users.
- Add Expense remains usable while the keyboard is open.

### Budgets and categories

- Monthly budget is editable.
- Category budgets are editable.
- Categories stay in sync between Budget and Add Expense.
- Deleted categories disappear from both places.

### Currency

- First expense requires a selected currency.
- Currency changes happen from Settings.
- Existing saved values are converted when currency changes.
- Cached fallback handling is used when live exchange-rate requests fail.

### Theme

- Dark and light modes are supported.
- Theme preference is persisted locally.

## Persistence

Stored with `shared_preferences`:

- onboarding completion
- selected currency
- expenses
- monthly budget
- category budgets
- custom categories
- hidden/deleted categories
- cached exchange-rate data
- theme mode

## Repository layout

- `lib/src/features/*` contains the shipped public app.
- `lib/src/experimental/*` contains future or non-shipping work.
- `assets/design_concept/` contains local design references.

## Experimental area

The following are intentionally isolated from the shipped app:

- backend API client code
- auth-first runtime/bootstrap work
- Splitwise-style online groups module
- older groups prototypes

These modules remain in the repository for future development, but they are not wired into the public app path.

## Important entry points

- `lib/main.dart`
- `lib/src/app.dart`
- `lib/src/features/navigation/presentation/widgets/expense_app_shell.dart`
- `lib/src/features/expenses/presentation/bloc/expense_bloc.dart`

## Testing expectations

Run:

```bash
flutter analyze
flutter test
```

Focus areas:

- onboarding flow
- navigation
- persistence
- category sync
- currency conversion
- budget behavior
- theme behavior

## Notes for contributors

- Keep public features local-first unless the change is explicitly scoped to `experimental/`.
- Avoid threading experimental auth or backend assumptions into the shipped runtime.
- Add comments only when they clarify intent or a non-obvious constraint.
- Prefer small, readable refactors over broad stylistic churn.
