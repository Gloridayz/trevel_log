-- Supabase SQL Editor에서 이 파일 내용 전체를 실행하세요.
-- entries 테이블은 이미 있다면 건너뛰어도 됩니다 (없다면 아래에서 함께 생성됩니다).

create table if not exists entries (
  id text primary key,
  category text not null default '기타',
  title text not null,
  map_link text,
  food text,
  note text,
  photos jsonb default '[]',
  created_at timestamptz default now()
);

create table if not exists wishlist (
  id text primary key,
  category text not null default '기타',
  title text not null,
  map_link text,
  photo text,
  note text,
  created_at timestamptz default now()
);

create table if not exists expenses (
  id text primary key,
  category text not null default '기타',
  item text not null,
  currency text not null default 'KRW',
  amount numeric not null,
  rate numeric not null default 1,
  krw_amount numeric not null,
  created_at timestamptz default now()
);

create table if not exists checklist_items (
  id text primary key,
  category text not null default '기타',
  owner text not null default '공동',
  text text not null,
  checked boolean not null default false,
  created_at timestamptz default now()
);

alter table entries enable row level security;
alter table wishlist enable row level security;
alter table expenses enable row level security;
alter table checklist_items enable row level security;

drop policy if exists "public all" on entries;
drop policy if exists "public all" on wishlist;
drop policy if exists "public all" on expenses;
drop policy if exists "public all" on checklist_items;

create policy "public all" on entries for all using (true) with check (true);
create policy "public all" on wishlist for all using (true) with check (true);
create policy "public all" on expenses for all using (true) with check (true);
create policy "public all" on checklist_items for all using (true) with check (true);

-- Storage: 'photos' 버킷을 미리 만들고(Public), 아래 정책을 적용하세요.
drop policy if exists "public upload" on storage.objects;
drop policy if exists "public read" on storage.objects;
drop policy if exists "public delete" on storage.objects;

create policy "public upload" on storage.objects for insert to anon with check (bucket_id = 'photos');
create policy "public read" on storage.objects for select to anon using (bucket_id = 'photos');
create policy "public delete" on storage.objects for delete to anon using (bucket_id = 'photos');
