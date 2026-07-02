-- ============================================================
-- LIMPIEZA DE REGLAS HEREDADAS DE CALIFICACIONES (V10)
-- ============================================================

SET search_path TO academico, public;

ALTER TABLE calificaciones
    DROP CONSTRAINT IF EXISTS uq_calificacion_matricula_evaluacion;

DROP INDEX IF EXISTS academico.idx_calificaciones_matricula_id;

UPDATE calificaciones
SET ponderacion = 1
WHERE ponderacion <= 0;

ALTER TABLE calificaciones
    DROP CONSTRAINT IF EXISTS chk_calificaciones_ponderacion;
ALTER TABLE calificaciones
    ADD CONSTRAINT chk_calificaciones_ponderacion
    CHECK (ponderacion > 0 AND ponderacion <= 100);
