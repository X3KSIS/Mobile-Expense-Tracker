-- App lock preference: opening the app asks for the fingerprint, face or
-- the phone's screen lock.

alter table public.profiles
  add column app_lock boolean not null default false;
