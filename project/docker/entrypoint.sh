#!/usr/bin/env sh
set -e

APP_PORT="${APP_PORT:-8000}"
DJANGO_ENV="${DJANGO_ENV:-development}"

echo "[entrypoint] DJANGO_ENV=${DJANGO_ENV}"

# Wait for postgres if configured
if [ "${DB_ENGINE:-postgres}" = "postgres" ]; then
  HOST="${POSTGRES_HOST:-db}"
  PORT="${POSTGRES_PORT:-5432}"
  echo "[entrypoint] waiting for postgres ${HOST}:${PORT}..."
  while ! nc -z "$HOST" "$PORT"; do
    sleep 1
  done
  echo "[entrypoint] postgres is available"
fi

python manage.py migrate --noinput

# collectstatic only when STATIC_ROOT is writable
python manage.py collectstatic --noinput || true

if [ "$DJANGO_ENV" = "production" ]; then
  echo "[entrypoint] starting gunicorn..."
  exec gunicorn project.wsgi:application \
    --bind 0.0.0.0:${APP_PORT} \
    --workers ${GUNICORN_WORKERS:-3} \
    --timeout ${GUNICORN_TIMEOUT:-60}
else
  echo "[entrypoint] starting django runserver..."
  exec python manage.py runserver 0.0.0.0:${APP_PORT}
fi
