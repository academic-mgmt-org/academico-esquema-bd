#!/bin/sh
set -eu

if [ "${1:-}" = "postgres" ]; then
  ssl_dir="${POSTGRES_SSL_DIR:-/var/lib/postgresql/ssl}"
  ssl_cert_file="${POSTGRES_SSL_CERT_FILE:-$ssl_dir/server.crt}"
  ssl_key_file="${POSTGRES_SSL_KEY_FILE:-$ssl_dir/server.key}"
  ssl_days="${POSTGRES_SSL_DAYS:-3650}"
  ssl_common_name="${POSTGRES_SSL_CN:-localhost}"

  mkdir -p "$ssl_dir"

  if [ ! -s "$ssl_cert_file" ] || [ ! -s "$ssl_key_file" ]; then
    openssl req -new -x509 -days "$ssl_days" -nodes \
      -out "$ssl_cert_file" \
      -keyout "$ssl_key_file" \
      -subj "/CN=$ssl_common_name"
  fi

  chown -R postgres:postgres "$ssl_dir"
  chmod 700 "$ssl_dir"
  chmod 600 "$ssl_key_file"
  chmod 644 "$ssl_cert_file"
fi

exec /usr/local/bin/docker-entrypoint.sh "$@"
