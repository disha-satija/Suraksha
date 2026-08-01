-- Suraksha — Supabase Schema Migration
-- Run this in your Supabase SQL editor before connecting the app.
-- Enable PostGIS extension for geo queries.

-- ── Extensions ────────────────────────────────────────────────────────────────
create extension if not exists postgis;

-- ── Tables ────────────────────────────────────────────────────────────────────

-- Reported incidents (synced from device outbox)
create table if not exists incidents (
  id              uuid primary key default gen_random_uuid(),
  local_id        text unique not null,
  latitude        double precision not null,
  longitude       double precision not null,
  crime_type      text not null,
  description     text default '',
  time_of_day     text not null,
  reported_at     timestamptz not null,
  created_at      timestamptz default now(),
  geom            geography(Point, 4326)
    generated always as (
      ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography
    ) stored
);

-- Live user locations (guardian realtime tracking)
create table if not exists user_locations (
  user_id         text primary key,
  latitude        double precision not null,
  longitude       double precision not null,
  updated_at      timestamptz default now(),
  geom            geography(Point, 4326)
    generated always as (
      ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography
    ) stored
);

-- Location history (offline queue flush)
create table if not exists location_history (
  id              uuid primary key default gen_random_uuid(),
  local_id        text unique not null,
  user_id         text,
  latitude        double precision not null,
  longitude       double precision not null,
  recorded_at     timestamptz not null,
  created_at      timestamptz default now()
);

-- ── Indexes ───────────────────────────────────────────────────────────────────
create index if not exists idx_incidents_geom
  on incidents using gist (geom);

create index if not exists idx_incidents_crime_type
  on incidents (crime_type);

create index if not exists idx_incidents_reported_at
  on incidents (reported_at desc);

create index if not exists idx_location_history_user
  on location_history (user_id, recorded_at desc);

-- ── Row Level Security ────────────────────────────────────────────────────────

alter table incidents enable row level security;
alter table user_locations enable row level security;
alter table location_history enable row level security;

-- Incidents: anyone can insert, anyone can read
-- (for hackathon — tighten in production with auth)
create policy "public insert incidents"
  on incidents for insert
  to anon
  with check (true);

create policy "public read incidents"
  on incidents for select
  to anon
  using (true);

-- User locations: anyone can upsert and read
-- (for hackathon demo — in production scope to authenticated users)
create policy "public upsert user_locations"
  on user_locations for all
  to anon
  using (true)
  with check (true);

-- Location history: anyone can insert and read
create policy "public insert location_history"
  on location_history for insert
  to anon
  with check (true);

create policy "public read location_history"
  on location_history for select
  to anon
  using (true);

-- ── Realtime ──────────────────────────────────────────────────────────────────
-- Enable realtime on user_locations for guardian live tracking
alter publication supabase_realtime add table user_locations;
