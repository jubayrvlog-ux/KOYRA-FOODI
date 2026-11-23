-- Koyra Food database setup. Run the entire file in Supabase SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  full_name text default '',
  phone text default '',
  address text default '',
  union_name text default '',
  role text not null default 'customer' check (role in ('customer','admin')),
  created_at timestamptz not null default now()
);

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles(id,email,full_name)
  values(new.id,new.email,coalesce(new.raw_user_meta_data->>'full_name',''))
  on conflict (id) do nothing;
  return new;
end; $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute procedure public.handle_new_user();

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text default '',
  price numeric(10,2) not null check(price >= 0),
  image_url text default '',
  category text default 'অন্যান্য',
  available boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id),
  customer_name text not null,
  phone text not null,
  union_name text not null,
  address text not null,
  items jsonb not null,
  subtotal numeric(10,2) not null,
  delivery_fee numeric(10,2) not null,
  total numeric(10,2) not null,
  note text default '',
  status text not null default 'pending'
    check(status in ('pending','accepted','preparing','on_the_way','delivered','rejected')),
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
alter table public.products enable row level security;
alter table public.orders enable row level security;

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path=public as $$
  select exists(select 1 from public.profiles where id=auth.uid() and role='admin');
$$;

drop policy if exists "profiles read own or admin" on public.profiles;
create policy "profiles read own or admin" on public.profiles for select to authenticated
using (id=auth.uid() or public.is_admin());
drop policy if exists "profiles update own" on public.profiles;
create policy "profiles update own" on public.profiles for update to authenticated
using (id=auth.uid()) with check (id=auth.uid() and (role='customer' or public.is_admin()));

drop policy if exists "products public read" on public.products;
create policy "products public read" on public.products for select to anon, authenticated using (true);
drop policy if exists "products admin insert" on public.products;
create policy "products admin insert" on public.products for insert to authenticated with check(public.is_admin());
drop policy if exists "products admin update" on public.products;
create policy "products admin update" on public.products for update to authenticated using(public.is_admin()) with check(public.is_admin());
drop policy if exists "products admin delete" on public.products;
create policy "products admin delete" on public.products for delete to authenticated using(public.is_admin());

drop policy if exists "customer create own order" on public.orders;
create policy "customer create own order" on public.orders for insert to authenticated
with check(user_id=auth.uid() and status='pending');
drop policy if exists "customer read own or admin" on public.orders;
create policy "customer read own or admin" on public.orders for select to authenticated
using(user_id=auth.uid() or public.is_admin());
drop policy if exists "admin update orders" on public.orders;
create policy "admin update orders" on public.orders for update to authenticated
using(public.is_admin()) with check(public.is_admin());

-- Product images bucket (public read, authenticated admin writes)
insert into storage.buckets(id,name,public) values('food-images','food-images',true)
on conflict(id) do nothing;
drop policy if exists "food images public view" on storage.objects;
create policy "food images public view" on storage.objects for select using(bucket_id='food-images');
drop policy if exists "admin upload food images" on storage.objects;
create policy "admin upload food images" on storage.objects for insert to authenticated
with check(bucket_id='food-images' and public.is_admin());
drop policy if exists "admin update food images" on storage.objects;
create policy "admin update food images" on storage.objects for update to authenticated
using(bucket_id='food-images' and public.is_admin());
drop policy if exists "admin delete food images" on storage.objects;
create policy "admin delete food images" on storage.objects for delete to authenticated
using(bucket_id='food-images' and public.is_admin());

-- Promote your own account to admin after you sign up:
-- update public.profiles set role='admin' where email='YOUR_GMAIL@gmail.com';


-- Starter menu: prices for kacchi/burger/moglai are intentionally left at 0
-- until the owner sets the correct prices in the Admin panel.
insert into public.products(name,description,price,image_url,category,available)
select * from (values
 ('মুরগির বিরিয়ানি','এক প্লেট মুরগির বিরিয়ানি',110,'https://images.unsplash.com/photo-1563379091339-03246963d96c?w=900','বিরিয়ানি',true),
 ('কাচ্চি বিরিয়ানি','কাচ্চি বিরিয়ানি — দাম অ্যাডমিন নির্ধারণ করবেন',0,'https://images.unsplash.com/photo-1589302168068-964664d93dc0?w=900','বিরিয়ানি',true),
 ('বার্গার','সুস্বাদু বার্গার — দাম অ্যাডমিন নির্ধারণ করবেন',0,'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=900','ফাস্ট ফুড',true),
 ('মোগলাই পরোটা','মোগলাই পরোটা — দাম অ্যাডমিন নির্ধারণ করবেন',0,'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=900','স্ন্যাকস',true)
) as v(name,description,price,image_url,category,available)
where not exists (select 1 from public.products);
