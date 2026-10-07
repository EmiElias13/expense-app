-- Run this in the Supabase SQL editor.

create table if not exists public.expenses (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  amount numeric(12,2) not null check (amount >= 0),
  category text not null,
  is_expense boolean not null default true,
  created_at timestamptz not null default now()
);

alter table public.expenses enable row level security;

-- Demo-only policies: anyone with the anon key can read, insert and delete.
-- Replace with auth-based policies before shipping.
create policy "anon read" on public.expenses for select using (true);
create policy "anon insert" on public.expenses for insert with check (true);
create policy "anon delete" on public.expenses for delete using (true);
