-- ============================================================
-- SEMILLAS DE USUARIOS PARA VALIDACION DE LOGIN (V7)
-- ============================================================
--
-- Crea los usuarios base que consume academico-login desde
-- academico.usuarios. Las contrasenas se almacenan como SHA-256
-- con prefijo, formato soportado por el microservicio de login.
--
-- Credenciales:
--   allunav@utn.edu.ec / password123
--   docente@utn.edu.ec / password123

BEGIN;

SET search_path TO academico, public;

INSERT INTO roles (nombre, descripcion)
VALUES
    ('estudiante', 'Usuario que puede matricularse en cursos y consultar calificaciones'),
    ('docente', 'Usuario que imparte cursos y registra calificaciones')
ON CONFLICT (nombre) DO UPDATE
SET
    descripcion = EXCLUDED.descripcion,
    estado = 'activo',
    actualizado_en = CURRENT_TIMESTAMP;

WITH seed_users (
    rol_nombre,
    nombres,
    apellidos,
    email,
    password_hash,
    identificacion,
    estado
) AS (
    VALUES
        (
            'estudiante',
            'Estudiante',
            'Prueba',
            'allunav@utn.edu.ec',
            'sha256:ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f',
            '1000000001',
            'activo'
        ),
        (
            'docente',
            'Docente',
            'Prueba',
            'docente@utn.edu.ec',
            'sha256:ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f',
            '1000000002',
            'activo'
        )
),
resolved_users AS (
    SELECT
        roles.id AS rol_id,
        seed_users.nombres,
        seed_users.apellidos,
        seed_users.email,
        seed_users.password_hash,
        seed_users.identificacion,
        seed_users.estado
    FROM seed_users
    INNER JOIN roles
        ON roles.nombre = seed_users.rol_nombre
)
INSERT INTO usuarios (
    rol_id,
    nombres,
    apellidos,
    email,
    password_hash,
    identificacion,
    estado
)
SELECT
    rol_id,
    nombres,
    apellidos,
    email,
    password_hash,
    identificacion,
    estado
FROM resolved_users
ON CONFLICT (email) DO UPDATE
SET
    rol_id = EXCLUDED.rol_id,
    nombres = EXCLUDED.nombres,
    apellidos = EXCLUDED.apellidos,
    password_hash = EXCLUDED.password_hash,
    identificacion = EXCLUDED.identificacion,
    estado = EXCLUDED.estado,
    actualizado_en = CURRENT_TIMESTAMP;

DO $$
DECLARE
    seeded_users_count INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO seeded_users_count
    FROM usuarios
    WHERE email IN ('allunav@utn.edu.ec', 'docente@utn.edu.ec')
      AND estado = 'activo';

    IF seeded_users_count <> 2 THEN
        RAISE EXCEPTION 'No se pudieron sembrar todos los usuarios base de login. Usuarios activos encontrados: %', seeded_users_count;
    END IF;
END $$;

COMMIT;
