-- ============================================================
-- INTRODUCIR MATRICULA-ASIGNATURA EN CALIFICACIONES (V11)
-- ============================================================
--
-- Alinea el esquema central con academico-calificaciones:
-- - La matricula global queda como matricula_codigo.
-- - Las notas se agrupan por matricula_asignatura_codigo.
-- - La nota final se guarda por materia inscrita, no por toda la matricula.

CREATE SCHEMA IF NOT EXISTS academico;
SET search_path TO academico, public;

CREATE TABLE IF NOT EXISTS matricula_asignaturas (
    codigo VARCHAR(200) PRIMARY KEY,
    matricula_codigo VARCHAR(40) NOT NULL,
    estudiante_id BIGINT,
    estudiante_cedula VARCHAR(80),
    oferta_curso_id BIGINT,
    ciclo_acad_codigo VARCHAR(40) NOT NULL,
    materia_codigo VARCHAR(120) NOT NULL,
    paralelo_codigo VARCHAR(40) NOT NULL,
    docente_cedula VARCHAR(80),
    nivel_codigo VARCHAR(40),
    depen_codigo VARCHAR(40),
    estado VARCHAR(20) NOT NULL DEFAULT 'activo',
    nota_final NUMERIC(5,2),
    creado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    actualizado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_matricula_asignaturas_estado
        CHECK (estado IN ('activo', 'aprobado', 'reprobado', 'anulado')),
    CONSTRAINT chk_matricula_asignaturas_nota_final
        CHECK (nota_final IS NULL OR (nota_final >= 0 AND nota_final <= 10))
);

ALTER TABLE calificaciones
    ADD COLUMN IF NOT EXISTS matricula_codigo VARCHAR(40),
    ADD COLUMN IF NOT EXISTS matricula_asignatura_codigo VARCHAR(200);

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'academico'
          AND table_name = 'calificaciones'
          AND column_name = 'matricula_id'
    ) THEN
        UPDATE calificaciones AS calificacion
        SET
            matricula_codigo = COALESCE(calificacion.matricula_codigo, calificacion.matricula_id::text),
            estudiante_id = COALESCE(calificacion.estudiante_id, matricula.estudiante_id),
            oferta_curso_id = COALESCE(calificacion.oferta_curso_id, matricula.oferta_curso_id)
        FROM matriculas AS matricula
        WHERE calificacion.matricula_id = matricula.id;

        UPDATE calificaciones
        SET matricula_codigo = matricula_id::text
        WHERE matricula_codigo IS NULL;
    END IF;
END $$;

UPDATE calificaciones
SET matricula_codigo = CONCAT('SIN-MATRICULA:', id)
WHERE matricula_codigo IS NULL;

WITH base AS (
    SELECT
        calificacion.id AS calificacion_id,
        LEFT(CONCAT(
            calificacion.matricula_codigo, ':',
            COALESCE(periodo.id::text, 'SIN-CICLO'), ':',
            COALESCE(NULLIF(curso.codigo, ''), 'SIN-MATERIA'), ':',
            COALESCE(NULLIF(oferta.paralelo, ''), 'SIN-PARALELO'), ':',
            COALESCE(NULLIF(docente.identificacion, ''), oferta.docente_id::text, 'SIN-DOCENTE')
        ), 200) AS codigo,
        calificacion.matricula_codigo,
        COALESCE(calificacion.estudiante_id, matricula.estudiante_id) AS estudiante_id,
        estudiante.identificacion AS estudiante_cedula,
        COALESCE(calificacion.oferta_curso_id, matricula.oferta_curso_id) AS oferta_curso_id,
        COALESCE(periodo.id::text, 'SIN-CICLO') AS ciclo_acad_codigo,
        COALESCE(NULLIF(curso.codigo, ''), 'SIN-MATERIA') AS materia_codigo,
        COALESCE(NULLIF(oferta.paralelo, ''), 'SIN-PARALELO') AS paralelo_codigo,
        COALESCE(NULLIF(docente.identificacion, ''), oferta.docente_id::text) AS docente_cedula,
        CASE
            WHEN matricula.estado = 'aprobado' THEN 'aprobado'
            WHEN matricula.estado = 'reprobado' THEN 'reprobado'
            WHEN matricula.estado IN ('retirado', 'anulado') THEN 'anulado'
            ELSE 'activo'
        END AS estado,
        matricula.nota_final
    FROM calificaciones AS calificacion
    LEFT JOIN matriculas AS matricula
        ON matricula.id::text = calificacion.matricula_codigo
    LEFT JOIN usuarios AS estudiante
        ON estudiante.id = COALESCE(calificacion.estudiante_id, matricula.estudiante_id)
    LEFT JOIN ofertas_curso AS oferta
        ON oferta.id = COALESCE(calificacion.oferta_curso_id, matricula.oferta_curso_id)
    LEFT JOIN usuarios AS docente
        ON docente.id = oferta.docente_id
    LEFT JOIN cursos AS curso
        ON curso.id = oferta.curso_id
    LEFT JOIN periodos_academicos AS periodo
        ON periodo.id = oferta.periodo_id
    WHERE calificacion.matricula_asignatura_codigo IS NULL
)
INSERT INTO matricula_asignaturas (
    codigo,
    matricula_codigo,
    estudiante_id,
    estudiante_cedula,
    oferta_curso_id,
    ciclo_acad_codigo,
    materia_codigo,
    paralelo_codigo,
    docente_cedula,
    estado,
    nota_final
)
SELECT DISTINCT ON (codigo)
    codigo,
    matricula_codigo,
    estudiante_id,
    estudiante_cedula,
    oferta_curso_id,
    ciclo_acad_codigo,
    materia_codigo,
    paralelo_codigo,
    docente_cedula,
    estado,
    nota_final
FROM base
ORDER BY codigo, estudiante_id NULLS LAST, oferta_curso_id NULLS LAST
ON CONFLICT (codigo) DO UPDATE
SET
    matricula_codigo = EXCLUDED.matricula_codigo,
    estudiante_id = COALESCE(matricula_asignaturas.estudiante_id, EXCLUDED.estudiante_id),
    estudiante_cedula = COALESCE(matricula_asignaturas.estudiante_cedula, EXCLUDED.estudiante_cedula),
    oferta_curso_id = COALESCE(matricula_asignaturas.oferta_curso_id, EXCLUDED.oferta_curso_id),
    ciclo_acad_codigo = EXCLUDED.ciclo_acad_codigo,
    materia_codigo = EXCLUDED.materia_codigo,
    paralelo_codigo = EXCLUDED.paralelo_codigo,
    docente_cedula = COALESCE(matricula_asignaturas.docente_cedula, EXCLUDED.docente_cedula),
    estado = EXCLUDED.estado,
    nota_final = COALESCE(matricula_asignaturas.nota_final, EXCLUDED.nota_final),
    actualizado_en = NOW();

WITH base AS (
    SELECT
        calificacion.id AS calificacion_id,
        LEFT(CONCAT(
            calificacion.matricula_codigo, ':',
            COALESCE(periodo.id::text, 'SIN-CICLO'), ':',
            COALESCE(NULLIF(curso.codigo, ''), 'SIN-MATERIA'), ':',
            COALESCE(NULLIF(oferta.paralelo, ''), 'SIN-PARALELO'), ':',
            COALESCE(NULLIF(docente.identificacion, ''), oferta.docente_id::text, 'SIN-DOCENTE')
        ), 200) AS codigo
    FROM calificaciones AS calificacion
    LEFT JOIN matriculas AS matricula
        ON matricula.id::text = calificacion.matricula_codigo
    LEFT JOIN ofertas_curso AS oferta
        ON oferta.id = COALESCE(calificacion.oferta_curso_id, matricula.oferta_curso_id)
    LEFT JOIN usuarios AS docente
        ON docente.id = oferta.docente_id
    LEFT JOIN cursos AS curso
        ON curso.id = oferta.curso_id
    LEFT JOIN periodos_academicos AS periodo
        ON periodo.id = oferta.periodo_id
    WHERE calificacion.matricula_asignatura_codigo IS NULL
)
UPDATE calificaciones AS calificacion
SET matricula_asignatura_codigo = base.codigo
FROM base
WHERE calificacion.id = base.calificacion_id;

INSERT INTO matricula_asignaturas (
    codigo,
    matricula_codigo,
    estudiante_id,
    oferta_curso_id,
    ciclo_acad_codigo,
    materia_codigo,
    paralelo_codigo
)
SELECT DISTINCT ON (calificacion.matricula_asignatura_codigo)
    calificacion.matricula_asignatura_codigo,
    calificacion.matricula_codigo,
    calificacion.estudiante_id,
    calificacion.oferta_curso_id,
    'SIN-CICLO',
    'SIN-MATERIA',
    'SIN-PARALELO'
FROM calificaciones AS calificacion
WHERE calificacion.matricula_asignatura_codigo IS NOT NULL
  AND NOT EXISTS (
      SELECT 1
      FROM matricula_asignaturas AS matricula_asignatura
      WHERE matricula_asignatura.codigo = calificacion.matricula_asignatura_codigo
  )
ORDER BY calificacion.matricula_asignatura_codigo, calificacion.id
ON CONFLICT (codigo) DO NOTHING;

ALTER TABLE calificaciones
    ALTER COLUMN matricula_codigo SET NOT NULL,
    ALTER COLUMN matricula_asignatura_codigo SET NOT NULL;

ALTER TABLE calificaciones
    DROP CONSTRAINT IF EXISTS fk_calificaciones_matricula_asignatura;

ALTER TABLE calificaciones
    ADD CONSTRAINT fk_calificaciones_matricula_asignatura
        FOREIGN KEY (matricula_asignatura_codigo)
        REFERENCES matricula_asignaturas(codigo)
        ON UPDATE CASCADE
        ON DELETE RESTRICT;

ALTER TABLE calificaciones
    DROP CONSTRAINT IF EXISTS fk_calificaciones_matricula;

DROP INDEX IF EXISTS academico.uq_calificaciones_matricula_componente_activa;
DROP INDEX IF EXISTS academico.uq_calificaciones_matricula_componente_vigente;
DROP INDEX IF EXISTS academico.uq_calificaciones_matricula_codigo_componente_activa;
DROP INDEX IF EXISTS academico.uq_calificaciones_matricula_codigo_componente_vigente;
DROP INDEX IF EXISTS academico.idx_calificaciones_matricula;
DROP INDEX IF EXISTS academico.idx_calificaciones_matricula_id;

ALTER TABLE calificaciones
    DROP COLUMN IF EXISTS matricula_id;

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

CREATE INDEX IF NOT EXISTS idx_matricula_asignaturas_matricula
    ON matricula_asignaturas(matricula_codigo);
CREATE INDEX IF NOT EXISTS idx_matricula_asignaturas_estudiante
    ON matricula_asignaturas(estudiante_id);
CREATE INDEX IF NOT EXISTS idx_matricula_asignaturas_estudiante_cedula
    ON matricula_asignaturas(estudiante_cedula);
CREATE INDEX IF NOT EXISTS idx_matricula_asignaturas_ciclo
    ON matricula_asignaturas(ciclo_acad_codigo);
CREATE INDEX IF NOT EXISTS idx_matricula_asignaturas_materia
    ON matricula_asignaturas(materia_codigo);
CREATE INDEX IF NOT EXISTS idx_calificaciones_matricula_asignatura
    ON calificaciones(matricula_asignatura_codigo);
CREATE INDEX IF NOT EXISTS idx_calificaciones_matricula_codigo
    ON calificaciones(matricula_codigo);

DROP TRIGGER IF EXISTS trg_matricula_asignaturas_actualizado ON matricula_asignaturas;
CREATE TRIGGER trg_matricula_asignaturas_actualizado
BEFORE UPDATE ON matricula_asignaturas
FOR EACH ROW
EXECUTE FUNCTION actualizar_fecha_modificacion();
