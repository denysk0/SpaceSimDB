**Example of a Backup Strategy**:

> Uzywamy `pg_dump` dla robienia backupow:  
> ```bash
> pg_dump -U postgres -d SpaceSimDB -F c -b -v -f /backups/SpaceSimDB_YYYYMMDD.dump
> ```
>  
> Odtworzenie danych:  
> ```bash
> pg_restore -U postgres -d SpaceSimDB -v "/backups/SpaceSimDB_YYYYMMDD.dump"
> ```
>  
> Mozna zgonfigurowac codzienne automatyczne kopie zapasowe wykonywane w godzinach nocnych (mniej onlin'u, planowy restart) - np. uzywajac cron w Linux lub Task Scheduler na Windows).