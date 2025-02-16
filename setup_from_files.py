# setup_from_files.py
import os
import psycopg2
from psycopg2 import extensions
import sqlparse

# parametry administracyjne - uzywane w funkcji execute_admin_sql
ADMIN_DB_PARAMS = {
    "dbname": "postgres",
    "user": "postgres",
    "password": "postgres",
    "host": "localhost",
    "port": "5432"
}

# nazwa nowej bazy danych
NEW_DB_NAME = "spacesimdb"

# katalog, gdzie sa pliki sql (zakladamy, ze sa w tym samym katalogu)
SQL_DIR = "./"

# kolejnosc plikow sql
SQL_FILES_ORDER = [
    "CreateDatabase.sql",
    "Tables.sql",
    "FunctionsAndProcedures.sql",
    "Triggers.sql",
    "Views.sql",
    "Inserts.sql"
]

def read_sql_file(filename):
    # czyta zawartosc pliku sql
    with open(filename, 'r', encoding='utf-8') as f:
        return f.read()

def execute_sql(sql_script, conn):
    # wykonuje skrypt sql na podanym polaczeniu
    try:
        with conn.cursor() as cur:
            statements = sqlparse.split(sql_script)
            for stmt in statements:
                stmt = stmt.strip()
                if stmt:
                    cur.execute(stmt)
        conn.commit()
        print("skrypt sql wykonany pomyslnie")
    except Exception as e:
        conn.rollback()
        print(f"blad wykonania skryptu: {e}")

def execute_admin_sql(sql_script):
    # wykonuje skrypt sql przy uzyciu polaczenia administracyjnego
    conn = None
    try:
        conn = psycopg2.connect(**ADMIN_DB_PARAMS)
        conn.set_isolation_level(extensions.ISOLATION_LEVEL_AUTOCOMMIT)
        with conn.cursor() as cur:
            statements = sqlparse.split(sql_script)
            for stmt in statements:
                stmt = stmt.strip()
                if stmt:
                    cur.execute(stmt)
        print("skrypt administracyjny wykonany pomyslnie")
    except Exception as e:
        print(f"blad wykonania skryptu administracyjnego: {e}")
    finally:
        if conn:
            conn.close()

def main():
    # krok 1: wykonaj CreateDatabase.sql przez polaczenie administracyjne
    create_db_file = os.path.join(SQL_DIR, SQL_FILES_ORDER[0])
    if os.path.exists(create_db_file):
        sql_script = read_sql_file(create_db_file)
        print(f"wykonywanie {SQL_FILES_ORDER[0]} ...")
        execute_admin_sql(sql_script)
    else:
        print(f"plik {SQL_FILES_ORDER[0]} nie zostal znaleziony")
        return

    # krok 2: polacz sie z nowa baza danych
    try:
        new_db_params = ADMIN_DB_PARAMS.copy()
        new_db_params["dbname"] = NEW_DB_NAME
        conn = psycopg2.connect(**new_db_params)
        conn.set_isolation_level(extensions.ISOLATION_LEVEL_AUTOCOMMIT)
        print(f"polaczono z baza {NEW_DB_NAME}")
    except Exception as e:
        print(f"blad polaczenia z baza {NEW_DB_NAME}: {e}")
        return

    # krok 3: wykonaj pozostale pliki sql w kolejnosci
    for sql_file in SQL_FILES_ORDER[1:]:
        file_path = os.path.join(SQL_DIR, sql_file)
        if os.path.exists(file_path):
            print(f"wykonywanie {sql_file} ...")
            sql_script = read_sql_file(file_path)
            execute_sql(sql_script, conn)
        else:
            print(f"plik {sql_file} nie zostal znaleziony, pomijam")
    conn.close()
    print("konfiguracja bazy zakonczona")

if __name__ == "__main__":
    main()
