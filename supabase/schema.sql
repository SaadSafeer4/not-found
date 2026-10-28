-- Not Found: database schema.
-- Paste this whole file into the Supabase SQL editor and run it once.

create table public.pages (
  slug       text primary key
             check (char_length(slug) between 1 and 100 and slug = lower(slug) and slug !~ '[\s/]'),
  body       text not null
             check (char_length(body) between 1 and 280),
  created_at timestamptz not null default now()
);

alter table public.pages enable row level security;

create policy "anyone can read pages"
  on public.pages for select to anon using (true);

create policy "anyone can claim a page"
  on public.pages for insert to anon with check (true);
-- No update or delete policies: claims are permanent.
