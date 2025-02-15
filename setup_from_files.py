# setup_from_files.py

import os
import psycopg2
from psycopg2 import extensions
import sqlparse  # pip install sqlparse

# Параметры административного подключения (база "postgres")
ADMIN_DB_PARAMS = {
    "dbname": "postgres",
    "user": "postgres",
    "password": "postgres",  # замените на свой пароль
    "host": "localhost",     # можно использовать "localhost"
    "port": "5432"
}

# Имя создаваемой базы данных
NEW_DB_NAME = "spacesimdb"

# Директория, где лежат SQL-файлы
SQL_DIR = "./"  # если файлы находятся в той же директории, что и скрипт

# Список файлов для выполнения в нужном порядке
SQL_FILES_ORDER = [
    "CreateDatabase.sql",
    "Tables.sql",
    "FunctionsAndProcedures.sql",
    "Triggers.sql",
    "Views.sql",
    "Inserts.sql"
]

def read_sql_file(filename):
    """Читает содержимое файла с SQL-запросами."""
    with open(filename, 'r', encoding='utf-8') as f:
        return f.read()

def execute_sql(sql_script, conn):
    """
    Выполняет SQL-скрипт в переданном соединении.
    Для корректного разделения SQL-операторов используется sqlparse.
    """
    try:
        with conn.cursor() as cur:
            statements = sqlparse.split(sql_script)
            for stmt in statements:
                stmt = stmt.strip()
                if stmt:
                    cur.execute(stmt)
        conn.commit()
        print("Скрипт выполнен успешно.")
    except Exception as e:
        conn.rollback()
        print(f"Ошибка при выполнении скрипта: {e}")

def execute_admin_sql(sql_script):
    """
    Выполняет SQL-скрипт через административное подключение (к базе postgres).
    Скрипт разбивается с помощью sqlparse.
    """
    conn = None
    try:
        conn = psycopg2.connect(**ADMIN_DB_PARAMS)
        # Устанавливаем автокоммит (важно для команд типа DROP DATABASE)
        conn.set_isolation_level(extensions.ISOLATION_LEVEL_AUTOCOMMIT)
        with conn.cursor() as cur:
            statements = sqlparse.split(sql_script)
            for stmt in statements:
                stmt = stmt.strip()
                if stmt:
                    cur.execute(stmt)
        print("Административный скрипт выполнен успешно.")
    except Exception as e:
        print(f"Ошибка при выполнении административного скрипта: {e}")
    finally:
        if conn:
            conn.close()

def main():
    # 1. Выполнить CreateDatabase.sql через административное подключение
    create_db_file = os.path.join(SQL_DIR, SQL_FILES_ORDER[0])
    if os.path.exists(create_db_file):
        sql_script = read_sql_file(create_db_file)
        print(f"Выполняем {SQL_FILES_ORDER[0]} ...")
        execute_admin_sql(sql_script)
    else:
        print(f"Файл {SQL_FILES_ORDER[0]} не найден!")
        return

    # 2. Подключаемся к новой базе данных
    try:
        new_db_params = ADMIN_DB_PARAMS.copy()
        new_db_params["dbname"] = NEW_DB_NAME
        conn = psycopg2.connect(**new_db_params)
        # Для остальных SQL-скриптов установим автокоммит
        conn.set_isolation_level(extensions.ISOLATION_LEVEL_AUTOCOMMIT)
        print(f"Подключились к базе {NEW_DB_NAME}.")
    except Exception as e:
        print(f"Ошибка подключения к базе {NEW_DB_NAME}: {e}")
        return

    # 3. Выполняем остальные SQL-скрипты в указанном порядке
    for sql_file in SQL_FILES_ORDER[1:]:
        file_path = os.path.join(SQL_DIR, sql_file)
        if os.path.exists(file_path):
            print(f"Выполняем {sql_file} ...")
            sql_script = read_sql_file(file_path)
            execute_sql(sql_script, conn)
        else:
            print(f"Файл {sql_file} не найден, пропускаем.")

    conn.close()
    print("Настройка базы данных завершена.")

if __name__ == "__main__":
    main()