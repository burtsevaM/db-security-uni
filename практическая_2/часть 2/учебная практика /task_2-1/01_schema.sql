-- Задание 2.1
-- Создание базы данных и схемы

CREATE DATABASE task_management;

\c task_management;

CREATE SCHEMA app;

-- Таблица пользователей
CREATE TABLE app.users (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Таблица проектов
CREATE TABLE app.projects (
    project_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    owner_id INTEGER REFERENCES app.users(user_id),
    status VARCHAR(20) DEFAULT 'active'
        CHECK (status IN ('active', 'completed', 'archived')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Таблица задач
CREATE TABLE app.tasks (
    task_id SERIAL PRIMARY KEY,
    project_id INTEGER REFERENCES app.projects(project_id),
    title VARCHAR(200) NOT NULL,
    description TEXT,
    status VARCHAR(20) DEFAULT 'todo'
        CHECK (status IN ('todo', 'in_progress', 'review', 'done')),
    priority INTEGER DEFAULT 3
        CHECK (priority BETWEEN 1 AND 5),
    assignee_id INTEGER REFERENCES app.users(user_id),
    created_by INTEGER REFERENCES app.users(user_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Таблица комментариев
CREATE TABLE app.comments (
    comment_id SERIAL PRIMARY KEY,
    task_id INTEGER REFERENCES app.tasks(task_id),
    user_id INTEGER REFERENCES app.users(user_id),
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Таблица истории изменений задач
CREATE TABLE app.task_history (
    history_id SERIAL PRIMARY KEY,
    task_id INTEGER REFERENCES app.tasks(task_id),
    changed_by INTEGER REFERENCES app.users(user_id),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    field_name VARCHAR(50) NOT NULL,
    old_value TEXT,
    new_value TEXT
);

-- Таблица логов доступа
CREATE TABLE app.access_logs (
    log_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES app.users(user_id),
    action VARCHAR(50) NOT NULL,
    resource_type VARCHAR(50),
    resource_id INTEGER,
    ip_address INET,
    logged_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);