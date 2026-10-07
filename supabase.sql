-- Run this whole file in Supabase > SQL Editor
create table profiles(id uuid primary key references auth.users on delete cascade, name text not null);
create table listings(
  id uuid primary key default gen_random_uuid(),
  seller_id uuid not null default auth.uid() references profiles(id) on delete cascade,
  title text not null check (char_length(title) between 3 and 80),
  description text not null default '',
  price numeric not null check (price >= 0),
  category text not null,
  image_url text,
  status text not null default 'available' check (status in ('available','sold')),
  lat double precision, lng double precision,
  created_at timestamptz not null default now());
create table favourites(user_id uuid default auth.uid() references profiles(id) on delete cascade,
  listing_id uuid references listings(id) on delete cascade, primary key(user_id, listing_id));
create table messages(id bigint generated always as identity primary key,
  listing_id uuid not null references listings(id) on delete cascade,
  sender_id uuid not null default auth.uid() references profiles(id),
  receiver_id uuid not null references profiles(id),
  body text not null check (char_length(body) between 1 and 500),
  created_at timestamptz not null default now());
create index on listings(created_at desc); create index on messages(listing_id);

create function handle_new_user() returns trigger language plpgsql security definer as $$
begin insert into profiles(id,name) values(new.id, coalesce(new.raw_user_meta_data->>'name', split_part(new.email,'@',1))); return new; end $$;
create trigger on_signup after insert on auth.users for each row execute function handle_new_user();

alter table profiles enable row level security; alter table listings enable row level security;
alter table favourites enable row level security; alter table messages enable row level security;
create policy "profiles read" on profiles for select using (true);
create policy "listings read" on listings for select using (true);
create policy "listings insert own" on listings for insert to authenticated with check (seller_id = auth.uid());
create policy "listings update own" on listings for update to authenticated using (seller_id = auth.uid()) with check (seller_id = auth.uid());
create policy "listings delete own" on listings for delete to authenticated using (seller_id = auth.uid());
create policy "fav own" on favourites for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "msg read mine" on messages for select to authenticated using (sender_id = auth.uid() or receiver_id = auth.uid());
create policy "msg send" on messages for insert to authenticated with check (sender_id = auth.uid());

-- Analytics views
create view top_sellers as select p.name, count(*)::int as total from listings l join profiles p on p.id=l.seller_id
  where l.status='sold' group by p.name order by total desc limit 5;
create view top_buyers as select p.name, count(distinct m.listing_id)::int as total from messages m
  join listings l on l.id=m.listing_id join profiles p on p.id=m.sender_id
  where m.sender_id <> l.seller_id group by p.name order by total desc limit 5;
grant select on top_sellers, top_buyers to anon, authenticated;

-- Realtime + image storage
alter publication supabase_realtime add table listings, messages;
insert into storage.buckets(id,name,public) values('listing-images','listing-images',true);
create policy "img read" on storage.objects for select using (bucket_id='listing-images');
create policy "img upload own" on storage.objects for insert to authenticated
  with check (bucket_id='listing-images' and (storage.foldername(name))[1]=auth.uid()::text);
