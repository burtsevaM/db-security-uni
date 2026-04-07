\c task_management

-- ---------------------------------------------------------
-- Шаг 1. Создание групповых ролей без LOGIN
-- ---------------------------------------------------------

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app_guest') THEN
        EXECUTE 'CREATE ROLE app_guest NOLOGIN';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app_employee') THEN
        EXECUTE 'CREATE ROLE app_employee NOLOGIN';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app_manager') THEN
        EXECUTE 'CREATE ROLE app_manager NOLOGIN';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app_admin') THEN
        EXECUTE 'CREATE ROLE app_admin NOLOGIN';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app_superuser') THEN
        EXECUTE 'CREATE ROLE app_superuser NOLOGIN';
    END IF;
END
$$;

-- ---------------------------------------------------------
-- Шаг 2. Настройка иерархии ролей
-- guest -> employee -> manager -> admin -> superuser
-- ---------------------------------------------------------

GRANT app_guest TO app_employee;
GRANT app_employee TO app_manager;
GRANT app_manager TO app_admin;
GRANT app_admin TO app_superuser;

-- ---------------------------------------------------------
-- Шаг 3. Доступ к базе и схеме
-- ---------------------------------------------------------

GRANT CONNECT ON DATABASE task_management
TO app_guest, app_employee, app_manager, app_admin, app_superuser;

GRANT USAGE ON SCHEMA app
TO app_guest, app_employee, app_manager, app_admin, app_superuser;

-- ---------------------------------------------------------
-- Шаг 4. Права для app_guest
-- Гость может только просматривать список проектов
-- ---------------------------------------------------------

GRANT SELECT ON TABLE app.projects TO app_guest;

-- ---------------------------------------------------------
-- Шаг 5. Права для app_employee
-- Сотрудник работает с задачами, комментариями и читает основные данные
-- ---------------------------------------------------------

-- Ограниченное чтение пользователей без email и password_hash
GRANT SELECT (user_id, username, full_name, is_active, created_at)
ON TABLE app.users TO app_employee;

-- Чтение прикладных таблиц
GRANT SELECT ON TABLE app.projects TO app_employee;
GRANT SELECT ON TABLE app.tasks TO app_employee;
GRANT SELECT ON TABLE app.comments TO app_employee;
GRANT SELECT ON TABLE app.task_history TO app_employee;

-- Работа с задачами
GRANT INSERT, UPDATE ON TABLE app.tasks TO app_employee;

-- Работа с комментариями
GRANT INSERT ON TABLE app.comments TO app_employee;

-- Для SERIAL-полей
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA app TO app_employee;

-- ---------------------------------------------------------
-- Шаг 6. Права для app_manager
-- Менеджер наследует employee и получает расширенные права
-- ---------------------------------------------------------

-- Работа с проектами
GRANT INSERT, UPDATE, DELETE ON TABLE app.projects TO app_manager;

-- Полный доступ к задачам
GRANT INSERT, UPDATE, DELETE ON TABLE app.tasks TO app_manager;

-- Расширенный доступ к комментариям
GRANT DELETE ON TABLE app.comments TO app_manager;

-- Запись истории изменений
GRANT INSERT ON TABLE app.task_history TO app_manager;

-- ---------------------------------------------------------
-- Шаг 7. Права для app_admin
-- Администратор наследует manager и получает полный доступ к схеме app
-- ---------------------------------------------------------

-- Управление пользователями
GRANT SELECT, INSERT, UPDATE ON TABLE app.users TO app_admin;

-- Полный доступ ко всем таблицам и последовательностям
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA app TO app_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA app TO app_admin;

-- Право создавать объекты в схеме
GRANT CREATE ON SCHEMA app TO app_admin;

-- ---------------------------------------------------------
-- Шаг 8. Права для app_superuser
-- Это верхняя роль приложения, не системный PostgreSQL SUPERUSER
-- ---------------------------------------------------------

GRANT ALL PRIVILEGES ON DATABASE task_management TO app_superuser;
GRANT ALL PRIVILEGES ON SCHEMA app TO app_superuser;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA app TO app_superuser;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA app TO app_superuser;

-- ---------------------------------------------------------
-- Шаг 9. Создание тестовых LOGIN-ролей
-- Они нужны только для демонстрации и проверки
-- ---------------------------------------------------------

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'demo_guest') THEN
        EXECUTE 'CREATE ROLE demo_guest LOGIN PASSWORD ''GuestPass123!''';
    ELSE
        EXECUTE 'ALTER ROLE demo_guest LOGIN PASSWORD ''GuestPass123!''';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'demo_employee') THEN
        EXECUTE 'CREATE ROLE demo_employee LOGIN PASSWORD ''EmployeePass123!''';
    ELSE
        EXECUTE 'ALTER ROLE demo_employee LOGIN PASSWORD ''EmployeePass123!''';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'demo_manager') THEN
        EXECUTE 'CREATE ROLE demo_manager LOGIN PASSWORD ''ManagerPass123!''';
    ELSE
        EXECUTE 'ALTER ROLE demo_manager LOGIN PASSWORD ''ManagerPass123!''';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'demo_admin') THEN
        EXECUTE 'CREATE ROLE demo_admin LOGIN PASSWORD ''AdminPass123!''';
    ELSE
        EXECUTE 'ALTER ROLE demo_admin LOGIN PASSWORD ''AdminPass123!''';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'demo_superuser') THEN
        EXECUTE 'CREATE ROLE demo_superuser LOGIN PASSWORD ''SuperPass123!''';
    ELSE
        EXECUTE 'ALTER ROLE demo_superuser LOGIN PASSWORD ''SuperPass123!''';
    END IF;
END
$$;

-- ---------------------------------------------------------
-- Шаг 10. Назначение приложенческих ролей LOGIN-пользователям
-- ---------------------------------------------------------

GRANT app_guest TO demo_guest;
GRANT app_employee TO demo_employee;
GRANT app_manager TO demo_manager;
GRANT app_admin TO demo_admin;
GRANT app_superuser TO demo_superuser;

-- ---------------------------------------------------------
-- Шаг 11. Проверка результата
-- ---------------------------------------------------------

\echo '=== СПИСОК РОЛЕЙ ==='
\du

\echo '=== ИЕРАРХИЯ РОЛЕЙ ==='
SELECT
    parent.rolname AS granted_role,
    child.rolname  AS member_role
FROM pg_auth_members m
JOIN pg_roles parent ON parent.oid = m.roleid
JOIN pg_roles child  ON child.oid = m.member
WHERE parent.rolname IN ('app_guest', 'app_employee', 'app_manager', 'app_admin', 'app_superuser')
ORDER BY parent.rolname, child.rolname;

\echo '=== ПРИВИЛЕГИИ НА ТАБЛИЦЫ ==='
SELECT
    grantee,
    table_schema,
    table_name,
    privilege_type
FROM information_schema.table_privileges
WHERE table_schema = 'app'
  AND grantee IN ('app_guest', 'app_employee', 'app_manager', 'app_admin', 'app_superuser')
ORDER BY grantee, table_name, privilege_type;