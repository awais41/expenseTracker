# Future Features and Experimental Work

This repository includes a small experimental area for work that is intentionally not part of the shipped open-source app.

## Current experimental modules

- `lib/src/experimental/api`
  - backend API client, route constants, auth token storage, and response parsing
- `lib/src/experimental/auth_sync`
  - auth-first bootstrap, auth repositories, profile setup flow, and related sync models
- `lib/src/experimental/online_groups`
  - Splitwise-style online group expense sharing prototype
- `lib/src/experimental/groups_prototype`
  - earlier local groups prototype kept for reference

## Why this is separated

The public app is released as a polished local-first expense tracker. Keeping future collaboration work isolated makes the shipped code easier to review, understand, and maintain.

## Contributor guidance

- Do not wire experimental modules back into the public runtime unless the repository direction explicitly changes.
- If you extend experimental work, keep imports and dependencies contained inside `experimental/` where possible.
- If a feature graduates into the public app, move it back intentionally with matching docs, tests, and product copy.
