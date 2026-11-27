-- Privacy screen preference: hide the app's content in recent apps and
-- block screenshots (Android).

alter table public.profiles
  add column privacy_screen boolean not null default false;
