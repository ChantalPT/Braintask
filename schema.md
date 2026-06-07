## Table `calificacion_soluciones`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `int8` | Primary Identity |
| `id_solucion` | `int8` |  |
| `usuario_id` | `uuid` |  Nullable |
| `estrellas` | `int4` |  Nullable |

## Table `calificaciones`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `int8` | Primary Identity |
| `publicacion_id` | `int8` |  |
| `calificador` | `uuid` |  |
| `calificado` | `uuid` |  |
| `puntuacion` | `int4` |  |
| `comentario` | `text` |  Nullable |
| `fecha` | `timestamptz` |  Nullable |
| `id_solucion` | `int4` |  Nullable |
| `usuario_id` | `uuid` |  Nullable |
| `estrellas` | `int4` |  Nullable |

## Table `calificaciones_dificultad`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id_calificacion` | `int8` | Primary |
| `id_publicacion` | `int4` |  Nullable |
| `cedula_usuarios` | `uuid` |  Nullable |
| `dificultad` | `int4` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |

## Table `carreras`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `int4` | Primary |
| `nombre` | `text` |  Unique |

## Table `facultades`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id_facultad` | `int8` | Primary Identity |
| `nombre_facultad` | `text` |  |

## Table `foro_respuestas`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id_respuesta` | `int8` | Primary Identity |
| `id_publicacion` | `int8` |  |
| `usuario_id` | `uuid` |  |
| `contenido` | `text` |  |
| `votos` | `int8` |  Nullable |
| `tiempo` | `timestamptz` |  Nullable |

## Table `materias`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id_materias` | `int8` | Primary Identity |
| `nombre_materias` | `text` |  |
| `id_facultad` | `int8` |  Nullable |

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
| `archivo_url` | `text` |  |
| `comentario_solucion` | `text` |  Nullable |
| `fecha_subida` | `timestamptz` |  Nullable |
| `calificacion` | `int4` |  Nullable |
| `comentario_calificacion` | `text` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |
| `usuario_id` | `uuid` |  Nullable |
| `aceptada` | `bool` |  Nullable |

## Table `usuarios`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `cedula` | `int8` | Primary Unique Identity |
| `nombre` | `text` |  |
| `apellido` | `text` |  Nullable |
| `carnet` | `text` |  Unique |
| `correo` | `text` |  Unique |
| `puntuacion` | `int8` |  |
| `reputacion` | `float8` |  Nullable |
| `total_calificaciones` | `int4` |  Nullable |
| `reputacion_promedio` | `float8` |  Nullable |
| `auth_user_id` | `uuid` |  Nullable Unique |
| `carrera_id` | `int4` |  Nullable |

