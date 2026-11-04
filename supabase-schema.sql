-- =====================================================================
-- TSI Build Quality Hub: database setup for Supabase
-- Run this ONCE in Supabase > SQL Editor (paste everything, press Run).
-- Before you run it, change the admin email in the last section.
-- =====================================================================

-- 1. One table holds every record of the tool (audits, members, disputes, ...)
create table if not exists public.qa_records (
  coll       text        not null,
  id         text        not null,
  data       jsonb       not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  primary key (coll, id)
);
create index if not exists qa_records_updated_idx on public.qa_records (updated_at);
create index if not exists qa_members_email_idx on public.qa_records (lower(data ->> 'email')) where coll = 'members';

-- keep updated_at correct (the page uses it to fetch only what changed)
create or replace function public.qa_touch() returns trigger language plpgsql as $$
begin new.updated_at := now(); return new; end $$;
drop trigger if exists qa_records_touch on public.qa_records;
create trigger qa_records_touch before insert or update on public.qa_records
  for each row execute function public.qa_touch();

-- 2. Admins: emails that always have full access (used for the very first setup)
create table if not exists public.qa_admins (email text primary key);
alter table public.qa_admins enable row level security;   -- no policy: nobody can read it from the page

-- 3. Who is the signed-in person? Admin, or the role in Team Members (active members only)
create or replace function public.qa_role() returns text
language sql stable security definer set search_path = public as $$
  select case
    when exists (select 1 from public.qa_admins a
                 where lower(a.email) = lower(coalesce(auth.jwt() ->> 'email', ''))) then 'Admin'
    else (select r.data ->> 'role' from public.qa_records r
          where r.coll = 'members'
            and lower(r.data ->> 'email') = lower(coalesce(auth.jwt() ->> 'email', ''))
            and coalesce(r.data ->> 'status', 'Active') <> 'Inactive'
          limit 1)
  end
$$;

-- 4. Who may change which area? (the same rules the page follows)
create or replace function public.qa_can_write(c text) returns boolean
language sql stable security definer set search_path = public as $$
  select case
    when public.qa_role() is null then false
    when c = 'shots' then public.qa_role() in ('Admin','Designer','QA','Designer/QA','Team Lead','Manager','Tower Head')
    when c = 'notes' then true
    when public.qa_role() in ('Admin','Team Lead','Manager','Tower Head')
      then (c <> 'access' or public.qa_role() in ('Admin','Tower Head'))
    when c in ('audits','external','calib') then public.qa_role() in ('QA','Designer/QA')
    when c in ('selfs','fixes','edits','rca','pkta','builds','disputes')
      then public.qa_role() in ('Designer','QA','Designer/QA')
    else false
  end
$$;

-- 5. Row level security: only signed-in, active team members get in
alter table public.qa_records enable row level security;
drop policy if exists qa_read   on public.qa_records;
drop policy if exists qa_insert on public.qa_records;
drop policy if exists qa_update on public.qa_records;
drop policy if exists qa_delete on public.qa_records;
create policy qa_read   on public.qa_records for select to authenticated using ((select public.qa_role()) is not null);
create policy qa_insert on public.qa_records for insert to authenticated with check (public.qa_can_write(coll));
create policy qa_update on public.qa_records for update to authenticated using (public.qa_can_write(coll)) with check (public.qa_can_write(coll));
create policy qa_delete on public.qa_records for delete to authenticated using (public.qa_can_write(coll));

revoke all on public.qa_records from anon, public;
revoke all on public.qa_admins  from anon, authenticated;
grant select, insert, update, delete on public.qa_records to authenticated;
grant execute on function public.qa_role()           to authenticated;
grant execute on function public.qa_can_write(text)  to authenticated;

-- 6. YOUR ADMIN EMAIL: replace the text below with your work email, then run.
insert into public.qa_admins (email) values ('PASTE-ADMIN-EMAIL@company.com') on conflict do nothing;
