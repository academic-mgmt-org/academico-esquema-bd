-- ============================================================
-- USUARIO SINTETICO PARA LATENCIA DE NOTIFICACIONES (V14)
-- ============================================================
--
-- Crea una cuenta activa, de bajo privilegio, para pruebas de latencia
-- contra academico-notificaciones. La contrasena no se almacena en claro;
-- academico-login soporta hashes bcrypt en academico.usuarios.password_hash.

BEGIN;

SET search_path TO academico, public;

INSERT INTO roles (nombre, descripcion)
VALUES (
    'estudiante',
    'Usuario que puede matricularse en cursos y consultar informacion academica'
)
ON CONFLICT (nombre) DO UPDATE
SET
    descripcion = EXCLUDED.descripcion,
    estado = 'activo',
    actualizado_en = CURRENT_TIMESTAMP;

WITH synthetic_user AS (
    SELECT
        roles.id AS rol_id,
        'Latencia'::VARCHAR(100) AS nombres,
        'Notificaciones'::VARCHAR(100) AS apellidos,
        'latencia.notificaciones@utn.edu.ec'::VARCHAR(150) AS email,
        '$2b$10$8lE6MnVtCqkS58xcexhVs.MTGJmocfCJaIoQMm3Cduys/GCbleF1e'::VARCHAR(255) AS password_hash,
        '1999000001'::VARCHAR(20) AS identificacion,
        'activo'::VARCHAR(20) AS estado
    FROM roles
    WHERE roles.nombre = 'estudiante'
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
FROM synthetic_user
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
    synthetic_users_count INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO synthetic_users_count
    FROM usuarios
    WHERE email = 'latencia.notificaciones@utn.edu.ec'
      AND identificacion = '1999000001'
      AND estado = 'activo';

    IF synthetic_users_count <> 1 THEN
        RAISE EXCEPTION 'No se pudo sembrar el usuario sintetico de latencia de notificaciones.';
    END IF;
END $$;

COMMIT;
