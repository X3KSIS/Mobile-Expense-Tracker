# ExpenseTrack (Flutter)

Personal finance app for tracking income and expenses in Zambian Kwacha (ZMW). Mobile companion to an existing Django web app.

Features, now and planned: dashboard, transactions (recurring, receipts, tags), categories with colours, budgets, reports and charts, spending heatmap, grocery lists, price tracker, reminders.

Later phases will add Firebase Auth, offline-first storage with Drift (SQLite), and sync to a Django REST API. Until then, all data comes from fake repositories.

## Working rules

- Always write complete files. No partial snippets or "rest unchanged" comments.
- Keep `flutter analyze` at zero issues. Run it after every change.
- Don't add packages beyond the list below without asking first.
- Keep widgets small. If a build method grows past ~80 lines, extract a widget.
- Never hard-code colours, radii or text styles inside screens. Use the theme and tokens.
- Currency is always formatted as `ZMW 1,234.00` via a shared formatter in `lib/utils/`.

## Architecture (Flutter recommended, MVVM)

Follows https://docs.flutter.dev/app-architecture.

- **UI layer:** a View (widget) and a ViewModel (`ChangeNotifier`) for each feature.
  - Views hold no business logic. They read state from the ViewModel and call its commands.
  - ViewModels depend only on repositories, never on services directly.
  - Async actions use a `Command` class (running, error and completed state) from `lib/utils/command.dart`.
- **Data layer:**
  - Repositories are the single source of truth. Each is an abstract class plus implementations: `*_local_fake.dart` now, real ones later.
  - Services wrap external sources (API client, local DB, Firebase). They are stateless and used only by repositories.
- **Domain models:** immutable plain Dart classes in `lib/domain/models/`, shared by both layers.
- **Dependency injection:** `provider`, configured in `lib/config/dependencies.dart`. Repositories are provided at app level, and ViewModels are created in the route builders.
- **Navigation:** `go_router` in `lib/routing/`. Route paths live as constants in `routes.dart`. The main tabs use a `StatefulShellRoute`.
- **Errors:** repositories return `Result<T>` (`Ok`/`Error`) from `lib/utils/result.dart` instead of throwing.

### Folder structure

```
lib/
  main.dart
  config/
    dependencies.dart
  routing/
    router.dart
    routes.dart
  domain/
    models/
  data/
    repositories/
      <name>/
        <name>_repository.dart          # abstract
        <name>_repository_local_fake.dart
    services/
  ui/
    core/
      themes/       colors.dart, dimens.dart, theme.dart
      ui/           shared widgets (app_shell.dart, cards, buttons)
    splash/
      view_models/
      widgets/
    home/
      view_models/
      widgets/
    <feature>/...
  utils/
    command.dart
    result.dart
    currency.dart
test/
  (mirrors lib/; fakes live in test/testing/)
```

## Packages

`provider`, `go_router`, `intl`, `flutter_native_splash` (dev), `flutter_lints` (dev).

Added in later phases: `drift`, `firebase_auth`, `dio`, `fl_chart`, `connectivity_plus`, `flutter_local_notifications`.

## Design system: coral and navy

The font is **Plus Jakarta Sans**, bundled in `assets/fonts/` with weights 400, 500, 600, 700 and 800.

### Colours

| Token | Hex | Use |
|---|---|---|
| background | #F7F7F8 | scaffold |
| surface | #FFFFFF | cards |
| border | #EEEEF1 | card and button borders (1px) |
| surfaceMuted | #F1F1F3 | stat tiles, active nav pill, track backgrounds |
| navy | #1B2A38 | feature cards, selected chips, segmented controls |
| textPrimary | #1B2433 | main text |
| textSecondary | #6B7280 | labels, captions |
| textOnNavyMuted | #B8C2CC | secondary text on navy |
| accent | #FF6B4A | highlights, big numbers on navy, progress, decorative |
| accentStrong | #D2401F | primary buttons (white text passes contrast) |
| accentText | #C2391A | coral text or links on light backgrounds |
| accentSoft | #FFE6DF | soft coral backgrounds, badges |
| success | #177A4B | income amounts |
| successSoft | #E4F4EB | success badges |
| fab | #141A22 | black "+" button |

The coral accent (#FF6B4A) is never used for small text or as the background behind white text, because it fails contrast. Use accentStrong or accentText instead.

### Shape and spacing

- **Radii:** big cards 26, list containers 22–24, buttons and inputs 14–18, icon tiles 14, primary full-width button and nav bar fully rounded.
- **Spacing:** screen horizontal padding 22, gap between sections 14–20.
- **Shadows:** soft only, e.g. `0 8 24 rgba(27,36,51,.08)`.

### Gradients

Defined in `lib/ui/core/themes/gradients.dart` (`AppGradients`).

1. **Hues:** stay within 60° of the colour wheel. Use neighbouring hues only, for smooth, professional gradients.
2. **Direction:** 135° (top-left to bottom-right).
3. **Mesh gradients:** use multiple colour points (`MeshGradientBox`) for organic, natural blends on large surfaces like the navy cards.
4. **Text gradients:** headlines only (`GradientText` in screen titles). All other text stays solid.

Text on a gradient must meet the contrast rules on every stop. Chart data marks stay solid.

### Typography

| Style | Size / weight |
|---|---|
| Screen title | 24 / 800, letter-spacing -0.02em |
| Section title | 17 / 700 |
| Body | 15 / 600 for list titles, 14 / 500 for body |
| Caption | 12 / 500, textSecondary |
| Overline | 11 / 600, letter-spacing 0.12em, uppercase |
| Big amounts | 34–38 / 800 |

Big amounts show the "ZMW" prefix smaller and grey, and the decimals smaller and lighter.

### Components

- **Bottom nav:** a floating white pill (height 64) next to a 64px black circular "+" button. The active tab shows icon plus label on #F1F1F3, the others show icon only.
- **Header icon buttons:** 46px rounded squares (radius 16), white with a 1px border.
- **Primary action:** a full-width fully rounded button (height 58), accentStrong, with a soft coral shadow.
- **Icons:** outline style, stroke ~1.8. Use Material Symbols Rounded or custom outline icons. Never emoji.

### Accessibility

- Touch targets are at least 44px.
- Icon-only buttons get a `Semantics` or tooltip label.
- Text contrast is at least 4.5:1.
