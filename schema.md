## Table `mensajes`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `int8` | Primary Identity |
| `emisor_id` | `uuid` | Not Null |
| `receptor_id` | `uuid` | Not Null |
| `contenido` | `text` | Not Null |
| `leido` | `bool` | Not Null, Default false |
| `created_at` | `timestamptz` | Not Null, Default now() |

## Table `notificaciones`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `int4` | Primary |
| `usuario_id` | `uuid` |  |
| `mensaje` | `text` |  |
| `leida` | `bool` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |
| `tipo` | `text` |  Nullable |

## Table `publicaciones`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id_publicacion` | `int8` | Primary Identity |
| `cedula_usuarios` | `int8` |  Nullable |
| `titulo` | `text` |  Nullable |
| `descripcion` | `text` |  Nullable |
| `foto_url` | `text` |  Nullable |
| `tiempo` | `timestamp` |  Nullable |
| `tipo` | `text` |  Nullable |
| `puntuacion` | `int8` |  Nullable |
| `id_materia` | `int8` |  Nullable |
| `estado` | `text` |  Nullable |
| `id_resolutor` | `uuid` |  Nullable |
| `autor_id` | `uuid` |  Nullable |
| `votos_foro` | `int4` |  Nullable |

## Table `soluciones`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id_solucion` | `int8` | Primary |
| `id_publicacion` | `int8` |  |
| `cedula_usuario_solver` | `int8` |  Nullable |
| `archivo_url` | `text` |  Nullable |
| `comentario_solucion` | `text` |  Nullable |
| `fecha_subida` | `timestamptz` |  Nullable |
| `calificacion` | `int4` |  Nullable |
| `comentario_calificacion` | `text` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |
| `usuario_id` | `uuid` |  Nullable |
| `aceptada` | `bool` |  Nullable |