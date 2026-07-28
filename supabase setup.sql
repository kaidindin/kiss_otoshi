-- ============================================
-- KISS落とし ランキング用 Supabase セットアップ
-- Supabase → SQL Editor に貼り付けて実行してください
-- ============================================

-- 1) テーブル
create table if not exists public.ko_scores (
  id         bigint generated always as identity primary key,
  name       text not null,
  score      integer not null,
  created_at timestamptz not null default now()
);

create index if not exists ko_scores_score_idx on public.ko_scores (score desc);

-- 2) RLS を有効化（直接アクセスは全面禁止／RPC経由のみ）
alter table public.ko_scores enable row level security;
-- ポリシーは作らない = anon から直接 select/insert は不可

-- 3) スコア登録 RPC（security definer）
create or replace function public.ko_submit(p_name text, p_score integer)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_score is null or p_score < 0 or p_score > 100000 then
    raise exception 'invalid score';
  end if;
  insert into public.ko_scores (name, score)
  values (coalesce(nullif(trim(p_name), ''), 'ななし')::text, p_score);
end;
$$;

-- 4) TOP10 取得 RPC（security definer）
create or replace function public.ko_top()
returns table (name text, score integer)
language sql
security definer
set search_path = public
as $$
  select name, score
  from public.ko_scores
  order by score desc, created_at asc
  limit 10;
$$;

-- 5) anon ロールに RPC 実行権限を付与
grant execute on function public.ko_submit(text, integer) to anon;
grant execute on function public.ko_top() to anon;
