-- ============================================================
-- MALLAS CURRICULARES Y CURSOS POR NIVEL (V6)
-- ============================================================
--
-- Mantiene cursos como catalogo reutilizable y mueve la ubicacion de una
-- materia dentro de una carrera a una malla curricular versionada.
-- Esto permite consultar, por ejemplo, materias de primer nivel de la
-- malla vigente de Software sin fijar el semestre directamente en cursos.

BEGIN;

SET search_path TO academico, public;

-- ============================================================
-- TABLA: mallas_curriculares
-- ============================================================

CREATE TABLE IF NOT EXISTS mallas_curriculares (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    carrera_id BIGINT NOT NULL,
    codigo VARCHAR(50) NOT NULL UNIQUE,
    nombre VARCHAR(150) NOT NULL,
    version VARCHAR(30) NOT NULL,
    fecha_inicio DATE NOT NULL DEFAULT CURRENT_DATE,
    fecha_fin DATE,
    vigente BOOLEAN NOT NULL DEFAULT FALSE,
    estado VARCHAR(20) NOT NULL DEFAULT 'activa',
    creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_mallas_curriculares_carrera
        FOREIGN KEY (carrera_id)
        REFERENCES carreras(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_mallas_curriculares_estado
        CHECK (estado IN ('borrador', 'activa', 'inactiva', 'archivada')),

    CONSTRAINT chk_mallas_curriculares_fechas
        CHECK (fecha_fin IS NULL OR fecha_fin > fecha_inicio),

    CONSTRAINT uq_mallas_curriculares_carrera_version
        UNIQUE (carrera_id, version)
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_mallas_curriculares_vigente_por_carrera
ON mallas_curriculares(carrera_id)
WHERE vigente IS TRUE;

CREATE INDEX IF NOT EXISTS idx_mallas_curriculares_carrera_id
ON mallas_curriculares(carrera_id);

CREATE INDEX IF NOT EXISTS idx_mallas_curriculares_estado
ON mallas_curriculares(estado);

DROP TRIGGER IF EXISTS trg_mallas_curriculares_actualizado ON mallas_curriculares;

CREATE TRIGGER trg_mallas_curriculares_actualizado
BEFORE UPDATE ON mallas_curriculares
FOR EACH ROW
EXECUTE FUNCTION actualizar_fecha_modificacion();

-- ============================================================
-- TABLA: malla_cursos
-- ============================================================

CREATE TABLE IF NOT EXISTS malla_cursos (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    malla_id BIGINT NOT NULL,
    curso_id BIGINT NOT NULL,
    nivel_periodo INTEGER NOT NULL,
    orden INTEGER NOT NULL DEFAULT 1,
    tipo VARCHAR(30) NOT NULL DEFAULT 'obligatoria',
    estado VARCHAR(20) NOT NULL DEFAULT 'activa',
    creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_malla_cursos_malla
        FOREIGN KEY (malla_id)
        REFERENCES mallas_curriculares(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT fk_malla_cursos_curso
        FOREIGN KEY (curso_id)
        REFERENCES cursos(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_malla_cursos_nivel_periodo
        CHECK (nivel_periodo > 0),

    CONSTRAINT chk_malla_cursos_orden
        CHECK (orden > 0),

    CONSTRAINT chk_malla_cursos_tipo
        CHECK (tipo IN ('obligatoria', 'optativa', 'itinerario', 'practica', 'titulacion')),

    CONSTRAINT chk_malla_cursos_estado
        CHECK (estado IN ('activa', 'inactiva')),

    CONSTRAINT uq_malla_cursos_malla_curso
        UNIQUE (malla_id, curso_id),

    CONSTRAINT uq_malla_cursos_malla_nivel_orden
        UNIQUE (malla_id, nivel_periodo, orden)
);

CREATE INDEX IF NOT EXISTS idx_malla_cursos_malla_id
ON malla_cursos(malla_id);

CREATE INDEX IF NOT EXISTS idx_malla_cursos_curso_id
ON malla_cursos(curso_id);

CREATE INDEX IF NOT EXISTS idx_malla_cursos_nivel_periodo
ON malla_cursos(nivel_periodo);

DROP TRIGGER IF EXISTS trg_malla_cursos_actualizado ON malla_cursos;

CREATE TRIGGER trg_malla_cursos_actualizado
BEFORE UPDATE ON malla_cursos
FOR EACH ROW
EXECUTE FUNCTION actualizar_fecha_modificacion();

-- ============================================================
-- TABLA: malla_curso_prerrequisitos
-- ============================================================

CREATE TABLE IF NOT EXISTS malla_curso_prerrequisitos (
    malla_curso_id BIGINT NOT NULL,
    prerrequisito_malla_curso_id BIGINT NOT NULL,
    tipo VARCHAR(30) NOT NULL DEFAULT 'obligatorio',
    creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_malla_curso_prerrequisitos
        PRIMARY KEY (malla_curso_id, prerrequisito_malla_curso_id),

    CONSTRAINT fk_malla_curso_prerrequisitos_curso
        FOREIGN KEY (malla_curso_id)
        REFERENCES malla_cursos(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT fk_malla_curso_prerrequisitos_requisito
        FOREIGN KEY (prerrequisito_malla_curso_id)
        REFERENCES malla_cursos(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_malla_curso_prerrequisitos_distinto
        CHECK (malla_curso_id <> prerrequisito_malla_curso_id),

    CONSTRAINT chk_malla_curso_prerrequisitos_tipo
        CHECK (tipo IN ('obligatorio', 'correquisito', 'recomendado'))
);

CREATE INDEX IF NOT EXISTS idx_malla_curso_prerrequisitos_requisito
ON malla_curso_prerrequisitos(prerrequisito_malla_curso_id);

-- ============================================================
-- SEMILLAS: malla vigente inicial por carrera
-- ============================================================

INSERT INTO mallas_curriculares (
    carrera_id,
    codigo,
    nombre,
    version,
    fecha_inicio,
    vigente,
    estado
)
SELECT
    c.id,
    c.codigo || '-MALLA-2026',
    'Malla curricular vigente - ' || c.nombre,
    '2026',
    DATE '2026-01-01',
    TRUE,
    'activa'
FROM carreras c
ON CONFLICT (carrera_id, version) DO UPDATE SET
    codigo = EXCLUDED.codigo,
    nombre = EXCLUDED.nombre,
    fecha_inicio = EXCLUDED.fecha_inicio,
    vigente = EXCLUDED.vigente,
    estado = EXCLUDED.estado;

-- Mapear los cursos existentes a la malla vigente de su carrera. La
-- mayoria de semillas actuales representan materias iniciales; se deja
-- INF-201 en nivel 2 para reflejar una progresion minima de Software.
WITH cursos_malla AS (
    SELECT
        m.id AS malla_id,
        cu.id AS curso_id,
        CASE
            WHEN cu.codigo = 'INF-201' THEN 2
            ELSE 1
        END AS nivel_periodo,
        ROW_NUMBER() OVER (
            PARTITION BY
                m.id,
                CASE
                    WHEN cu.codigo = 'INF-201' THEN 2
                    ELSE 1
                END
            ORDER BY
                CASE cu.codigo
                    WHEN 'INF-101' THEN 1
                    WHEN 'INF-102' THEN 2
                    WHEN 'SOFT-101' THEN 3
                    WHEN 'INF-201' THEN 1
                    ELSE 10
                END,
                cu.codigo
        ) AS orden
    FROM cursos cu
    INNER JOIN carreras c
        ON c.id = cu.carrera_id
    INNER JOIN mallas_curriculares m
        ON m.carrera_id = c.id
       AND m.version = '2026'
    WHERE cu.estado = 'activo'
)
INSERT INTO malla_cursos (
    malla_id,
    curso_id,
    nivel_periodo,
    orden,
    tipo,
    estado
)
SELECT
    malla_id,
    curso_id,
    nivel_periodo,
    orden,
    'obligatoria',
    'activa'
FROM cursos_malla
ON CONFLICT (malla_id, curso_id) DO UPDATE SET
    nivel_periodo = EXCLUDED.nivel_periodo,
    orden = EXCLUDED.orden,
    tipo = EXCLUDED.tipo,
    estado = EXCLUDED.estado;

-- Prerrequisito inicial para la malla de Software.
INSERT INTO malla_curso_prerrequisitos (
    malla_curso_id,
    prerrequisito_malla_curso_id,
    tipo
)
SELECT
    mc_destino.id,
    mc_requisito.id,
    'obligatorio'
FROM malla_cursos mc_destino
INNER JOIN cursos curso_destino
    ON curso_destino.id = mc_destino.curso_id
INNER JOIN malla_cursos mc_requisito
    ON mc_requisito.malla_id = mc_destino.malla_id
INNER JOIN cursos curso_requisito
    ON curso_requisito.id = mc_requisito.curso_id
WHERE curso_destino.codigo = 'INF-201'
  AND curso_requisito.codigo = 'INF-101'
ON CONFLICT (malla_curso_id, prerrequisito_malla_curso_id) DO UPDATE SET
    tipo = EXCLUDED.tipo;

-- ============================================================
-- VISTA DE CONSULTA PARA MALLAS VIGENTES
-- ============================================================

CREATE OR REPLACE VIEW v_malla_cursos_vigente AS
SELECT
    f.id AS facultad_id,
    f.codigo AS facultad_codigo,
    f.nombre AS facultad_nombre,
    c.id AS carrera_id,
    c.codigo AS carrera_codigo,
    c.nombre AS carrera_nombre,
    m.id AS malla_id,
    m.codigo AS malla_codigo,
    m.version AS malla_version,
    mc.nivel_periodo,
    mc.orden,
    mc.tipo,
    cu.id AS curso_id,
    cu.codigo AS curso_codigo,
    cu.nombre AS curso_nombre,
    cu.creditos,
    cu.estado AS curso_estado
FROM mallas_curriculares m
INNER JOIN carreras c
    ON c.id = m.carrera_id
LEFT JOIN facultades f
    ON f.id = c.facultad_id
INNER JOIN malla_cursos mc
    ON mc.malla_id = m.id
INNER JOIN cursos cu
    ON cu.id = mc.curso_id
WHERE m.vigente IS TRUE
  AND m.estado = 'activa'
  AND mc.estado = 'activa';

COMMENT ON TABLE mallas_curriculares IS
'Versiones de malla curricular por carrera. Permite mantener mallas historicas y una vigente.';

COMMENT ON TABLE malla_cursos IS
'Ubicacion de cursos dentro de una malla curricular, incluyendo nivel/periodo y orden.';

COMMENT ON TABLE malla_curso_prerrequisitos IS
'Prerrequisitos definidos dentro de una version especifica de malla curricular.';

COMMENT ON VIEW v_malla_cursos_vigente IS
'Vista de consulta para materias de la malla vigente por carrera, facultad y nivel_periodo.';

COMMIT;
