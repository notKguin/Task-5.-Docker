#!/usr/bin/env bash
set -euo pipefail

# Миграция данных из SQLite (db.sqlite3 в корне проекта) в PostgreSQL (из docker-compose).
# Скрипт НЕ хранит пароли — берёт их из .env.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIXTURE_PATH="${ROOT_DIR}/scripts/recipes_fixture.json"

echo "[migrate] 1) Делаем fixture из SQLite -> ${FIXTURE_PATH}"
(
  cd "${ROOT_DIR}"
  DB_ENGINE=sqlite python manage.py dumpdata recipes --indent 2 > "${FIXTURE_PATH}"
)

echo "[migrate] 2) Поднимаем PostgreSQL (если ещё не поднят)"
(
  cd "${ROOT_DIR}"
  docker compose up -d db
)

echo "[migrate] 3) Применяем миграции и загружаем данные в PostgreSQL"
(
  cd "${ROOT_DIR}"
  docker compose run --rm web sh -lc "python manage.py migrate --noinput && python manage.py loaddata /app/scripts/recipes_fixture.json"
)

echo "[migrate] Done ✅"