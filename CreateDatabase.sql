-- CreateDatabase.sql
DROP DATABASE IF EXISTS spacesimdb;
CREATE DATABASE spacesimdb
  WITH ENCODING = 'UTF8'
       TEMPLATE = template0
       LC_COLLATE = 'en_US.UTF-8'
       LC_CTYPE = 'en_US.UTF-8';

-- Подключаемся к созданной базе (для psql)
-- \c SpaceSimDB;
