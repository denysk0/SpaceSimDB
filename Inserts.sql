------------------------------------------------------------------------------
-- 6_Inserts.sql
------------------------------------------------------------------------------

-- Добавим пару систем
INSERT INTO StarSystems(system_name, coord_x, coord_y, coord_z, star_type)
VALUES ('Sol', 0,0,0, 'YellowStar'),
       ('AlphaCentauri', 4.3,0,0, 'BinaryStar'),
       ('BarnardsStar', 6.0,1.2,3.4, 'RedDwarf');

-- Пара планет
INSERT INTO Planets(planet_name, planet_type, system_id, is_populated, population)
VALUES ('Earth', 'Rocky', 1, TRUE, 8000000000),
       ('Mars',  'Rocky', 1, TRUE, 1000000),
       ('ProximaB', 'Rocky', 2, FALSE, 0);

-- Фракции
INSERT INTO Factions(faction_name, government, influence)
VALUES ('Federation', 'Democracy', 25.5),
       ('Empire', 'Monarchy', 15.0),
       ('Alliance', 'Confederacy', 10.0);

-- Станции
INSERT INTO Stations(station_name, station_type, system_id, controlling_faction)
VALUES ('Galactic Hub', 'Orbital', 1, 1),
       ('Mars Base', 'Surface', 1, 1),
       ('Centauri Station', 'Orbital', 2, 2);

-- Пара игроков
INSERT INTO Players(player_name, credits)
VALUES ('PlayerOne', 5000),
       ('JohnDoe', 10000);

-- Корабли (в родительскую Ships)
INSERT INTO Ships(model_name, max_speed, cargo_capacity, jump_range, current_system)
VALUES ('GenericShipModel', 200, 16, 10, 1);

-- PlayerShips
INSERT INTO PlayerShips(model_name, max_speed, cargo_capacity, jump_range, current_system, owner_player_id)
VALUES ('Asp Explorer', 250, 32, 25, 1, 1);

-- NPCShips
INSERT INTO NPCShips(model_name, max_speed, cargo_capacity, jump_range, current_system, faction_id)
VALUES ('PirateVessel', 180, 8, 15, 2, 2);

-- Goods
INSERT INTO Goods(good_name, category, base_price)
VALUES ('Food', 'Foodstuffs', 10),
       ('Gold', 'Metals', 1000),
       ('Medicine', 'Pharma', 50);

-- Deals
INSERT INTO Deals(player_id, station_id, good_id, quantity, price_per_unit, deal_type)
VALUES (1, 1, 1, 10, 12, 'BUY'),
       (2, 1, 2, 2, 950, 'SELL');

-- Missions
INSERT INTO Missions(mission_type, reward, assigned_player, status)
VALUES ('Delivery', 500, 1, 'Open'),
       ('Bounty', 1000, 2, 'Open');

-- GoodsPriceHistory
INSERT INTO GoodsPriceHistory(station_id, good_id, price)
VALUES (1,1, 15),
       (1,2, 1200),
       (2,1, 14);

-- PilotsReputationHistory
INSERT INTO PilotsReputationHistory(player_id, faction_id, rep_value)
VALUES (1,1, 20),
       (2,2, 40);

-- RouteEdges (между системами)
INSERT INTO RouteEdges(system_from, system_to, distance_ly)
VALUES (1,2, 4.3),
       (1,3, 6.0),
       (2,3, 2.0);

-- ShipUpgrades
INSERT INTO ShipUpgrades(ship_id, module_name, module_level)
VALUES (1, 'Cargo Expansion', 2);

-- Achievements
INSERT INTO Achievements(achievement_name)
VALUES ('FirstBlood'), ('MasterTrader');

-- PlayerAchievements
INSERT INTO PlayerAchievements(player_id, achievement_id)
VALUES (1,1), (2,2);

-- Logs
INSERT INTO Logs(event_type, description)
VALUES ('INFO', 'Initial test log entry');
