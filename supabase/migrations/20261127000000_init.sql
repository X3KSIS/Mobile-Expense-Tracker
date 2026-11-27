-- Expense Tracker: initial schema.
--
-- Run once in the Supabase dashboard (SQL Editor → New query → paste →
-- Run), or with the Supabase CLI: `supabase db push`.
--
-- Every table belongs to one user (user_id) and is protected by row-level
-- security, so a signed-in user can only ever read or change their own
-- rows.
--
-- Sync columns, on every table:
--   id           text chosen by the app (UUIDs, or fixed ids such as
--                'c-groceries' for default categories), unique per user.
--   modified_at  when the user made the change, set by the app. When two
--                devices edit the same row, the later edit wins.
--   updated_at   when the server stored the change, set here. Apps pull
--                rows whose updated_at is after their last pull.
--   deleted      rows are never removed, only marked, so the deletion
--                reaches every device.

-- ---------------------------------------------------------------------
-- Sync helpers
-- ---------------------------------------------------------------------

-- Keeps the newer edit and stamps the server time.
create or replace function public.sync_guard()
returns trigger
language plpgsql
as $$
begin
  if tg_op = 'UPDATE' and new.modified_at < old.modified_at then
    -- An older edit arrived late: keep what is stored.
    return null;
  end if;
  -- clock_timestamp(), not now(): rows stored together still get
  -- distinct times, so paging by updated_at never skips one.
  new.updated_at := clock_timestamp();
  return new;
end;
$$;

-- ---------------------------------------------------------------------
-- Profiles and settings (one row per user)
-- ---------------------------------------------------------------------

create table public.profiles (
  user_id     uuid primary key references auth.users (id) on delete cascade,
  name        text not null default '',
  phone       text,
  payday      smallint not null default 1 check (payday between 1 and 28),
  theme       text not null default 'system'
                check (theme in ('system', 'light', 'dark')),
  created_at  timestamptz not null default now(),
  modified_at timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- Categories
-- ---------------------------------------------------------------------

create table public.categories (
  user_id     uuid not null default auth.uid()
                references auth.users (id) on delete cascade,
  id          text not null,
  name        text not null check (length(trim(name)) > 0),
  icon        text not null,
  color       bigint not null,
  type        text not null check (type in ('expense', 'income')),
  sort_order  integer not null default 0,
  modified_at timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  deleted     boolean not null default false,
  primary key (user_id, id)
);

-- ---------------------------------------------------------------------
-- Wallets and transfers
-- ---------------------------------------------------------------------

create table public.wallets (
  user_id         uuid not null default auth.uid()
                    references auth.users (id) on delete cascade,
  id              text not null,
  name            text not null check (length(trim(name)) > 0),
  kind            text not null check (kind in ('cash', 'mobileMoney', 'bank')),
  opening_balance numeric(14, 2) not null default 0,
  sort_order      integer not null default 0,
  modified_at     timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  deleted         boolean not null default false,
  primary key (user_id, id)
);

create table public.transfers (
  user_id        uuid not null default auth.uid()
                   references auth.users (id) on delete cascade,
  id             text not null,
  from_wallet_id text not null,
  to_wallet_id   text not null,
  amount         numeric(14, 2) not null check (amount > 0),
  date           timestamptz not null,
  note           text,
  modified_at    timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  deleted        boolean not null default false,
  primary key (user_id, id),
  check (from_wallet_id <> to_wallet_id)
);

-- ---------------------------------------------------------------------
-- Transactions
-- ---------------------------------------------------------------------

-- The category's name, icon and colour are copied onto the transaction,
-- so renaming or removing a category never rewrites past spending.
create table public.transactions (
  user_id        uuid not null default auth.uid()
                   references auth.users (id) on delete cascade,
  id             text not null,
  title          text not null,
  category_name  text not null,
  category_icon  text not null,
  category_color bigint not null,
  amount         numeric(14, 2) not null check (amount > 0),
  type           text not null check (type in ('expense', 'income')),
  date           timestamptz not null,
  note           text,
  wallet_id      text not null,
  modified_at    timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  deleted        boolean not null default false,
  primary key (user_id, id)
);

create index transactions_user_date on public.transactions (user_id, date desc);

-- ---------------------------------------------------------------------
-- Budgets
-- ---------------------------------------------------------------------

create table public.budgets (
  user_id        uuid not null default auth.uid()
                   references auth.users (id) on delete cascade,
  id             text not null,
  category_name  text not null,
  category_icon  text not null,
  category_color bigint not null,
  limit_amount   numeric(14, 2) not null check (limit_amount > 0),
  sort_order     integer not null default 0,
  modified_at    timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  deleted        boolean not null default false,
  primary key (user_id, id)
);

-- ---------------------------------------------------------------------
-- Payments read from notifications, and institution API links
-- ---------------------------------------------------------------------

create table public.detected_payments (
  user_id     uuid not null default auth.uid()
                references auth.users (id) on delete cascade,
  id          text not null,
  message     jsonb not null,
  received_at timestamptz not null,
  sender      text,
  status      text not null default 'pending'
                check (status in ('pending', 'added', 'dismissed')),
  modified_at timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  deleted     boolean not null default false,
  primary key (user_id, id)
);

create table public.account_links (
  user_id        uuid not null default auth.uid()
                   references auth.users (id) on delete cascade,
  id             text not null, -- the wallet id
  provider_name  text not null,
  account_ref    text not null,
  last_synced_at timestamptz,
  modified_at    timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  deleted        boolean not null default false,
  primary key (user_id, id)
);

-- ---------------------------------------------------------------------
-- Triggers, indexes and row-level security for every synced table
-- ---------------------------------------------------------------------

do $$
declare
  t text;
begin
  foreach t in array array[
    'profiles', 'categories', 'wallets', 'transfers', 'transactions',
    'budgets', 'detected_payments', 'account_links'
  ] loop
    execute format(
      'create trigger %1$s_sync_guard before insert or update on public.%1$s
         for each row execute function public.sync_guard()', t);
    execute format(
      'create index %1$s_user_updated on public.%1$s (user_id, updated_at)', t);
    execute format('alter table public.%1$s enable row level security', t);
    execute format(
      'grant select, insert, update on public.%1$s to authenticated', t);
    execute format(
      'create policy "Own rows: read" on public.%1$s
         for select to authenticated using ((select auth.uid()) = user_id)', t);
    execute format(
      'create policy "Own rows: insert" on public.%1$s
         for insert to authenticated with check ((select auth.uid()) = user_id)', t);
    execute format(
      'create policy "Own rows: update" on public.%1$s
         for update to authenticated
         using ((select auth.uid()) = user_id)
         with check ((select auth.uid()) = user_id)', t);
  end loop;
end;
$$;

-- No delete policies: the app marks rows deleted instead, and deleting
-- the account (auth.users) removes everything through the cascades.

-- ---------------------------------------------------------------------
-- New users: a profile, the default categories and a Cash wallet
-- ---------------------------------------------------------------------

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (user_id, name, phone)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'name', ''),
    nullif(new.raw_user_meta_data ->> 'phone', '')
  );

  insert into public.categories (user_id, id, name, icon, color, type, sort_order)
  values
    (new.id, 'c-groceries',     'Groceries',      'groceries',     4293154606, 'expense', 0),
    (new.id, 'c-transport',     'Transport',      'fuel',          4281298907, 'expense', 1),
    (new.id, 'c-utilities',     'Utilities',      'electricity',   4290214175, 'expense', 2),
    (new.id, 'c-airtime',       'Airtime',        'airtime',       4286205145, 'expense', 3),
    (new.id, 'c-housing',       'Housing',        'housing',       4279970360, 'expense', 4),
    (new.id, 'c-eating-out',    'Eating out',     'eating_out',    4292429434, 'expense', 5),
    (new.id, 'c-health',        'Health',         'health',        4280257162, 'expense', 6),
    (new.id, 'c-education',     'Education',      'education',     4283064257, 'expense', 7),
    (new.id, 'c-entertainment', 'Entertainment',  'entertainment', 4290795135, 'expense', 8),
    (new.id, 'c-fees',          'Fees & charges', 'fees',          4287262011, 'expense', 9),
    (new.id, 'c-other-expense', 'Other',          'other',         4285231744, 'expense', 10),
    (new.id, 'c-salary',        'Salary',         'salary',        4279728715, 'income',  11),
    (new.id, 'c-business',      'Business',       'business',      4281240407, 'income',  12),
    (new.id, 'c-gifts',         'Gifts',          'gift',          4287519702, 'income',  13),
    (new.id, 'c-other-income',  'Other income',   'other',         4285231744, 'income',  14);

  insert into public.wallets (user_id, id, name, kind, sort_order)
  values (new.id, 'w-cash', 'Cash', 'cash', 0);

  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
