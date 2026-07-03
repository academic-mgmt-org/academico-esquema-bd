-- ============================================================
-- CORE ASSET CALIFICACIONES (V8)
-- ============================================================
--
-- Alinea el esquema central con academico-calificaciones sin borrar
-- historiales existentes. Si existen calificaciones heredadas por
-- nombre_evaluacion, crea componentes equivalentes y enlaza componente_id.

CREATE SCHEMA IF NOT EXISTS academico;
SET search_path TO academico, public;

CREATE TABLE IF NOT EXISTS componentes_calificacion (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    oferta_curso_id BIGINT,
    paralelo_id VARCHAR(80),
    nombre VARCHAR(150) NOT NULL,
    descripcion TEXT,
    tipo VARCHAR(50) NOT NULL DEFAULT 'otro',
    ponderacion NUMERIC(5,2) NOT NULL,
    puntaje_maximo NUMERIC(5,2) NOT NULL DEFAULT 10,
    fecha_entrega DATE,
    estado VARCHAR(20) NOT NULL DEFAULT 'activo',
    creado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    actualizado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_componentes_calificacion_tipo
        CHECK (tipo IN ('tarea', 'leccion', 'examen', 'proyecto', 'participacion', 'otro')),
    CONSTRAINT chk_componentes_calificacion_ponderacion
        CHECK (ponderacion > 0 AND ponderacion <= 100),
    CONSTRAINT chk_componentes_calificacion_puntaje_maximo
        CHECK (puntaje_maximo > 0 AND puntaje_maximo <= 10),
    CONSTRAINT chk_componentes_calificacion_estado
        CHECK (estado IN ('activo', 'inactivo'))
);

ALTER TABLE calificaciones
    ADD COLUMN IF NOT EXISTS estudiante_id BIGINT,
    ADD COLUMN IF NOT EXISTS oferta_curso_id BIGINT,
    ADD COLUMN IF NOT EXISTS componente_id BIGINT,
    ADD COLUMN IF NOT EXISTS estado VARCHAR(20),
    ADD COLUMN IF NOT EXISTS publicado BOOLEAN,
    ADD COLUMN IF NOT EXISTS registrada_por BIGINT;

ALTER TABLE calificaciones
    ALTER COLUMN nombre_evaluacion TYPE VARCHAR(150);

UPDATE calificaciones AS calificacion
SET
    estudiante_id = COALESCE(calificacion.estudiante_id, matricula.estudiante_id),
    oferta_curso_id = COALESCE(calificacion.oferta_curso_id, matricula.oferta_curso_id)
FROM matriculas AS matricula
WHERE calificacion.matricula_id = matricula.id;

INSERT INTO componentes_calificacion (
    oferta_curso_id,
    paralelo_id,
    nombre,
    descripcion,
    tipo,
    ponderacion,
    puntaje_maximo,
    estado
)
SELECT DISTINCT
    calificacion.oferta_curso_id,
    oferta.paralelo,
    calificacion.nombre_evaluacion,
    'Componente migrado desde calificaciones heredadas',
    calificacion.tipo,
    CASE
        WHEN calificacion.ponderacion > 0 THEN calificacion.ponderacion
        ELSE 1
    END,
    10,
    'activo'
FROM calificaciones AS calificacion
LEFT JOIN ofertas_curso AS oferta
    ON oferta.id = calificacion.oferta_curso_id
WHERE calificacion.componente_id IS NULL
  AND NOT EXISTS (
      SELECT 1
      FROM componentes_calificacion AS componente
      WHERE COALESCE(componente.oferta_curso_id, -1) = COALESCE(calificacion.oferta_curso_id, -1)
        AND COALESCE(componente.paralelo_id, '') = COALESCE(oferta.paralelo, '')
        AND LOWER(componente.nombre) = LOWER(calificacion.nombre_evaluacion)
  );

UPDATE calificaciones AS calificacion
SET componente_id = componente.id
FROM componentes_calificacion AS componente
WHERE calificacion.componente_id IS NULL
  AND COALESCE(componente.oferta_curso_id, -1) = COALESCE(calificacion.oferta_curso_id, -1)
  AND COALESCE(componente.paralelo_id, '') = COALESCE((
      SELECT oferta.paralelo
      FROM ofertas_curso AS oferta
      WHERE oferta.id = calificacion.oferta_curso_id
      LIMIT 1
  ), '')
  AND LOWER(componente.nombre) = LOWER(calificacion.nombre_evaluacion);

UPDATE calificaciones
SET estado = 'borrador'
WHERE estado IS NULL;

UPDATE calificaciones
SET publicado = FALSE
WHERE publicado IS NULL;

ALTER TABLE calificaciones
    ALTER COLUMN estado SET DEFAULT 'borrador',
    ALTER COLUMN estado SET NOT NULL,
    ALTER COLUMN publicado SET DEFAULT FALSE,
    ALTER COLUMN publicado SET NOT NULL,
    ALTER COLUMN componente_id SET NOT NULL;

ALTER TABLE calificaciones
    DROP CONSTRAINT IF EXISTS chk_calificaciones_estado;
ALTER TABLE calificaciones
    ADD CONSTRAINT chk_calificaciones_estado
    CHECK (estado IN ('borrador', 'publicado', 'anulado'));

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.table_constraints
        WHERE constraint_schema = 'academico'
          AND table_name = 'calificaciones'
          AND constraint_name = 'fk_calificaciones_componente_id'
    ) THEN
        ALTER TABLE calificaciones
            ADD CONSTRAINT fk_calificaciones_componente_id
            FOREIGN KEY (componente_id)
            REFERENCES componentes_calificacion(id)
            ON UPDATE CASCADE
            ON DELETE RESTRICT;
    END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS uq_componentes_calificacion_contexto_nombre
    ON componentes_calificacion (
        COALESCE(oferta_curso_id, -1),
        COALESCE(paralelo_id, ''),
        LOWER(nombre)
    );

CREATE UNIQUE INDEX IF NOT EXISTS uq_calificaciones_matricula_componente_vigente
    ON calificaciones (matricula_id, componente_id)
    WHERE estado <> 'anulado';

CREATE INDEX IF NOT EXISTS idx_componentes_calificacion_oferta
    ON componentes_calificacion(oferta_curso_id);
CREATE INDEX IF NOT EXISTS idx_componentes_calificacion_paralelo
    ON componentes_calificacion(paralelo_id);
CREATE INDEX IF NOT EXISTS idx_calificaciones_matricula
    ON calificaciones(matricula_id);
CREATE INDEX IF NOT EXISTS idx_calificaciones_estudiante
    ON calificaciones(estudiante_id);
CREATE INDEX IF NOT EXISTS idx_calificaciones_oferta
    ON calificaciones(oferta_curso_id);
CREATE INDEX IF NOT EXISTS idx_calificaciones_publicado
    ON calificaciones(publicado);
