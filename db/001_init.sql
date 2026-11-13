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
