# algo_erp_front

The Flutter client for **algoERP** — a multi-tenant ERP (inventory, accounts, employees,
organization, and transactional vouchers). The backend it talks to is a TypeScript + Express 5 +
Prisma + MySQL service that lives outside this repo, at `../models/backend`.

## What makes this app different

This is **not** a conventional feature-per-bloc Flutter app. It runs on a **manifest-driven master
engine**: the `lib/core/` layer owns the machinery (generic repository, `CrudBloc`, and the list/form
"Surfaces"), and each feature under `lib/features/` merely **declares** an entity via an
`EntityManifest`. Core renders it. Most master features contain zero bloc, repository, or list-widget
code. See `CLAUDE.md` and `docs/manifest-spec.md` before adding anything.

- **State:** flutter_bloc (not Riverpod) · **DI:** get_it + injectable · **Routing:** go_router
- **Money/quantity:** always `package:decimal`, never `double`
- **Design:** the "Ledger & Linen" system, lagoon-teal seed; all styling from `context.tokens`

## Getting started

```bash
flutter pub get                                            # deps
dart run build_runner build --delete-conflicting-outputs   # codegen (freezed, injectable)
flutter analyze                                            # lints (very_good_analysis)
dart format .                                              # CI format gate is strict — run before committing
flutter test
```

Run the app — three flavor entrypoints, each with its `API_BASE_URL` baked in:

```bash
make run-dev        # lib/main_dev.dart      → http://localhost:5000
make run-staging    # lib/main_staging.dart  → staging
make run-prod       # lib/main_prod.dart     → prod
# add -d chrome | -d windows | -d android | ... to pick a device
```

The dev backend listens on **port 5000**; seed login is `brand.tester` / `BrandTest123!`.

## Where to look

| I want to… | Read |
|---|---|
| Understand the architecture & conventions | `CLAUDE.md` |
| See what's shipped / deferred | `docs/STATUS.md` |
| Add a master entity (the 7-file recipe) | `docs/manifest-spec.md` |
| Add a voucher type | `docs/templates/voucher-blueprint-recipe.md` |
| Know the backend contract | `docs/api-contract.md` |
| Track backend gaps | `docs/backend-suggestions.md` |
| Browse the widget library | `docs/widget-catalog.md` |

Historical, pre-online-pivot documents are kept under `docs/_archive/` — do not follow them.
