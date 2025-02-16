-- Inserts.sql

------------------------------------------------------------------------------
-- Przygotowanie danych testowych
TRUNCATE ShipCargo, Deals, PlayerShips, NPCShips, Ships, Stations, Planets,
         StarSystems, Players, Factions, Goods, Missions, RouteEdges, Logs
RESTART IDENTITY CASCADE;

------------------------------------------------------------------------------
-- Inserts 1: StarSystems
INSERT INTO StarSystems(system_name, coord_x, coord_y, coord_z, star_type)
VALUES
  ('Sol', 0, 0, 0, 'G-type'),
  ('AlphaCentauri', 4.3, 0, 0, 'RedDwarf'),
  ('Sirius', 8.6, 1.0, 2.0, 'WhiteDwarf'),
  ('BH1', 0, 10, 0, 'BlackHole'),
  ('BH2', 0, 20, 0, 'BlackHole'),
  ('BH3', 0, 30, 0, 'BlackHole'),
  ('BH4', 0, 40, 0, 'BlackHole'),
  ('BH5', 0, 50, 0, 'BlackHole'),
  ('BH6', 0, 60, 0, 'BlackHole'),
  ('BH7', 0, 70, 0, 'BlackHole');

------------------------------------------------------------------------------
-- Inserts 2: Planets
INSERT INTO Planets(planet_name, planet_type, planet_size, population, is_populated, system_id)
VALUES
  ('Earth', 'Rocky', 12742, 8000000000, TRUE, 1),
  ('Mars', 'Rocky', 6792, 1000000, TRUE, 1);

------------------------------------------------------------------------------
-- Inserts 3: Factions
INSERT INTO Factions(faction_name, government, influence)
VALUES
  ('Federation', 'Democracy', 25.5),
  ('Empire', 'Monarchy', 15.0);

------------------------------------------------------------------------------
-- Inserts 4: Stations
INSERT INTO Stations(station_name, station_type, system_id, planet_id, controlling_faction)
VALUES
  ('Galactic Hub', 'Orbital', 1, NULL, 1),
  ('Mars Base', 'Surface', 1, 2, 1);

------------------------------------------------------------------------------
-- Inserts 5: Players
INSERT INTO Players(player_name, credits)
VALUES
  ('PlayerOne', 5000),
  ('JohnDoe', 10000),
  ('TestPilot', 2000);

------------------------------------------------------------------------------
-- Inserts 6a: PlayerShips
INSERT INTO PlayerShips(owner_player_id, model_name, max_speed, cargo_capacity, jump_range, current_system, current_station, is_destroyed)
VALUES
  (1, 'Asp Explorer', 250, 32, 15, 1, 1, FALSE)
RETURNING ship_id;

------------------------------------------------------------------------------
-- Inserts 6b: NPCShips
INSERT INTO NPCShips(faction_id, npc_name, model_name, max_speed, cargo_capacity, jump_range, current_system, current_station, is_destroyed)
VALUES
  (2, 'Pirate#1', 'PirateVessel', 180, 16, 10, 1, 1, FALSE);

------------------------------------------------------------------------------
-- Inserts 7: Goods
INSERT INTO Goods(good_name, category, base_price)
VALUES
  ('Food', 'Foodstuffs', 10),
  ('Gold', 'Metals', 1000),
  ('Medicine', 'Pharma', 50);

------------------------------------------------------------------------------
-- Inserts 8: Missions
INSERT INTO Missions(mission_type, reward, assigned_player, target_station_id, required_good_id, required_qty, status)
VALUES
  ('Delivery', 500, 1, 1, 1, 10, 'Open'),
  ('Bounty', 1000, 2, NULL, NULL, 0, 'Open');

------------------------------------------------------------------------------
-- Inserts 9: RouteEdges
INSERT INTO RouteEdges(system_from, system_to, distance_ly)
VALUES
  (1, 2, 5.0),
  (2, 1, 5.0),
  (1, 3, 8.6),
  (3, 1, 8.6),
  (2, 3, 4.5),
  (3, 2, 4.5);

------------------------------------------------------------------------------
-- Inserts 10: Logs
INSERT INTO Logs(event_type, description)
VALUES
  ('INFO', 'Poczatkowy log testowy');