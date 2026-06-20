# Esquema de Base de Datos - Sistema de Gestión Académica

Este repositorio contiene la definición central del esquema de base de datos para el **Sistema de Gestión Académica**. Actúa como la única fuente de verdad para la estructura del esquema, triggers, índices y datos iniciales (semillas) consumidos por todos los servicios de la organización de GitHub.

## 🚀 Desarrollo Local con Docker

Para levantar la base de datos localmente con todo el esquema e información inicial precargados, asegúrate de tener Docker instalado y ejecuta el siguiente comando en la raíz del repositorio:

```bash
docker compose up -d
```

### 🔑 Credenciales de Conexión Local

* **Host:** `localhost`
* **Port:** `5432`
* **Database:** `academic_management_db`
* **User:** `academic_user`
* **Password:** `academic_password`

---

## 📁 Estructura del Repositorio

* `migrations/`: Contiene los archivos SQL versionados de esquema y migración.
  * `V1__init_schema.sql`: Contiene las tablas base, tipos ENUM, triggers de auditoría de tiempo (`updated_at`), índices y datos de configuración inicial (roles y permisos).
* `docker-compose.yml`: Archivo de orquestación de Docker para el entorno local.

---

## 🧩 Resumen del Esquema

El esquema (`academic`) está diseñado para modelar los siguientes dominios:

1. **Usuarios, Roles y Permisos (`users`, `roles`, `permissions`)**: Seguridad basada en roles (RBAC) con contraseñas seguras y auditoría.
2. **Estructura Académica (`faculties`, `programs`, `curricula`, `courses`)**: Facultades, carreras, mallas curriculares y asignaturas con prerrequisitos.
3. **Personas Académicas (`students`, `teachers`, `administrative_staff`)**: Datos específicos de estudiantes, docentes y personal de apoyo.
4. **Planificación y Horarios (`academic_periods`, `classrooms`, `course_sections`, `section_schedules`)**: Gestión de periodos lectivos, aulas, paralelos e itinerario semanal.
5. **Matrículas e Inscripciones (`enrollments`, `enrollment_courses`)**: Registro e historial de estudiantes inscritos en paralelos específicos.
6. **Calificaciones y Asistencia (`grade_items`, `grades`, `attendance_sessions`, `attendance_records`)**: Registro detallado de notas con ponderaciones y asistencia diaria.
7. **Flujos Administrativos (`academic_requests`, `student_documents`)**: Solicitudes de estudiantes y validación de documentación digital.
8. **Notificaciones y Auditoría (`notifications`, `audit_logs`)**: Alertas al usuario y registro de eventos/cambios en el sistema con soporte JSONB.

---

## 🛠️ Reglas para Modificaciones de Base de Datos (Flujo GitOps)

Dado que múltiples repositorios dependen de esta base de datos, sigue estas reglas para realizar cambios en el esquema:

1. **Nunca modifiques un archivo de migración existente** (como `V1__init_schema.sql`) una vez que haya sido desplegado a entornos compartidos.
2. Para cualquier cambio (añadir tablas, columnas, índices), crea un nuevo archivo de migración en la carpeta `migrations/` con la nomenclatura:
   `V<NÚMERO_SECUENCIAL>__descripción_corta.sql` (Ejemplo: `V2__add_student_status.sql`).
3. Abre un Pull Request en este repositorio para revisión y aprobación del equipo.
4. Una vez aprobado y fusionado a `main`, el pipeline de CI/CD aplicará automáticamente la migración en los entornos correspondientes (Desarrollo, Staging, Producción).
