# Diseño y Estructura de la Base de Datos: Sistema de Gestión Académica

![Diagrama de Entidad-Relación (Concepto)](database_er_diagram.jpg)

![Diagrama de Entidad-Relación (Físico SVG)](database_design.svg)

Este documento detalla el diseño relacional del esquema `academico` del Sistema de Gestión Académica. Para facilitar la comprensión de las conexiones y dependencias, el esquema de 28 tablas ha sido organizado en **módulos lógicos**.

---

## 1. Módulo de Seguridad e Identidad (RBAC)

Este módulo gestiona la autenticación de usuarios, la definición de roles y la asignación de permisos a nivel de sistema.

```mermaid
erDiagram
    usuarios ||--o{ usuario_roles : "tiene"
    roles ||--o{ usuario_roles : "se asigna"
    roles ||--o{ rol_permisos : "posee"
    permisos ||--o{ rol_permisos : "se concede"

    usuarios {
        uuid usuario_id PK
        varchar nombre_completo
        varchar correo_electronico UK
        varchar clave_hash
        varchar telefono
        text avatar_url
        estado_usuario estado
        timestamp ultimo_ingreso_at
        timestamp creado_at
        timestamp actualizado_at
    }

    roles {
        uuid rol_id PK
        varchar nombre UK
        text descripcion
        timestamp creado_at
        timestamp actualizado_at
    }

    permisos {
        uuid permiso_id PK
        varchar codigo UK
        text descripcion
        timestamp creado_at
        timestamp actualizado_at
    }

    usuario_roles {
        uuid usuario_id PK, FK
        uuid rol_id PK, FK
        timestamp asignado_at
    }

    rol_permisos {
        uuid rol_id PK, FK
        uuid permiso_id PK, FK
        timestamp asignado_at
    }
```

---

## 2. Módulo de Estructura Académica

Define la jerarquía académica: las facultades de la universidad, las carreras (pregrado y posgrado), las mallas curriculares vigentes y las asignaturas con sus respectivos prerrequisitos.

```mermaid
erDiagram
    facultades ||--o{ carreras : "alberga"
    carreras ||--o{ mallas_curriculares : "contiene"
    mallas_curriculares ||--o{ malla_asignaturas : "se compone de"
    asignaturas ||--o{ malla_asignaturas : "forma parte de"
    asignaturas ||--o{ prerrequisitos_asignaturas : "es prerrequisito de"

    facultades {
        uuid facultad_id PK
        varchar codigo UK
        varchar nombre
        text descripcion
        estado_general estado
        timestamp creado_at
        timestamp actualizado_at
    }

    carreras {
        uuid carrera_id PK
        uuid facultad_id FK
        varchar codigo UK
        varchar nombre
        varchar titulo_otorgado
        int duracion_semestres
        nivel_programa nivel_academico
        estado_general estado
        timestamp creado_at
        timestamp actualizado_at
    }

    mallas_curriculares {
        uuid malla_id PK
        uuid carrera_id FK
        varchar version
        varchar nombre
        int anio_inicio
        estado_general estado
        timestamp creado_at
        timestamp actualizado_at
    }

    asignaturas {
        uuid asignatura_id PK
        varchar codigo UK
        varchar nombre
        text descripcion
        int creditos
        int horas_teoria
        int horas_practica
        estado_general estado
        timestamp creado_at
        timestamp actualizado_at
    }

    malla_asignaturas {
        uuid malla_asignatura_id PK
        uuid malla_id FK
        uuid asignatura_id FK
        int numero_semestre
        boolean es_obligatoria
        timestamp creado_at
    }

    prerrequisitos_asignaturas {
        uuid asignatura_id PK, FK
        uuid asignatura_prerrequisito_id PK, FK
    }
```

---

## 3. Módulo de Personas y Perfiles

Modela los perfiles de los actores universitarios. Los perfiles heredan la información base de la tabla `usuarios` (relación 1:1) y añaden datos específicos de su rol.

```mermaid
erDiagram
    usuarios ||--|| estudiantes : "se perfila como"
    usuarios ||--|| docentes : "se perfila como"
    usuarios ||--|| personal_administrativo : "se perfila como"
    carreras ||--o{ estudiantes : "cursa"
    mallas_curriculares ||--o{ estudiantes : "sigue"
    facultades ||--o{ docentes : "pertenece"

    estudiantes {
        uuid estudiante_id PK
        uuid usuario_id FK, UK
        uuid carrera_id FK
        uuid malla_id FK
        varchar codigo_estudiante UK
        varchar numero_documento UK
        date fecha_nacimiento
        varchar direccion
        varchar telefono
        date fecha_admision
        int semestre_actual
        estado_persona_academica estado
        timestamp creado_at
        timestamp actualizado_at
    }

    docentes {
        uuid docente_id PK
        uuid usuario_id FK, UK
        uuid facultad_id FK
        varchar codigo_docente UK
        varchar numero_documento UK
        varchar especialidad
        varchar titulo_academico
        date fecha_contratacion
        estado_general estado
        timestamp creado_at
        timestamp actualizado_at
    }

    personal_administrativo {
        uuid personal_id PK
        uuid usuario_id FK, UK
        varchar codigo_personal UK
        varchar nombre_departamento
        varchar cargo
        estado_general estado
        timestamp creado_at
        timestamp actualizado_at
    }
```

---

## 4. Módulo de Planificación y Horarios

Representa la oferta académica: las aulas físicas, los periodos de tiempo académicos, la apertura de paralelos para impartir asignaturas y los horarios semanales de dichos paralelos.

```mermaid
erDiagram
    periodos_academicos ||--o{ paralelos : "programa"
    asignaturas ||--o{ paralelos : "oferta"
    docentes ||--o{ paralelos : "dicta"
    paralelos ||--o{ horarios_paralelos : "se distribuye en"
    aulas ||--o{ horarios_paralelos : "asigna"

    periodos_academicos {
        uuid periodo_academico_id PK
        varchar codigo UK
        varchar nombre
        date fecha_inicio
        date fecha_fin
        date fecha_inicio_matriculacion
        date fecha_fin_matriculacion
        date fecha_inicio_calificaciones
        date fecha_fin_calificaciones
        estado_periodo estado
        timestamp creado_at
        timestamp actualizado_at
    }

    aulas {
        uuid aula_id PK
        varchar codigo UK
        varchar nombre
        int capacidad
        varchar ubicacion
        estado_general estado
        timestamp creado_at
        timestamp actualizado_at
    }

    paralelos {
        uuid paralelo_id PK
        uuid asignatura_id FK
        uuid periodo_academico_id FK
        uuid docente_id FK
        varchar codigo_paralelo
        modalidad_asignatura modalidad
        int capacidad
        int cantidad_matriculados
        text enlace_virtual
        estado_paralelo estado
        timestamp creado_at
        timestamp actualizado_at
    }

    horarios_paralelos {
        uuid horario_paralelo_id PK
        uuid paralelo_id FK
        uuid aula_id FK
        smallint dia_semana
        time hora_inicio
        time hora_fin
        timestamp creado_at
    }
```

---

## 5. Módulo de Matrículas y Calificaciones

Este módulo registra la inscripción de los estudiantes a los periodos académicos, el detalle de asignaturas inscritas por paralelo, los componentes de evaluación configurados por el docente (deberes, exámenes, etc.) y la nota asignada a cada alumno.

```mermaid
erDiagram
    estudiantes ||--o{ matriculas : "inscribe"
    periodos_academicos ||--o{ matriculas : "registra"
    matriculas ||--o{ matricula_asignaturas : "contiene"
    paralelos ||--o{ matricula_asignaturas : "se inscribe en"
    paralelos ||--o{ componentes_calificacion : "evalua con"
    matricula_asignaturas ||--o{ calificaciones : "recibe"
    componentes_calificacion ||--o{ calificaciones : "pondera"
    usuarios ||--o{ calificaciones : "registrada por"

    matriculas {
        uuid matricula_id PK
        uuid estudiante_id FK
        uuid periodo_academico_id FK
        varchar numero_matricula UK
        estado_matricula estado
        timestamp presentada_at
        uuid aprobada_por FK
        timestamp aprobada_at
        text observaciones
        timestamp creado_at
        timestamp actualizado_at
    }

    matricula_asignaturas {
        uuid matricula_asignatura_id PK
        uuid matricula_id FK
        uuid paralelo_id FK
        estado_asignatura_matricula estado
        numeric calificacion_final
        text observacion_final
        timestamp retirada_at
        timestamp creado_at
        timestamp actualizado_at
    }

    componentes_calificacion {
        uuid componente_calificacion_id PK
        uuid paralelo_id FK
        varchar nombre
        text descripcion
        numeric peso
        numeric puntaje_maximo
        date fecha_entrega
        int indice_orden
        timestamp creado_at
        timestamp actualizado_at
    }

    calificaciones {
        uuid calificacion_id PK
        uuid matricula_asignatura_id FK
        uuid componente_calificacion_id FK
        numeric puntaje
        text retroalimentacion
        uuid registrada_por FK
        timestamp registrada_at
        timestamp creado_at
        timestamp actualizado_at
    }
```

---

## 6. Módulo de Asistencia, Trámites y Documentos

Maneja el registro diario de asistencia por clase, la carga de requisitos o documentos digitales de los estudiantes y el procesamiento de solicitudes académicas y administrativas.

```mermaid
erDiagram
    paralelos ||--o{ sesiones_asistencia : "registra clase"
    usuarios ||--o{ sesiones_asistencia : "creada por"
    sesiones_asistencia ||--o{ registro_asistencia : "contiene"
    matricula_asignaturas ||--o{ registro_asistencia : "registra a"
    estudiantes ||--o{ solicitudes_academicas : "presenta"
    matriculas ||--o{ solicitudes_academicas : "aplica a"
    matricula_asignaturas ||--o{ solicitudes_academicas : "aplica a"
    paralelos ||--o{ solicitudes_academicas : "aplica a"
    usuarios ||--o{ solicitudes_academicas : "revisada por"
    estudiantes ||--o{ documentos_estudiante : "carga"
    usuarios ||--o{ documentos_estudiante : "revisado por"

    sesiones_asistencia {
        uuid sesion_asistencia_id PK
        uuid paralelo_id FK
        date fecha_clase
        varchar tema
        uuid creada_por FK
        timestamp creado_at
        timestamp actualizado_at
    }

    registro_asistencia {
        uuid registro_asistencia_id PK
        uuid sesion_asistencia_id FK
        uuid matricula_asignatura_id FK
        estado_asistencia estado
        text observacion
        timestamp creado_at
        timestamp actualizado_at
    }

    solicitudes_academicas {
        uuid solicitud_academica_id PK
        uuid estudiante_id FK
        tipo_solicitud tipo_solicitud
        uuid matricula_id FK
        uuid matricula_asignatura_id FK
        uuid paralelo_id FK
        text descripcion
        estado_solicitud estado
        uuid revisada_por FK
        timestamp revisada_at
        text respuesta
        timestamp creado_at
        timestamp actualizado_at
    }

    documentos_estudiante {
        uuid documento_estudiante_id PK
        uuid estudiante_id FK
        varchar tipo_documento
        varchar nombre_archivo
        text url_archivo
        estado_documento estado
        uuid revisado_por FK
        timestamp revisado_at
        text observacion
        timestamp cargado_at
        timestamp creado_at
        timestamp actualizado_at
    }
```

---

## 7. Módulo de Auditoría y Notificaciones

Registra logs de operaciones críticas realizadas por los usuarios para seguridad y cumplimiento (audit logs), y gestiona el envío de alertas y notificaciones a los usuarios dentro del sistema.

```mermaid
erDiagram
    usuarios ||--o{ notificaciones : "recibe"
    usuarios ||--o{ registros_auditoria : "realiza accion"

    notificaciones {
        uuid notificacion_id PK
        uuid usuario_id FK
        varchar titulo
        text mensaje
        estado_notificacion estado
        timestamp leido_at
        timestamp creado_at
        timestamp actualizado_at
    }

    registros_auditoria {
        uuid registro_auditoria_id PK
        uuid usuario_actor_id FK
        varchar accion
        varchar nombre_entidad
        uuid entidad_id
        jsonb valores_anteriores
        jsonb valores_nuevos
        varchar direccion_ip
        text agente_usuario
        timestamp creado_at
    }
```
