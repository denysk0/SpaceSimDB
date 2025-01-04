**Example of a Backup Strategy** (described in a separate file or a PDF report):

> We use `pg_dump` for backups:  
> ```bash
> pg_dump -U postgres -d SpaceSimDB -F c -b -v -f /backups/SpaceSimDB_YYYYMMDD.dump
> ```
>  
> Then restore with:  
> ```bash
> pg_restore -U postgres -d SpaceSimDB -v "/backups/SpaceSimDB_YYYYMMDD.dump"
> ```
>  
> A schedule can be configured (e.g., using cron in Linux or Task Scheduler in Windows).  