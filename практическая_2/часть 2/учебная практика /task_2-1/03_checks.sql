-- Проверка 1. Текущая база
SELECT current_database() AS current_db;

-- Проверка 2. Какие таблицы созданы в схеме app
SELECT schemaname, tablename
FROM pg_tables
WHERE schemaname = 'app'
ORDER BY tablename;

-- Проверка 3. Количество записей
SELECT COUNT(*) AS users_count FROM app.users;
SELECT COUNT(*) AS projects_count FROM app.projects;
SELECT COUNT(*) AS tasks_count FROM app.tasks;
SELECT COUNT(*) AS comments_count FROM app.comments;
SELECT COUNT(*) AS history_count FROM app.task_history;
SELECT COUNT(*) AS access_logs_count FROM app.access_logs;

-- Проверка 4. Список задач вместе с проектом, исполнителем и автором
SELECT
    t.task_id,
    t.title,
    p.name AS project_name,
    assignee.full_name AS assignee_name,
    creator.full_name AS created_by,
    t.status,
    t.priority
FROM app.tasks t
JOIN app.projects p ON t.project_id = p.project_id
LEFT JOIN app.users assignee ON t.assignee_id = assignee.user_id
LEFT JOIN app.users creator ON t.created_by = creator.user_id
ORDER BY t.task_id;

-- Проверка 5. Сколько задач в каждом проекте
SELECT
    p.project_id,
    p.name,
    COUNT(t.task_id) AS tasks_in_project
FROM app.projects p
LEFT JOIN app.tasks t ON p.project_id = t.project_id
GROUP BY p.project_id, p.name
ORDER BY p.project_id;

-- Проверка 6. Количество задач по статусам
SELECT
    status,
    COUNT(*) AS total
FROM app.tasks
GROUP BY status
ORDER BY status;

-- Проверка 7. Проверка ссылочной целостности:
-- нет ли задач без существующего проекта или автора
SELECT
    t.task_id,
    t.title
FROM app.tasks t
LEFT JOIN app.projects p ON t.project_id = p.project_id
LEFT JOIN app.users u ON t.created_by = u.user_id
WHERE p.project_id IS NULL OR u.user_id IS NULL;

-- Проверка 8. Комментарии по задачам
SELECT
    c.comment_id,
    t.title AS task_title,
    u.full_name AS author,
    c.content
FROM app.comments c
JOIN app.tasks t ON c.task_id = t.task_id
JOIN app.users u ON c.user_id = u.user_id
ORDER BY c.comment_id;

-- Проверка 9. Логи доступа
SELECT
    l.log_id,
    u.full_name,
    l.action,
    l.resource_type,
    l.resource_id,
    l.ip_address,
    l.logged_at
FROM app.access_logs l
LEFT JOIN app.users u ON l.user_id = u.user_id
ORDER BY l.log_id;