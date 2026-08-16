-- 준비물 담당자를 자유 텍스트에서 관리형 목록(checklist_owners)으로 전환합니다.
-- 이 파일 전체를 Supabase SQL Editor에서 한 번 실행하세요.
-- 이미 적용된 상태라면(= checklist_items.owner가 이미 checklist_owners를 참조하면)
-- 자동으로 아무 것도 하지 않고 건너뛰므로, 실수로 다시 실행해도 안전합니다.

do $$
begin
  if not exists (
    select 1 from information_schema.table_constraints
    where table_name = 'checklist_items' and constraint_name = 'checklist_items_owner_fkey'
  ) then

    create table if not exists checklist_owners (
      id text primary key,
      trip_category_id text references trip_categories(id),
      name text not null,
      color text not null default '#5c6f5a',
      created_at timestamptz default now()
    );
    alter table checklist_owners enable row level security;
    if not exists (select 1 from pg_policies where tablename = 'checklist_owners' and policyname = 'public all') then
      create policy "public all" on checklist_owners for all using (true) with check (true);
    end if;

    -- 기존 checklist_items.owner(자유 텍스트) 값들을 담당자 목록으로 이전
    -- (카테고리별로 팔레트 6색을 순서대로 배정)
    insert into checklist_owners (id, trip_category_id, name, color)
    select 'co_' || md5(coalesce(trip_category_id, '') || '|' || owner),
           trip_category_id, owner,
           (array['#a8412d','#a1793a','#5c6f5a','#3a6ea1','#7a4a91','#ba7a2a'])[
             ((row_number() over (partition by trip_category_id order by owner) - 1) % 6) + 1
           ]
    from (select distinct trip_category_id, owner from checklist_items where owner is not null) d
    on conflict (id) do nothing;

    update checklist_items ci
    set owner = co.id
    from checklist_owners co
    where co.name = ci.owner
      and co.trip_category_id is not distinct from ci.trip_category_id;

    alter table checklist_items add constraint checklist_items_owner_fkey foreign key (owner) references checklist_owners(id);

    raise notice '마이그레이션 완료: 준비물 담당자가 관리형 목록(checklist_owners)으로 전환되었습니다.';
  else
    raise notice '이미 마이그레이션이 적용되어 있는 것으로 보입니다. 아무 것도 변경하지 않았습니다.';
  end if;
end $$;
