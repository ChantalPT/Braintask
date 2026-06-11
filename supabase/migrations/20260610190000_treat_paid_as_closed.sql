-- El estado "pagado" tambien representa una solicitud cerrada/resuelta.

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
  v_resolutor_id uuid;
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

  if v_estado in ('resuelto', 'pagado') then
    raise exception 'Esta publicacion ya fue resuelta.';
  end if;

  select usuario_id
  into v_resolutor_id
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
      id_resolutor = v_resolutor_id
  where id_publicacion = p_id_publicacion;
end;
$$;

grant execute on function public.aceptar_solucion(bigint, bigint) to authenticated;

create or replace function public.bloquear_soluciones_en_publicaciones_resueltas()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if exists (
    select 1
    from publicaciones
    where id_publicacion = new.id_publicacion
      and estado in ('resuelto', 'pagado')
  ) then
    raise exception 'Esta publicacion ya fue resuelta.';
  end if;

  return new;
end;
$$;
