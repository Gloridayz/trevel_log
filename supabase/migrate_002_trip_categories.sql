-- 정보구조 개편 마이그레이션: 자유 텍스트 category → trip_categories 기반 구조
--
-- 실행 전 권장: Supabase 대시보드 Settings → Database → Backups에서 최근 백업이
-- 있는지 확인하거나, 각 테이블을 CSV로 한 번 내려받아두세요 (만약을 위한 안전장치).
--
-- 이 파일 전체를 Supabase SQL Editor에서 한 번 실행하세요.
-- 이미 마이그레이션이 적용된 상태라면(= entries에 category 컬럼이 없으면)
-- 자동으로 아무 것도 하지 않고 건너뛰므로, 실수로 다시 실행해도 안전합니다.

do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_name = 'entries' and column_name = 'category'
  ) then

    -- 1. trip_categories 테이블 생성
    create table if not exists trip_categories (
      id text primary key,
      name text not null unique,
      sort_order integer not null default 0,
      created_at timestamptz default now()
    );
    alter table trip_categories enable row level security;
    if not exists (select 1 from pg_policies where tablename = 'trip_categories' and policyname = 'public all') then
      create policy "public all" on trip_categories for all using (true) with check (true);
    end if;

    -- 2. 기존 4개 테이블에 흩어져 있던 category 값들을 trip_categories로 이전
    insert into trip_categories (id, name)
    select 'tc_' || md5(cat), cat from (
      select distinct category as cat from entries
      union select distinct category as cat from wishlist
      union select distinct category as cat from expenses
      union select distinct category as cat from checklist_items
    ) c
    where cat is not null
    on conflict (name) do nothing;

    -- 3. trip_category_id 컬럼 추가 후, 기존 category 값 기준으로 채우기
    alter table entries add column if not exists trip_category_id text references trip_categories(id);
    alter table wishlist add column if not exists trip_category_id text references trip_categories(id);
    alter table expenses add column if not exists trip_category_id text references trip_categories(id);
    alter table checklist_items add column if not exists trip_category_id text references trip_categories(id);

    update entries e set trip_category_id = tc.id from trip_categories tc where tc.name = e.category;
    update wishlist w set trip_category_id = tc.id from trip_categories tc where tc.name = w.category;
    update expenses x set trip_category_id = tc.id from trip_categories tc where tc.name = x.category;
    update checklist_items c set trip_category_id = tc.id from trip_categories tc where tc.name = c.category;

    -- 4. 경비: item(자유 텍스트) → expense_items 참조로 전환 + date/note 컬럼 추가
    create table if not exists expense_items (
      id text primary key,
      trip_category_id text references trip_categories(id),
      name text not null,
      description text,
      created_at timestamptz default now()
    );
    alter table expense_items enable row level security;
    if not exists (select 1 from pg_policies where tablename = 'expense_items' and policyname = 'public all') then
      create policy "public all" on expense_items for all using (true) with check (true);
    end if;

    alter table expenses add column if not exists date date;
    alter table expenses add column if not exists note text;

    insert into expense_items (id, trip_category_id, name)
    select 'ei_' || md5(coalesce(trip_category_id, '') || '|' || item), trip_category_id, item
    from (select distinct trip_category_id, item from expenses where item is not null) d
    on conflict (id) do nothing;

    update expenses x
    set item = ei.id
    from expense_items ei
    where ei.name = x.item
      and ei.trip_category_id is not distinct from x.trip_category_id;

    -- 5. 옛 category(자유 텍스트) 컬럼 제거
    alter table entries drop column category;
    alter table wishlist drop column category;
    alter table expenses drop column category;
    alter table checklist_items drop column category;

    -- 6. expenses.item을 expense_items 참조로 확정
    alter table expenses add constraint expenses_item_fkey foreign key (item) references expense_items(id);

    raise notice '마이그레이션 완료: trip_categories 기반 구조로 전환되었습니다.';
  else
    raise notice '이미 마이그레이션이 적용되어 있는 것으로 보입니다. 아무 것도 변경하지 않았습니다.';
  end if;
end $$;
