# Progress

Running log of what has been built and what comes next. Newest session first.

## Where things stand (end of 26 Nov 2026)

**Core objective:** expense tracking and spending habits (see `CLAUDE.md`).

**Built, on fake repositories:** auth screens (interface only), Home, Activity (last 7 days) and History, full-screen search, Add transaction (with wallet, fill from an SMS), budgets per pay cycle (expand, reorder), Reports (habits, regular payments, categories, trend, heatmap), wallets and transfers, payday and safe to spend, payment capture from notifications, Profile, dark mode, one coral icon style, motion throughout. Launcher icon and the name Expense Tracker on every platform. Everything is pushed to `origin/main`; `flutter analyze` is clean and 189 tests pass.

**Not yet verified on the phone:** everything since session 3. The APK build could not finish from Claude's sandbox, so run it from a terminal: `flutter run -d 1519137578004351`.

**Pick up next time:**

1. Run on the phone; turn on notification access (Profile → Payment messages) and check real MoMo, Airtel and bank messages are read. Share a few real messages (details changed) to tune the parser.
2. Category trends over time, then personal inflation with the price tracker.
3. Reminders before regular payments are due (needs `flutter_local_notifications`; ask first).
4. Wallet follow-ups: edit or delete wallets with transactions, show the wallet on transaction details, filter by wallet.
5. Later phases: Drift storage (nothing persists yet: settings, wallets, payday, detected payments), Firebase Auth (restore form validation), Django REST sync.
6. Still open from earlier: visual corrections for Home, splash and the nav bar; notifications screen, receipts, grocery lists, price tracker, categories management.

## Session 5: 26 Nov 2026 (continued)

### Done

- **One icon colour:** category and wallet tiles share `IconTile`: a coral (accentText) outline icon on accentSoft, or white on accentStrong for the selected category in the picker. Stored category colours remain data only.
- **History:** the Activity tab shows the last 7 days (filter, totals and search kept) and ends with a See all activity card. The new History page (`/history`) groups every transaction by month (with each month's money in and out) and day, with the same All / Expenses / Income filter folding rows and months in place.
- **Core objective** added to `CLAUDE.md`: expense tracking and spending habits.
- **Habit insights:** `SpendingInsights.compute` (domain) compares this month so far with the same days last month (whole months for past months): overall pace, biggest category rise and fall, categories rising 3+ months running, top place visited more than once, small spends (ZMW 100 or less) adding up, and the busiest weekday over 90 days. Shown as a Your habits section on Reports (per selected month) and a Your spending habits card on Home with the top insight. Wording lives in `describeInsight` (`insight_row.dart`).
- **Regular payments:** `RecurringPayments.detect` (domain) groups expenses by place and finds weekly, fortnightly and monthly rhythms (3+ payments, 70% of gaps on rhythm, last 200 days). Each gets a usual amount, fixed or varying, a kind (subscription, bill, regular spending), monthly cost, next due date and status (upcoming, due soon within 5 days, late); stopped ones drop out. Reports has a Regular payments section; `/recurring` shows the monthly and yearly total, Coming up, and each kind. Demo data gained a monthly DStv Compact (history only).
- **Quality:** `flutter analyze` clean; 189 tests pass; screens rendered and reviewed.

### Next

1. Category trends over time and personal inflation with the price tracker.
2. Remind before a regular payment is due (needs `flutter_local_notifications`, a planned package).

## Session 4: 26 Nov 2026 (continued)

**Scope:** the three features that set the app apart for Zambian users: wallets, payday-to-payday budgeting and reading mobile money messages. No new packages.

### Done

- **Wallets:** `Wallet` (cash, mobile money, bank) and `Transfer` models; every transaction has a `walletId`. Balances are computed (`WalletBalance.compute`) from opening balance, transactions and transfers. `WalletRepository` with fake Cash, MTN MoMo and Zanaco wallets and monthly top-ups and withdrawals. Wallets page (`/wallets`): money held across wallets, each balance, add or edit a wallet, Move money (with an optional charge saved as a Fees & charges expense), recent transfers. Home has a wallet strip; Add transaction has a Paid from / Received into picker. New Fees & charges category.
- **Payday budgeting:** `PayCycle` (payday to the day before the next; payday 1 = calendar month) and `CycleForecast` (money held spread over the days to payday, the spending pace, the day it runs out, and on track / tight / runs short / empty). Home shows a Safe to spend today card; budgets and the budget alert are measured per pay cycle. Payday is set from the Home card or Profile (`SettingsRepository.payday`, default 1).
- **Mobile money messages:** `MoneyMessageParser` reads MTN MoMo, Airtel Money, Zamtel Kwacha and bank SMS: amount, direction (received, spent, cash withdrawal), provider, other party, charge, balance, reference, date (day first) and a category guess. Add transaction has Fill from a message: paste (or tap Paste), check the preview, fill the form. The matching wallet is picked, and a charge is saved separately unless dropped. Withdrawals point to Move money.
- **Automatic capture (approved package `notification_listener_service`):** Android notification access, explained and requested on a From your messages screen (`/detected`, also from Profile). Payment notifications (parsed, and naming a provider) wait there to be added or dismissed; nothing is saved automatically. Add opens Add transaction pre-filled and clears the item once saved. Home shows a banner while payments wait. Notifications arrive only while the app runs, so the tray is re-scanned on start and every return to the foreground. `android/build.gradle.kts` compiles plugins against SDK 36 (the plugin asked for 34).
- **Quality:** `flutter analyze` clean; 160 tests pass. Screens rendered and reviewed. The APK build could not finish from Claude's sandbox (network downloads failed), so it is not yet verified on the phone.

### Next

1. Run on the phone (`flutter run -d 1519137578004351`), allow notification access, and check real MoMo, Airtel and bank messages are picked up; tune the parser with them (the test samples are made up).
2. Capture while the app is closed would need a background isolate; for now the tray catch-up covers it.
3. Edit or delete wallets that have transactions; show the wallet on transaction details; filter Activity by wallet.
4. Persist settings, wallets and transfers once Drift lands.

## Session 3 — 26 Nov 2026

**Scope:** the UI/UX spec: smooth navigation, status colours with unique icons and shapes, morphing icons with dark mode, skeletons and a slow-motion pull-to-refresh, drag to reorder, card expansion, springy buttons and a focused full-screen search.

### Done

- **Dark mode:** colour, text, gradient and shadow tokens moved into an `AppPalette` theme extension with light and dark palettes; every widget reads `context.colors` / `context.text`. Switching blends every colour over 500 ms. Theme preference (system, light, dark) in a new `SettingsRepository` (in-memory fake). Category icons are lightened on dark surfaces so dark ones (Housing) stay visible.
- **Sun-to-moon toggle** in the Home header: rays swirl and retract, a crescent is cut in, a star twinkles in.
- **Status system:** success, warning, danger and neutral, each with its own colour, shape (circle, triangle, octagon, dashed ring) and glyph. Budgets show On track, Near limit, Over budget or Not started.
- **Budget cards** expand on tap (350 ms ease-out) to show left per day, spent per day and Edit. Long-press to drag them into a new order: the lifted card grows 5% and the others slide aside. Order is saved through `BudgetRepository.reorderBudgets` (budgets are no longer sorted by percentage).
- **Buttons** (primary, header icons, "+", quick actions, search chips) shrink to 95% and spring back.
- **Pull to refresh** on every tab is a slow-motion indicator (`SlowRefresh`): a coral ring fills as you pull, the arrow flips past the trigger, it spins slowly while refreshing and glides back.
- **Full-screen search** (`/search`): the Activity search box glides into a focused page above the tabs, with category suggestions and results by day. Search moved out of the Activity view model.
- **App icon and name:** launcher icons on every platform (Android legacy, adaptive and themed; iOS; macOS; web; Windows) are drawn from one vector copy of the splash wallet. Regenerate with `flutter test tool/app_icon/generate_app_icons_test.dart`. The app is called Expense Tracker everywhere (the in-app wordmark still says ExpenseTrack).
- **Activity filters:** switching All, Expenses and Income folds rows in and out in place instead of swapping the list, and the count and totals roll to their new values. Fixed `FadeSwitcher` throwing tall content about 110px (its drift was 2% of the child's height; now a fixed 8px).
- **Docs:** `CLAUDE.md` has the dark palette, status table and motion rules.
- **Quality:** `flutter analyze` clean; 116 tests pass. Light and dark screens rendered to PNG and reviewed; not yet checked on the phone.

### Next

1. Run on the phone: check dark mode, reorder, pull-to-refresh and search feel.
2. Use the status badges for transactions once they have states (pending, failed, draft), e.g. with recurring payments.
3. Persist the theme preference once Drift lands.
4. Carry-overs from session 2: notifications, receipts, grocery lists, price tracker, reminders, category management.

## Session 2 — 25 Nov 2026

**Scope:** sign-in, sign-up and Profile, then every main feature: Add transaction, Activity, Budgets and Reports. All on fake repositories; no Firebase, database or new packages.

### Done

- **Auth (interface only):** `AuthRepository` (a `ChangeNotifier`) with a local fake. For testing, **any input signs in or signs up**: blank or unknown details open the demo account (Paul Mubanga, demo@expensetrack.app). Form validation on the auth screens is switched off with `TODO(auth)` markers. Nothing is persisted, so the app starts signed out on every launch.
- **Routing:** go_router `redirect` keeps signed-out users on `/login` and `/signup`. The router refreshes only on sign-in/out, not on profile edits (those refreshes raced with popping the edit screen).
- **Sign in / Sign up / Profile / Edit profile:** as designed; Profile opens from the Home avatar and has sign-out with confirmation.
- **Data:** `TransactionCategory` model and `CategoryRepository`; `TransactionRepository` lists, adds and deletes and notifies on change; the fake keeps this month fixed (net 4,820) and adds five earlier months for reports. `Budget` + `BudgetProgress`: spending is computed from transactions, so adding an expense moves the budgets.
- **Add transaction** (`/add`): Expense/Income toggle, big amount input, category grid, optional title, date picker and note. Quick actions open it preset (`/add?type=income`, Grocery preselects Groceries).
- **Activity** tab: all transactions grouped by day with each day's net, search, All/Expenses/Income filter, money in/out totals, and a details sheet with delete (also opened from Home).
- **Budgets** tab: navy month summary, per-budget progress cards (left/over), add/edit/delete via a bottom sheet.
- **Reports** tab: month switcher; income/expenses/net tiles with change vs last month; spending by category (ranked single-hue bars); six-month trend columns with the selected month emphasised; daily spending heatmap on one coral ramp.
- **Fixes:** nav bar overflow on narrow phones, then a follow-up so the active tab's label shows again (the first fix squeezed it out). Domain `Category` renamed to `TransactionCategory` (clashed with Flutter's `Category` annotation).
- **Polish:** smooth nav bar (one eased value drives pill colour, padding, icon colour, and the label sliding open and fading in) and cross-fading tab content. Gradient system per the new rules in `CLAUDE.md`: navy mesh cards, gradient primary button, gradient screen headlines.
- **Motion and loading:** `AppMotion` tokens drive every transition. Pushed screens fade forwards, tabs and content swaps fade through (old out, then new in), the segmented toggle slides, progress bars grow, and toggles, spinners and error banners cross-fade. Loading states show shimmer skeletons shaped like the real content instead of spinners. Sign-in and sign-up content is centred.
- **Quality:** `flutter analyze` clean; 102 tests pass. Screens were rendered to PNG in a throwaway test (real fonts) and reviewed; not yet checked on the phone.

### Next

1. Run on the phone and review all new screens.
2. The user's visual corrections for Home, splash and the nav bar.
3. Notifications screen, receipts, grocery lists, price tracker, reminders, categories management (Profile rows show "coming soon").
4. Later phases: Firebase Auth (restore form validation), Drift storage, Django REST sync. New packages need approval.

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
