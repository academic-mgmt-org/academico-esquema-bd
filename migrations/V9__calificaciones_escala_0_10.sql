-- ============================================================
-- ESCALA DE CALIFICACIONES 0-10 (V9)
-- ============================================================

SET search_path TO academico, public;

UPDATE calificaciones
SET nota = ROUND((nota / 10)::numeric, 2)
WHERE nota > 10 AND nota <= 100;

UPDATE componentes_calificacion
SET puntaje_maximo = 10
WHERE puntaje_maximo > 10;

ALTER TABLE componentes_calificacion
    ALTER COLUMN puntaje_maximo SET DEFAULT 10;

ALTER TABLE calificaciones
    DROP CONSTRAINT IF EXISTS chk_calificaciones_nota;
ALTER TABLE calificaciones
    ADD CONSTRAINT chk_calificaciones_nota CHECK (nota BETWEEN 0 AND 10);

ALTER TABLE componentes_calificacion
    DROP CONSTRAINT IF EXISTS chk_componentes_calificacion_puntaje_maximo;
ALTER TABLE componentes_calificacion
    ADD CONSTRAINT chk_componentes_calificacion_puntaje_maximo
    CHECK (puntaje_maximo > 0 AND puntaje_maximo <= 10);

UPDATE matriculas
SET nota_final = ROUND((nota_final / 10)::numeric, 2)
WHERE nota_final > 10 AND nota_final <= 100;

ALTER TABLE matriculas
    DROP CONSTRAINT IF EXISTS chk_matriculas_nota_final;
ALTER TABLE matriculas
    ADD CONSTRAINT chk_matriculas_nota_final
    CHECK (nota_final IS NULL OR (nota_final >= 0 AND nota_final <= 10));
