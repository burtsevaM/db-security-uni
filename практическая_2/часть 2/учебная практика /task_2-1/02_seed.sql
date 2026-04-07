-- Заполнение тестовыми данными

INSERT INTO app.users (username, email, password_hash, full_name) VALUES
('neo', 'neo@zion.local', 'hash_neo', 'Neo Anderson'),
('trinity', 'trinity@zion.local', 'hash_trinity', 'Trinity'),
('leia', 'leia@rebellion.local', 'hash_leia', 'Leia Organa'),
('tony', 'tony@stark.local', 'hash_tony', 'Tony Stark'),
('hermione', 'hermione@hogwarts.local', 'hash_hermione', 'Hermione Granger'),
('sherlock', 'sherlock@bakerstreet.local', 'hash_sherlock', 'Sherlock Holmes');

INSERT INTO app.projects (name, description, owner_id, status) VALUES
('Cyber Shield', 'Платформа для контроля инцидентов и аудита действий', 4, 'active'),
('Star Archive', 'Внутренний архив документов и базы знаний', 3, 'active');

INSERT INTO app.tasks (project_id, title, description, status, priority, assignee_id, created_by) VALUES
(1, 'Настроить журналирование действий', 'Подготовить базовую схему аудита действий пользователей', 'in_progress', 1, 1, 4),
(1, 'Добавить страницу входа', 'Сверстать и подключить форму аутентификации', 'todo', 2, 2, 4),
(1, 'Реализовать роли доступа', 'Добавить разграничение прав admin, manager, analyst', 'review', 1, 3, 4),
(1, 'Подготовить отчет по инцидентам', 'Собрать шаблон ежедневного отчета', 'done', 3, 6, 4),
(1, 'Проверить резервное копирование', 'Провести тестовое восстановление базы данных', 'todo', 2, 5, 4),
(2, 'Создать каталог документов', 'Настроить структуру разделов и метаданные', 'in_progress', 2, 3, 3),
(2, 'Импортировать стартовый архив', 'Загрузить первые записи в архив', 'todo', 3, 1, 3),
(2, 'Настроить поиск по тегам', 'Добавить поиск по ключевым словам и категориям', 'review', 2, 2, 3),
(2, 'Проверить права на чтение', 'Убедиться, что пользователи видят только свои разделы', 'done', 1, 5, 3),
(2, 'Описать правила именования', 'Подготовить инструкцию по оформлению документов', 'todo', 4, 6, 3);

INSERT INTO app.comments (task_id, user_id, content) VALUES
(1, 4, 'Начни с таблицы access_logs и связей с users.'),
(1, 1, 'Базовая структура готова, осталось проверить типы данных.'),
(3, 3, 'Для ролей доступа нужен отдельный уровень проверки прав.'),
(6, 3, 'Каталог документов разбит по отделам и темам.'),
(9, 5, 'Проверка прав завершена, замечаний не найдено.');

INSERT INTO app.task_history (task_id, changed_by, field_name, old_value, new_value) VALUES
(1, 1, 'status', 'todo', 'in_progress'),
(3, 3, 'status', 'in_progress', 'review'),
(4, 6, 'status', 'review', 'done'),
(9, 5, 'status', 'review', 'done');

INSERT INTO app.access_logs (user_id, action, resource_type, resource_id, ip_address) VALUES
(1, 'login', 'system', NULL, '192.168.1.10'),
(4, 'create_project', 'project', 1, '192.168.1.11'),
(3, 'create_project', 'project', 2, '192.168.1.12'),
(2, 'update_task', 'task', 8, '192.168.1.13'),
(5, 'view_report', 'project', 1, '192.168.1.14'),
(6, 'logout', 'system', NULL, '192.168.1.15');