-- ============================================================
-- CORRECCION DE SEMILLAS DE CURSOS DE CATALOGO (V5)
-- ============================================================
--
-- V4 fue aplicada en remoto con el runner anterior, que no detenía psql
-- ante errores SQL. Las facultades y carreras se insertaron, pero la
-- insercion de cursos fallo en ambientes donde la secuencia cursos.id
-- estaba por detras de los IDs existentes. Esta migracion corrige la
-- secuencia y reintenta las semillas de cursos de forma idempotente.

SET search_path TO academico, public;

SELECT setval(
    pg_get_serial_sequence('academico.cursos', 'id'),
    COALESCE((SELECT MAX(id) FROM cursos), 0) + 1,
    false
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
    v.codigo,
    v.nombre,
    v.descripcion,
    v.creditos,
    v.estado,
    c.id
FROM (
    VALUES
        ('ARTP-101', 'Taller de Artes Plasticas', 'Materia semilla de catalogo para la carrera Artes Plasticas.', 4, 'activo', 'FECYT-ARTPLAS'),
        ('COM-101', 'Fundamentos de Comunicacion', 'Materia semilla de catalogo para la carrera Comunicacion.', 4, 'activo', 'FECYT-COM'),
        ('DG-101', 'Fundamentos de Diseno Grafico', 'Materia semilla de catalogo para la carrera Diseno Grafico.', 4, 'activo', 'FECYT-DISGRAF'),
        ('EB-101', 'Fundamentos de Educacion Basica', 'Materia semilla de catalogo para la carrera Educacion Basica.', 4, 'activo', 'FECYT-EDUBAS'),
        ('EI-101', 'Fundamentos de Educacion Inicial', 'Materia semilla de catalogo para la carrera Educacion Inicial.', 4, 'activo', 'FECYT-EDUINI'),
        ('ED-101', 'Fundamentos de Entrenamiento Deportivo', 'Materia semilla de catalogo para la carrera Entrenamiento Deportivo.', 4, 'activo', 'FECYT-ENTDEP'),
        ('AFD-101', 'Actividad Fisica y Deporte', 'Materia semilla de catalogo para la carrera Pedagogia de la Actividad Fisica y Deporte.', 4, 'activo', 'FECYT-ACTFIS'),
        ('PAH-101', 'Artes y Humanidades', 'Materia semilla de catalogo para la carrera Pedagogia de las Artes y Humanidades.', 4, 'activo', 'FECYT-ARTHUM'),
        ('PCE-101', 'Ciencias Experimentales', 'Materia semilla de catalogo para la carrera Pedagogia de las Ciencias Experimentales.', 4, 'activo', 'FECYT-CIEXP'),
        ('PINE-101', 'Pedagogia de Idiomas', 'Materia semilla de catalogo para la carrera Pedagogia de los Idiomas Nacionales y Extranjeros.', 4, 'activo', 'FECYT-IDIOMAS'),
        ('PSI-101', 'Fundamentos de Psicologia', 'Materia semilla de catalogo para la carrera Psicologia.', 4, 'activo', 'FECYT-PSICO'),
        ('PSP-101', 'Fundamentos de Psicopedagogia', 'Materia semilla de catalogo para la carrera Psicopedagogia.', 4, 'activo', 'FECYT-PSICOPED'),
        ('PUB-101', 'Fundamentos de Publicidad', 'Materia semilla de catalogo para la carrera Publicidad.', 4, 'activo', 'FECYT-PUB'),

        ('ELEC-101', 'Circuitos Electricos I', 'Materia semilla de catalogo para la carrera Electricidad.', 4, 'activo', 'FICA-ELEC'),
        ('AUTO-101', 'Fundamentos de Ingenieria Automotriz', 'Materia semilla de catalogo para la carrera Ingenieria Automotriz.', 4, 'activo', 'FICA-AUTO'),
        ('IND-101', 'Procesos Industriales', 'Materia semilla de catalogo para la carrera Ingenieria Industrial.', 4, 'activo', 'FICA-IND'),
        ('MEC-101', 'Fundamentos de Mecatronica', 'Materia semilla de catalogo para la carrera Mecatronica.', 4, 'activo', 'FICA-MECAT'),
        ('SOFT-101', 'Fundamentos de Programacion', 'Materia semilla de catalogo para la carrera Software.', 4, 'activo', 'SOFT-001'),
        ('TEL-101', 'Fundamentos de Telecomunicaciones', 'Materia semilla de catalogo para la carrera Telecomunicaciones.', 4, 'activo', 'FICA-TELECOM'),
        ('TEX-101', 'Tecnologia Textil', 'Materia semilla de catalogo para la carrera Textiles.', 4, 'activo', 'FICA-TEXT'),

        ('AGI-101', 'Fundamentos de Agroindustria', 'Materia semilla de catalogo para la carrera Agroindustria.', 4, 'activo', 'FICAYA-AGROIND'),
        ('AGP-101', 'Produccion Agropecuaria', 'Materia semilla de catalogo para la carrera Agropecuaria.', 4, 'activo', 'FICAYA-AGROPEC'),
        ('BIO-101', 'Biologia Molecular Basica', 'Materia semilla de catalogo para la carrera Biotecnologia.', 4, 'activo', 'FICAYA-BIOTEC'),
        ('FOR-101', 'Silvicultura Basica', 'Materia semilla de catalogo para la carrera Ingenieria Forestal.', 4, 'activo', 'FICAYA-FOREST'),
        ('RNR-101', 'Ecologia y Recursos Naturales', 'Materia semilla de catalogo para la carrera Recursos Naturales Renovables.', 4, 'activo', 'FICAYA-RNR'),
        ('ER-101', 'Fundamentos de Energias Renovables', 'Materia semilla de catalogo para la carrera Energias Renovables.', 4, 'activo', 'FICAYA-ENERREN'),

        ('ADE-101', 'Administracion General', 'Materia semilla de catalogo para la carrera Administracion de Empresas.', 4, 'activo', 'FACAE-ADE'),
        ('CONT-101', 'Contabilidad General', 'Materia semilla de catalogo para la carrera Contabilidad Superior y Auditoria.', 4, 'activo', 'FACAE-CONT'),
        ('ECO-101', 'Microeconomia', 'Materia semilla de catalogo para la carrera Economia.', 4, 'activo', 'FACAE-ECON'),
        ('GAS-101', 'Cocina Profesional I', 'Materia semilla de catalogo para la carrera Gastronomia.', 4, 'activo', 'FACAE-GASTRO'),
        ('MKT-101', 'Fundamentos de Mercadotecnia', 'Materia semilla de catalogo para la carrera Mercadotecnia.', 4, 'activo', 'FACAE-MKT'),
        ('TUR-101', 'Gestion Turistica', 'Materia semilla de catalogo para la carrera Turismo.', 4, 'activo', 'FACAE-TUR'),

        ('ENF-101', 'Fundamentos de Enfermeria', 'Materia semilla de catalogo para la carrera Enfermeria.', 4, 'activo', 'FCCSS-ENF'),
        ('FIS-101', 'Anatomia Funcional', 'Materia semilla de catalogo para la carrera Fisioterapia.', 4, 'activo', 'FCCSS-FISIO'),
        ('MED-101', 'Anatomia Humana', 'Materia semilla de catalogo para la carrera Medicina.', 5, 'activo', 'FCCSS-MED'),
        ('NUT-101', 'Nutricion Basica', 'Materia semilla de catalogo para la carrera Nutricion y Dietetica.', 4, 'activo', 'FCCSS-NUT')
) AS v (
    codigo,
    nombre,
    descripcion,
    creditos,
    estado,
    carrera_codigo
)
INNER JOIN carreras c
    ON c.codigo = v.carrera_codigo
ON CONFLICT (codigo) DO UPDATE SET
    nombre = EXCLUDED.nombre,
    descripcion = EXCLUDED.descripcion,
    creditos = EXCLUDED.creditos,
    estado = EXCLUDED.estado,
    carrera_id = EXCLUDED.carrera_id;
