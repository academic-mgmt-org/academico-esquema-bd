-- ============================================================
-- MIGRACIÓN DE SIMPLIFICACIÓN DE ESQUEMA (V2)
-- ============================================================

-- Asegurar que trabajamos en el esquema academico
SET search_path TO academico, public;

-- 1. Eliminar vistas originales si existen
DROP VIEW IF EXISTS v_calificaciones_estudiante CASCADE;
DROP VIEW IF EXISTS v_detalle_paralelos CASCADE;
DROP VIEW IF EXISTS v_matriculas_estudiante CASCADE;

-- 2. Eliminar las 28 tablas originales si existen
DROP TABLE IF EXISTS registros_auditoria CASCADE;
DROP TABLE IF EXISTS notificaciones CASCADE;
DROP TABLE IF EXISTS documentos_estudiante CASCADE;
DROP TABLE IF EXISTS solicitudes_academicas CASCADE;
DROP TABLE IF EXISTS registro_asistencia CASCADE;
DROP TABLE IF EXISTS sesiones_asistencia CASCADE;
DROP TABLE IF EXISTS calificaciones CASCADE;
DROP TABLE IF EXISTS componentes_calificacion CASCADE;
DROP TABLE IF EXISTS matricula_asignaturas CASCADE;
DROP TABLE IF EXISTS matriculas CASCADE;
DROP TABLE IF EXISTS horarios_paralelos CASCADE;
DROP TABLE IF EXISTS paralelos CASCADE;
DROP TABLE IF EXISTS aulas CASCADE;
DROP TABLE IF EXISTS periodos_academicos CASCADE;
DROP TABLE IF EXISTS personal_administrativo CASCADE;
DROP TABLE IF EXISTS docentes CASCADE;
DROP TABLE IF EXISTS estudiantes CASCADE;
DROP TABLE IF EXISTS prerrequisitos_asignaturas CASCADE;
DROP TABLE IF EXISTS malla_asignaturas CASCADE;
DROP TABLE IF EXISTS asignaturas CASCADE;
DROP TABLE IF EXISTS mallas_curriculares CASCADE;
DROP TABLE IF EXISTS carreras CASCADE;
DROP TABLE IF EXISTS facultades CASCADE;
DROP TABLE IF EXISTS rol_permisos CASCADE;
DROP TABLE IF EXISTS usuario_roles CASCADE;
DROP TABLE IF EXISTS permisos CASCADE;
DROP TABLE IF EXISTS usuarios CASCADE;
DROP TABLE IF EXISTS roles CASCADE;

-- 3. Eliminar tipos ENUM originales si existen
DROP TYPE IF EXISTS estado_usuario CASCADE;
DROP TYPE IF EXISTS estado_general CASCADE;
DROP TYPE IF EXISTS estado_persona_academica CASCADE;
DROP TYPE IF EXISTS estado_periodo CASCADE;
DROP TYPE IF EXISTS estado_paralelo CASCADE;
DROP TYPE IF EXISTS estado_matricula CASCADE;
DROP TYPE IF EXISTS estado_asignatura_matricula CASCADE;
DROP TYPE IF EXISTS tipo_solicitud CASCADE;
DROP TYPE IF EXISTS estado_solicitud CASCADE;
DROP TYPE IF EXISTS estado_asistencia CASCADE;
DROP TYPE IF EXISTS estado_notificacion CASCADE;
DROP TYPE IF EXISTS estado_documento CASCADE;
DROP TYPE IF EXISTS modalidad_asignatura CASCADE;
DROP TYPE IF EXISTS nivel_programa CASCADE;

-- 4. Eliminar funciones antiguas si existen
DROP FUNCTION IF EXISTS actualizar_fecha_modificacion() CASCADE;

-- ============================================================
-- NUEVO MODELO MÍNIMO CON 8 TABLAS
-- ============================================================

-- Eliminar tablas del nuevo esquema si ya existen (por seguridad)
DROP TABLE IF EXISTS solicitudes_administrativas CASCADE;
DROP TABLE IF EXISTS calificaciones CASCADE;
DROP TABLE IF EXISTS matriculas CASCADE;
DROP TABLE IF EXISTS ofertas_curso CASCADE;
DROP TABLE IF EXISTS cursos CASCADE;
DROP TABLE IF EXISTS periodos_academicos CASCADE;
DROP TABLE IF EXISTS usuarios CASCADE;
DROP TABLE IF EXISTS roles CASCADE;

-- ============================================================
-- 1. TABLA: roles
-- ============================================================

CREATE TABLE roles (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    descripcion TEXT,
    estado VARCHAR(20) NOT NULL DEFAULT 'activo',
    creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_roles_estado
        CHECK (estado IN ('activo', 'inactivo'))
);

-- ============================================================
-- 2. TABLA: usuarios
-- ============================================================

CREATE TABLE usuarios (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    rol_id BIGINT NOT NULL,
    nombres VARCHAR(100) NOT NULL,
    apellidos VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    identificacion VARCHAR(20) UNIQUE,
    telefono VARCHAR(20),
    estado VARCHAR(20) NOT NULL DEFAULT 'activo',
    creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_usuarios_roles
        FOREIGN KEY (rol_id)
        REFERENCES roles(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_usuarios_estado
        CHECK (estado IN ('activo', 'inactivo', 'bloqueado'))
);

-- ============================================================
-- 3. TABLA: periodos_academicos
-- ============================================================

CREATE TABLE periodos_academicos (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'planificado',
    creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_periodos_fechas
        CHECK (fecha_fin > fecha_inicio),

    CONSTRAINT chk_periodos_estado
        CHECK (estado IN ('planificado', 'activo', 'cerrado', 'cancelado'))
);

-- ============================================================
-- 4. TABLA: cursos
-- ============================================================

CREATE TABLE cursos (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo VARCHAR(30) NOT NULL UNIQUE,
    nombre VARCHAR(150) NOT NULL,
    descripcion TEXT,
    creditos INTEGER NOT NULL DEFAULT 0,
    estado VARCHAR(20) NOT NULL DEFAULT 'activo',
    creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_cursos_creditos
        CHECK (creditos >= 0),

    CONSTRAINT chk_cursos_estado
        CHECK (estado IN ('activo', 'inactivo'))
);

-- ============================================================
-- 5. TABLA: ofertas_curso
-- Curso abierto en un periodo específico
-- ============================================================

CREATE TABLE ofertas_curso (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    curso_id BIGINT NOT NULL,
    periodo_id BIGINT NOT NULL,
    docente_id BIGINT,
    paralelo VARCHAR(20) NOT NULL,
    cupo INTEGER NOT NULL DEFAULT 30,
    horario JSONB,
    aula VARCHAR(50),
    estado VARCHAR(20) NOT NULL DEFAULT 'abierta',
    creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_ofertas_curso_cursos
        FOREIGN KEY (curso_id)
        REFERENCES cursos(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_ofertas_curso_periodos
        FOREIGN KEY (periodo_id)
        REFERENCES periodos_academicos(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_ofertas_curso_docente
        FOREIGN KEY (docente_id)
        REFERENCES usuarios(id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    CONSTRAINT chk_ofertas_cupo
        CHECK (cupo > 0),

    CONSTRAINT chk_ofertas_estado
        CHECK (estado IN ('abierta', 'cerrada', 'cancelada')),

    CONSTRAINT uq_oferta_curso_periodo_paralelo
        UNIQUE (curso_id, periodo_id, paralelo)
);

-- ============================================================
-- 6. TABLA: matriculas
-- Relaciona estudiantes con ofertas de curso
-- ============================================================

CREATE TABLE matriculas (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    estudiante_id BIGINT NOT NULL,
    oferta_curso_id BIGINT NOT NULL,
    fecha_matricula TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    estado VARCHAR(20) NOT NULL DEFAULT 'matriculado',
    nota_final NUMERIC(5,2),
    observacion TEXT,
    creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_matriculas_estudiante
        FOREIGN KEY (estudiante_id)
        REFERENCES usuarios(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_matriculas_oferta
        FOREIGN KEY (oferta_curso_id)
        REFERENCES ofertas_curso(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_matriculas_estado
        CHECK (estado IN ('matriculado', 'retirado', 'aprobado', 'reprobado', 'anulado')),

    CONSTRAINT chk_matriculas_nota_final
        CHECK (nota_final IS NULL OR nota_final BETWEEN 0 AND 100),

    CONSTRAINT uq_matricula_estudiante_oferta
        UNIQUE (estudiante_id, oferta_curso_id)
);

-- ============================================================
-- 7. TABLA: calificaciones
-- Permite registrar varias notas por matrícula
-- ============================================================

CREATE TABLE calificaciones (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    matricula_id BIGINT NOT NULL,
    nombre_evaluacion VARCHAR(100) NOT NULL,
    tipo VARCHAR(50) NOT NULL,
    nota NUMERIC(5,2) NOT NULL,
    ponderacion NUMERIC(5,2) NOT NULL DEFAULT 0,
    observacion TEXT,
    fecha_registro TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_calificaciones_matricula
        FOREIGN KEY (matricula_id)
        REFERENCES matriculas(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT chk_calificaciones_nota
        CHECK (nota BETWEEN 0 AND 100),

    CONSTRAINT chk_calificaciones_ponderacion
        CHECK (ponderacion BETWEEN 0 AND 100),

    CONSTRAINT chk_calificaciones_tipo
        CHECK (tipo IN ('tarea', 'leccion', 'examen', 'proyecto', 'participacion', 'otro')),

    CONSTRAINT uq_calificacion_matricula_evaluacion
        UNIQUE (matricula_id, nombre_evaluacion)
);

-- ============================================================
-- 8. TABLA: solicitudes_administrativas
-- ============================================================

CREATE TABLE solicitudes_administrativas (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    estudiante_id BIGINT NOT NULL,
    oferta_curso_id BIGINT,
    matricula_id BIGINT,
    tipo VARCHAR(50) NOT NULL,
    descripcion TEXT NOT NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'pendiente',
    respuesta TEXT,
    resuelto_por BIGINT,
    fecha_solicitud TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_resolucion TIMESTAMP,
    creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_solicitudes_estudiante
        FOREIGN KEY (estudiante_id)
        REFERENCES usuarios(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_solicitudes_oferta
        FOREIGN KEY (oferta_curso_id)
        REFERENCES ofertas_curso(id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    CONSTRAINT fk_solicitudes_matricula
        FOREIGN KEY (matricula_id)
        REFERENCES matriculas(id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    CONSTRAINT fk_solicitudes_resuelto_por
        FOREIGN KEY (resuelto_por)
        REFERENCES usuarios(id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    CONSTRAINT chk_solicitudes_tipo
        CHECK (tipo IN (
            'retiro',
            'cambio_paralelo',
            'revision_nota',
            'justificacion',
            'certificado',
            'otro'
        )),

    CONSTRAINT chk_solicitudes_estado
        CHECK (estado IN ('pendiente', 'en_revision', 'aprobada', 'rechazada', 'cancelada'))
);

-- ============================================================
-- ÍNDICES RECOMENDADOS
-- ============================================================

CREATE INDEX idx_usuarios_rol_id
ON usuarios(rol_id);

CREATE INDEX idx_ofertas_curso_curso_id
ON ofertas_curso(curso_id);

CREATE INDEX idx_ofertas_curso_periodo_id
ON ofertas_curso(periodo_id);

CREATE INDEX idx_ofertas_curso_docente_id
ON ofertas_curso(docente_id);

CREATE INDEX idx_matriculas_estudiante_id
ON matriculas(estudiante_id);

CREATE INDEX idx_matriculas_oferta_curso_id
ON matriculas(oferta_curso_id);

CREATE INDEX idx_calificaciones_matricula_id
ON calificaciones(matricula_id);

CREATE INDEX idx_solicitudes_estudiante_id
ON solicitudes_administrativas(estudiante_id);

CREATE INDEX idx_solicitudes_estado
ON solicitudes_administrativas(estado);

-- ============================================================
-- FUNCIÓN PARA ACTUALIZAR actualizado_en AUTOMÁTICAMENTE
-- ============================================================

CREATE OR REPLACE FUNCTION actualizar_fecha_modificacion()
RETURNS TRIGGER AS $$
BEGIN
    NEW.actualizado_en = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- TRIGGERS PARA actualizado_en
-- ============================================================

CREATE TRIGGER trg_roles_actualizado
BEFORE UPDATE ON roles
FOR EACH ROW
EXECUTE FUNCTION actualizar_fecha_modificacion();

CREATE TRIGGER trg_usuarios_actualizado
BEFORE UPDATE ON usuarios
FOR EACH ROW
EXECUTE FUNCTION actualizar_fecha_modificacion();

CREATE TRIGGER trg_periodos_actualizado
BEFORE UPDATE ON periodos_academicos
FOR EACH ROW
EXECUTE FUNCTION actualizar_fecha_modificacion();

CREATE TRIGGER trg_cursos_actualizado
BEFORE UPDATE ON cursos
FOR EACH ROW
EXECUTE FUNCTION actualizar_fecha_modificacion();

CREATE TRIGGER trg_ofertas_actualizado
BEFORE UPDATE ON ofertas_curso
FOR EACH ROW
EXECUTE FUNCTION actualizar_fecha_modificacion();

CREATE TRIGGER trg_matriculas_actualizado
BEFORE UPDATE ON matriculas
FOR EACH ROW
EXECUTE FUNCTION actualizar_fecha_modificacion();

CREATE TRIGGER trg_calificaciones_actualizado
BEFORE UPDATE ON calificaciones
FOR EACH ROW
EXECUTE FUNCTION actualizar_fecha_modificacion();

CREATE TRIGGER trg_solicitudes_actualizado
BEFORE UPDATE ON solicitudes_administrativas
FOR EACH ROW
EXECUTE FUNCTION actualizar_fecha_modificacion();

-- ============================================================
-- DATOS INICIALES (SEMILLAS)
-- ============================================================

INSERT INTO roles (nombre, descripcion) VALUES
('estudiante', 'Usuario que puede matricularse en cursos y consultar calificaciones'),
('docente', 'Usuario que imparte cursos y registra calificaciones'),
('administrador', 'Usuario con permisos de gestión general del sistema'),
('coordinador', 'Usuario que gestiona procesos académicos y administrativos');
