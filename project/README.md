# Django Recipes — Docker + PostgreSQL

Проект переведён на запуск в Docker (Django + PostgreSQL) и поддерживает:

- выбор хранилища **XML / DB** (как в предыдущем задании);
- AJAX-поиск по данным БД;
- CRUD по рецептам в БД;
- постоянное хранение данных PostgreSQL и статических файлов через **volumes**.

## Что внутри

- `Dockerfile` — сборка образа приложения.
- `docker-compose.yml` — оркестрация `web` (Django) + `db` (PostgreSQL).
- `.dockerignore` — исключения из контекста сборки.
- `.env.example` — пример переменных окружения (секретов в репозитории нет).
- `project/settings.py` — подключение к БД через переменные окружения (`DB_ENGINE=postgres|sqlite`).
- `docker/entrypoint.sh` — ожидание БД, `migrate`, `collectstatic`, запуск `runserver`/`gunicorn`.
- `scripts/migrate_sqlite_to_postgres.sh` — миграция данных из `db.sqlite3` в PostgreSQL.

## Быстрый старт (development)

1) Создайте файл окружения:

```bash
cp .env.example .env
```

2) Запустите сервисы:

```bash
docker compose up --build
```

3) Откройте приложение:

- `http://localhost:8000/`

Данные БД и статика сохраняются между перезапусками:

- PostgreSQL: `postgres_data` (named volume)
- статика: `./staticfiles`
- медиа/файлы: `./media`

## Запуск (production)

Для production достаточно поменять переменные в `.env`:

```env
DJANGO_ENV=production
DJANGO_DEBUG=0
DJANGO_ALLOWED_HOSTS=your-domain.com
DJANGO_SECRET_KEY=very-strong-secret
```

И запустить:

```bash
docker compose up -d --build
```

В production контейнер `web` стартует через **gunicorn** (см. `docker/entrypoint.sh`).

## Переключение хранилища (XML / DB)

На главной странице используйте параметры:

- `view_from=xml|db` — откуда читать
- `save_to=xml|db` — куда сохранять

Например:

- `http://localhost:8000/?view_from=db&save_to=db`

XML-файл хранится в `media/recipes/recipes.xml`.

## Миграция данных SQLite → PostgreSQL

В репозитории есть старая SQLite база `db.sqlite3`. Для переноса данных в PostgreSQL:

### Вариант 1 (скриптом)

```bash
bash scripts/migrate_sqlite_to_postgres.sh
```

Скрипт:

1) делает `dumpdata` приложения `recipes` из SQLite (через `DB_ENGINE=sqlite`),
2) поднимает PostgreSQL,
3) применяет миграции и выполняет `loaddata` в PostgreSQL.

### Вариант 2 (вручную)

1) Снять дамп из SQLite:

```bash
DB_ENGINE=sqlite python manage.py dumpdata recipes --indent 2 > scripts/recipes_fixture.json
```

2) Поднять PostgreSQL и загрузить данные:

```bash
docker compose up -d db
docker compose run --rm web sh -lc "python manage.py migrate --noinput && python manage.py loaddata /app/scripts/recipes_fixture.json"
```

> Файл `scripts/recipes_fixture.json` — артефакт миграции, его можно не коммитить.

## Проверка функционала

После запуска в Docker (PostgreSQL):

- добавление в БД работает (`save_to=db`)
- поиск по БД работает (поле поиска + AJAX)
- редактирование/удаление работает
- проверка на дубликаты использует ORM и корректно работает на PostgreSQL

## Безопасность

- `.env` в репозиторий **не попадает** (см. `.gitignore`).
- секретный ключ и пароли передаются только через переменные окружения.
