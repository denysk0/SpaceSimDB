-- Inserts.sql
------------------------------------------------------------------------------
-- Пример вставок для тестирования
-- Звёздные системы
INSERT INTO StarSystems(system_name, coord_x, coord_y, coord_z, star_type)
VALUES ('Sol', 0,0,0, 'YellowStar'),
       ('AlphaCentauri', 4.3,0,0, 'RedDwarf');

-- Планеты
INSERT INTO Planets(planet_name, planet_type, planet_size, population, is_populated, system_id)
VALUES ('Earth', 'Rocky', 12742, 8000000000, TRUE, 1),
       ('Mars',  'Rocky', 6792,  1000000,     TRUE, 1),
       ('ProximaB', 'Rocky', 5000, 0, FALSE, 2);

-- Фракции
INSERT INTO Factions(faction_name, government, influence)
VALUES ('Federation', 'Democracy', 25.5),
       ('Empire', 'Monarchy', 15.0),
       ('Alliance', 'Confederacy', 10.0);

-- Станции
INSERT INTO Stations(station_name, station_type, system_id, planet_id, controlling_faction)
VALUES ('Galactic Hub', 'Orbital', 1, NULL, 1),
       ('Mars Base', 'Surface', 1, 2, 1),
       ('Centauri Station', 'Orbital', 2, NULL, 2);

-- Игроки
INSERT INTO Players(player_name, credits)
VALUES ('PlayerOne', 5000),
       ('JohnDoe', 10000);

-- Корабли (создадим один для теста)
-- Сначала вставляем в Ships
INSERT INTO Ships(model_name, max_speed, cargo_capacity, jump_range, current_system, current_station)
VALUES ('GenericShipModel', 200, 16, 10, 1, 1) RETURNING ship_id;
-- Предположим, что вернулось ship_id = 1
-- Вставляем в PlayerShips (наследование)
INSERT INTO PlayerShips(ship_id, owner_player_id, model_name, max_speed, cargo_capacity, jump_range, current_system, current_station, is_destroyed)
VALUES (1, 1, 'Asp Explorer', 250, 32, 25, 1, 1, FALSE);

-- NPCShips
INSERT INTO NPCShips(ship_id, faction_id, model_name, max_speed, cargo_capacity, jump_range, current_system, current_station, is_destroyed, npc_name)
VALUES (2, 2, 'PirateVessel', 180, 8, 15, 2, 1, FALSE, 'SpacePirate#1');

-- Товары
INSERT INTO Goods(good_name, category, base_price)
VALUES ('Food', 'Foodstuffs', 10),
       ('Gold', 'Metals', 1000),
       ('Medicine', 'Pharma', 50);

-- Insert для таблицы Deals можно вставлять через приложение
-- Миссии
INSERT INTO Missions(mission_type, reward, assigned_player, target_station_id, required_good_id, required_qty)
VALUES ('Delivery', 500, 1, 1, 1, 10),
       ('Bounty', 1000, 2, NULL, NULL, 0);

-- Логи
INSERT INTO Logs(event_type, description)
VALUES ('INFO', 'Начальный тестовый лог');
------------------------------------------------------------------------------
-- Конец файла 6_Inserts.sql