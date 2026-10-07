-- Poker tab: database setup. Paste this whole file into the Supabase SQL editor and run it once.
-- Starting PINs are set near the bottom (table PIN: DEAL, host PIN: BANKER).
-- Change both from the Host settings screen in the app after your first sign-in.

create extension if not exists pgcrypto with schema extensions;

-- One row holds the whole book. Nobody can read or write the table directly;
-- everything goes through the PIN-checked functions below.
create table if not exists public.poker_book (
  id int primary key default 1 check (id = 1),
  state jsonb not null default '{}'::jsonb,
  version bigint not null default 0,
  view_pin_hash text not null,
  host_pin_hash text not null,
  updated_at timestamptz not null default now()
);

alter table public.poker_book enable row level security;
revoke all on public.poker_book from anon, authenticated;

create or replace function public.poker_role(p_pin text)
returns text
language sql stable security definer
set search_path = public, extensions
as $$
  select case
    when host_pin_hash = crypt(upper(coalesce(p_pin, '')), host_pin_hash) then 'host'
    when view_pin_hash = crypt(upper(coalesce(p_pin, '')), view_pin_hash) then 'viewer'
  end
  from poker_book where id = 1
$$;

create or replace function public.poker_get(p_pin text)
returns json
language plpgsql stable security definer
set search_path = public, extensions
as $$
declare r text := poker_role(p_pin);
begin
  if r is null then return json_build_object('ok', false, 'reason', 'bad_pin'); end if;
  return (select json_build_object('ok', true, 'role', r, 'version', version, 'state', state)
          from poker_book where id = 1);
end $$;

create or replace function public.poker_save(p_pin text, p_state jsonb, p_version bigint)
returns json
language plpgsql security definer
set search_path = public, extensions
as $$
declare v bigint;
begin
  if poker_role(p_pin) is distinct from 'host' then
    return json_build_object('ok', false, 'reason', 'bad_pin');
  end if;
  if octet_length(p_state::text) > 2000000 then
    return json_build_object('ok', false, 'reason', 'too_big');
  end if;
  update poker_book set state = p_state, version = version + 1, updated_at = now()
    where id = 1 and version = p_version
    returning version into v;
  if v is null then return json_build_object('ok', false, 'reason', 'conflict'); end if;
  return json_build_object('ok', true, 'version', v);
end $$;

create or replace function public.poker_set_pins(p_pin text, p_view text, p_host text)
returns json
language plpgsql security definer
set search_path = public, extensions
as $$
begin
  if poker_role(p_pin) is distinct from 'host' then
    return json_build_object('ok', false, 'reason', 'bad_pin');
  end if;
  if p_view is not null and length(p_view) <> 4 then
    return json_build_object('ok', false, 'reason', 'view_length');
  end if;
  if p_host is not null and length(p_host) < 4 then
    return json_build_object('ok', false, 'reason', 'host_length');
  end if;
  -- The two PINs must differ, or every guest would be let in as a host.
  if upper(coalesce(p_view, '')) = upper(coalesce(p_host, '-'))
     or (p_view is not null and p_host is null and exists (
           select 1 from poker_book where id = 1 and host_pin_hash = crypt(upper(p_view), host_pin_hash)))
     or (p_host is not null and p_view is null and exists (
           select 1 from poker_book where id = 1 and view_pin_hash = crypt(upper(p_host), view_pin_hash)))
  then
    return json_build_object('ok', false, 'reason', 'same');
  end if;
  update poker_book set
    view_pin_hash = case when p_view is null then view_pin_hash else crypt(upper(p_view), gen_salt('bf')) end,
    host_pin_hash = case when p_host is null then host_pin_hash else crypt(upper(p_host), gen_salt('bf')) end
    where id = 1;
  return json_build_object('ok', true);
end $$;

revoke all on function public.poker_role(text) from public, anon, authenticated;
grant execute on function public.poker_get(text) to anon, authenticated;
grant execute on function public.poker_save(text, jsonb, bigint) to anon, authenticated;
grant execute on function public.poker_set_pins(text, text, text) to anon, authenticated;

-- Starting PINs. Running this file again will not overwrite PINs you have since changed.
insert into public.poker_book (id, view_pin_hash, host_pin_hash)
values (1,
  extensions.crypt('DEAL', extensions.gen_salt('bf')),
  extensions.crypt('BANKER', extensions.gen_salt('bf')))
on conflict (id) do nothing;
