-- ============================================================
-- SEMBRAR DATOS DEL FLUJO INDEPENDIENTE DE CALIFICACIONES (V12)
-- ============================================================
--
-- Alinea los datos base con el flujo documentado en:
-- DOCUMENTOS/03_Endpoints_y_Consultas/FLUJO_INDEPENDIENTE/
-- CALIFICACIONES_REGISTRO_PUBLICACION_NOTAS.md
--
-- Datos principales del flujo:
-- - Matricula: 1
-- - Estudiante: Maria Fernanda Castro Imbaquingo (id 101)
-- - Docente: Ing. Andrea Morales (id 102)
-- - Materia: SOF-101 - Programación Orientada a Objetos I
-- - Ciclo academico: 2026A
-- - Paralelo: A
-- - Matricula-asignatura: 1:2026A:SOF-101:A:2

BEGIN;

SET search_path TO academico, public;

INSERT INTO roles (nombre, descripcion, estado)
VALUES
    ('estudiante', 'Usuario que puede matricularse en cursos y consultar calificaciones', 'activo'),
    ('docente', 'Usuario que imparte cursos y registra calificaciones', 'activo')
ON CONFLICT (nombre) DO UPDATE
SET
    descripcion = EXCLUDED.descripcion,
    estado = EXCLUDED.estado,
    actualizado_en = CURRENT_TIMESTAMP;

INSERT INTO facultades (
    codigo,
    nombre,
    descripcion,
    estado
) VALUES (
    'FICA',
    'Facultad de Ingenieria en Ciencias Aplicadas',
    'Unidad academica de carreras de ingenieria, tecnologia aplicada, software, telecomunicaciones y areas industriales.',
    'activa'
)
ON CONFLICT (codigo) DO UPDATE
SET
    nombre = EXCLUDED.nombre,
    descripcion = EXCLUDED.descripcion,
    estado = EXCLUDED.estado,
    actualizado_en = CURRENT_TIMESTAMP;

INSERT INTO carreras (
    codigo,
    nombre,
    descripcion,
    nivel,
    modalidad,
    duracion_periodos,
    estado,
    facultad_id
)
SELECT
    'SOFT-001',
    'Software',
    'Carrera de grado orientada al desarrollo, arquitectura y gestion de sistemas de software.',
    'grado',
    'presencial',
    10,
    'activa',
    facultades.id
FROM facultades
WHERE facultades.codigo = 'FICA'
ON CONFLICT (codigo) DO UPDATE
SET
    nombre = EXCLUDED.nombre,
    descripcion = EXCLUDED.descripcion,
    nivel = EXCLUDED.nivel,
    modalidad = EXCLUDED.modalidad,
    duracion_periodos = EXCLUDED.duracion_periodos,
    estado = EXCLUDED.estado,
    facultad_id = EXCLUDED.facultad_id,
    actualizado_en = CURRENT_TIMESTAMP;

-- Los usuarios del flujo de calificaciones usan ids reservados para no pisar
-- las semillas de login de V7, que en bases nuevas suelen ocupar ids 1 y 2.
UPDATE usuarios
SET email = CONCAT('usuario-', id, '-anterior@utn.edu.ec')
WHERE id <> 101
  AND email = 'maria.fernanda.castro.flujo@utn.edu.ec';

UPDATE usuarios
SET identificacion = CONCAT('ANT-', id, '-1')
WHERE id <> 101
  AND identificacion = '1';

UPDATE usuarios
SET email = CONCAT('usuario-', id, '-anterior@utn.edu.ec')
WHERE id <> 102
  AND email = 'andrea.morales.flujo@utn.edu.ec';

UPDATE usuarios
SET identificacion = CONCAT('ANT-', id, '-2')
WHERE id <> 102
  AND identificacion = '2';

INSERT INTO usuarios (
    id,
    rol_id,
    nombres,
    apellidos,
    email,
    password_hash,
    identificacion,
    estado,
    carrera_id
)
OVERRIDING SYSTEM VALUE
SELECT
    101,
    roles.id,
    'Maria Fernanda',
    'Castro Imbaquingo',
    'maria.fernanda.castro.flujo@utn.edu.ec',
    'sha256:ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f',
    '1',
    'activo',
    carreras.id
FROM roles
LEFT JOIN carreras
    ON carreras.codigo = 'SOFT-001'
WHERE roles.nombre = 'estudiante'
ON CONFLICT (id) DO UPDATE
SET
    rol_id = EXCLUDED.rol_id,
    nombres = EXCLUDED.nombres,
    apellidos = EXCLUDED.apellidos,
    email = EXCLUDED.email,
    password_hash = EXCLUDED.password_hash,
    identificacion = EXCLUDED.identificacion,
    estado = EXCLUDED.estado,
    carrera_id = EXCLUDED.carrera_id,
    actualizado_en = CURRENT_TIMESTAMP;

INSERT INTO usuarios (
    id,
    rol_id,
    nombres,
    apellidos,
    email,
    password_hash,
    identificacion,
    estado,
    carrera_id
)
OVERRIDING SYSTEM VALUE
SELECT
    102,
    roles.id,
    'Andrea',
    'Morales',
    'andrea.morales.flujo@utn.edu.ec',
    'sha256:ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f',
    '2',
    'activo',
    carreras.id
FROM roles
LEFT JOIN carreras
    ON carreras.codigo = 'SOFT-001'
WHERE roles.nombre = 'docente'
ON CONFLICT (id) DO UPDATE
SET
    rol_id = EXCLUDED.rol_id,
    nombres = EXCLUDED.nombres,
    apellidos = EXCLUDED.apellidos,
    email = EXCLUDED.email,
    password_hash = EXCLUDED.password_hash,
    identificacion = EXCLUDED.identificacion,
    estado = EXCLUDED.estado,
    carrera_id = EXCLUDED.carrera_id,
    actualizado_en = CURRENT_TIMESTAMP;

SELECT setval(
    pg_get_serial_sequence('academico.usuarios', 'id'),
    GREATEST((SELECT COALESCE(MAX(id), 1) FROM usuarios), 1),
    true
);

INSERT INTO cursos (
    codigo,
    nombre,
    descripcion,
    creditos,
    estado,
    carrera_id
)
SELECT
    'SOF-101',
    'Programación Orientada a Objetos I',
    'Materia de la carrera de Software orientada a fundamentos de programacion orientada a objetos.',
    4,
    'activo',
    carreras.id
FROM carreras
WHERE carreras.codigo = 'SOFT-001'
ON CONFLICT (codigo) DO UPDATE
SET
    nombre = EXCLUDED.nombre,
    descripcion = EXCLUDED.descripcion,
    creditos = EXCLUDED.creditos,
    estado = EXCLUDED.estado,
    carrera_id = EXCLUDED.carrera_id,
    actualizado_en = CURRENT_TIMESTAMP;

UPDATE periodos_academicos
SET nombre = CONCAT('Periodo anterior ', id)
WHERE id <> 1
  AND nombre = '2026A';

INSERT INTO periodos_academicos (
    id,
    nombre,
    fecha_inicio,
    fecha_fin,
    estado
)
OVERRIDING SYSTEM VALUE
VALUES (
    1,
    '2026A',
    DATE '2026-07-01',
    DATE '2026-12-31',
    'activo'
)
ON CONFLICT (id) DO UPDATE
SET
    nombre = EXCLUDED.nombre,
    fecha_inicio = EXCLUDED.fecha_inicio,
    fecha_fin = EXCLUDED.fecha_fin,
    estado = EXCLUDED.estado,
    actualizado_en = CURRENT_TIMESTAMP;

SELECT setval(
    pg_get_serial_sequence('academico.periodos_academicos', 'id'),
    GREATEST((SELECT COALESCE(MAX(id), 1) FROM periodos_academicos), 1),
    true
);

UPDATE ofertas_curso
SET paralelo = LEFT(CONCAT('A-PREV-', id), 20)
WHERE id <> 1
  AND curso_id = (SELECT id FROM cursos WHERE codigo = 'SOF-101')
  AND periodo_id = 1
  AND paralelo = 'A';

INSERT INTO ofertas_curso (
    id,
    curso_id,
    periodo_id,
    docente_id,
    paralelo,
    cupo,
    horario,
    aula,
    estado
)
OVERRIDING SYSTEM VALUE
SELECT
    1,
    cursos.id,
    1,
    102,
    'A',
    30,
    '{"lunes": "08:00-10:00", "miercoles": "08:00-10:00"}'::jsonb,
    'LAB-POO-1',
    'abierta'
FROM cursos
WHERE cursos.codigo = 'SOF-101'
ON CONFLICT (id) DO UPDATE
SET
    curso_id = EXCLUDED.curso_id,
    periodo_id = EXCLUDED.periodo_id,
    docente_id = EXCLUDED.docente_id,
    paralelo = EXCLUDED.paralelo,
    cupo = EXCLUDED.cupo,
    horario = EXCLUDED.horario,
    aula = EXCLUDED.aula,
    estado = EXCLUDED.estado,
    actualizado_en = CURRENT_TIMESTAMP;

SELECT setval(
    pg_get_serial_sequence('academico.ofertas_curso', 'id'),
    GREATEST((SELECT COALESCE(MAX(id), 1) FROM ofertas_curso), 1),
    true
);

INSERT INTO matriculas (
    id,
    estudiante_id,
    oferta_curso_id,
    fecha_matricula,
    estado,
    nota_final,
    observacion
)
OVERRIDING SYSTEM VALUE
VALUES (
    1,
    101,
    1,
    TIMESTAMP '2026-07-02 00:00:00',
    'matriculado',
    NULL,
    'Matricula academica usada por el flujo independiente de calificaciones.'
)
ON CONFLICT (id) DO UPDATE
SET
    estudiante_id = EXCLUDED.estudiante_id,
    oferta_curso_id = EXCLUDED.oferta_curso_id,
    fecha_matricula = EXCLUDED.fecha_matricula,
    estado = EXCLUDED.estado,
    nota_final = EXCLUDED.nota_final,
    observacion = EXCLUDED.observacion,
    actualizado_en = CURRENT_TIMESTAMP;

SELECT setval(
    pg_get_serial_sequence('academico.matriculas', 'id'),
    GREATEST((SELECT COALESCE(MAX(id), 1) FROM matriculas), 1),
    true
);

UPDATE componentes_calificacion
SET nombre = CONCAT(nombre, ' anterior ', id)
WHERE id NOT IN (1, 2)
  AND oferta_curso_id = 1
  AND paralelo_id = 'A'
  AND LOWER(nombre) IN ('examen parcial', 'proyecto integrador');

INSERT INTO componentes_calificacion (
    id,
    oferta_curso_id,
    paralelo_id,
    nombre,
    descripcion,
    tipo,
    ponderacion,
    puntaje_maximo,
    fecha_entrega,
    estado
)
OVERRIDING SYSTEM VALUE
VALUES
    (
        1,
        1,
        'A',
        'Examen parcial',
        'Evaluacion escrita del primer parcial',
        'examen',
        40,
        10,
        DATE '2026-07-15',
        'activo'
    ),
    (
        2,
        1,
        'A',
        'Proyecto integrador',
        'Proyecto integrador con defensa oral',
        'proyecto',
        60,
        10,
        DATE '2026-07-24',
        'activo'
    )
ON CONFLICT (id) DO UPDATE
SET
    oferta_curso_id = EXCLUDED.oferta_curso_id,
    paralelo_id = EXCLUDED.paralelo_id,
    nombre = EXCLUDED.nombre,
    descripcion = EXCLUDED.descripcion,
    tipo = EXCLUDED.tipo,
    ponderacion = EXCLUDED.ponderacion,
    puntaje_maximo = EXCLUDED.puntaje_maximo,
    fecha_entrega = EXCLUDED.fecha_entrega,
    estado = EXCLUDED.estado,
    actualizado_en = NOW();

SELECT setval(
    pg_get_serial_sequence('academico.componentes_calificacion', 'id'),
    GREATEST((SELECT COALESCE(MAX(id), 1) FROM componentes_calificacion), 1),
    true
);

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
VALUES (
    '1:2026A:SOF-101:A:2',
    '1',
    101,
    '1',
    1,
    '2026A',
    'SOF-101',
    'A',
    '2',
    'activo',
    NULL
)
ON CONFLICT (codigo) DO UPDATE
SET
    matricula_codigo = EXCLUDED.matricula_codigo,
    estudiante_id = EXCLUDED.estudiante_id,
    estudiante_cedula = EXCLUDED.estudiante_cedula,
    oferta_curso_id = EXCLUDED.oferta_curso_id,
    ciclo_acad_codigo = EXCLUDED.ciclo_acad_codigo,
    materia_codigo = EXCLUDED.materia_codigo,
    paralelo_codigo = EXCLUDED.paralelo_codigo,
    docente_cedula = EXCLUDED.docente_cedula,
    estado = EXCLUDED.estado,
    nota_final = EXCLUDED.nota_final,
    actualizado_en = NOW();

UPDATE calificaciones
SET
    matricula_codigo = '1',
    matricula_asignatura_codigo = '1:2026A:SOF-101:A:2',
    estudiante_id = 101,
    oferta_curso_id = 1,
    registrada_por = CASE
        WHEN registrada_por IS NULL OR registrada_por = 2 THEN 102
        ELSE registrada_por
    END
WHERE matricula_codigo = '1'
   OR matricula_asignatura_codigo LIKE '1:%';

UPDATE calificaciones
SET
    componente_id = 1,
    nombre_evaluacion = 'Examen parcial',
    tipo = 'examen',
    ponderacion = 40
WHERE matricula_asignatura_codigo = '1:2026A:SOF-101:A:2'
  AND (
      componente_id = 1
      OR LOWER(nombre_evaluacion) LIKE 'examen parcial%'
  );

UPDATE calificaciones
SET
    componente_id = 2,
    nombre_evaluacion = 'Proyecto integrador',
    tipo = 'proyecto',
    ponderacion = 60
WHERE matricula_asignatura_codigo = '1:2026A:SOF-101:A:2'
  AND (
      componente_id = 2
      OR LOWER(nombre_evaluacion) LIKE 'proyecto integrador%'
  );

WITH resumen AS (
    SELECT
        matricula_asignatura_codigo,
        ROUND(
            (SUM(nota * ponderacion) / NULLIF(SUM(ponderacion), 0))::numeric,
            2
        ) AS nota_final
    FROM calificaciones
    WHERE matricula_asignatura_codigo = '1:2026A:SOF-101:A:2'
      AND estado <> 'anulado'
    GROUP BY matricula_asignatura_codigo
)
UPDATE matricula_asignaturas
SET
    nota_final = resumen.nota_final,
    estado = CASE
        WHEN resumen.nota_final >= 7 THEN 'aprobado'
        ELSE 'reprobado'
    END,
    actualizado_en = NOW()
FROM resumen
WHERE matricula_asignaturas.codigo = resumen.matricula_asignatura_codigo;

COMMIT;
