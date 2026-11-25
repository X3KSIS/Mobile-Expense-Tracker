# Progress

Running log of what has been built and what comes next. Newest session first.

## Session 2 — 25 Nov 2026

**Scope:** sign-in, sign-up, Profile and Edit profile on a fake auth repository. No Firebase yet.

### Done

- **Auth data:** `AppUser` and `AuthException` domain models. `AuthRepository` (a `ChangeNotifier`) with sign in, sign up, sign out, password reset and profile update. `AuthRepositoryLocalFake` keeps accounts in memory with one demo account: **demo@expensetrack.app / password123**. Nothing is persisted, so the app starts signed out on every launch.
- **Routing:** go_router `redirect` keeps signed-out users on `/login` and `/signup`, and moves signed-in users to `/home`. The router refreshes only when the signed-in state changes, not on profile edits (profile-edit refreshes raced with popping the edit screen). The splash screen picks Home or sign-in from the auth state.
- **Sign in** (`/login`): email and password with inline validation, show/hide password, error banner, "Forgot password?" (snackbar confirmation) and a link to sign up.
- **Sign up** (`/signup`): name, email, password (8+ characters with a letter and a number) and confirm password. A successful sign-up signs the user in and opens Home.
- **Profile** (`/profile`, opened by tapping the avatar on Home): navy user card, Account / Preferences / Support sections (most items show "coming soon"), About dialog, and sign-out with confirmation.
- **Edit profile** (`/profile/edit`): name and optional Zambian phone number. Email is read-only for now.
- **Shared UI:** `PrimaryButton`, `LabeledTextField`, `PasswordTextField`, `FormErrorBanner`, `UserAvatar`, `ScreenHeader`, plus `Command1`, `Validators` and `formatPhone`.
- **Fix:** the floating nav bar overflowed by 19px on narrow phones with a long tab label selected. The active pill now shrinks and ellipsizes.
- **Quality:** `flutter analyze` clean; 64 tests pass (auth fake, validators, auth and profile ViewModels, login widget tests, full sign-in / sign-up / profile / sign-out navigation).

### Next

1. Run on the phone and review the new screens (not yet checked on the device).
2. Visual fixes the user has noted for Home, splash and the nav bar.
3. Add transaction (`/add`), Activity, Budgets, Reports.
4. Firebase Auth: swap `AuthRepositoryLocalFake` for a Firebase-backed repository (needs package approval).

## Session 1 — 24 Nov 2026

**Scope:** theme, splash screen, navigation shell and Home screen UI. Mock data only (no backend, Firebase or database).

### Done

- **Setup:** `provider`, `go_router`, `intl`, `flutter_native_splash` (dev). Plus Jakarta Sans (400–800) bundled in `assets/fonts/` with its OFL licence. Folder structure from `CLAUDE.md`; counter demo removed.
- **Theme** (`lib/ui/core/themes/`): colour, spacing, radius and typography tokens; Material 3 `ThemeData` with card, filled/outlined/text button, chip, input, snackbar and tooltip themes.
- **Splash:** native splash (#F7F7F8 with the coral wallet logo, including Android 12). Flutter splash fades and scales in the logo, "ExpenseTrack" wordmark and tagline over 600 ms. `SplashViewModel` waits 1.5 s, then goes to `/home` (auth check is a `TODO(auth)`).
- **Navigation:** `StatefulShellRoute` with Home, Activity, Budgets and Reports. Custom floating pill bottom bar and black "+" button that pushes `/add`. Activity, Budgets, Reports and Add are placeholder screens.
- **Home:** header, balance card with hide-amounts toggle, budget alert card, quick actions and recent activity. `HomeViewModel` loads via a `Command`, exposes loading/error/data state, supports pull-to-refresh.
- **Data:** domain models (`Transaction`, `MonthlySummary`, `BudgetAlert`), abstract repositories and `*_local_fake` implementations with ZMW mock data (net 4,820; Groceries budget 97 % used, ZMW 100 left).
- **Quality:** `flutter analyze` clean; 19 tests pass (HomeViewModel unit tests, Home widget tests, currency formatter, splash → home navigation). Ran on a physical Android 15 device without errors.

### Decisions

- `Transaction.categoryIcon` is a string key and `categoryColor` an ARGB int, so domain models stay free of Flutter types. The UI resolves them in `lib/ui/core/ui/category_icon.dart`.
- `MonthlySummary` has a `month` field for the "Net balance · November" label.
- Fake transactions are dated relative to the current time so "today"/"Yesterday" labels look right.

### Next

1. Review Home, splash and bottom bar on the device and fix any visual issues.
2. Build the next screen: Activity (full transactions list) or Add transaction (`/add`). "See all", "+" and the quick actions already lead there.
3. Notifications screen (bell currently shows "coming soon").
4. Later phases: Firebase Auth (replaces the splash `TODO(auth)` and the hard-coded user name), Drift offline storage, Django REST sync, `fl_chart` reports.
