-- DOCA WMS — tabelas no projeto Supabase "Agenda"
-- Cole tudo em Supabase → SQL Editor → New query → Run

create table if not exists public.wms_clientes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  nome text not null,
  cnpj text,
  contato text,
  telefone text,
  email text,
  tipo_preco text default 'pedido',        -- 'pedido' ou 'unidade' (venda normal)
  prep_pedido numeric default 0,           -- R$ por pedido (venda normal)
  prep_unidade numeric default 0,          -- R$ por unidade (venda normal)
  full_unidade numeric default 0,          -- R$ por unidade enviada ao Full
  remessa_dia numeric default 0,           -- R$ cobrado 1x por dia com envio Full
  motoboy numeric default 0,               -- frete padrão motoboy
  valor_m3 numeric default 0,              -- R$ por m³ no mês
  modalidade_m3 text default 'media',      -- 'media' ou 'minimo'
  m3_minimo numeric default 0,             -- franquia mínima de m³
  fixo_mensal numeric default 0,
  endereco_fiscal numeric default 0,
  servicos jsonb default '[]'::jsonb,      -- serviços extras [{nome, base, valor}]
  obs text,
  status text default 'ativo',
  created_at timestamptz default now(),
  canceled_at timestamptz
);

create table if not exists public.wms_produtos (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  cliente_id uuid references public.wms_clientes(id) on delete cascade,
  sku text not null,
  nome text,
  ean text,
  alt_cm numeric default 0,
  larg_cm numeric default 0,
  prof_cm numeric default 0,
  peso_kg numeric default 0,
  valor_unit numeric default 0,
  status text default 'ativo',
  created_at timestamptz default now(),
  canceled_at timestamptz
);

create table if not exists public.wms_docs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  tipo text not null,                      -- entrada, saida, devolucao, ajuste
  cliente_id uuid references public.wms_clientes(id) on delete cascade,
  data date not null,
  ref text,                                -- NF, pedido ou etiqueta
  modalidade text,                         -- normal, full, motoboy, amostra
  marketplace text,
  destinatario text,
  itens jsonb default '[]'::jsonb,
  custo_prep numeric default 0,
  custo_extra numeric default 0,
  frete numeric default 0,
  custo_total numeric default 0,
  preco_manual boolean default false,
  extras jsonb default '[]'::jsonb,
  divergencia boolean default false,
  motivo text,
  obs text,
  status text default 'ativo',
  created_at timestamptz default now(),
  canceled_at timestamptz
);

create table if not exists public.wms_fechamentos (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  cliente_id uuid references public.wms_clientes(id) on delete cascade,
  competencia text not null,               -- '2026-10'
  valores jsonb,
  status text default 'fechado',           -- fechado ou reaberto
  created_at timestamptz default now(),
  canceled_at timestamptz
);

do $$
declare t text;
begin
  foreach t in array array['wms_clientes','wms_produtos','wms_docs','wms_fechamentos'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists "ver os meus" on public.%I', t);
    execute format('drop policy if exists "criar os meus" on public.%I', t);
    execute format('drop policy if exists "editar os meus" on public.%I', t);
    execute format('drop policy if exists "apagar os meus" on public.%I', t);
    execute format('create policy "ver os meus" on public.%I for select using (auth.uid() = user_id)', t);
    execute format('create policy "criar os meus" on public.%I for insert with check (auth.uid() = user_id)', t);
    execute format('create policy "editar os meus" on public.%I for update using (auth.uid() = user_id)', t);
    execute format('create policy "apagar os meus" on public.%I for delete using (auth.uid() = user_id)', t);
  end loop;
end $$;

create index if not exists wms_docs_cli_data on public.wms_docs (cliente_id, data);
create index if not exists wms_prod_cli on public.wms_produtos (cliente_id);
