-- Bills: payments the user set up to be reminded about (rent, DStv,
-- school fees), and the time of day bill reminders come.

create table public.bills (
  user_id        uuid not null default auth.uid()
                   references auth.users (id) on delete cascade,
  id             text not null,
  name           text not null check (length(trim(name)) > 0),
  amount         numeric(14, 2) not null check (amount > 0),
  category_name  text not null,
  category_icon  text not null,
  category_color bigint not null,
  wallet_id      text not null,
  cadence        text not null check (cadence in ('weekly', 'monthly', 'yearly')),
  next_due       timestamptz not null,
  anchor_day     smallint not null check (anchor_day between 1 and 31),
  modified_at    timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  deleted        boolean not null default false,
  primary key (user_id, id)
);

create trigger bills_sync_guard before insert or update on public.bills
  for each row execute function public.sync_guard();

create index bills_user_updated on public.bills (user_id, updated_at);

alter table public.bills enable row level security;

-- This project grants nothing by default.
grant select, insert, update on public.bills to authenticated;

create policy "Own rows: read" on public.bills
  for select to authenticated using ((select auth.uid()) = user_id);

create policy "Own rows: insert" on public.bills
  for insert to authenticated with check ((select auth.uid()) = user_id);

create policy "Own rows: update" on public.bills
  for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

alter table public.profiles
  add column bill_reminder_minutes integer not null default 480
    check (bill_reminder_minutes between 0 and 1439);
