 # Progress

Running log of what has been built and what comes next. Newest session first.

## Start here (28 Nov 2026)

This is where the next session starts.

**Core objective:** expense tracking and spending habits (see `CLAUDE.md`). Judge every feature against it.

### Where things stand

- **Everything is in a database.** Data is saved on the phone first (Drift, works offline) and synced to Supabase (Postgres with row-level security). Fake repositories exist for tests only.
- **Real sign-in:** Supabase Auth, email and password, form validation on, email confirmation required. There is no demo sign-in in the app.
- **Quality:** `flutter analyze` clean, 309 tests pass. Everything is committed and pushed to `origin/main` (GitHub `X3KSIS/Mobile-Expense-Tracker`).
- **Runs on the phone** (TECNO KM7, `1519137578004351`) against Supabase. The features from the 28 Nov session have not been tried on the phone yet.

### What the app does

- **Capture:** Add, Edit, Spend again and Undo delete; fill from a MoMo, Airtel or bank SMS; payments read from notifications to review; default wallet.
- **See spending:** Home (spending hero with daily bars and safe to spend, where it went with budget status, habit card, hide amounts), Activity (7 days) and History, full-screen search, Reports (habits, regular payments, categories, trend, heatmap), category trends, regular payments page.
- **Plan:** budgets per pay cycle (expand, reorder, warning level 70/80/90%), payday, wallets and transfers.
- **Manage:** categories (add, rename that carries over to past transactions and budgets, icons, reorder, delete with guards), CSV export through the share sheet.
- **Account:** profile photo (gallery), personal details, change password, sync status with Sync now, sign out (refused while unsent changes can't go up).
- **Preferences:** theme (system, light, dark), payday, budget warning level, default wallet, show habits on Home, hide amounts on Home, hide in recent apps (blocks screenshots), lock with fingerprint or PIN.
- **Look and feel:** coral and navy design system, dark mode, motion throughout, skeletons not spinners.

### Backend (Supabase)

- **Project:** "X3KSIS's Project", ref `ambfmaujbnraqiujckoh`, eu-west-1, free plan. Dashboard: https://supabase.com/dashboard/project/ambfmaujbnraqiujckoh
- **Migrations, all applied in the SQL Editor:**
  1. `20261127000000_init.sql`: tables, RLS, `sync_guard` trigger, new-user seeding (profile, 15 categories, Cash wallet).
  2. `20261128000000_preferences.sql`: preference columns on `profiles`.
  3. `20261128010000_profile_photos.sql`: `avatar_path`, private `avatars` Storage bucket and its policies.
  4. `20261128020000_privacy_screen.sql`: `privacy_screen`.
  5. `20261128030000_app_lock.sql`: `app_lock`.
  6. `20261129000000_notifications.sql`: reminder and alert settings, `notifications_seen_at`.
  7. `20261129010000_preferred_name.sql`: `preferred_name`.
  8. `20261129020000_usernames.sql`: `username` (unique), `set_username` and `username_available`. **Not applied yet.**
- **Edge Function** `sign-in-with-username` (`supabase/functions/`), deployed with Verify JWT off. **Not deployed yet.** Steps in `supabase/README.md`.
- **New tables need explicit grants** (`grant select, insert, update ... to authenticated`): this project does not grant access by default.
- **Config:** the project URL and publishable key are built into `SupabaseConfig`, so F5 or `flutter run` connects. `supabase.json` (gitignored) can point a build at another project. Never put the secret key in the app.
- **Email:** Supabase's built-in sender only sends its default link email and is rate-limited. Templates can only be edited after custom SMTP is set up. Clicking the link does confirm the account, even though the page it opens shows "localhost".
- **Device database:** Drift schema version 8 (profile columns were added in versions 2 to 8).

### How to run and check

- **Build and run from a normal terminal or VS Code**, not from Claude's shell: its network breaks Gradle downloads. Use `flutter run -d 1519137578004351`, or F5 with "Expense Tracker (Supabase)".
- **Android build settings already in place:** plugins use NDK 30.0.16248370; Kotlin compiles in-process with incremental builds off (the project is on E:, the pub cache on C:).
- **Reading the phone's database** (debug build):
  `adb exec-out run-as com.example.flutter_expensetracker cat app_flutter/expense_tracker.sqlite > phone.sqlite`
  where `adb` is `%LOCALAPPDATA%\Android\sdk\platform-tools\adb.exe`. Don't take phone screenshots; they show the user's personal apps.
- **Server checks:** SQL Editor queries (read-only) and Logs → API Gateway (filter by POST to see uploads).

### Open issues

1. **Transactions don't reach the phone's database file.** On 28 Nov at 17:5x a ZMW 10 expense showed "Expense saved", yet `expense_tracker.sqlite` was last written at 10:05:59. No `-journal` or `-wal` file existed, and the same file was the only one the app had open. Earlier writes (profile photo 10:03, Cash opening balance 10:05) did land and sync. The wiring is right (`TransactionRepositoryDrift`). Leading theory: a Drift transaction opened around 10:05:59 never committed, and later writes ran inside it in memory. Next check: does the expense survive a force close and reopen? If not, the theory holds; then find which `transaction()` hangs (sync pull, `openAccount`, category save).
2. **The sync loop is fixed,** but the fix hasn't run on the phone yet (it used to sync every 2 seconds).
3. **Password reset** sends Supabase's link, which opens "localhost". It needs custom SMTP and code-based reset (or a deep link).

### Workflow

- **Commit and push** each feature as it's finished (`git push origin main` works). Never add AI attribution to commits.
- **New packages need approval.** Approved so far: `provider`, `go_router`, `intl`, `notification_listener_service`, `drift`, `drift_flutter`, `supabase_flutter`, `image_picker` (gallery only), `share_plus`, plus dev tools.
- **Rules:** keep `flutter analyze` at zero, add tests with every change, and render new screens in light and dark to check them.
- **Data:** every new kind of data needs a Drift table or column, a Supabase migration with RLS and grants, and an entry in the sync.

### Pick up next

1. **On the phone:** apply migration 5, build, turn on Preferences → Lock with fingerprint or PIN and try it (cold start, away under and over a minute, cancel the prompt). Then fully restart, add a transaction (see open issue 1), then try the profile photo, categories, export, Spend again, Undo and Hide in recent apps.
2. **Recommended features,** each needing a package or a decision:
   - **Receipts:** attach a photo to a transaction (Supabase Storage; `image_picker` is already in).
   - **Custom SMTP** in Supabase, then switch the confirmation email to a code (`{{ .Token }}`; the app's code screen is ready) and add code-based password reset.
   - **Auto-add regular payments** (DStv, rent) on their due date, with a confirm step.
3. **Later:** personal inflation with the price tracker, grocery lists. Direct MoMo and bank APIs wait for the institutions (the seam is ready).

## Session 13: 29 Nov 2026

### Done

- **Profile:** the card shows @username and three tracking stats (day streak, recorded this month, months tracked; `TrackingStats.compute` in `domain/models/tracking_stats.dart`) and opens Personal details when tapped. The menu is regrouped into Account, Tracking and App with shorter subtitles; Help is a real sheet of quick answers (was "coming soon"); About uses the name Expense Tracker; the read-only Currency row moved to the footer ("Amounts in ZMW").
- **Budgets:** the summary is now "Spent on budgets" (it never counted unbudgeted spending) with what is left per day until payday and how many budgets need a look. Each bar has a "today" marker (an even pace through the cycle), cards say how spending compares ("ZMW 870 under plan so far"), show what is left on the right, and the caption uses whole kwacha. A new "Not budgeted yet" section lists the biggest categories without a budget with what went on them this cycle and a one-tap budget at a suggested amount (last cycle's spending, rounded up), which opens the sheet pre-filled.
- **Reports money card:** one card, Spent first and largest, Income and Net in equal columns below, each with its change from the previous month.
- **Sign in with a username:** sign-in takes an email or a username; a username is set in Personal details (unique, 3 to 20 lowercase letters, numbers, dots, underscores) through the `set_username` database function, so a clash is caught at once and never blocks sync (the profile push leaves `username` out; pulls bring it down). Username sign-in goes through the `sign-in-with-username` Edge Function, which looks the account up with the service role and returns only a refresh token (`auth.setSession`), so emails are never exposed and a wrong username fails like a wrong password. Note: Supabase's per-IP sign-in rate limit sees the function's address, not the user's.
- **Month picker:** tap the month on Reports for a sheet with a year switcher and a grid of months, each showing what was spent; reaches back to the first month with data (no longer only 6). The trend chart's 6 months end at the selected month when it is older.

## Session 12: 28 Nov 2026 (late night, continued)

### Done

- **Greeting:** Home says Good morning (5:00 to noon), Good afternoon (to 17:00) or Good evening, with the user's preferred name, or their first name when none is set. "What should we call you?" in Personal details (`preferred_name` on the profile, Drift schema 7, Supabase migration 7, synced).
- **Activity:** a Spent this week card (total, change against the previous 7 days, seven tappable day columns with today picked, money in as a small line) replaces the Money in / Money out tiles; day headings show what was spent (what was received only on days without spending); rows under a day heading show the time, not the date again (also in History and Search).
- **Quality:** `flutter analyze` clean; 299 tests pass; Activity rendered in light and dark.

## Session 11: 28 Nov 2026 (late night)

### Done

- **Home redesigned around spending:** a navy hero with what was spent this pay cycle, the change against the same point last cycle, daily bars (today in coral) and safe to spend with days to payday (tap to change payday); then Where it went (top 4 categories, share of spending, budget status marks), the habit tip, Recent activity, and Wallets last. `CycleSpending.compute` (`domain/models/cycle_spending.dart`).
- **Removed** the net balance card, the separate safe-to-spend card, the navy budget alert (now a status line in Where it went) and the quick actions (the + button covers adding; Receipt and Grocery were placeholders).
- **Also:** `flutter_local_notifications` pinned to 22.x (23 needs compileSdk 37).
- **Quality:** `flutter analyze` clean; 296 tests pass; Home rendered in light and dark.

## Session 10: 28 Nov 2026 (night)

### Done

- **Notifications page** (`/notifications`, from the Home bell): budgets near or over their limit this pay cycle, regular payments due soon or late, and payments to review, grouped New and Earlier; each opens Budgets, Regular payments or Payment messages. Worked out from the data (`SpendingNotifications.compute`, `domain/models/app_notification.dart`); only `notifications_seen_at` is stored. The bell's dot shows only when something is new.
- **Notification settings** (`/notification-settings`, from Profile and the page's header): daily reminder with a time (default 20:00), bill reminders, budget alerts. Profile columns (Drift schema 6, Supabase migration 6), synced.
- **Phone reminders** (`flutter_local_notifications` 23.0.4, `timezone` 0.11.2): `ReminderRepositoryLocal` reschedules on any settings or transaction change: the daily reminder for the next 7 days, skipping today once something was recorded; bills at 18:00 the day before they are due. Tapping one opens Add or Regular payments. Inexact alarms, so no exact-alarm permission. Turning a reminder on asks for notification permission.
- **Android:** core library desugaring, `RECEIVE_BOOT_COMPLETED` with the plugin's receivers, a white wallet `ic_stat_wallet` icon (kept in release by `res/raw/keep.xml`).
- **Quality:** `flutter analyze` clean; 293 tests pass; both pages rendered in light and dark.

## Session 9: 28 Nov 2026 (evening)

### Done

- **App lock** (`local_auth` 3.0.2, approved): Preferences → Privacy → Lock with fingerprint or PIN. Turning it on asks to confirm first. The app locks on a cold start and on coming back after a minute or more away (the gallery or share sheet don't count; neither does the prompt itself). The lock screen covers the app at once, prompts by itself and fades away on unlock. A phone without a screen lock is never shut out. Stored on the profile (`app_lock`, Drift schema 5, Supabase migration 5) and synced. `AppLockRepository` (device + fake), `DeviceAuthService`, `AppLockGate` in `MaterialApp.builder`.
- **Android:** `MainActivity` is a `FlutterFragmentActivity`; `USE_BIOMETRIC` permission; pre-Android 12 launch themes use AppCompat (with `androidx.appcompat` added) so the prompt doesn't crash on Android 8 and below. Re-running `flutter_native_splash` may reset those themes; check them afterwards.
- **Investigated the missing transaction** (open issue 1): narrowed down, not solved.
- **Quality:** `flutter analyze` clean; 274 tests pass; lock screen rendered in light and dark.

## Session 8: 28 Nov 2026

### Done

- **Profile photo** (Personal details, gallery only, `image_picker`): shrunk to 512px, kept in the device database so it shows offline, uploaded to the private `avatars` bucket and downloaded on other devices.
- **Spend again** (Add again for income) on transaction details: the form opens filled in, dated now.
- **Hide in recent apps** (Preferences, Privacy): Android's secure-window flag through a method channel in `MainActivity`. Off by default, applied on start.
- **Demo data fix:** the fake "today" transactions stay on today just after midnight (a test failed between 00:00 and 03:00).
- **Quality:** `flutter analyze` clean; 261 tests pass; new screens rendered and reviewed.

## Session 7: 27 Nov 2026 (into the night)

### Done

- **Running on the phone with Supabase:** project ambfmaujbnraqiujckoh, migration applied and verified. Build fixes: plugins use NDK 30, Kotlin compiles in-process without incremental caches. The project URL and publishable key are built in (`SupabaseConfig`), so F5 connects; no demo sign-in in the app.
- **Email confirmation by code:** Confirm your email screen (`/verify-email`) with resend. Supabase still sends its default link email until custom SMTP is set up (templates are locked without it); the link confirms anyway.
- **Sync loop fixed:** pulls no longer rewrite an unchanged profile (it re-triggered sync every 2 s).
- **Preferences page** (`/preferences`, from Profile): theme, payday, budget warning level, default wallet, show habits on Home, hide amounts on Home (now remembered). New profile columns in Drift (schema 2) and Supabase (`20261128000000_preferences.sql`, applied).

- **Database for everything (offline-first):** a Drift database on the phone (`lib/data/services/database/app_database.dart`) holds transactions, categories, budgets and their order, wallets, transfers, settings (theme, payday), the profile, payments read from notifications and account links. Drift repositories replace the fakes in the app. Writes are marked dirty with a `modifiedAt`; deletes become marks so they sync.
- **Supabase:** migration `supabase/migrations/20261127000000_init.sql` (tables, RLS, `sync_guard` trigger keeping the later edit, new-user seeding of profile, default categories and Cash). `SyncRepositoryDrift` pushes dirty rows and pulls rows stored since the last pull (cursor per table), later edit wins on both sides, retries after failures, runs after changes, every 5 minutes and on resume. Tested with a fake server and two simulated devices.
- **Auth:** `AuthRepositorySupabase` (email and password, email confirmation, password reset email). The device database belongs to the signed-in account; data from before the first sign-in moves to it; sign-out sends unsaved changes and is refused while offline with unsent changes. Form validation restored. Without `--dart-define-from-file=supabase.json` the app shows a setup screen; there is no demo sign-in (the fake auth is for tests only).

- **Category trends:** tapping a category in Reports' Spending by category opens its page (`/category?name=…&month=yyyy-mm`). `CategoryTrends.compute` (domain) gives the last 6 months, what was spent in the selected month against a usual month (the average of earlier months with spending in the category, cut at today's date while the month is still running), where the money went (places grouped by name, how often, average each) and the payments. The page has a navy summary card with the comparison in words, the 6-month column chart (tap a month), Where it went and Payments (tap for details and delete).
- **Provider APIs deferred:** direct MoMo and bank connections wait until the institutions grant API access. The seam is ready: `ProviderApiService` (one per institution, maps records to `MoneyMessage`) and `AccountLinkRepositoryApi` (links a wallet, syncs into payments to review). No institutions wired in, no UI.
- **Backend:** the app is standalone with its own backend (no Django web app). The backend is Supabase; `CLAUDE.md` updated.
- **Edit transactions:** the details sheet has Edit transaction, opening the form (`/add` with the `Transaction` as `extra`) filled with the saved values. Saving calls `TransactionRepository.updateTransaction`, keeping the id, and the original time when the day is unchanged. A category that no longer exists is kept selectable.
- **Quality:** `flutter analyze` clean; 209 tests pass; light and dark renders reviewed.

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
