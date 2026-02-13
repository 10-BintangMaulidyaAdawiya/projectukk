-- Jalankan SQL ini di Supabase SQL Editor.
-- Tujuan: fitur kirim pesan dari admin ke petugas.

create table if not exists public.pesan_admin_petugas (
  id bigserial primary key,
  admin_user_id uuid not null references auth.users(id) on delete cascade,
  petugas_user_id uuid not null references auth.users(id) on delete cascade,
  isi_pesan text not null,
  status_baca boolean not null default false,
  created_at timestamptz not null default now()
);

alter table public.pesan_admin_petugas enable row level security;

-- Admin boleh kirim pesan ke petugas
drop policy if exists "admin_insert_pesan_admin_petugas" on public.pesan_admin_petugas;
create policy "admin_insert_pesan_admin_petugas"
on public.pesan_admin_petugas
for insert
to authenticated
with check (
  exists (
    select 1
    from public.users_profile up
    where up.user_id = auth.uid()
      and up.role = 'admin'
  )
);

-- Admin boleh lihat pesan yang dia kirim
drop policy if exists "admin_select_pesan_admin_petugas" on public.pesan_admin_petugas;
create policy "admin_select_pesan_admin_petugas"
on public.pesan_admin_petugas
for select
to authenticated
using (
  admin_user_id = auth.uid()
  and exists (
    select 1
    from public.users_profile up
    where up.user_id = auth.uid()
      and up.role = 'admin'
  )
);

-- Petugas boleh baca pesan yang ditujukan ke dirinya
drop policy if exists "petugas_select_pesan_admin_petugas" on public.pesan_admin_petugas;
create policy "petugas_select_pesan_admin_petugas"
on public.pesan_admin_petugas
for select
to authenticated
using (
  petugas_user_id = auth.uid()
  and exists (
    select 1
    from public.users_profile up
    where up.user_id = auth.uid()
      and up.role = 'petugas'
  )
);

-- Opsional: petugas bisa menandai status_baca
drop policy if exists "petugas_update_status_baca_pesan_admin_petugas" on public.pesan_admin_petugas;
create policy "petugas_update_status_baca_pesan_admin_petugas"
on public.pesan_admin_petugas
for update
to authenticated
using (
  petugas_user_id = auth.uid()
  and exists (
    select 1
    from public.users_profile up
    where up.user_id = auth.uid()
      and up.role = 'petugas'
  )
)
with check (
  petugas_user_id = auth.uid()
);

create index if not exists idx_pesan_admin_petugas_petugas_created_at
  on public.pesan_admin_petugas (petugas_user_id, created_at desc);

create index if not exists idx_pesan_admin_petugas_admin_created_at
  on public.pesan_admin_petugas (admin_user_id, created_at desc);
