# Supabase setup

The app saves everything on the phone first (Drift), so it works offline, and syncs it to Supabase when there is a connection. Each user only ever sees their own rows (row-level security).

## 1. Create the project

1. Sign in at [supabase.com](https://supabase.com) and create a new project. Pick the region closest to your users and save the database password somewhere safe.
2. Wait for the project to finish setting up.

## 2. Create the tables

1. Open **SQL Editor → New query**.
2. Paste the whole of `migrations/20261127000000_init.sql` and click **Run**.

This creates the tables (profiles, categories, wallets, transfers, transactions, budgets, detected payments, account links), turns on row-level security, and gives every new account a profile, the default categories and a Cash wallet.

## 3. Email sign-in

In **Authentication → Sign In / Providers → Email**:

- Keep **Email** enabled.
- **Confirm email** is on by default: new users get a link and must open it before signing in. The app tells them so. For quick testing you can switch it off, but turn it back on before real users sign up.
- Supabase's built-in email sender is rate-limited and meant for testing. Before launch, add your own SMTP provider under **Authentication → Emails → SMTP settings**.

## 4. Connect the app

1. Open **Project Settings → API Keys** and copy the **publishable key** (`sb_publishable_…`). A legacy *anon* key also works. Copy the **Project URL** from **Project Settings → Data API**.
2. Copy `supabase.example.json` (in the project root) to `supabase.json` and fill in both values. `supabase.json` is gitignored.
3. The app's own project is built in (`lib/data/services/supabase/supabase_config.dart`), so `flutter run` or F5 connects to it. `supabase.json` is only needed to point a build at a different project:

   ```sh
   flutter run -d <device> --dart-define-from-file=supabase.json
   ```

Never put the **secret** or **service_role** key in the app or in `supabase.json`. It bypasses row-level security.

There is no demo sign-in: every sign-in goes through Supabase.

## 5. Sign in with a username

Users can set a username in Personal details and sign in with it instead
of their email. Two pieces make this work:

1. Run `migrations/20261129020000_usernames.sql` in the SQL Editor (the
   `username` column, its unique index, and the `set_username` and
   `username_available` functions).
2. Deploy the Edge Function in `functions/sign-in-with-username/index.ts`:
   Dashboard → Edge Functions → Deploy a new function → Via Editor, name it
   `sign-in-with-username`, paste the file, and deploy. Then open its
   settings and turn **Verify JWT** off (people aren't signed in yet when
   they call it). With the Supabase CLI instead:
   `supabase functions deploy sign-in-with-username --no-verify-jwt`.

The function looks the account up with the service role and returns only
a refresh token, so the email behind a username never reaches the device,
and a wrong username fails like a wrong password.

## How sync works

- Every row has `modified_at` (when the user changed it, set by the app) and `updated_at` (when the server stored it, set by a trigger).
- The app sends rows it has changed, then fetches rows the server stored since its last fetch.
- When the same row was changed on two devices, the later `modified_at` wins, on the server (`sync_guard` trigger) and on the phone.
- Deleting marks a row `deleted` instead of removing it, so the deletion reaches every device.
- Sync runs after changes (a couple of seconds later), every 5 minutes, when the app comes back to the foreground, and retries a minute after a failure.
- Signing out first sends anything unsaved. If that fails (no connection), sign-out is refused so nothing is lost.
