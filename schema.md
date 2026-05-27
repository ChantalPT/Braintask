| table_name                | column_name             | data_type                   | is_nullable | is_primary_key | foreign_table | foreign_column |
| ------------------------- | ----------------------- | --------------------------- | ----------- | -------------- | ------------- | -------------- |
| calificaciones            | id                      | bigint                      | NO          | YES            | null          | null           |
| calificaciones            | publicacion_id          | bigint                      | NO          | NO             | publicaciones | id_publicacion |
| calificaciones            | publicacion_id          | bigint                      | NO          | NO             | null          | null           |
| calificaciones            | calificador             | uuid                        | NO          | NO             | null          | null           |
| calificaciones            | calificador             | uuid                        | NO          | NO             | null          | null           |
| calificaciones            | calificado              | uuid                        | NO          | NO             | null          | null           |
| calificaciones            | puntuacion              | integer                     | NO          | NO             | null          | null           |
| calificaciones            | comentario              | text                        | YES         | NO             | null          | null           |
| calificaciones            | fecha                   | timestamp with time zone    | YES         | NO             | null          | null           |
| calificaciones_dificultad | id_calificacion         | bigint                      | NO          | YES            | null          | null           |
| calificaciones_dificultad | id_publicacion          | integer                     | YES         | NO             | publicaciones | id_publicacion |
| calificaciones_dificultad | cedula_usuarios         | uuid                        | YES         | NO             | null          | null           |
| calificaciones_dificultad | dificultad              | integer                     | YES         | NO             | null          | null           |
| calificaciones_dificultad | created_at              | timestamp with time zone    | YES         | NO             | null          | null           |
| carreras                  | id                      | integer                     | NO          | YES            | null          | null           |
| carreras                  | nombre                  | text                        | NO          | NO             | null          | null           |
| facultades                | id_facultad             | bigint                      | NO          | YES            | null          | null           |
| facultades                | nombre_facultad         | text                        | NO          | NO             | null          | null           |
| foro_respuestas           | id_respuesta            | bigint                      | NO          | YES            | null          | null           |
| foro_respuestas           | id_publicacion          | bigint                      | NO          | NO             | publicaciones | id_publicacion |
| foro_respuestas           | usuario_id              | uuid                        | NO          | NO             | usuarios      | auth_user_id   |
| foro_respuestas           | contenido               | text                        | NO          | NO             | null          | null           |
| foro_respuestas           | votos                   | bigint                      | YES         | NO             | null          | null           |
| foro_respuestas           | tiempo                  | timestamp with time zone    | YES         | NO             | null          | null           |
| materias                  | id_materias             | bigint                      | NO          | YES            | null          | null           |
| materias                  | nombre_materias         | text                        | NO          | NO             | null          | null           |
| materias                  | id_facultad             | bigint                      | YES         | NO             | facultades    | id_facultad    |
| publicaciones             | id_publicacion          | bigint                      | NO          | YES            | null          | null           |
| publicaciones             | cedula_usuarios         | bigint                      | YES         | NO             | usuarios      | cedula         |
| publicaciones             | titulo                  | text                        | YES         | NO             | null          | null           |
| publicaciones             | descripcion             | text                        | YES         | NO             | null          | null           |
| publicaciones             | foto_url                | text                        | YES         | NO             | null          | null           |
| publicaciones             | tiempo                  | timestamp without time zone | YES         | NO             | null          | null           |
| publicaciones             | tipo                    | text                        | YES         | NO             | null          | null           |
| publicaciones             | puntuacion              | bigint                      | YES         | NO             | null          | null           |
| publicaciones             | id_materia              | bigint                      | YES         | NO             | materias      | id_materias    |
| publicaciones             | estado                  | text                        | YES         | NO             | null          | null           |
| publicaciones             | id_resolutor            | uuid                        | YES         | NO             | null          | null           |
| publicaciones             | autor_id                | uuid                        | YES         | NO             | null          | null           |
| publicaciones             | votos_foro              | integer                     | YES         | NO             | null          | null           |
| soluciones                | id_solucion             | bigint                      | NO          | YES            | null          | null           |
| soluciones                | id_publicacion          | bigint                      | NO          | NO             | publicaciones | id_publicacion |
| soluciones                | cedula_usuario_solver   | bigint                      | NO          | NO             | null          | null           |
| soluciones                | archivo_url             | text                        | NO          | NO             | null          | null           |
| soluciones                | comentario_solucion     | text                        | YES         | NO             | null          | null           |
| soluciones                | fecha_subida            | timestamp with time zone    | YES         | NO             | null          | null           |
| soluciones                | calificacion            | integer                     | YES         | NO             | null          | null           |
| soluciones                | comentario_calificacion | text                        | YES         | NO             | null          | null           |
| soluciones                | created_at              | timestamp with time zone    | YES         | NO             | null          | null           |
| soluciones                | usuario_id              | uuid                        | YES         | NO             | null          | null           |
| soluciones                | aceptada                | boolean                     | YES         | NO             | null          | null           |
| usuarios                  | cedula                  | bigint                      | NO          | NO             | null          | null           |
| usuarios                  | cedula                  | bigint                      | NO          | YES            | null          | null           |
| usuarios                  | nombre                  | text                        | NO          | NO             | null          | null           |
| usuarios                  | apellido                | text                        | YES         | NO             | null          | null           |
| usuarios                  | carnet                  | text                        | NO          | NO             | null          | null           |
| usuarios                  | carnet                  | text                        | NO          | NO             | null          | null           |
| usuarios                  | correo                  | text                        | NO          | NO             | null          | null           |
| usuarios                  | puntuacion              | bigint                      | YES         | NO             | null          | null           |
| usuarios                  | reputacion              | double precision            | YES         | NO             | null          | null           |
| usuarios                  | total_calificaciones    | integer                     | YES         | NO             | null          | null           |
| usuarios                  | reputacion_promedio     | double precision            | YES         | NO             | null          | null           |
| usuarios                  | auth_user_id            | uuid                        | YES         | NO             | null          | null           |
| usuarios                  | auth_user_id            | uuid                        | YES         | NO             | null          | null           |
| usuarios                  | carrera_id              | integer                     | YES         | NO             | carreras      | id             |
| vista_publicaciones       | id_publicacion          | bigint                      | YES         | NO             | null          | null           |
| vista_publicaciones       | cedula_usuarios         | bigint                      | YES         | NO             | null          | null           |
| vista_publicaciones       | titulo                  | text                        | YES         | NO             | null          | null           |
| vista_publicaciones       | descripcion             | text                        | YES         | NO             | null          | null           |
| vista_publicaciones       | foto_url                | text                        | YES         | NO             | null          | null           |
| vista_publicaciones       | tiempo                  | timestamp without time zone | YES         | NO             | null          | null           |
| vista_publicaciones       | tipo                    | text                        | YES         | NO             | null          | null           |
| vista_publicaciones       | puntuacion              | bigint                      | YES         | NO             | null          | null           |
| vista_publicaciones       | id_materia              | bigint                      | YES         | NO             | null          | null           |
| vista_publicaciones       | estado                  | text                        | YES         | NO             | null          | null           |
| vista_publicaciones       | materia_nombre          | text                        | YES         | NO             | null          | null           |