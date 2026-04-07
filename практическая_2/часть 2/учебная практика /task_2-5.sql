\c task_management

-- ---------------------------------------------------------
-- Шаг 1. Вспомогательная функция:
-- связываем login-роли demo_* с бизнес-пользователями из app.users
-- ---------------------------------------------------------

CREATE OR REPLACE FUNCTION app.current_business_username()
RETURNS text
LANGUAGE sql
STABLE
AS $$
    SELECT CASE current_user
        WHEN 'demo_employee' THEN 'trinity'
        WHEN 'demo_manager' THEN 'tony'
        WHEN 'demo_admin' THEN 'hermione'
        WHEN 'demo_superuser' THEN 'sherlock'
        ELSE NULL
    END
$$;

GRANT EXECUTE ON FUNCTION app.current_business_username() TO PUBLIC;

-- ---------------------------------------------------------
-- Шаг 2. Дополнительный узкий grant для профиля сотрудника
-- В 2.3 у employee не было UPDATE на app.users,
-- поэтому для демонстрации RLS на users даем право менять только full_name
-- ---------------------------------------------------------

GRANT UPDATE (full_name) ON TABLE app.users TO app_employee;

-- ---------------------------------------------------------
-- Шаг 3. Включаем RLS
-- ---------------------------------------------------------

ALTER TABLE app.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.users ENABLE ROW LEVEL SECURITY;

-- ---------------------------------------------------------
-- Шаг 4. Удаляем старые политики, если скрипт запускается повторно
-- ---------------------------------------------------------

DROP POLICY IF EXISTS tasks_employee_select ON app.tasks;
DROP POLICY IF EXISTS tasks_employee_insert ON app.tasks;
DROP POLICY IF EXISTS tasks_employee_update ON app.tasks;
DROP POLICY IF EXISTS tasks_manager_all ON app.tasks;
DROP POLICY IF EXISTS tasks_admin_all ON app.tasks;
DROP POLICY IF EXISTS tasks_superuser_all ON app.tasks;

DROP POLICY IF EXISTS users_employee_select ON app.users;
DROP POLICY IF EXISTS users_employee_update_own ON app.users;
DROP POLICY IF EXISTS users_admin_all ON app.users;
DROP POLICY IF EXISTS users_superuser_all ON app.users;

-- ---------------------------------------------------------
-- Шаг 5. RLS для app.tasks
-- ---------------------------------------------------------

-- Сотрудник видит только свои задачи
CREATE POLICY tasks_employee_select
ON app.tasks
FOR SELECT
TO app_employee
USING (
    assignee_id = (
        SELECT user_id
        FROM app.users
        WHERE username = app.current_business_username()
    )
);

-- Сотрудник может создавать только задачи на себя
CREATE POLICY tasks_employee_insert
ON app.tasks
FOR INSERT
TO app_employee
WITH CHECK (
    assignee_id = (
        SELECT user_id
        FROM app.users
        WHERE username = app.current_business_username()
    )
    AND created_by = (
        SELECT user_id
        FROM app.users
        WHERE username = app.current_business_username()
    )
);

-- Сотрудник может обновлять только свои задачи
CREATE POLICY tasks_employee_update
ON app.tasks
FOR UPDATE
TO app_employee
USING (
    assignee_id = (
        SELECT user_id
        FROM app.users
        WHERE username = app.current_business_username()
    )
)
WITH CHECK (
    assignee_id = (
        SELECT user_id
        FROM app.users
        WHERE username = app.current_business_username()
    )
);

-- Менеджер видит и изменяет задачи только своих проектов
CREATE POLICY tasks_manager_all
ON app.tasks
FOR ALL
TO app_manager
USING (
    project_id IN (
        SELECT project_id
        FROM app.projects
        WHERE owner_id = (
            SELECT user_id
            FROM app.users
            WHERE username = app.current_business_username()
        )
    )
)
WITH CHECK (
    project_id IN (
        SELECT project_id
        FROM app.projects
        WHERE owner_id = (
            SELECT user_id
            FROM app.users
            WHERE username = app.current_business_username()
        )
    )
);

-- Администратор видит и изменяет все задачи
CREATE POLICY tasks_admin_all
ON app.tasks
FOR ALL
TO app_admin
USING (TRUE)
WITH CHECK (TRUE);

-- Верхняя роль приложения видит и изменяет все задачи
CREATE POLICY tasks_superuser_all
ON app.tasks
FOR ALL
TO app_superuser
USING (TRUE)
WITH CHECK (TRUE);

-- ---------------------------------------------------------
-- Шаг 6. RLS для app.users
-- ---------------------------------------------------------

-- Сотрудник видит все строки users,
-- но только те колонки, на которые уже есть SELECT из 2.3
CREATE POLICY users_employee_select
ON app.users
FOR SELECT
TO app_employee
USING (TRUE);

-- Сотрудник может обновлять только свою строку
CREATE POLICY users_employee_update_own
ON app.users
FOR UPDATE
TO app_employee
USING (
    username = app.current_business_username()
)
WITH CHECK (
    username = app.current_business_username()
);

-- Администратор имеет полный доступ к users
CREATE POLICY users_admin_all
ON app.users
FOR ALL
TO app_admin
USING (TRUE)
WITH CHECK (TRUE);

-- Верхняя роль приложения имеет полный доступ к users
CREATE POLICY users_superuser_all
ON app.users
FOR ALL
TO app_superuser
USING (TRUE)
WITH CHECK (TRUE);

-- ---------------------------------------------------------
-- Шаг 7. Проверка созданных политик
-- ---------------------------------------------------------

SELECT
    schemaname,
    tablename,
    policyname,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE schemaname = 'app'
ORDER BY tablename, policyname;