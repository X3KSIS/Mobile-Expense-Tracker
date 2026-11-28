-- Usernames: an optional, unique name to sign in with instead of the email.
--
-- The app sets a username through set_username (never through the normal
-- profile sync), so a clash is caught at once instead of blocking sync.
-- Signing in with a username goes through the sign-in-with-username Edge
-- Function, which looks the account up with the service role, so the
-- email behind a username is never exposed.

alter table public.profiles
  add column username text
    check (username ~ '^[a-z0-9_.]{3,20}$');

create unique index profiles_username_key on public.profiles (username);

-- Is this username free (or already the caller's own)? Signed-in users
-- only, and it says nothing about who has it.
create or replace function public.username_available(candidate text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select not exists (
    select 1
    from public.profiles
    where username = lower(trim(candidate))
      and user_id <> (select auth.uid())
  );
$$;

revoke all on function public.username_available(text) from public, anon;
grant execute on function public.username_available(text) to authenticated;

-- Sets the caller's username, or removes it when given null or ''.
-- Returns the stored value. Raises 'username_invalid' or 'username_taken'.
create or replace function public.set_username(new_username text)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  cleaned text := nullif(lower(trim(coalesce(new_username, ''))), '');
begin
  if (select auth.uid()) is null then
    raise exception 'not_signed_in';
  end if;
  if cleaned is not null and cleaned !~ '^[a-z0-9_.]{3,20}$' then
    raise exception 'username_invalid' using errcode = '22023';
  end if;
  update public.profiles
    set username = cleaned
    where user_id = (select auth.uid());
  return cleaned;
exception
  when unique_violation then
    raise exception 'username_taken' using errcode = '23505';
end;
$$;

revoke all on function public.set_username(text) from public, anon;
grant execute on function public.set_username(text) to authenticated;
