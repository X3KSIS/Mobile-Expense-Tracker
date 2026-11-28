-- Notification settings: phone reminders (a daily one to record spending,
-- and one before regular payments are due), budget alerts in the app, and
-- when Notifications was last opened.

alter table public.profiles
  add column daily_reminder boolean not null default false,
  add column reminder_minutes integer not null default 1200
    check (reminder_minutes between 0 and 1439),
  add column bill_reminders boolean not null default false,
  add column budget_alerts boolean not null default true,
  add column notifications_seen_at timestamptz;
