-- ============================================================
-- BASE DE DATOS: Sistema de Gestion Academica
-- Motor: PostgreSQL
-- ============================================================

-- IMPORTANTE:
-- Si quieres crear la base desde cero, ejecuta esto separado:
-- CREATE DATABASE academic_management_db;

-- Luego conectate a la base academic_management_db y ejecuta el resto.

-- Si estas en desarrollo y quieres reiniciar todo, puedes descomentar:
-- DROP SCHEMA IF EXISTS academico CASCADE;

CREATE SCHEMA IF NOT EXISTS academico;

SET search_path TO academico, public;

-- ============================================================
-- EXTENSIONES
-- ============================================================

-- CREATE EXTENSION IF NOT EXISTS pgcrypto;
-- CREATE EXTENSION IF NOT EXISTS citext;

-- ============================================================
-- TIPOS ENUM
-- ============================================================

CREATE TYPE estado_usuario AS ENUM (
    'activo',
    'inactivo',
    'bloqueado'
);

CREATE TYPE estado_general AS ENUM (
    'activo',
    'inactivo',
    'archivado'
);

CREATE TYPE estado_persona_academica AS ENUM (
    'activo',
    'inactivo',
    'graduado',
    'suspendido',
    'retirado'
);

CREATE TYPE estado_periodo AS ENUM (
    'planificado',
    'activo',
    'cerrado',
    'archivado'
);

CREATE TYPE estado_paralelo AS ENUM (
    'planificado',
    'abierto',
    'cerrado',
    'cancelado',
    'completado'
);

CREATE TYPE estado_matricula AS ENUM (
    'borrador',
    'pendiente',
    'aprobado',
    'rechazado',
    'cancelado'
);

CREATE TYPE estado_asignatura_matricula AS ENUM (
    'matriculado',
    'retirado',
    'completado',
    'aprobado',
    'reprobado'
);

CREATE TYPE tipo_solicitud AS ENUM (
    'aprobacion_matricula',
    'retiro',
    'cambio_paralelo',
    'revision_calificacion',
    'actualizacion_documento',
    'certificado_academico',
    'otro'
);

CREATE TYPE estado_solicitud AS ENUM (
    'pendiente',
    'en_revision',
    'aprobado',
    'rechazado',
    'cancelado'
);

CREATE TYPE estado_asistencia AS ENUM (
    'presente',
    'ausente',
    'atraso',
    'justificado'
);

CREATE TYPE estado_notificacion AS ENUM (
    'no_leido',
    'leido'
);

CREATE TYPE estado_documento AS ENUM (
    'pendiente',
    'aprobado',
    'rechazado'
);

CREATE TYPE modalidad_asignatura AS ENUM (
    'presencial',
    'virtual',
    'hibrida'
);

CREATE TYPE nivel_programa AS ENUM (
    'pregrado',
    'posgrado'
);

-- ============================================================
-- FUNCION PARA actualizado_at
-- ============================================================

CREATE OR REPLACE FUNCTION academico.establecer_actualizado_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.actualizado_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- USUARIOS, ROLES Y PERMISOS
-- ============================================================

CREATE TABLE usuarios (
    usuario_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre_completo VARCHAR(150) NOT NULL,
    correo_electronico VARCHAR(255) NOT NULL UNIQUE,
    clave_hash VARCHAR(255) NOT NULL,
    telefono VARCHAR(30),
    avatar_url TEXT,
    estado estado_usuario NOT NULL DEFAULT 'activo',
    ultimo_ingreso_at TIMESTAMP,
    creado_at TIMESTAMP NOT NULL DEFAULT NOW(),
    actualizado_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE roles (
    rol_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre VARCHAR(50) NOT NULL UNIQUE,
    descripcion TEXT,
    creado_at TIMESTAMP NOT NULL DEFAULT NOW(),
    actualizado_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE permisos (
    permiso_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    codigo VARCHAR(100) NOT NULL UNIQUE,
    descripcion TEXT,
    creado_at TIMESTAMP NOT NULL DEFAULT NOW(),
    actualizado_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE usuario_roles (
    usuario_id UUID NOT NULL,
    rol_id UUID NOT NULL,
    asignado_at TIMESTAMP NOT NULL DEFAULT NOW(),

    PRIMARY KEY (usuario_id, rol_id),

    CONSTRAINT fk_usuario_roles_usuario
        FOREIGN KEY (usuario_id)
        REFERENCES usuarios(usuario_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_usuario_roles_rol
        FOREIGN KEY (rol_id)
        REFERENCES roles(rol_id)
        ON DELETE CASCADE
);

CREATE TABLE rol_permisos (
    rol_id UUID NOT NULL,
    permiso_id UUID NOT NULL,
    asignado_at TIMESTAMP NOT NULL DEFAULT NOW(),

    PRIMARY KEY (rol_id, permiso_id),

    CONSTRAINT fk_rol_permisos_rol
        FOREIGN KEY (rol_id)
        REFERENCES roles(rol_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_rol_permisos_permiso
        FOREIGN KEY (permiso_id)
        REFERENCES permisos(permiso_id)
        ON DELETE CASCADE
);

-- ============================================================
-- ESTRUCTURA ACADEMICA
-- Facultades, carreras, mallas y asignaturas
-- ============================================================

CREATE TABLE facultades (
    facultad_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    codigo VARCHAR(30) NOT NULL UNIQUE,
    nombre VARCHAR(150) NOT NULL,
    descripcion TEXT,
    estado estado_general NOT NULL DEFAULT 'activo',
    creado_at TIMESTAMP NOT NULL DEFAULT NOW(),
    actualizado_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE carreras (
    carrera_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    facultad_id UUID NOT NULL,
    codigo VARCHAR(30) NOT NULL UNIQUE,
    nombre VARCHAR(150) NOT NULL,
    titulo_otorgado VARCHAR(150),
    duracion_semestres INT NOT NULL,
    nivel_academico nivel_programa NOT NULL DEFAULT 'pregrado',
    estado estado_general NOT NULL DEFAULT 'activo',
    creado_at TIMESTAMP NOT NULL DEFAULT NOW(),
    actualizado_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_carreras_facultad
        FOREIGN KEY (facultad_id)
        REFERENCES facultades(facultad_id),

    CONSTRAINT chk_carrera_duracion
        CHECK (duracion_semestres > 0)
);

CREATE TABLE mallas_curriculares (
    malla_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    carrera_id UUID NOT NULL,
    version VARCHAR(50) NOT NULL,
    nombre VARCHAR(150) NOT NULL,
    anio_inicio INT,
    estado estado_general NOT NULL DEFAULT 'activo',
    creado_at TIMESTAMP NOT NULL DEFAULT NOW(),
    actualizado_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_mallas_carrera
        FOREIGN KEY (carrera_id)
        REFERENCES carreras(carrera_id),

    CONSTRAINT uq_malla_carrera_version
        UNIQUE (carrera_id, version)
);

CREATE TABLE asignaturas (
    asignatura_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    codigo VARCHAR(30) NOT NULL UNIQUE,
    nombre VARCHAR(150) NOT NULL,
    descripcion TEXT,
    creditos INT NOT NULL DEFAULT 0,
    horas_teoria INT NOT NULL DEFAULT 0,
    horas_practica INT NOT NULL DEFAULT 0,
    estado estado_general NOT NULL DEFAULT 'activo',
    creado_at TIMESTAMP NOT NULL DEFAULT NOW(),
    actualizado_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_asignatura_creditos
        CHECK (creditos >= 0),

    CONSTRAINT chk_asignatura_horas
        CHECK (horas_teoria >= 0 AND horas_practica >= 0)
);

CREATE TABLE malla_asignaturas (
    malla_asignatura_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    malla_id UUID NOT NULL,
    asignatura_id UUID NOT NULL,
    numero_semestre INT NOT NULL,
    es_obligatoria BOOLEAN NOT NULL DEFAULT TRUE,
    creado_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_malla_asignaturas_malla
        FOREIGN KEY (malla_id)
        REFERENCES mallas_curriculares(malla_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_malla_asignaturas_asignatura
        FOREIGN KEY (asignatura_id)
        REFERENCES asignaturas(asignatura_id),

    CONSTRAINT chk_malla_semestre
        CHECK (numero_semestre > 0),

    CONSTRAINT uq_malla_asignatura
        UNIQUE (malla_id, asignatura_id)
);

CREATE TABLE prerrequisitos_asignaturas (
    asignatura_id UUID NOT NULL,
    asignatura_prerrequisito_id UUID NOT NULL,

    PRIMARY KEY (asignatura_id, asignatura_prerrequisito_id),

    CONSTRAINT fk_prerrequisitos_asignatura
        FOREIGN KEY (asignatura_id)
        REFERENCES asignaturas(asignatura_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_prerrequisitos_prerrequisito
        FOREIGN KEY (asignatura_prerrequisito_id)
        REFERENCES asignaturas(asignatura_id)
        ON DELETE CASCADE,

    CONSTRAINT chk_no_auto_prerrequisito
        CHECK (asignatura_id <> asignatura_prerrequisito_id)
);

-- ============================================================
-- PERSONAS ACADEMICAS
-- Estudiantes, docentes y personal administrativo
-- ============================================================

CREATE TABLE estudiantes (
    estudiante_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID NOT NULL UNIQUE,
    carrera_id UUID NOT NULL,
    malla_id UUID,
    codigo_estudiante VARCHAR(50) NOT NULL UNIQUE,
    numero_documento VARCHAR(50) UNIQUE,
    fecha_nacimiento DATE,
    direccion VARCHAR(255),
    telefono VARCHAR(30),
    fecha_admision DATE,
    semestre_actual INT DEFAULT 1,
    estado estado_persona_academica NOT NULL DEFAULT 'activo',
    creado_at TIMESTAMP NOT NULL DEFAULT NOW(),
    actualizado_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_estudiantes_usuario
        FOREIGN KEY (usuario_id)
        REFERENCES usuarios(usuario_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_estudiantes_carrera
        FOREIGN KEY (carrera_id)
        REFERENCES carreras(carrera_id),

    CONSTRAINT fk_estudiantes_malla
        FOREIGN KEY (malla_id)
        REFERENCES mallas_curriculares(malla_id),

    CONSTRAINT chk_estudiante_semestre
        CHECK (semestre_actual IS NULL OR semestre_actual > 0)
);

CREATE TABLE docentes (
    docente_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID NOT NULL UNIQUE,
    facultad_id UUID,
    codigo_docente VARCHAR(50) NOT NULL UNIQUE,
    numero_documento VARCHAR(50) UNIQUE,
    especialidad VARCHAR(150),
    titulo_academico VARCHAR(150),
    fecha_contratacion DATE,
    estado estado_general NOT NULL DEFAULT 'activo',
    creado_at TIMESTAMP NOT NULL DEFAULT NOW(),
    actualizado_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_docentes_usuario
        FOREIGN KEY (usuario_id)
        REFERENCES usuarios(usuario_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_docentes_facultad
        FOREIGN KEY (facultad_id)
        REFERENCES facultades(facultad_id)
);

CREATE TABLE personal_administrativo (
    personal_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID NOT NULL UNIQUE,
    codigo_personal VARCHAR(50) NOT NULL UNIQUE,
    nombre_departamento VARCHAR(150),
    cargo VARCHAR(150),
    estado estado_general NOT NULL DEFAULT 'activo',
    creado_at TIMESTAMP NOT NULL DEFAULT NOW(),
    actualizado_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_personal_usuario
        FOREIGN KEY (usuario_id)
        REFERENCES usuarios(usuario_id)
        ON DELETE CASCADE
);

-- ============================================================
-- PERIODOS ACADEMICOS
-- ============================================================

CREATE TABLE periodos_academicos (
    periodo_academico_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    codigo VARCHAR(50) NOT NULL UNIQUE,
    nombre VARCHAR(150) NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    fecha_inicio_matriculacion DATE,
    fecha_fin_matriculacion DATE,
    fecha_inicio_calificaciones DATE,
    fecha_fin_calificaciones DATE,
    estado estado_periodo NOT NULL DEFAULT 'planificado',
    creado_at TIMESTAMP NOT NULL DEFAULT NOW(),
    actualizado_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_periodo_fechas
        CHECK (fecha_inicio < fecha_fin),

    CONSTRAINT chk_matriculacion_fechas
        CHECK (
            fecha_inicio_matriculacion IS NULL
            OR fecha_fin_matriculacion IS NULL
            OR fecha_inicio_matriculacion <= fecha_fin_matriculacion
        ),

    CONSTRAINT chk_calificaciones_fechas
        CHECK (
            fecha_inicio_calificaciones IS NULL
            OR fecha_fin_calificaciones IS NULL
            OR fecha_inicio_calificaciones <= fecha_fin_calificaciones
        )
);

-- ============================================================
-- AULAS, PARALELOS Y HORARIOS
-- ============================================================

CREATE TABLE aulas (
    aula_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    codigo VARCHAR(50) NOT NULL UNIQUE,
    nombre VARCHAR(100),
    capacidad INT NOT NULL DEFAULT 0,
    ubicacion VARCHAR(150),
    estado estado_general NOT NULL DEFAULT 'activo',
    creado_at TIMESTAMP NOT NULL DEFAULT NOW(),
    actualizado_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_aula_capacidad
        CHECK (capacidad >= 0)
);

CREATE TABLE paralelos (
    paralelo_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    asignatura_id UUID NOT NULL,
    periodo_academico_id UUID NOT NULL,
    docente_id UUID,
    codigo_paralelo VARCHAR(30) NOT NULL,
    modalidad modalidad_asignatura NOT NULL DEFAULT 'presencial',
    capacidad INT NOT NULL,
    cantidad_matriculados INT NOT NULL DEFAULT 0,
    enlace_virtual TEXT,
    estado estado_paralelo NOT NULL DEFAULT 'planificado',
    creado_at TIMESTAMP NOT NULL DEFAULT NOW(),
    actualizado_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_paralelos_asignatura
        FOREIGN KEY (asignatura_id)
        REFERENCES asignaturas(asignatura_id),

    CONSTRAINT fk_paralelos_periodo
        FOREIGN KEY (periodo_academico_id)
        REFERENCES periodos_academicos(periodo_academico_id),

    CONSTRAINT fk_paralelos_docente
        FOREIGN KEY (docente_id)
        REFERENCES docentes(docente_id),

    CONSTRAINT chk_paralelo_capacidad
        CHECK (capacidad > 0),

    CONSTRAINT chk_cantidad_matriculados
        CHECK (cantidad_matriculados >= 0),

    CONSTRAINT uq_asignatura_paralelo_periodo
        UNIQUE (asignatura_id, periodo_academico_id, codigo_paralelo)
);

CREATE TABLE horarios_paralelos (
    horario_paralelo_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    paralelo_id UUID NOT NULL,
    aula_id UUID,
    dia_semana SMALLINT NOT NULL,
    hora_inicio TIME NOT NULL,
    hora_fin TIME NOT NULL,
    creado_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_horarios_paralelos_paralelo
        FOREIGN KEY (paralelo_id)
        REFERENCES paralelos(paralelo_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_horarios_paralelos_aula
        FOREIGN KEY (aula_id)
        REFERENCES aulas(aula_id),

    CONSTRAINT chk_dia_semana
        CHECK (dia_semana BETWEEN 1 AND 7),

    CONSTRAINT chk_horario_tiempo
        CHECK (hora_inicio < hora_fin)
);

-- ============================================================
-- MATRICULAS
-- ============================================================

CREATE TABLE matriculas (
    matricula_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    estudiante_id UUID NOT NULL,
    periodo_academico_id UUID NOT NULL,
    numero_matricula VARCHAR(50) NOT NULL UNIQUE,
    estado estado_matricula NOT NULL DEFAULT 'borrador',
    presentada_at TIMESTAMP,
    aprobada_por UUID,
    aprobada_at TIMESTAMP,
    observaciones TEXT,
    creado_at TIMESTAMP NOT NULL DEFAULT NOW(),
    actualizado_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_matriculas_estudiante
        FOREIGN KEY (estudiante_id)
        REFERENCES estudiantes(estudiante_id),

    CONSTRAINT fk_matriculas_periodo
        FOREIGN KEY (periodo_academico_id)
        REFERENCES periodos_academicos(periodo_academico_id),

    CONSTRAINT fk_matriculas_aprobada_por
        FOREIGN KEY (aprobada_por)
        REFERENCES usuarios(usuario_id),

    CONSTRAINT uq_estudiante_periodo_matricula
        UNIQUE (estudiante_id, periodo_academico_id)
);

CREATE TABLE matricula_asignaturas (
    matricula_asignatura_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    matricula_id UUID NOT NULL,
    paralelo_id UUID NOT NULL,
    estado estado_asignatura_matricula NOT NULL DEFAULT 'matriculado',
    calificacion_final NUMERIC(5,2),
    observacion_final TEXT,
    retirada_at TIMESTAMP,
    creado_at TIMESTAMP NOT NULL DEFAULT NOW(),
    actualizado_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_matricula_asignaturas_matricula
        FOREIGN KEY (matricula_id)
        REFERENCES matriculas(matricula_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_matricula_asignaturas_paralelo
        FOREIGN KEY (paralelo_id)
        REFERENCES paralelos(paralelo_id),

    CONSTRAINT chk_calificacion_final
        CHECK (calificacion_final IS NULL OR calificacion_final BETWEEN 0 AND 100),

    CONSTRAINT uq_matricula_paralelo
        UNIQUE (matricula_id, paralelo_id)
);

-- ============================================================
-- CALIFICACIONES
-- ============================================================

CREATE TABLE componentes_calificacion (
    componente_calificacion_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    paralelo_id UUID NOT NULL,
    nombre VARCHAR(150) NOT NULL,
    descripcion TEXT,
    peso NUMERIC(5,2) NOT NULL,
    puntaje_maximo NUMERIC(5,2) NOT NULL DEFAULT 100,
    fecha_entrega DATE,
    indice_orden INT DEFAULT 1,
    creado_at TIMESTAMP NOT NULL DEFAULT NOW(),
    actualizado_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_componentes_paralelo
        FOREIGN KEY (paralelo_id)
        REFERENCES paralelos(paralelo_id)
        ON DELETE CASCADE,

    CONSTRAINT chk_componente_peso
        CHECK (peso > 0 AND peso <= 100),

    CONSTRAINT chk_componente_puntaje_maximo
        CHECK (puntaje_maximo > 0),

    CONSTRAINT uq_componente_paralelo_nombre
        UNIQUE (paralelo_id, nombre)
);

CREATE TABLE calificaciones (
    calificacion_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    matricula_asignatura_id UUID NOT NULL,
    componente_calificacion_id UUID NOT NULL,
    puntaje NUMERIC(5,2) NOT NULL,
    retroalimentacion TEXT,
    registrada_por UUID NOT NULL,
    registrada_at TIMESTAMP NOT NULL DEFAULT NOW(),
    creado_at TIMESTAMP NOT NULL DEFAULT NOW(),
    actualizado_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_calificaciones_matricula_asignatura
        FOREIGN KEY (matricula_asignatura_id)
        REFERENCES matricula_asignaturas(matricula_asignatura_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_calificaciones_componente
        FOREIGN KEY (componente_calificacion_id)
        REFERENCES componentes_calificacion(componente_calificacion_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_calificaciones_registrada_por
        FOREIGN KEY (registrada_por)
        REFERENCES usuarios(usuario_id),

    CONSTRAINT chk_calificacion_puntaje
        CHECK (puntaje BETWEEN 0 AND 100),

    CONSTRAINT uq_calificacion_por_componente
        UNIQUE (matricula_asignatura_id, componente_calificacion_id)
);

-- ============================================================
-- ASISTENCIA
-- ============================================================

CREATE TABLE sesiones_asistencia (
    sesion_asistencia_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    paralelo_id UUID NOT NULL,
    fecha_clase DATE NOT NULL,
    tema VARCHAR(255),
    creada_por UUID,
    creado_at TIMESTAMP NOT NULL DEFAULT NOW(),
    actualizado_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_sesiones_asistencia_paralelo
        FOREIGN KEY (paralelo_id)
        REFERENCES paralelos(paralelo_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_sesiones_asistencia_creada_por
        FOREIGN KEY (creada_por)
        REFERENCES usuarios(usuario_id),

    CONSTRAINT uq_sesion_asistencia
        UNIQUE (paralelo_id, fecha_clase)
);

CREATE TABLE registro_asistencia (
    registro_asistencia_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sesion_asistencia_id UUID NOT NULL,
    matricula_asignatura_id UUID NOT NULL,
    estado estado_asistencia NOT NULL DEFAULT 'presente',
    observacion TEXT,
    creado_at TIMESTAMP NOT NULL DEFAULT NOW(),
    actualizado_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_registro_asistencia_sesion
        FOREIGN KEY (sesion_asistencia_id)
        REFERENCES sesiones_asistencia(sesion_asistencia_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_registro_asistencia_matricula_asignatura
        FOREIGN KEY (matricula_asignatura_id)
        REFERENCES matricula_asignaturas(matricula_asignatura_id)
        ON DELETE CASCADE,

    CONSTRAINT uq_registro_asistencia
        UNIQUE (sesion_asistencia_id, matricula_asignatura_id)
);

-- ============================================================
-- SOLICITUDES ADMINISTRATIVAS
-- ============================================================

CREATE TABLE solicitudes_academicas (
    solicitud_academica_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    estudiante_id UUID NOT NULL,
    tipo_solicitud tipo_solicitud NOT NULL,
    matricula_id UUID,
    matricula_asignatura_id UUID,
    paralelo_id UUID,
    descripcion TEXT NOT NULL,
    estado estado_solicitud NOT NULL DEFAULT 'pendiente',
    revisada_por UUID,
    revisada_at TIMESTAMP,
    respuesta TEXT,
    creado_at TIMESTAMP NOT NULL DEFAULT NOW(),
    actualizado_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_solicitudes_estudiante
        FOREIGN KEY (estudiante_id)
        REFERENCES estudiantes(estudiante_id),

    CONSTRAINT fk_solicitudes_matricula
        FOREIGN KEY (matricula_id)
        REFERENCES matriculas(matricula_id),

    CONSTRAINT fk_solicitudes_matricula_asignatura
        FOREIGN KEY (matricula_asignatura_id)
        REFERENCES matricula_asignaturas(matricula_asignatura_id),

    CONSTRAINT fk_solicitudes_paralelo
        FOREIGN KEY (paralelo_id)
        REFERENCES paralelos(paralelo_id),

    CONSTRAINT fk_solicitudes_revisada_por
        FOREIGN KEY (revisada_por)
        REFERENCES usuarios(usuario_id)
);

-- ============================================================
-- DOCUMENTOS ESTUDIANTILES
-- ============================================================

CREATE TABLE documentos_estudiante (
    documento_estudiante_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    estudiante_id UUID NOT NULL,
    tipo_documento VARCHAR(100) NOT NULL,
    nombre_archivo VARCHAR(255),
    url_archivo TEXT NOT NULL,
    estado estado_documento NOT NULL DEFAULT 'pendiente',
    revisado_por UUID,
    revisado_at TIMESTAMP,
    observacion TEXT,
    cargado_at TIMESTAMP NOT NULL DEFAULT NOW(),
    creado_at TIMESTAMP NOT NULL DEFAULT NOW(),
    actualizado_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_documentos_estudiante_estudiante
        FOREIGN KEY (estudiante_id)
        REFERENCES estudiantes(estudiante_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_documentos_estudiante_revisado_por
        FOREIGN KEY (revisado_por)
        REFERENCES usuarios(usuario_id)
);

-- ============================================================
-- NOTIFICACIONES
-- ============================================================

CREATE TABLE notificaciones (
    notificacion_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID NOT NULL,
    titulo VARCHAR(150) NOT NULL,
    mensaje TEXT NOT NULL,
    estado estado_notificacion NOT NULL DEFAULT 'no_leido',
    leido_at TIMESTAMP,
    creado_at TIMESTAMP NOT NULL DEFAULT NOW(),
    actualizado_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_notificaciones_usuario
        FOREIGN KEY (usuario_id)
        REFERENCES usuarios(usuario_id)
        ON DELETE CASCADE
);

-- ============================================================
-- AUDITORIA
-- ============================================================

CREATE TABLE registros_auditoria (
    registro_auditoria_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_actor_id UUID,
    accion VARCHAR(100) NOT NULL,
    nombre_entidad VARCHAR(100) NOT NULL,
    entidad_id UUID,
    valores_anteriores JSONB,
    valores_nuevos JSONB,
    direccion_ip VARCHAR(50),
    agente_usuario TEXT,
    creado_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_registros_auditoria_actor
        FOREIGN KEY (usuario_actor_id)
        REFERENCES usuarios(usuario_id)
);

-- ============================================================
-- TRIGGERS actualizado_at
-- ============================================================

DO $$
DECLARE
    tbl TEXT;
BEGIN
    FOREACH tbl IN ARRAY ARRAY[
        'usuarios',
        'roles',
        'permisos',
        'facultades',
        'carreras',
        'mallas_curriculares',
        'asignaturas',
        'estudiantes',
        'docentes',
        'personal_administrativo',
        'periodos_academicos',
        'aulas',
        'paralelos',
        'matriculas',
        'matricula_asignaturas',
        'componentes_calificacion',
        'calificaciones',
        'sesiones_asistencia',
        'registro_asistencia',
        'solicitudes_academicas',
        'documentos_estudiante',
        'notificaciones'
    ]
    LOOP
        EXECUTE format(
            'DROP TRIGGER IF EXISTS %I ON academico.%I',
            'trg_' || tbl || '_actualizado_at',
            tbl
        );

        EXECUTE format(
            'CREATE TRIGGER %I
             BEFORE UPDATE ON academico.%I
             FOR EACH ROW
             EXECUTE FUNCTION academico.establecer_actualizado_at()',
            'trg_' || tbl || '_actualizado_at',
            tbl
        );
    END LOOP;
END $$;

-- ============================================================
-- FUNCION PARA ACTUALIZAR cantidad_matriculados
-- ============================================================

CREATE OR REPLACE FUNCTION academico.actualizar_cantidad_matriculados(p_paralelo_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE academico.paralelos p
    SET cantidad_matriculados = (
        SELECT COUNT(*)
        FROM academico.matricula_asignaturas ma
        INNER JOIN academico.matriculas m
            ON m.matricula_id = ma.matricula_id
        WHERE ma.paralelo_id = p_paralelo_id
          AND ma.estado = 'matriculado'
          AND m.estado IN ('pendiente', 'aprobado')
    )
    WHERE p.paralelo_id = p_paralelo_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION academico.trg_actualizar_cantidad_matriculados()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        PERFORM academico.actualizar_cantidad_matriculados(NEW.paralelo_id);
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        PERFORM academico.actualizar_cantidad_matriculados(NEW.paralelo_id);

        IF OLD.paralelo_id IS DISTINCT FROM NEW.paralelo_id THEN
            PERFORM academico.actualizar_cantidad_matriculados(OLD.paralelo_id);
        END IF;

        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        PERFORM academico.actualizar_cantidad_matriculados(OLD.paralelo_id);
        RETURN OLD;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_matricula_asignaturas_actualizar_cantidad ON academico.matricula_asignaturas;

CREATE TRIGGER trg_matricula_asignaturas_actualizar_cantidad
AFTER INSERT OR UPDATE OR DELETE ON academico.matricula_asignaturas
FOR EACH ROW
EXECUTE FUNCTION academico.trg_actualizar_cantidad_matriculados();

-- ============================================================
-- INDICES
-- ============================================================

CREATE INDEX idx_usuarios_correo ON usuarios(correo_electronico);
CREATE INDEX idx_usuarios_estado ON usuarios(estado);

CREATE INDEX idx_estudiantes_usuario ON estudiantes(usuario_id);
CREATE INDEX idx_estudiantes_carrera ON estudiantes(carrera_id);
CREATE INDEX idx_estudiantes_estado ON estudiantes(estado);

CREATE INDEX idx_docentes_usuario ON docentes(usuario_id);
CREATE INDEX idx_docentes_facultad ON docentes(facultad_id);

CREATE INDEX idx_carreras_facultad ON carreras(facultad_id);
CREATE INDEX idx_carreras_nivel ON carreras(nivel_academico);
CREATE INDEX idx_mallas_carrera ON mallas_curriculares(carrera_id);
CREATE INDEX idx_malla_asignaturas_malla ON malla_asignaturas(malla_id);
CREATE INDEX idx_malla_asignaturas_asignatura ON malla_asignaturas(asignatura_id);

CREATE INDEX idx_asignaturas_codigo ON asignaturas(codigo);
CREATE INDEX idx_paralelos_asignatura ON paralelos(asignatura_id);
CREATE INDEX idx_paralelos_periodo ON paralelos(periodo_academico_id);
CREATE INDEX idx_paralelos_docente ON paralelos(docente_id);
CREATE INDEX idx_paralelos_estado ON paralelos(estado);

CREATE INDEX idx_matriculas_estudiante ON matriculas(estudiante_id);
CREATE INDEX idx_matriculas_periodo ON matriculas(periodo_academico_id);
CREATE INDEX idx_matriculas_estado ON matriculas(estado);

CREATE INDEX idx_matricula_asignaturas_matricula ON matricula_asignaturas(matricula_id);
CREATE INDEX idx_matricula_asignaturas_paralelo ON matricula_asignaturas(paralelo_id);
CREATE INDEX idx_matricula_asignaturas_estado ON matricula_asignaturas(estado);

CREATE INDEX idx_componentes_paralelo ON componentes_calificacion(paralelo_id);
CREATE INDEX idx_calificaciones_matricula_asignatura ON calificaciones(matricula_asignatura_id);
CREATE INDEX idx_calificaciones_componente ON calificaciones(componente_calificacion_id);

CREATE INDEX idx_sesiones_asistencia_paralelo ON sesiones_asistencia(paralelo_id);
CREATE INDEX idx_registro_asistencia_sesion ON registro_asistencia(sesion_asistencia_id);
CREATE INDEX idx_registro_asistencia_matricula_asignatura ON registro_asistencia(matricula_asignatura_id);

CREATE INDEX idx_solicitudes_estudiante ON solicitudes_academicas(estudiante_id);
CREATE INDEX idx_solicitudes_estado ON solicitudes_academicas(estado);
CREATE INDEX idx_solicitudes_tipo ON solicitudes_academicas(tipo_solicitud);

CREATE INDEX idx_notificaciones_usuario ON notificaciones(usuario_id);
CREATE INDEX idx_notificaciones_estado ON notificaciones(estado);

CREATE INDEX idx_registros_auditoria_actor ON registros_auditoria(usuario_actor_id);
CREATE INDEX idx_registros_auditoria_entidad ON registros_auditoria(nombre_entidad, entidad_id);
CREATE INDEX idx_registros_auditoria_creado_at ON registros_auditoria(creado_at);

-- ============================================================
-- VISTAS UTILES
-- ============================================================

CREATE OR REPLACE VIEW v_matriculas_estudiante AS
SELECT
    m.matricula_id,
    m.numero_matricula,
    m.estado AS estado_matricula,
    m.creado_at AS fecha_creacion_matricula,
    e.estudiante_id,
    e.codigo_estudiante,
    u.nombre_completo AS nombre_estudiante,
    u.correo_electronico AS correo_estudiante,
    pa.periodo_academico_id,
    pa.codigo AS codigo_periodo,
    pa.nombre AS nombre_periodo,
    c.carrera_id,
    c.nombre AS nombre_carrera,
    c.nivel_academico AS nivel_carrera
FROM matriculas m
INNER JOIN estudiantes e
    ON e.estudiante_id = m.estudiante_id
INNER JOIN usuarios u
    ON u.usuario_id = e.usuario_id
INNER JOIN periodos_academicos pa
    ON pa.periodo_academico_id = m.periodo_academico_id
INNER JOIN carreras c
    ON c.carrera_id = e.carrera_id;

CREATE OR REPLACE VIEW v_detalle_paralelos AS
SELECT
    p.paralelo_id,
    a.codigo AS codigo_asignatura,
    a.nombre AS nombre_asignatura,
    p.codigo_paralelo,
    p.modalidad,
    p.capacidad,
    p.cantidad_matriculados,
    p.estado AS estado_paralelo,
    pa.codigo AS codigo_periodo,
    pa.nombre AS nombre_periodo,
    du.nombre_completo AS nombre_docente
FROM paralelos p
INNER JOIN asignaturas a
    ON a.asignatura_id = p.asignatura_id
INNER JOIN periodos_academicos pa
    ON pa.periodo_academico_id = p.periodo_academico_id
LEFT JOIN docentes d
    ON d.docente_id = p.docente_id
LEFT JOIN usuarios du
    ON du.usuario_id = d.usuario_id;

CREATE OR REPLACE VIEW v_calificaciones_estudiante AS
SELECT
    e.estudiante_id,
    e.codigo_estudiante,
    u.nombre_completo AS nombre_estudiante,
    m.matricula_id,
    pa.codigo AS codigo_periodo,
    asig.codigo AS codigo_asignatura,
    asig.nombre AS nombre_asignatura,
    p.codigo_paralelo,
    cc.nombre AS nombre_componente,
    cc.peso,
    cal.puntaje,
    ma.calificacion_final
FROM calificaciones cal
INNER JOIN componentes_calificacion cc
    ON cc.componente_calificacion_id = cal.componente_calificacion_id
INNER JOIN matricula_asignaturas ma
    ON ma.matricula_asignatura_id = cal.matricula_asignatura_id
INNER JOIN matriculas m
    ON m.matricula_id = ma.matricula_id
INNER JOIN estudiantes e
    ON e.estudiante_id = m.estudiante_id
INNER JOIN usuarios u
    ON u.usuario_id = e.usuario_id
INNER JOIN paralelos p
    ON p.paralelo_id = ma.paralelo_id
INNER JOIN asignaturas asig
    ON asig.asignatura_id = p.asignatura_id
INNER JOIN periodos_academicos pa
    ON pa.periodo_academico_id = m.periodo_academico_id;

-- ============================================================
-- DATOS INICIALES
-- ============================================================

INSERT INTO roles (nombre, descripcion)
VALUES
    ('admin', 'Administrador general del sistema'),
    ('student', 'Estudiante'),
    ('teacher', 'Docente'),
    ('secretary', 'Secretaria academica'),
    ('coordinator', 'Coordinador academico')
ON CONFLICT (nombre) DO NOTHING;

INSERT INTO permisos (codigo, descripcion)
VALUES
    ('users.manage', 'Gestionar usuarios'),
    ('roles.manage', 'Gestionar roles y permisos'),
    ('students.manage', 'Gestionar estudiantes'),
    ('teachers.manage', 'Gestionar docentes'),
    ('programs.manage', 'Gestionar carreras'),
    ('courses.manage', 'Gestionar asignaturas'),
    ('periods.manage', 'Gestionar periodos academicos'),
    ('sections.manage', 'Gestionar paralelos'),
    ('enrollments.manage', 'Gestionar matriculas'),
    ('grades.manage', 'Gestionar calificaciones'),
    ('attendance.manage', 'Gestionar asistencia'),
    ('requests.manage', 'Gestionar solicitudes academicas'),
    ('reports.view', 'Ver reportes')
ON CONFLICT (codigo) DO NOTHING;

-- Asignar todos los permisos al rol admin
INSERT INTO rol_permisos (rol_id, permiso_id)
SELECT r.rol_id, p.permiso_id
FROM roles r
CROSS JOIN permisos p
WHERE r.nombre = 'admin'
ON CONFLICT DO NOTHING;

-- ============================================================
-- FIN DEL SCRIPT
-- ============================================================
