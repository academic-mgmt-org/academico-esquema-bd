# Esquema de Base de Datos - Sistema de Gestión Académica

Este repositorio contiene la definición central del esquema de base de datos para el **Sistema de Gestión Académica**. Actúa como la única fuente de verdad para la estructura del esquema, triggers, índices y datos iniciales (semillas) consumidos por todos los servicios de la organización de GitHub.

---

## 🚀 Desarrollo Local con Docker

Para levantar la base de datos localmente con todo el esquema e información inicial precargados, asegúrate de tener Docker instalado y ejecuta el siguiente comando en la raíz del repositorio:

```bash
docker compose up -d
```

---

## 📁 Estructura del Repositorio

* `migrations/`: Contiene los archivos SQL versionados de esquema y migración.
  * `V1__init_schema.sql`: Contiene el esquema completo traducido al español, incluyendo tablas base, tipos ENUM, triggers de auditoría, índices y configuraciones iniciales.
* `scripts/`: Scripts auxiliares de desarrollo y automatización.
  * `apply-migrations.sh`: Script ejecutable encargado de aplicar las migraciones de forma secuencial y llevar el historial.
* `azure-pipelines.yml`: Pipeline de Azure DevOps para publicar el esquema en la base de datos de produccion.
* `.github/workflows/`: Flujo historico de GitHub Actions. No se usa para el despliegue principal en Azure DevOps.
* `docker-compose.yml`: Archivo de orquestación de Docker para el entorno local.

---

## 🧩 Resumen del Esquema

El esquema (`academico`) está diseñado para modelar los siguientes dominios:

1. **Usuarios, Roles y Permisos (`usuarios`, `roles`, `permisos`)**: Seguridad basada en roles (RBAC) con contraseñas seguras y auditoría.
2. **Estructura Académica (`facultades`, `carreras`, `mallas_curriculares`, `asignaturas`)**: Facultades, carreras (con clasificación de pregrado/posgrado), mallas curriculares y asignaturas con prerrequisitos.
3. **Personas Académicas (`estudiantes`, `docentes`, `personal_administrativo`)**: Datos específicos de estudiantes, docentes y personal de apoyo.
4. **Planificación y Horarios (`periodos_academicos`, `aulas`, `paralelos`, `horarios_paralelos`)**: Gestión de periodos lectivos, aulas, paralelos e itinerario semanal.
5. **Matrículas e Inscripciones (`matriculas`, `matricula_asignaturas`)**: Registro e historial de estudiantes inscritos en paralelos específicos.
6. **Calificaciones y Asistencia (`componentes_calificacion`, `calificaciones`, `sesiones_asistencia`, `registro_asistencia`)**: Registro detallado de notas con ponderaciones y asistencia diaria.
7. **Flujos Administrativos (`solicitudes_academicas`, `documentos_estudiante`)**: Solicitudes de estudiantes y validación de documentación digital.
8. **Notificaciones y Auditoría (`notificaciones`, `registros_auditoria`)**: Alertas al usuario y registro de eventos/cambios en el sistema con soporte JSONB.

---

## ⚙️ Despliegue en Azure DevOps

El repositorio esta configurado con **Azure DevOps Pipelines** en el proyecto `academico-estudiantes` para aplicar las migraciones SQL en la base de datos de produccion.

El pipeline se llama `academico-esquema-bd-deploy-prod` y usa el archivo `azure-pipelines.yml`. La ejecucion de produccion es manual (`trigger: none`) para evitar despliegues accidentales.

### Variables del Pipeline
Para que el despliegue funcione, las credenciales estan configuradas en el variable group de Azure DevOps `academico-db-production`:

* `DB_HOST`: Host de la base de datos de Azure.
* `DB_PORT`: Puerto de conexión (por defecto `5432`).
* `DB_DATABASE`: Nombre de la base de datos objetivo.
* `DB_USER`: Usuario administrador de la base de datos.
* `DB_PASSWORD`: Contraseña del usuario administrador, configurada como variable secreta.

El pipeline lee estas variables de forma segura en tiempo de ejecucion y ejecuta `scripts/apply-migrations.sh` desde el agente `self-hosted-agent` del pool `Default`.

---

## 🛠️ Guía Paso a Paso para Modificar la Base de Datos

Dado que múltiples repositorios dependen de esta base de datos, sigue estas reglas para realizar cambios en el esquema.

### Reglas Clave:
1. **Nunca modifiques un archivo de migración existente** (como `V1__init_schema.sql`) una vez que haya sido desplegado.
2. Toda modificación debe realizarse mediante un nuevo archivo SQL incremental en la carpeta `migrations/`.
3. Nombra las nuevas migraciones con la estructura: `V<NÚMERO_SECUENCIAL>__descripción_corta.sql` (usa doble guion bajo `__` después de la versión).
4. No uses acentos ni el carácter `ñ` en nombres de tablas, columnas u otros identificadores SQL.

### Ejemplo de flujo para una nueva migración:

Supongamos que deseas añadir una nueva columna llamada `observacion` a la tabla `estudiantes`.

1. **Crear el archivo SQL localmente:**
   Crea el archivo `migrations/V2__agregar_observacion_estudiante.sql` con el siguiente contenido:
   ```sql
   -- Añadir columna de observación opcional a la tabla estudiantes
   ALTER TABLE academico.estudiantes 
   ADD COLUMN observacion VARCHAR(255);
   ```

2. **Probar localmente (Opcional):**
   Puedes aplicar el cambio en tu base de datos local de desarrollo para pruebas.

3. **Subir los cambios a GitHub:**
   Agrega el archivo al commit y haz push:
   ```bash
   git add migrations/V2__agregar_observacion_estudiante.sql
   git commit -m "Añadir columna observacion a estudiantes"
   git push origin main
   ```

4. **Despliegue en Azure DevOps:**
   * Ejecuta manualmente el pipeline **academico-esquema-bd-deploy-prod** desde Azure DevOps.
   * El agente comparara las migraciones existentes contra la tabla `academico.schema_history` en Azure.
   * Al notar que `V2` no ha sido ejecutado, aplicara unicamente el script `V2__agregar_observacion_estudiante.sql` y registrara el exito de la migracion en el historial.
