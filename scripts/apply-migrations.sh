#!/bin/bash
set -eo pipefail

# Verificar variables de entorno requeridas
if [ -z "$DB_HOST" ] || [ -z "$DB_DATABASE" ] || [ -z "$DB_USER" ] || [ -z "$DB_PASSWORD" ]; then
    echo "[!] Error: Faltan variables de entorno requeridas para la conexion (DB_HOST, DB_DATABASE, DB_USER, DB_PASSWORD)."
    exit 1
fi

DB_PORT="${DB_PORT:-5432}"

echo "=== Conectando a la base de datos PostgreSQL en $DB_HOST ==="

# Asegurar que existe la tabla de historial de esquema en la base de datos
PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_DATABASE" -c "
CREATE SCHEMA IF NOT EXISTS academico;
CREATE TABLE IF NOT EXISTS academico.schema_history (
    installed_rank SERIAL PRIMARY KEY,
    version VARCHAR(50) UNIQUE NOT NULL,
    description VARCHAR(200),
    script VARCHAR(100) NOT NULL,
    applied_at TIMESTAMP DEFAULT NOW()
);
" > /dev/null

# Buscar archivos de migracion en la carpeta migrations/
MIGRATIONS_DIR="migrations"
if [ ! -d "$MIGRATIONS_DIR" ]; then
    echo "[!] Error: No se encontro el directorio '$MIGRATIONS_DIR'."
    exit 1
fi

# Obtener archivos de migracion ordenados por version (V1, V2, etc.)
files=$(find "$MIGRATIONS_DIR" -name "V*__*.sql" | sort -V)

if [ -z "$files" ]; then
    echo "[i] No se encontraron archivos de migracion."
    exit 0
fi

for file in $files; do
    filename=$(basename "$file")
    # Extraer la version (ej. V1, V2 de V1__init_schema.sql)
    version=$(echo "$filename" | cut -d'_' -f1)
    # Extraer descripcion amigable
    description=$(echo "$filename" | sed -E 's/^V[0-9]+__//' | sed 's/\.sql$//' | tr '_' ' ')

    # Verificar si la migración ya fue aplicada
    already_applied=$(PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_DATABASE" -t -A -c "
        SELECT COUNT(*) FROM academico.schema_history WHERE version = '$version';
    ")

    if [ "$already_applied" -eq 0 ]; then
        echo "[>] Aplicando migración $version ($description) desde el archivo: $filename..."
        
        # Ejecutar la migración
        if PGPASSWORD="$DB_PASSWORD" psql -v ON_ERROR_STOP=1 -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_DATABASE" -f "$file"; then
            # Registrar en el historial de esquema
            PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_DATABASE" -c "
                INSERT INTO academico.schema_history (version, description, script) 
                VALUES ('$version', '$description', '$filename');
            " > /dev/null
            echo "[✓] Migración $version aplicada correctamente."
        else
            echo "[!] Fallo al aplicar la migración $version desde el archivo $filename."
            exit 1
        fi
    else
        echo "[i] Migración $version ya está aplicada. Omitiendo."
    fi
done

echo "=== Proceso de migración finalizado exitosamente ==="
