-- What the user likes to be called, used in the Home greeting.

alter table public.profiles
  add column preferred_name text;
