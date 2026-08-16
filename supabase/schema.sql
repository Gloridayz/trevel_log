-- 새로 시작하는 경우 이 파일 전체를 Supabase SQL Editor에서 실행하세요.
--
-- 이미 예전 버전(각 테이블에 자유 텍스트 category 컬럼이 있는 버전)을 쓰고 있었다면
-- 이 파일 대신 supabase/migrate_002_trip_categories.sql 을 실행하세요.
-- (기존 데이터를 지우지 않고 새 구조로 안전하게 옮겨줍니다.)

create table if not exists trip_categories (
  id text primary key,
  name text not null unique,
  sort_order integer not null default 0,
  default_currency text not null default 'KRW',
  created_at timestamptz default now()
);

create table if not exists entries (
  id text primary key,
  trip_category_id text references trip_categories(id),
  title text not null,
  map_link text,
  food text,
  note text,
  photos jsonb default '[]',
  created_at timestamptz default now()
);

create table if not exists wishlist (
  id text primary key,
  trip_category_id text references trip_categories(id),
  title text not null,
  map_link text,
  photo text,
  note text,
  created_at timestamptz default now()
);

create table if not exists expense_items (
  id text primary key,
  trip_category_id text references trip_categories(id),
  name text not null,
  description text,
  created_at timestamptz default now()
);

create table if not exists expenses (
  id text primary key,
  trip_category_id text references trip_categories(id),
  date date,
  item text references expense_items(id),
  note text,
  currency text not null default 'KRW',
  amount numeric not null,
  rate numeric not null default 1,
  krw_amount numeric not null,
  created_at timestamptz default now()
);

create table if not exists checklist_items (
  id text primary key,
  trip_category_id text references trip_categories(id),
  owner text not null default '공동',
  text text not null,
  checked boolean not null default false,
  created_at timestamptz default now()
);

alter table trip_categories enable row level security;
alter table entries enable row level security;
alter table wishlist enable row level security;
alter table expense_items enable row level security;
alter table expenses enable row level security;
alter table checklist_items enable row level security;

drop policy if exists "public all" on trip_categories;
drop policy if exists "public all" on entries;
drop policy if exists "public all" on wishlist;
drop policy if exists "public all" on expense_items;
drop policy if exists "public all" on expenses;
drop policy if exists "public all" on checklist_items;

create policy "public all" on trip_categories for all using (true) with check (true);
create policy "public all" on entries for all using (true) with check (true);
create policy "public all" on wishlist for all using (true) with check (true);
create policy "public all" on expense_items for all using (true) with check (true);
create policy "public all" on expenses for all using (true) with check (true);
create policy "public all" on checklist_items for all using (true) with check (true);

-- Storage: 'photos' 버킷을 미리 만들고(Public), 아래 정책을 적용하세요.
drop policy if exists "public upload" on storage.objects;
drop policy if exists "public read" on storage.objects;
drop policy if exists "public delete" on storage.objects;

create policy "public upload" on storage.objects for insert to anon with check (bucket_id = 'photos');
create policy "public read" on storage.objects for select to anon using (bucket_id = 'photos');
create policy "public delete" on storage.objects for delete to anon using (bucket_id = 'photos');
