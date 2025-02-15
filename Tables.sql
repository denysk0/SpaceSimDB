-- Tables.sql
------------------------------------------------------------------------------
-- Создаём типы
DROP TYPE IF EXISTS station_type_enum CASCADE;
CREATE TYPE station_type_enum AS ENUM ('Orbital', 'Surface', 'MegaShip', 'FleetCarrier');

DROP TYPE IF EXISTS mission_status_enum CASCADE;
CREATE TYPE mission_status_enum AS ENUM ('Open', 'InProgress', 'Failed', 'Completed');

------------------------------------------------------------------------------
-- Таблица 1. StarSystems
DROP TABLE IF EXISTS StarSystems CASCADE;
CREATE TABLE StarSystems (
    system_id      SERIAL PRIMARY KEY,
    system_name    VARCHAR(100) NOT NULL UNIQUE,
    coord_x        NUMERIC(8,2) NOT NULL,
    coord_y        NUMERIC(8,2) NOT NULL,
    coord_z        NUMERIC(8,2) NOT NULL,
    star_type      VARCHAR(50) NOT NULL,
    discovered_on  DATE DEFAULT CURRENT_DATE
);

------------------------------------------------------------------------------
-- Таблица 2. Planets
DROP TABLE IF EXISTS Planets CASCADE;
CREATE TABLE Planets (
    planet_id     SERIAL PRIMARY KEY,
    planet_name   VARCHAR(100) NOT NULL UNIQUE,
    planet_type   VARCHAR(50) NOT NULL,
    planet_size   NUMERIC(10,2),
    population    BIGINT,
    is_populated  BOOLEAN NOT NULL DEFAULT FALSE,
    system_id     INT NOT NULL REFERENCES StarSystems(system_id) ON DELETE CASCADE
);

------------------------------------------------------------------------------
-- Таблица 3. Factions
DROP TABLE IF EXISTS Factions CASCADE;
CREATE TABLE Factions (
    faction_id    SERIAL PRIMARY KEY,
    faction_name  VARCHAR(100) NOT NULL UNIQUE,
    government    VARCHAR(50),
    influence     NUMERIC(5,2) DEFAULT 0.0
);

------------------------------------------------------------------------------
-- Таблица 4. Stations
DROP TABLE IF EXISTS Stations CASCADE;
CREATE TABLE Stations (
    station_id          SERIAL PRIMARY KEY,
    station_name        VARCHAR(100) NOT NULL UNIQUE,
    station_type        station_type_enum NOT NULL,
    system_id           INT REFERENCES StarSystems(system_id) ON DELETE CASCADE,
    planet_id           INT REFERENCES Planets(planet_id) ON DELETE SET NULL,
    controlling_faction INT REFERENCES Factions(faction_id) ON DELETE SET NULL
);

------------------------------------------------------------------------------
-- Таблица 5. Players
DROP TABLE IF EXISTS Players CASCADE;
CREATE TABLE Players (
    player_id       SERIAL PRIMARY KEY,
    player_name     VARCHAR(50) NOT NULL UNIQUE,
    credits         NUMERIC(18,2) NOT NULL DEFAULT 1000.00,
    combat_rank     INT DEFAULT 1,
    trade_rank      INT DEFAULT 1,
    exploration_rank INT DEFAULT 1,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

------------------------------------------------------------------------------
-- Таблица 6. Ships (родитель)
DROP TABLE IF EXISTS Ships CASCADE;
CREATE TABLE Ships (
    ship_id         SERIAL PRIMARY KEY,
    model_name      VARCHAR(100) NOT NULL,
    max_speed       INT NOT NULL,
    cargo_capacity  INT NOT NULL,
    jump_range      NUMERIC(5,2) NOT NULL DEFAULT 10.0,
    current_system  INT REFERENCES StarSystems(system_id) ON DELETE SET NULL,
    current_station INT REFERENCES Stations(station_id) ON DELETE SET NULL,
    is_destroyed    BOOLEAN NOT NULL DEFAULT FALSE
);

------------------------------------------------------------------------------
-- Таблица 6a. PlayerShips (наследование)
DROP TABLE IF EXISTS PlayerShips CASCADE;
CREATE TABLE PlayerShips (
    owner_player_id INT NOT NULL REFERENCES Players(player_id) ON DELETE CASCADE
)
INHERITS (Ships);

------------------------------------------------------------------------------
-- Таблица 6b. NPCShips (наследование)
DROP TABLE IF EXISTS NPCShips CASCADE;
CREATE TABLE NPCShips (
    npc_name   VARCHAR(100),
    faction_id INT REFERENCES Factions(faction_id) ON DELETE SET NULL
)
INHERITS (Ships);

------------------------------------------------------------------------------
-- Таблица 7. Goods
DROP TABLE IF EXISTS Goods CASCADE;
CREATE TABLE Goods (
    good_id       SERIAL PRIMARY KEY,
    good_name     VARCHAR(100) NOT NULL UNIQUE,
    category      VARCHAR(50) NOT NULL,
    base_price    NUMERIC(10,2) NOT NULL
);

------------------------------------------------------------------------------
-- Таблица 8. Deals
DROP TABLE IF EXISTS Deals CASCADE;
CREATE TABLE Deals (
    deal_id         SERIAL PRIMARY KEY,
    player_id       INT REFERENCES Players(player_id) ON DELETE CASCADE,
    station_id      INT REFERENCES Stations(station_id) ON DELETE CASCADE,
    good_id         INT REFERENCES Goods(good_id) ON DELETE RESTRICT,
    quantity        INT NOT NULL CHECK (quantity > 0),
    price_per_unit  NUMERIC(10,2) NOT NULL,
    deal_type       VARCHAR(4) NOT NULL CHECK (deal_type IN ('BUY','SELL')),
    deal_timestamp  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ship_id         INT  -- внешний ключ будем проверять триггером
);

------------------------------------------------------------------------------
-- Таблица 9. Missions
DROP TABLE IF EXISTS Missions CASCADE;
CREATE TABLE Missions (
    mission_id         SERIAL PRIMARY KEY,
    mission_type       VARCHAR(50) NOT NULL, -- например, 'Delivery', 'Bounty'
    reward             NUMERIC(10,2) NOT NULL,
    assigned_player    INT REFERENCES Players(player_id) ON DELETE SET NULL,
    status             mission_status_enum DEFAULT 'Open',
    target_station_id  INT REFERENCES Stations(station_id) ON DELETE CASCADE,
    required_good_id   INT REFERENCES Goods(good_id) ON DELETE RESTRICT,
    required_qty       INT NOT NULL DEFAULT 0
);

------------------------------------------------------------------------------
-- Таблица 10. GoodsPriceHistory
DROP TABLE IF EXISTS GoodsPriceHistory CASCADE;
CREATE TABLE GoodsPriceHistory (
    record_id   SERIAL PRIMARY KEY,
    station_id  INT NOT NULL REFERENCES Stations(station_id),
    good_id     INT NOT NULL REFERENCES Goods(good_id),
    price       NUMERIC(10,2) NOT NULL,
    changed_on  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

------------------------------------------------------------------------------
-- Таблица 11. PilotsReputationHistory
DROP TABLE IF EXISTS PilotsReputationHistory CASCADE;
CREATE TABLE PilotsReputationHistory (
    rep_id      SERIAL PRIMARY KEY,
    player_id   INT NOT NULL REFERENCES Players(player_id) ON DELETE CASCADE,
    faction_id  INT NOT NULL REFERENCES Factions(faction_id) ON DELETE CASCADE,
    rep_value   NUMERIC(5,2) NOT NULL,
    changed_on  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

------------------------------------------------------------------------------
-- Таблица 12. RouteEdges
DROP TABLE IF EXISTS RouteEdges CASCADE;
CREATE TABLE RouteEdges (
    edge_id     SERIAL PRIMARY KEY,
    system_from INT NOT NULL REFERENCES StarSystems(system_id),
    system_to   INT NOT NULL REFERENCES StarSystems(system_id),
    distance_ly NUMERIC(8,2) NOT NULL CHECK (distance_ly > 0)
);

------------------------------------------------------------------------------
-- Таблица 13. ShipUpgrades
DROP TABLE IF EXISTS ShipUpgrades CASCADE;
CREATE TABLE ShipUpgrades (
    upgrade_id   SERIAL PRIMARY KEY,
    ship_id      INT NOT NULL REFERENCES Ships(ship_id) ON DELETE CASCADE,
    module_name  VARCHAR(100) NOT NULL,
    module_level INT NOT NULL DEFAULT 1
);

------------------------------------------------------------------------------
-- Таблица 14. Achievements
DROP TABLE IF EXISTS Achievements CASCADE;
CREATE TABLE Achievements (
    achievement_id   SERIAL PRIMARY KEY,
    achievement_name VARCHAR(100) NOT NULL UNIQUE
);

------------------------------------------------------------------------------
-- Таблица 15. PlayerAchievements
DROP TABLE IF EXISTS PlayerAchievements CASCADE;
CREATE TABLE PlayerAchievements (
    player_id       INT NOT NULL REFERENCES Players(player_id) ON DELETE CASCADE,
    achievement_id  INT NOT NULL REFERENCES Achievements(achievement_id) ON DELETE CASCADE,
    awarded_on      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (player_id, achievement_id)
);

------------------------------------------------------------------------------
-- Таблица 16. Logs
DROP TABLE IF EXISTS Logs CASCADE;
CREATE TABLE Logs (
    log_id      SERIAL PRIMARY KEY,
    event_type  VARCHAR(100),
    description TEXT,
    created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

------------------------------------------------------------------------------
-- Новая таблица: ShipCargo (инвентарь кораблей)
DROP TABLE IF EXISTS ShipCargo CASCADE;
CREATE TABLE ShipCargo (
    ship_id   INT NOT NULL REFERENCES Ships(ship_id) ON DELETE CASCADE,
    good_id   INT NOT NULL REFERENCES Goods(good_id) ON DELETE CASCADE,
    quantity  INT NOT NULL DEFAULT 0 CHECK (quantity >= 0),
    PRIMARY KEY (ship_id, good_id)
);
------------------------------------------------------------------------------