-- Preferences on the profile: budget warning level, default wallet for new
-- expenses, whether Home shows the spending habit card, and whether Home
-- hides amounts.

alter table public.profiles
  add column budget_alert_percent smallint not null default 80
    check (budget_alert_percent in (70, 80, 90)),
  add column default_wallet_id text,
  add column show_habits boolean not null default true,
  add column hide_amounts boolean not null default false;
