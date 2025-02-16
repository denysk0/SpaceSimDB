# setup_from_files.py
import os
import psycopg2
from psycopg2 import extensions
import sqlparse  # pip install sqlparse

# PARAMETRY ADMINISTRACYJNE (Funkcja 1: execute_admin_sql)
ADMIN_DB_PARAMS = {
    "dbname": "postgres",
    "user": "postgres",
    "password": "postgres",  # zmien na swoj wlasny
    "host": "localhost",
    "port": "5432"
}

# NAZWA NOWEJ BAZY DANYCH
NEW_DB_NAME = "spacesimdb"

# KATALOG, GDZIE SA PLIKI SQL
SQL_DIR = "./"  # przy zalozeniu, ze pliki sa w tym samym katalogu

# KOLEJNOSC PLIKOW SQL (numeracja zgodna z wymaganiami)
SQL_FILES_ORDER = [
    "CreateDatabase.sql",
    "Tables.sql",
    "FunctionsAndProcedures.sql",
    "Triggers.sql",
    "Views.sql",
    "Inserts.sql"
]

def read_sql_file(filename):
    # Funkcja 2: czyta zawartosc pliku SQL
    with open(filename, 'r', encoding='utf-8') as f:
        return f.read()

def execute_sql(sql_script, conn):
    # Funkcja 3: wykonuje skrypt SQL na podanym polaczeniu
    try:
        with conn.cursor() as cur:
            statements = sqlparse.split(sql_script)
            for stmt in statements:
                stmt = stmt.strip()
                if stmt:
                    cur.execute(stmt)
        conn.commit()
        print("Skrypt SQL wykonany pomyslnie.")
    except Exception as e:
        conn.rollback()
        print(f"Blad wykonania skryptu: {e}")

def execute_admin_sql(sql_script):
    # Funkcja 4: wykonuje skrypt SQL przy uzyciu polaczenia administracyjnego
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
        print("Skrypt administracyjny wykonany pomyslnie.")
    except Exception as e:
        print(f"Blad wykonania skryptu administracyjnego: {e}")
    finally:
        if conn:
            conn.close()

def main():
    # Krok 1: Wykonaj CreateDatabase.sql przez polaczenie administracyjne
    create_db_file = os.path.join(SQL_DIR, SQL_FILES_ORDER[0])
    if os.path.exists(create_db_file):
        sql_script = read_sql_file(create_db_file)
        print(f"Wykonywanie {SQL_FILES_ORDER[0]} ...")
        execute_admin_sql(sql_script)
    else:
        print(f"Plik {SQL_FILES_ORDER[0]} nie zostal znaleziony!")
        return

    # Krok 2: Polacz sie z nowa baza danych
    try:
        new_db_params = ADMIN_DB_PARAMS.copy()
        new_db_params["dbname"] = NEW_DB_NAME
        conn = psycopg2.connect(**new_db_params)
        conn.set_isolation_level(extensions.ISOLATION_LEVEL_AUTOCOMMIT)
        print(f"Polaczono z baza {NEW_DB_NAME}.")
    except Exception as e:
        print(f"Blad polaczenia z baza {NEW_DB_NAME}: {e}")
        return

    # Krok 3: Wykonaj pozostale pliki SQL w zadanej kolejnosci
    for sql_file in SQL_FILES_ORDER[1:]:
        file_path = os.path.join(SQL_DIR, sql_file)
        if os.path.exists(file_path):
            print(f"Wykonywanie {sql_file} ...")
            sql_script = read_sql_file(file_path)
            execute_sql(sql_script, conn)
        else:
            print(f"Plik {sql_file} nie zostal znaleziony, pomijam.")
    conn.close()
    print("Konfiguracja bazy danych zakonczona.")

if __name__ == "__main__":
    main()