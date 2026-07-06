-- ============================================================
-- RESTAURAR USUARIOS BASE DE LOGIN (V16)
-- ============================================================
--
-- V7 sembro los usuarios base de login:
--   allunav@utn.edu.ec / password123
--   docente@utn.edu.ec / password123
--
-- En ambientes donde V12 ya habia sido aplicada antes de reservar los ids
-- 101/102, los usuarios del flujo de calificaciones ocuparon ids 1/2 y
-- reemplazaron esas semillas por email. Como esas bases no vuelven a ejecutar
-- V12, esta migracion restaura las cuentas base con ids nuevos generados por
-- la base de datos.

BEGIN;

SET search_path TO academico, public;

INSERT INTO roles (nombre, descripcion, estado)
VALUES
    ('estudiante', 'Usuario que puede matricularse en cursos y consultar calificaciones', 'activo'),
    ('docente', 'Usuario que imparte cursos y registra calificaciones', 'activo')
ON CONFLICT (nombre) DO UPDATE
SET
    descripcion = EXCLUDED.descripcion,
    estado = EXCLUDED.estado,
    actualizado_en = CURRENT_TIMESTAMP;

-- Liberar identificaciones esperadas si alguna fila distinta a la semilla las
-- conserva por una ejecucion parcial previa.
UPDATE usuarios
SET
    identificacion = CONCAT('ANT-', id, '-1000000001'),
    actualizado_en = CURRENT_TIMESTAMP
WHERE LOWER(email) <> 'allunav@utn.edu.ec'
  AND identificacion = '1000000001';

UPDATE usuarios
SET
    identificacion = CONCAT('ANT-', id, '-1000000002'),
    actualizado_en = CURRENT_TIMESTAMP
WHERE LOWER(email) <> 'docente@utn.edu.ec'
  AND identificacion = '1000000002';

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

SELECT setval(
    pg_get_serial_sequence('academico.usuarios', 'id'),
    GREATEST((SELECT COALESCE(MAX(id), 1) FROM usuarios), 1),
    true
);

DO $$
DECLARE
    seeded_users_count INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO seeded_users_count
    FROM usuarios
    INNER JOIN roles
        ON roles.id = usuarios.rol_id
    WHERE LOWER(usuarios.email) IN ('allunav@utn.edu.ec', 'docente@utn.edu.ec')
      AND usuarios.password_hash = 'sha256:ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f'
      AND LOWER(usuarios.estado) = 'activo'
      AND LOWER(roles.nombre) IN ('estudiante', 'docente');

    IF seeded_users_count <> 2 THEN
        RAISE EXCEPTION 'No se pudieron restaurar los usuarios base de login. Usuarios activos encontrados: %', seeded_users_count;
    END IF;
END $$;

COMMIT;
