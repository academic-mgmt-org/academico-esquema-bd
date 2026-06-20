-- ============================================================
-- MIGRACIÓN PARA AGREGAR FACULTADES Y CARRERAS (V3)
-- ============================================================

-- Asegurar que trabajamos en el esquema academico
SET search_path TO academico, public;

-- 1. Crear tabla de facultades
CREATE TABLE facultades (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo VARCHAR(30) NOT NULL UNIQUE,
    nombre VARCHAR(150) NOT NULL,
    descripcion TEXT,
    estado VARCHAR(20) NOT NULL DEFAULT 'activa',
    creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_facultades_estado
        CHECK (estado IN ('activa', 'inactiva', 'cerrada'))
);

-- 2. Crear tabla de carreras
CREATE TABLE carreras (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo VARCHAR(30) NOT NULL UNIQUE,
    nombre VARCHAR(150) NOT NULL,
    descripcion TEXT,
    nivel VARCHAR(50) NOT NULL,
    modalidad VARCHAR(50) NOT NULL,
    duracion_periodos INTEGER,
    estado VARCHAR(20) NOT NULL DEFAULT 'activa',
    creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    facultad_id BIGINT,

    CONSTRAINT chk_carreras_nivel
        CHECK (nivel IN ('tecnologico', 'grado', 'posgrado', 'maestria', 'doctorado')),

    CONSTRAINT chk_carreras_modalidad
        CHECK (modalidad IN ('presencial', 'semipresencial', 'virtual')),

    CONSTRAINT chk_carreras_estado
        CHECK (estado IN ('activa', 'inactiva', 'cerrada')),

    CONSTRAINT fk_carreras_facultad
        FOREIGN KEY (facultad_id)
        REFERENCES facultades(id)
        ON UPDATE CASCADE
        ON DELETE SET NULL
);

-- 3. Relacionar usuarios (estudiantes) con carreras
ALTER TABLE usuarios
ADD COLUMN carrera_id BIGINT;

ALTER TABLE usuarios
ADD CONSTRAINT fk_usuarios_carrera
FOREIGN KEY (carrera_id)
REFERENCES carreras(id)
ON UPDATE CASCADE
ON DELETE SET NULL;

-- 4. Relacionar cursos con carreras
ALTER TABLE cursos
ADD COLUMN carrera_id BIGINT;

ALTER TABLE cursos
ADD CONSTRAINT fk_cursos_carrera
FOREIGN KEY (carrera_id)
REFERENCES carreras(id)
ON UPDATE CASCADE
ON DELETE SET NULL;

-- 5. Crear índices para optimizar las nuevas relaciones
CREATE INDEX idx_carreras_facultad_id ON carreras(facultad_id);
CREATE INDEX idx_usuarios_carrera_id ON usuarios(carrera_id);
CREATE INDEX idx_cursos_carrera_id ON cursos(carrera_id);

-- 6. Agregar triggers para actualizar automáticamente el campo actualizado_en
CREATE TRIGGER trg_facultades_actualizado
BEFORE UPDATE ON facultades
FOR EACH ROW
EXECUTE FUNCTION actualizar_fecha_modificacion();

CREATE TRIGGER trg_carreras_actualizado
BEFORE UPDATE ON carreras
FOR EACH ROW
EXECUTE FUNCTION actualizar_fecha_modificacion();

-- 7. Datos de prueba iniciales (Semillas)
INSERT INTO facultades (
    codigo,
    nombre,
    descripcion
) VALUES (
    'FAC-ING',
    'Facultad de Ingeniería',
    'Facultad encargada de las carreras relacionadas con ingeniería, tecnología y sistemas.'
);

INSERT INTO carreras (
    codigo,
    nombre,
    descripcion,
    nivel,
    modalidad,
    duracion_periodos,
    facultad_id
) VALUES (
    'SOFT-001',
    'Ingeniería de Software',
    'Carrera orientada al desarrollo y gestión de sistemas de software.',
    'grado',
    'presencial',
    10,
    1
);
