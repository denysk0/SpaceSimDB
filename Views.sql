------------------------------------------------------------------------------
-- Views.sql
------------------------------------------------------------------------------

-- 1) vw_active_players: игроки, у которых credits > 0
CREATE OR REPLACE VIEW vw_active_players AS
SELECT player_id, player_name, credits
FROM Players
WHERE credits > 0;

-- 2) vw_stations_with_faction: список станций с указанием их фракции
CREATE OR REPLACE VIEW vw_stations_with_faction AS
SELECT s.station_id, s.station_name, f.faction_name
FROM Stations s
LEFT JOIN Factions f ON s.controlling_faction = f.faction_id;

-- 3) vw_ships_details: обобщаем Ships + указатель на игрока/фракцию
-- Представление кораблей (объединяем PlayerShips и NPCShips)
------------------------------------------------------------------------------
-- 3) vw_ships_details: обобщаем Ships + указатель на игрока/фракцию
-- Представление кораблей (объединяем PlayerShips и NPCShips)
CREATE OR REPLACE VIEW vw_ships_details AS
SELECT
  ps.ship_id,
  ps.model_name,
  ps.max_speed,
  ps.cargo_capacity,
  ps.jump_range,
  ps.current_system,
  ps.current_station,
  ps.is_destroyed,
  'PlayerShip' AS ship_type,
  p.player_name AS owner_or_npc
FROM PlayerShips ps
JOIN Players p ON ps.owner_player_id = p.player_id
UNION ALL
SELECT
  ns.ship_id,
  ns.model_name,
  ns.max_speed,
  ns.cargo_capacity,
  ns.jump_range,
  ns.current_system,
  ns.current_station,
  ns.is_destroyed,
  'NPCShip' AS ship_type,
  f.faction_name AS owner_or_npc
FROM NPCShips ns
LEFT JOIN Factions f ON ns.faction_id = f.faction_id;

-- 4) vw_deals_summary: сводка по сделкам
CREATE OR REPLACE VIEW vw_deals_summary AS
SELECT
    d.deal_id,
    pl.player_name,
    st.station_name,
    g.good_name,
    d.quantity,
    d.price_per_unit,
    d.deal_type,
    d.deal_timestamp
FROM Deals d
JOIN Players pl ON d.player_id = pl.player_id
JOIN Stations st ON d.station_id = st.station_id
JOIN Goods g ON d.good_id = g.good_id;

-- 5) vw_goods_prices: последний известный price на каждую (station, good)
--    (используем подзапрос max(changed_on))
CREATE OR REPLACE VIEW vw_goods_prices AS
SELECT gh.station_id,
       st.station_name,
       gh.good_id,
       g.good_name,
       gh.price,
       gh.changed_on
FROM GoodsPriceHistory gh
JOIN Stations st ON gh.station_id = st.station_id
JOIN Goods g ON gh.good_id = g.good_id
WHERE gh.changed_on = (
    SELECT MAX(g2.changed_on)
    FROM GoodsPriceHistory g2
    WHERE g2.station_id = gh.station_id
      AND g2.good_id = gh.good_id
);

