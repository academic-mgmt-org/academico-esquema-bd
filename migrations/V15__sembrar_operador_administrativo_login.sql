-- ============================================================
-- OPERADOR ADMINISTRATIVO PARA FLUJOS GESTIONADOS POR GRPC (V15)
-- ============================================================
--
-- Crea la cuenta documentada para ejecutar flujos administrativos:
--   administrador@demo.com / admin123
--
-- La contrasena se almacena como SHA-256 con prefijo, formato soportado por
-- academico-login en academico.usuarios.password_hash.

BEGIN;

SET search_path TO academico, public;

INSERT INTO roles (nombre, descripcion)
VALUES (
    'administrador',
    'Operador administrativo con permisos para gestionar usuarios y parametros academicos'
)
ON CONFLICT (nombre) DO UPDATE
SET
    descripcion = EXCLUDED.descripcion,
    estado = 'activo',
    actualizado_en = CURRENT_TIMESTAMP;

WITH admin_user AS (
    SELECT
        roles.id AS rol_id,
        'Administrador'::VARCHAR(100) AS nombres,
        'Demo'::VARCHAR(100) AS apellidos,
        'administrador@demo.com'::VARCHAR(150) AS email,
        'sha256:240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9'::VARCHAR(255) AS password_hash,
        '9000000001'::VARCHAR(20) AS identificacion,
        'activo'::VARCHAR(20) AS estado
    FROM roles
    WHERE roles.nombre = 'administrador'
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
FROM admin_user
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
    admin_users_count INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO admin_users_count
    FROM usuarios
    INNER JOIN roles
        ON roles.id = usuarios.rol_id
    WHERE LOWER(usuarios.email) = 'administrador@demo.com'
      AND usuarios.password_hash = 'sha256:240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9'
      AND usuarios.identificacion = '9000000001'
      AND LOWER(usuarios.estado) = 'activo'
      AND LOWER(roles.nombre) = 'administrador';

    IF admin_users_count <> 1 THEN
        RAISE EXCEPTION 'No se pudo sembrar el operador administrativo administrador@demo.com.';
    END IF;
END $$;

COMMIT;
