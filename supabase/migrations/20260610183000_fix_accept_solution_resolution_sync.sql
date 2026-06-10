-- Registra el resolutor real al aceptar una solucion y habilita realtime
-- para que las sesiones abiertas vean el cambio sin recargar manualmente.

create or replace function public.aceptar_solucion(
  p_id_publicacion bigint,
  p_id_solucion bigint
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_autor_id uuid;
  v_estado text;
  v_solver_id uuid;
begin
  select autor_id, estado
  into v_autor_id, v_estado
  from publicaciones
  where id_publicacion = p_id_publicacion
  for update;

  if not found then
    raise exception 'Publicacion no encontrada.';
  end if;

  if v_autor_id is distinct from auth.uid() then
    raise exception 'Solo el autor puede aceptar una solucion.';
  end if;

  if v_estado = 'resuelto' then
    raise exception 'Esta publicacion ya fue resuelta.';
  end if;

  select usuario_id
  into v_solver_id
  from soluciones
  where id_solucion = p_id_solucion
    and id_publicacion = p_id_publicacion;

  if not found then
    raise exception 'La solucion seleccionada no pertenece a esta publicacion.';
  end if;

  update soluciones
  set aceptada = false
  where id_publicacion = p_id_publicacion;

  update soluciones
  set aceptada = true
  where id_solucion = p_id_solucion
    and id_publicacion = p_id_publicacion;

  update publicaciones
  set estado = 'resuelto',
      id_resolutor = v_solver_id
  where id_publicacion = p_id_publicacion;
end;
$$;

grant execute on function public.aceptar_solucion(bigint, bigint) to authenticated;

do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    if not exists (
      select 1
      from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = 'publicaciones'
    ) then
      alter publication supabase_realtime add table public.publicaciones;
    end if;

    if not exists (
      select 1
      from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = 'soluciones'
    ) then
      alter publication supabase_realtime add table public.soluciones;
    end if;
  end if;
end;
$$;
