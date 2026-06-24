-- ============================================================
-- SEMILLAS DE FACULTADES, CARRERAS Y CURSOS DE CATALOGO (V4)
-- ============================================================
--
-- Fuente de carreras de grado: oferta academica publica UTN.
-- https://www.utn.edu.ec/oferta-grado/
--
-- La migracion V3 dejo una facultad generica FAC-ING y la carrera
-- SOFT-001. Esta migracion normaliza FAC-ING a FICA, agrega la
-- estructura oficial de facultades de grado y asocia SOFT-001 a FICA
-- sin duplicar la carrera Software.

SET search_path TO academico, public;

-- ============================================================
-- FACULTADES
-- ============================================================

UPDATE facultades
SET
    codigo = 'FICA',
    nombre = 'Facultad de Ingenieria en Ciencias Aplicadas',
    descripcion = 'Unidad academica de carreras de ingenieria, tecnologia aplicada, software, telecomunicaciones y areas industriales.',
    estado = 'activa'
WHERE codigo = 'FAC-ING'
  AND NOT EXISTS (
      SELECT 1
      FROM facultades f
      WHERE f.codigo = 'FICA'
  );

INSERT INTO facultades (
    codigo,
    nombre,
    descripcion,
    estado
) VALUES
    (
        'FECYT',
        'Facultad de Educacion, Ciencia y Tecnologia',
        'Unidad academica de carreras de educacion, comunicacion, artes, psicologia, deporte y areas afines.',
        'activa'
    ),
    (
        'FICA',
        'Facultad de Ingenieria en Ciencias Aplicadas',
        'Unidad academica de carreras de ingenieria, tecnologia aplicada, software, telecomunicaciones y areas industriales.',
        'activa'
    ),
    (
        'FICAYA',
        'Facultad de Ingenieria en Ciencias Agropecuarias y Ambientales',
        'Unidad academica de carreras agropecuarias, ambientales, forestales, biotecnologicas y de energia renovable.',
        'activa'
    ),
    (
        'FACAE',
        'Facultad de Ciencias Administrativas y Economicas',
        'Unidad academica de carreras administrativas, economicas, contables, turisticas, gastronomicas y de mercadotecnia.',
        'activa'
    ),
    (
        'FCCSS',
        'Facultad de Ciencias de la Salud',
        'Unidad academica de carreras vinculadas con salud, medicina, enfermeria, fisioterapia y nutricion.',
        'activa'
    )
ON CONFLICT (codigo) DO UPDATE SET
    nombre = EXCLUDED.nombre,
    descripcion = EXCLUDED.descripcion,
    estado = EXCLUDED.estado;

-- ============================================================
-- CARRERAS
-- ============================================================

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
    v.codigo,
    v.nombre,
    v.descripcion,
    v.nivel,
    v.modalidad,
    v.duracion_periodos,
    v.estado,
    f.id
FROM (
    VALUES
        ('FECYT-ARTPLAS', 'Artes Plasticas', 'Carrera de grado orientada a la formacion artistica, visual y plastica.', 'grado', 'presencial', 10, 'activa', 'FECYT'),
        ('FECYT-COM', 'Comunicacion', 'Carrera de grado orientada a la comunicacion social, medios y produccion de contenidos.', 'grado', 'presencial', 10, 'activa', 'FECYT'),
        ('FECYT-DISGRAF', 'Diseno Grafico', 'Carrera de grado orientada al diseno visual, comunicacion grafica y produccion multimedia.', 'grado', 'presencial', 10, 'activa', 'FECYT'),
        ('FECYT-EDUBAS', 'Educacion Basica', 'Carrera de grado orientada a la formacion docente para educacion basica.', 'grado', 'presencial', 10, 'activa', 'FECYT'),
        ('FECYT-EDUINI', 'Educacion Inicial', 'Carrera de grado orientada a la formacion docente para primera infancia.', 'grado', 'presencial', 10, 'activa', 'FECYT'),
        ('FECYT-ENTDEP', 'Entrenamiento Deportivo', 'Carrera de grado orientada a la preparacion fisica, entrenamiento y rendimiento deportivo.', 'grado', 'presencial', 10, 'activa', 'FECYT'),
        ('FECYT-ACTFIS', 'Pedagogia de la Actividad Fisica y Deporte', 'Carrera de grado orientada a la ensenanza de actividad fisica, deporte y recreacion.', 'grado', 'presencial', 10, 'activa', 'FECYT'),
        ('FECYT-ARTHUM', 'Pedagogia de las Artes y Humanidades', 'Carrera de grado orientada a la ensenanza de artes, cultura y humanidades.', 'grado', 'presencial', 10, 'activa', 'FECYT'),
        ('FECYT-CIEXP', 'Pedagogia de las Ciencias Experimentales', 'Carrera de grado orientada a la ensenanza de ciencias experimentales.', 'grado', 'presencial', 10, 'activa', 'FECYT'),
        ('FECYT-IDIOMAS', 'Pedagogia de los Idiomas Nacionales y Extranjeros', 'Carrera de grado orientada a la ensenanza de idiomas nacionales y extranjeros.', 'grado', 'presencial', 10, 'activa', 'FECYT'),
        ('FECYT-PSICO', 'Psicologia', 'Carrera de grado orientada al estudio del comportamiento humano y procesos psicologicos.', 'grado', 'presencial', 10, 'activa', 'FECYT'),
        ('FECYT-PSICOPED', 'Psicopedagogia', 'Carrera de grado orientada al apoyo de procesos de aprendizaje y orientacion educativa.', 'grado', 'presencial', 10, 'activa', 'FECYT'),
        ('FECYT-PUB', 'Publicidad', 'Carrera de grado orientada a estrategia publicitaria, creatividad y comunicacion comercial.', 'grado', 'presencial', 10, 'activa', 'FECYT'),

        ('FICA-ELEC', 'Electricidad', 'Carrera de grado orientada a sistemas electricos, energia y automatizacion.', 'grado', 'presencial', 10, 'activa', 'FICA'),
        ('FICA-AUTO', 'Ingenieria Automotriz', 'Carrera de grado orientada a sistemas automotrices, mantenimiento y tecnologia vehicular.', 'grado', 'presencial', 10, 'activa', 'FICA'),
        ('FICA-IND', 'Ingenieria Industrial', 'Carrera de grado orientada a procesos productivos, calidad y gestion industrial.', 'grado', 'presencial', 10, 'activa', 'FICA'),
        ('FICA-MECAT', 'Mecatronica', 'Carrera de grado orientada a automatizacion, electronica, mecanica y control.', 'grado', 'presencial', 10, 'activa', 'FICA'),
        ('SOFT-001', 'Software', 'Carrera de grado orientada al desarrollo, arquitectura y gestion de sistemas de software.', 'grado', 'presencial', 10, 'activa', 'FICA'),
        ('FICA-TELECOM', 'Telecomunicaciones', 'Carrera de grado orientada a redes, comunicaciones digitales e infraestructura tecnologica.', 'grado', 'presencial', 10, 'activa', 'FICA'),
        ('FICA-TEXT', 'Textiles', 'Carrera de grado orientada a procesos textiles, materiales y produccion industrial.', 'grado', 'presencial', 10, 'activa', 'FICA'),

        ('FICAYA-AGROIND', 'Agroindustria', 'Carrera de grado orientada a procesos agroindustriales, calidad e innovacion alimentaria.', 'grado', 'presencial', 10, 'activa', 'FICAYA'),
        ('FICAYA-AGROPEC', 'Agropecuaria', 'Carrera de grado orientada a produccion agricola, pecuaria y desarrollo rural.', 'grado', 'presencial', 10, 'activa', 'FICAYA'),
        ('FICAYA-BIOTEC', 'Biotecnologia', 'Carrera de grado orientada a bioprocesos, biologia aplicada e innovacion biotecnologica.', 'grado', 'presencial', 10, 'activa', 'FICAYA'),
        ('FICAYA-FOREST', 'Ingenieria Forestal', 'Carrera de grado orientada a manejo forestal, conservacion y gestion de recursos boscosos.', 'grado', 'presencial', 10, 'activa', 'FICAYA'),
        ('FICAYA-RNR', 'Recursos Naturales Renovables', 'Carrera de grado orientada a conservacion, gestion ambiental y uso sostenible de recursos naturales.', 'grado', 'presencial', 10, 'activa', 'FICAYA'),
        ('FICAYA-ENERREN', 'Energias Renovables', 'Carrera de grado orientada a tecnologias limpias, energia sostenible y eficiencia energetica.', 'grado', 'presencial', 10, 'activa', 'FICAYA'),

        ('FACAE-ADE', 'Administracion de Empresas', 'Carrera de grado orientada a gestion empresarial, emprendimiento y direccion organizacional.', 'grado', 'presencial', 10, 'activa', 'FACAE'),
        ('FACAE-CONT', 'Contabilidad Superior y Auditoria', 'Carrera de grado orientada a contabilidad, auditoria, tributacion y control financiero.', 'grado', 'presencial', 10, 'activa', 'FACAE'),
        ('FACAE-ECON', 'Economia', 'Carrera de grado orientada a analisis economico, finanzas, desarrollo y politicas publicas.', 'grado', 'presencial', 10, 'activa', 'FACAE'),
        ('FACAE-GASTRO', 'Gastronomia', 'Carrera de grado orientada a gestion culinaria, alimentos, servicios y cultura gastronomica.', 'grado', 'presencial', 10, 'activa', 'FACAE'),
        ('FACAE-MKT', 'Mercadotecnia', 'Carrera de grado orientada a investigacion de mercados, estrategia comercial y comunicacion de marca.', 'grado', 'presencial', 10, 'activa', 'FACAE'),
        ('FACAE-TUR', 'Turismo', 'Carrera de grado orientada a gestion turistica, patrimonio, servicios y desarrollo local.', 'grado', 'presencial', 10, 'activa', 'FACAE'),

        ('FCCSS-ENF', 'Enfermeria', 'Carrera de grado orientada al cuidado integral, promocion de salud y atencion de pacientes.', 'grado', 'presencial', 10, 'activa', 'FCCSS'),
        ('FCCSS-FISIO', 'Fisioterapia', 'Carrera de grado orientada a rehabilitacion, movimiento humano y terapia fisica.', 'grado', 'presencial', 10, 'activa', 'FCCSS'),
        ('FCCSS-MED', 'Medicina', 'Carrera de grado orientada a diagnostico, prevencion, tratamiento y atencion integral en salud.', 'grado', 'presencial', 12, 'activa', 'FCCSS'),
        ('FCCSS-NUT', 'Nutricion y Dietetica', 'Carrera de grado orientada a alimentacion, nutricion clinica, comunitaria y dietetica.', 'grado', 'presencial', 10, 'activa', 'FCCSS')
) AS v (
    codigo,
    nombre,
    descripcion,
    nivel,
    modalidad,
    duracion_periodos,
    estado,
    facultad_codigo
)
INNER JOIN facultades f
    ON f.codigo = v.facultad_codigo
ON CONFLICT (codigo) DO UPDATE SET
    nombre = EXCLUDED.nombre,
    descripcion = EXCLUDED.descripcion,
    nivel = EXCLUDED.nivel,
    modalidad = EXCLUDED.modalidad,
    duracion_periodos = EXCLUDED.duracion_periodos,
    estado = EXCLUDED.estado,
    facultad_id = EXCLUDED.facultad_id;

-- ============================================================
-- CURSOS DE CATALOGO
-- ============================================================
--
-- Los cursos son semillas minimas para que CatalogoService/ListarMaterias
-- devuelva materias asociadas a distintas carreras y facultades.

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
