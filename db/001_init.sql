-- Constella — skema awal (docs/05-data-models.md)
--
-- Belum dipakai. Aplikasi saat ini menyimpan semuanya di SQLite pada
-- perangkat; berkas ini ada supaya pindah ke Supabase nanti tidak perlu
-- merancang ulang. Bentuk tabelnya sudah sama dengan yang ditulis
-- `SavedConstellation.toRow()` dan `FocusSession.toRow()`.

create table if not exists public.users (
  id uuid primary key references auth.users (id) on delete cascade,
  username text unique not null,
  stardust_energy integer not null default 0 check (stardust_energy >= 0),
  created_at timestamptz not null default now()
);

create table if not exists public.constellations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users (id) on delete cascade,
  name text not null,
  node_coordinates jsonb not null,
  created_at timestamptz not null default now()
);

-- Daftar dibaca terbaru lebih dulu, per halaman keyset.
create index if not exists constellations_user_created_idx
  on public.constellations (user_id, created_at desc, id desc);

create table if not exists public.focus_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users (id) on delete cascade,
  duration_minutes integer not null check (duration_minutes > 0),
  completed_at timestamptz not null
);

create index if not exists focus_sessions_user_completed_idx
  on public.focus_sessions (user_id, completed_at desc);

-- Row Level Security: tiap orang hanya menyentuh barisnya sendiri.
alter table public.users enable row level security;
alter table public.constellations enable row level security;
alter table public.focus_sessions enable row level security;

create policy users_self on public.users
  for all using (auth.uid() = id) with check (auth.uid() = id);

create policy constellations_own on public.constellations
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy focus_sessions_own on public.focus_sessions
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Stardust tidak boleh ditulis langsung dari klien, supaya poin tidak bisa
-- dipalsukan (docs/05-data-models.md §5.3). Penambahannya lewat fungsi ini.
create or replace function public.award_stardust(amount integer)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  new_total integer;
begin
  if amount is null or amount <= 0 or amount > 10000 then
    raise exception 'jumlah stardust tidak wajar: %', amount;
  end if;

  update public.users
     set stardust_energy = stardust_energy + amount
   where id = auth.uid()
  returning stardust_energy into new_total;

  if new_total is null then
    raise exception 'profil pengguna tidak ditemukan';
  end if;

  return new_total;
end;
$$;

revoke all on function public.award_stardust(integer) from public;
grant execute on function public.award_stardust(integer) to authenticated;
