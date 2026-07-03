-- ============================================================
-- NORMALIZAR ESTADOS DEL DOMINIO DE CALIFICACIONES (V13)
-- ============================================================
--
-- Migra los estados de calificacion y matricula-asignatura a valores neutros.

BEGIN;

SET search_path TO academico, public;

DROP INDEX IF EXISTS academico.uq_calificaciones_matricula_componente_activa;
DROP INDEX IF EXISTS academico.uq_calificaciones_matricula_componente_vigente;
DROP INDEX IF EXISTS academico.uq_calificaciones_matricula_codigo_componente_activa;
DROP INDEX IF EXISTS academico.uq_calificaciones_matricula_codigo_componente_vigente;
DROP INDEX IF EXISTS academico.uq_matricula_asignaturas_contexto;
DROP INDEX IF EXISTS academico.uq_calificaciones_matricula_asignatura_componente_activa;
DROP INDEX IF EXISTS academico.uq_calificaciones_matricula_asignatura_componente_vigente;
DROP INDEX IF EXISTS academico.idx_calificaciones_publicada;
DROP INDEX IF EXISTS academico.idx_calificaciones_publicado;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'academico'
          AND table_name = 'calificaciones'
          AND column_name = 'publicada'
    ) AND NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'academico'
          AND table_name = 'calificaciones'
          AND column_name = 'publicado'
    ) THEN
        ALTER TABLE calificaciones RENAME COLUMN publicada TO publicado;
    END IF;
END $$;

ALTER TABLE IF EXISTS calificaciones
    ADD COLUMN IF NOT EXISTS publicado BOOLEAN;

UPDATE calificaciones
SET publicado = FALSE
WHERE publicado IS NULL;

ALTER TABLE IF EXISTS calificaciones
    ALTER COLUMN publicado SET DEFAULT FALSE;

ALTER TABLE IF EXISTS calificaciones
    ALTER COLUMN publicado SET NOT NULL;

ALTER TABLE IF EXISTS calificaciones
    DROP CONSTRAINT IF EXISTS chk_calificaciones_estado;

UPDATE calificaciones
SET estado = CASE estado
    WHEN 'publicada' THEN 'publicado'
    WHEN 'anulada' THEN 'anulado'
    ELSE estado
END
WHERE estado IN ('publicada', 'anulada');

ALTER TABLE IF EXISTS calificaciones
    ADD CONSTRAINT chk_calificaciones_estado
    CHECK (estado IN ('borrador', 'publicado', 'anulado'));

ALTER TABLE IF EXISTS matricula_asignaturas
    DROP CONSTRAINT IF EXISTS chk_matricula_asignaturas_estado;

ALTER TABLE IF EXISTS matricula_asignaturas
    ALTER COLUMN estado SET DEFAULT 'activo';

UPDATE matricula_asignaturas
SET estado = CASE estado
    WHEN 'activa' THEN 'activo'
    WHEN 'aprobada' THEN 'aprobado'
    WHEN 'reprobada' THEN 'reprobado'
    WHEN 'anulada' THEN 'anulado'
    ELSE estado
END
WHERE estado IN ('activa', 'aprobada', 'reprobada', 'anulada');

ALTER TABLE IF EXISTS matricula_asignaturas
    ADD CONSTRAINT chk_matricula_asignaturas_estado
    CHECK (estado IN ('activo', 'aprobado', 'reprobado', 'anulado'));

CREATE UNIQUE INDEX IF NOT EXISTS uq_matricula_asignaturas_contexto
    ON matricula_asignaturas (
        matricula_codigo,
        ciclo_acad_codigo,
        materia_codigo,
        paralelo_codigo,
        (COALESCE(docente_cedula, ''))
    )
    WHERE estado <> 'anulado';

CREATE UNIQUE INDEX IF NOT EXISTS uq_calificaciones_matricula_asignatura_componente_vigente
    ON calificaciones (matricula_asignatura_codigo, componente_id)
    WHERE estado <> 'anulado';

CREATE INDEX IF NOT EXISTS idx_calificaciones_publicado
    ON calificaciones(publicado);

COMMIT;
