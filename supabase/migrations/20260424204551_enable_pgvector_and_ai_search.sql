-- Enable the pgvector extension to work with embedding vectors
create extension if not exists vector;

-- Add an embedding column to the properties table.
-- Gemini text-embedding-004 outputs 768 dimensions.
alter table public.properties 
add column if not exists embedding vector(768);

-- Create an HNSW index for ultra-fast vector similarity searches.
create index on public.properties 
using hnsw (embedding vector_cosine_ops);

-- Create a function to perform the semantic search
create or replace function public.match_properties (
  query_embedding vector(768),
  match_threshold float,
  match_count int,
  filter_min_price float default 0,
  filter_max_price float default 999999999,
  filter_beds int default null,
  filter_type text default null
)
returns table (
  id uuid,
  title text,
  price numeric,
  similarity float
)
language sql stable
as $$
  select
    properties.id,
    properties.title,
    properties.price,
    1 - (properties.embedding <=> query_embedding) as similarity
  from properties
  where 1 - (properties.embedding <=> query_embedding) > match_threshold
    and properties.price >= filter_min_price
    and properties.price <= filter_max_price
    and (filter_beds is null or properties.beds = filter_beds)
    and (filter_type is null or properties.type = filter_type)
  order by properties.embedding <=> query_embedding
  limit match_count;
$$;
