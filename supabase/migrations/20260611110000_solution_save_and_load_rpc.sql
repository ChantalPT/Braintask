-- Hace confiable el flujo: guardar solucion y cargarla de vuelta desde Supabase.

create or replace function public.get_soluciones_publicacion(
  p_id_publicacion bigint
)
returns table (
  id_solucion bigint,
  id_publicacion bigint,
  usuario_id uuid,
  cedula_usuario_solver bigint,
  archivo_url text,
  comentario_solucion text,
  fecha_subida timestamptz,
  aceptada boolean,
  nombre text,
  apellido text
)
language sql
security definer
set search_path = public
as $$
  select
    s.id_solucion,
    s.id_publicacion,
    s.usuario_id,
    s.cedula_usuario_solver,
    s.archivo_url,
    s.comentario_solucion,
    s.fecha_subida,
    coalesce(s.aceptada, false) as aceptada,
    u.nombre,
    u.apellido
  from soluciones s
  left join usuarios u
    on u.auth_user_id = s.usuario_id
  where s.id_publicacion = p_id_publicacion
  order by s.fecha_subida desc;
$$;

grant execute on function public.get_soluciones_publicacion(bigint) to authenticated;

create or replace function public.subir_solucion(
  p_id_publicacion bigint,
  p_comentario_solucion text,
  p_archivo_url text default null
)
returns table (
  id_solucion bigint,
  id_publicacion bigint,
  usuario_id uuid,
  cedula_usuario_solver bigint,
  archivo_url text,
  comentario_solucion text,
  fecha_subida timestamptz,
  aceptada boolean,
  nombre text,
  apellido text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_cedula bigint;
  v_autor_id uuid;
  v_estado text;
  v_id_solucion bigint;
begin
  v_user_id := auth.uid();

  if v_user_id is null then
    raise exception 'Debes iniciar sesion para enviar una solucion.';
  end if;

  select autor_id, estado
  into v_autor_id, v_estado
  from publicaciones
  where publicaciones.id_publicacion = p_id_publicacion
  for update;

  if not found then
    raise exception 'Publicacion no encontrada.';
  end if;

  if v_estado in ('resuelto', 'pagado') then
    raise exception 'Esta publicacion ya fue resuelta.';
  end if;

  if v_autor_id is not distinct from v_user_id then
    raise exception 'No puedes responder a tu propia pregunta.';
  end if;

  select cedula
  into v_cedula
  from usuarios
  where auth_user_id = v_user_id;

  if v_cedula is null then
    raise exception 'No se encontro el perfil del usuario.';
  end if;

  insert into soluciones (
    id_publicacion,
    usuario_id,
    cedula_usuario_solver,
    archivo_url,
    comentario_solucion,
    aceptada,
    fecha_subida
  )
  values (
    p_id_publicacion,
    v_user_id,
    v_cedula,
    p_archivo_url,
    nullif(trim(coalesce(p_comentario_solucion, '')), ''),
    false,
    now()
  )
  returning soluciones.id_solucion into v_id_solucion;

  return query
  select g.*
  from public.get_soluciones_publicacion(p_id_publicacion) as g
  where g.id_solucion = v_id_solucion;
end;
$$;

grant execute on function public.subir_solucion(bigint, text, text) to authenticated;
