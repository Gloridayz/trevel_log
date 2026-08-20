-- 위시리스트 "다녀옴" 기능을 위해 converted 컬럼을 추가합니다.
-- 체크하면 해당 항목이 entries로 복사되고, 원본 wishlist row는 converted=true로
-- 표시되어 목록에서 걸러집니다 (데이터 보존을 위해 삭제하지 않습니다).
-- 이미 실행했어도 다시 실행해도 안전합니다.

alter table wishlist add column if not exists converted boolean not null default false;
