-- CreateDatabase.sql

-- Blok 1: Zabij aktywne polaczenia do bazy spacesimdb
DROP DATABASE IF EXISTS spacesimdb;
CREATE DATABASE spacesimdb
  WITH ENCODING = 'UTF8'
       TEMPLATE = template0
       LC_COLLATE = 'en_US.UTF-8'
       LC_CTYPE = 'en_US.UTF-8';

-- Aby polaczyc sie z baza, uzyj komendy: \c spacesimdb