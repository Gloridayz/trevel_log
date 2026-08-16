-- trip_categories에 여행별 기본 통화(default_currency) 컬럼을 추가합니다.
-- 이미 실행했어도 다시 실행해도 안전합니다 (컬럼이 이미 있으면 아무 것도 하지 않음).
--
-- 주의: supabase/migrate_002_trip_categories.sql을 먼저 실행해 trip_categories
-- 테이블이 만들어져 있어야 합니다. (schema.sql로 처음부터 새로 만든 경우는
-- 이미 이 컬럼이 포함되어 있으니 이 파일을 실행할 필요가 없습니다.)

alter table trip_categories add column if not exists default_currency text not null default 'KRW';
