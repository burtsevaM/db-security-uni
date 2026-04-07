#!/bin/zsh

DB="task_management"
HOST="localhost"

echo "=================================================="
echo "ТЕСТ 1. GUEST"
echo "=================================================="

PGPASSWORD='GuestPass123!' psql -X -h "$HOST" -U demo_guest -d "$DB" <<'SQL'
\pset pager off
\echo '--- кто подключен ---'
SELECT current_user, session_user;

\echo '--- guest: может читать projects ---'
SELECT project_id, name, status
FROM app.projects
ORDER BY project_id;

\echo '--- guest: не может вставлять tasks (ожидается ERROR) ---'
INSERT INTO app.tasks (project_id, title, description, status, priority, assignee_id, created_by)
VALUES (1, 'Guest test task', 'should fail', 'todo', 3, 1, 1);

\echo '--- guest: не может читать users (ожидается ERROR) ---'
SELECT * FROM app.users LIMIT 1;
SQL

echo
echo "=================================================="
echo "ТЕСТ 2. EMPLOYEE"
echo "=================================================="

PGPASSWORD='EmployeePass123!' psql -X -h "$HOST" -U demo_employee -d "$DB" <<'SQL'
\pset pager off
\echo '--- кто подключен ---'
SELECT current_user, session_user;

\echo '--- employee: может читать только разрешенные колонки users ---'
SELECT user_id, username, full_name, is_active, created_at
FROM app.users
ORDER BY user_id
LIMIT 5;

\echo '--- employee: не может читать email (ожидается ERROR) ---'
SELECT email
FROM app.users
LIMIT 1;

\echo '--- employee: может читать projects ---'
SELECT project_id, name, status
FROM app.projects
ORDER BY project_id;

\echo '--- employee: может читать tasks ---'
SELECT task_id, title, status, priority
FROM app.tasks
ORDER BY task_id
LIMIT 5;

\echo '--- employee: может читать comments ---'
SELECT comment_id, task_id, user_id
FROM app.comments
ORDER BY comment_id
LIMIT 5;

\echo '--- employee: может читать task_history ---'
SELECT history_id, task_id, changed_by, field_name
FROM app.task_history
ORDER BY history_id
LIMIT 5;

\echo '--- employee: может INSERT/UPDATE tasks и INSERT comments; изменения откатываем ---'
BEGIN;
INSERT INTO app.tasks (project_id, title, description, status, priority, assignee_id, created_by)
VALUES (1, 'Employee test task', '2.4 access test', 'todo', 3, 2, 2);

UPDATE app.tasks
SET status = 'review'
WHERE task_id = 1;

INSERT INTO app.comments (task_id, user_id, content)
VALUES (1, 2, 'Employee comment in 2.4 test');
ROLLBACK;

\echo '--- employee: не может DELETE tasks (ожидается ERROR) ---'
DELETE FROM app.tasks
WHERE task_id = 1;
SQL

echo
echo "=================================================="
echo "ТЕСТ 3. MANAGER"
echo "=================================================="

PGPASSWORD='ManagerPass123!' psql -X -h "$HOST" -U demo_manager -d "$DB" <<'SQL'
\pset pager off
\echo '--- кто подключен ---'
SELECT current_user, session_user;

\echo '--- manager: может изменять projects, tasks, comments, task_history; изменения откатываем ---'
BEGIN;

INSERT INTO app.projects (name, description, owner_id, status)
VALUES ('Manager temp project', '2.4 access test', 1, 'active');

UPDATE app.tasks
SET status = 'done'
WHERE task_id = 2;

DELETE FROM app.comments
WHERE comment_id = 1;

INSERT INTO app.task_history (task_id, changed_by, field_name, old_value, new_value)
VALUES (2, 1, 'status', 'todo', 'done');

ROLLBACK;

\echo '--- manager: не может изменять users (ожидается ERROR) ---'
UPDATE app.users
SET full_name = 'Hacked Name'
WHERE user_id = 2;
SQL

echo
echo "=================================================="
echo "ТЕСТ 4. ADMIN"
echo "=================================================="

PGPASSWORD='AdminPass123!' psql -X -h "$HOST" -U demo_admin -d "$DB" <<'SQL'
\pset pager off
\echo '--- кто подключен ---'
SELECT current_user, session_user;

\echo '--- admin: может читать users и access_logs ---'
SELECT user_id, username, email
FROM app.users
ORDER BY user_id
LIMIT 5;

SELECT log_id, user_id, action, resource_type
FROM app.access_logs
ORDER BY log_id
LIMIT 5;

\echo '--- admin: может менять users и создавать объекты в схеме app; изменения откатываем ---'
BEGIN;
UPDATE app.users
SET full_name = 'Temp Admin Update'
WHERE user_id = 2;

CREATE TABLE app.test_admin_24 (id INT);
DROP TABLE app.test_admin_24;
ROLLBACK;
SQL

echo
echo "=================================================="
echo "ТЕСТ 5. SUPERUSER"
echo "=================================================="

PGPASSWORD='SuperPass123!' psql -X -h "$HOST" -U demo_superuser -d "$DB" <<'SQL'
\pset pager off
\echo '--- кто подключен ---'
SELECT current_user, session_user;

\echo '--- superuser: полный доступ к таблицам схемы app ---'
SELECT COUNT(*) AS access_logs_count
FROM app.access_logs;

\echo '--- superuser: может создавать и удалять объекты; изменения откатываем ---'
BEGIN;
CREATE TABLE app.test_superuser_24 (id INT);
DROP TABLE app.test_superuser_24;
ROLLBACK;
SQL

echo
echo "=================================================="
echo "ДОПОЛНИТЕЛЬНАЯ ПРОВЕРКА ВЫДАННЫХ ПРАВ"
echo "=================================================="

psql -X -d "$DB" <<'SQL'
\pset pager off
SELECT
    grantee,
    table_name,
    privilege_type
FROM information_schema.role_table_grants
WHERE table_schema = 'app'
  AND grantee IN ('app_guest', 'app_employee', 'app_manager', 'app_admin', 'app_superuser')
ORDER BY grantee, table_name, privilege_type;

SELECT
    grantee,
    table_name,
    column_name,
    privilege_type
FROM information_schema.role_column_grants
WHERE table_schema = 'app'
  AND grantee IN ('app_employee', 'app_admin')
ORDER BY grantee, table_name, column_name, privilege_type;
SQL