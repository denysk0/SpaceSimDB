-- FunctionsAndProcedures.sql
------------------------------------------------------------------------------
------------------------------------------------------------------------------
-- Функция расчёта 3D-дистанции между системами
CREATE OR REPLACE FUNCTION func_get_distance(systemA INT, systemB INT)
RETURNS NUMERIC(10,4)
LANGUAGE plpgsql AS $$
DECLARE
    a RECORD;
    b RECORD;
    dist NUMERIC(10,4);
BEGIN
    SELECT coord_x, coord_y, coord_z INTO a FROM StarSystems WHERE system_id = systemA;
    SELECT coord_x, coord_y, coord_z INTO b FROM StarSystems WHERE system_id = systemB;
    IF a IS NULL OR b IS NULL THEN
        RAISE EXCEPTION 'Одна или обе системы не найдены';
    END IF;
    dist := sqrt( power(b.coord_x - a.coord_x,2) +
                  power(b.coord_y - a.coord_y,2) +
                  power(b.coord_z - a.coord_z,2) );
    RETURN dist;
END;
$$;

------------------------------------------------------------------------------
-- Функция поиска маршрута (упрощённо) для корабля с jump_range
-- Переименована в func_find_path, чтобы соответствовать вызову в ExampleQueries.sql
CREATE OR REPLACE FUNCTION func_find_path(systemA INT, systemB INT, ship_id INT)
RETURNS TEXT
LANGUAGE plpgsql AS $$
DECLARE
    maxJump NUMERIC(8,2);
    currentSystem INT := systemA;
    nextSystem INT;
    path TEXT := '';
    finished BOOLEAN := FALSE;
BEGIN
    SELECT jump_range INTO maxJump FROM Ships WHERE ship_id = ship_id;
    IF maxJump IS NULL THEN
        RAISE EXCEPTION 'Корабль не найден';
    END IF;
    path := 'Start(' || systemA || ')';
    WHILE NOT finished LOOP
        IF currentSystem = systemB THEN
            finished := TRUE;
            EXIT;
        END IF;
        SELECT system_to INTO nextSystem FROM RouteEdges
         WHERE system_from = currentSystem AND distance_ly <= maxJump
         ORDER BY distance_ly LIMIT 1;
        IF nextSystem IS NULL THEN
            RETURN 'Маршрут не найден';
        END IF;
        path := path || ' -> ' || nextSystem;
        currentSystem := nextSystem;
        IF currentSystem = systemB THEN
            finished := TRUE;
        END IF;
    END LOOP;
    RETURN path || ' -> End';
END;
$$;

------------------------------------------------------------------------------
-- Функция расчёта чистой прибыли игрока
CREATE OR REPLACE FUNCTION func_calc_player_profit(p_player_id INT)
RETURNS NUMERIC(18,2)
LANGUAGE plpgsql AS $$
DECLARE
    total_buy NUMERIC(18,2);
    total_sell NUMERIC(18,2);
BEGIN
    SELECT COALESCE(SUM(price_per_unit * quantity),0)
      INTO total_buy FROM Deals WHERE player_id = p_player_id AND deal_type = 'BUY';
    SELECT COALESCE(SUM(price_per_unit * quantity),0)
      INTO total_sell FROM Deals WHERE player_id = p_player_id AND deal_type = 'SELL';
    RETURN total_sell - total_buy;
END;
$$;

------------------------------------------------------------------------------
-- Функция апгрейда корабля
CREATE OR REPLACE FUNCTION func_upgrade_ship(p_ship_id INT, p_module_name VARCHAR)
RETURNS TEXT
LANGUAGE plpgsql AS $$
DECLARE
    existing RECORD;
    new_level INT;
BEGIN
    SELECT * INTO existing FROM ShipUpgrades
     WHERE ship_id = p_ship_id AND module_name = p_module_name;
    IF NOT FOUND THEN
        INSERT INTO ShipUpgrades(ship_id, module_name, module_level)
        VALUES (p_ship_id, p_module_name, 1);
        RETURN 'Установлен новый модуль "' || p_module_name || '" (уровень 1)';
    ELSE
        new_level := existing.module_level + 1;
        UPDATE ShipUpgrades SET module_level = new_level
         WHERE upgrade_id = existing.upgrade_id;
        RETURN 'Модуль "' || p_module_name || '" улучшен до уровня ' || new_level;
    END IF;
END;
$$;

------------------------------------------------------------------------------
-- Процедура генерации случайных звёздных систем и планет
CREATE OR REPLACE PROCEDURE proc_generate_random_systems_and_planets(p_system_count INT, p_planets_per_system INT)
LANGUAGE plpgsql AS $$
DECLARE
    i INT;
    j INT;
    new_sys_id INT;
    rndX NUMERIC(8,2);
    rndY NUMERIC(8,2);
    rndZ NUMERIC(8,2);
    starType TEXT;
BEGIN
    FOR i IN 1..p_system_count LOOP
        rndX := random() * 1000;
        rndY := random() * 1000;
        rndZ := random() * 1000;
        IF random() < 0.5 THEN
            starType := 'RedDwarf';
        ELSE
            starType := 'YellowStar';
        END IF;
        INSERT INTO StarSystems(system_name, coord_x, coord_y, coord_z, star_type)
         VALUES ('AutoSys_' || i || '_' || floor(random()*1000), rndX, rndY, rndZ, starType)
         RETURNING system_id INTO new_sys_id;
        FOR j IN 1..p_planets_per_system LOOP
            INSERT INTO Planets(planet_name, planet_type, planet_size, population, is_populated, system_id)
             VALUES ('AutoPlanet_' || i || '_' || j || '_' || floor(random()*1000),
                     'Rocky',
                     5000 + floor(random()*1000),
                     (random()*10000000)::BIGINT,
                     (random() < 0.5),
                     new_sys_id);
        END LOOP;
    END LOOP;
END;
$$;

------------------------------------------------------------------------------
-- Процедура создания новой системы
CREATE OR REPLACE PROCEDURE proc_create_system(p_system_name VARCHAR, p_coord_x NUMERIC, p_coord_y NUMERIC, p_coord_z NUMERIC, p_star_type VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO StarSystems(system_name, coord_x, coord_y, coord_z, star_type)
    VALUES (p_system_name, p_coord_x, p_coord_y, p_coord_z, p_star_type);
END;
$$;

------------------------------------------------------------------------------
-- Процедура создания новой планеты
CREATE OR REPLACE PROCEDURE proc_create_planet(p_planet_name VARCHAR, p_planet_type VARCHAR, p_planet_size NUMERIC, p_population BIGINT, p_is_populated BOOLEAN, p_system_id INT)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO Planets(planet_name, planet_type, planet_size, population, is_populated, system_id)
    VALUES (p_planet_name, p_planet_type, p_planet_size, p_population, p_is_populated, p_system_id);
END;
$$;

------------------------------------------------------------------------------
-- Процедура создания новой станции
CREATE OR REPLACE PROCEDURE proc_create_station(p_station_name VARCHAR, p_station_type station_type_enum, p_system_id INT, p_planet_id INT, p_controlling_faction INT)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO Stations(station_name, station_type, system_id, planet_id, controlling_faction)
    VALUES (p_station_name, p_station_type, p_system_id, p_planet_id, p_controlling_faction);
END;
$$;

------------------------------------------------------------------------------
-- Процедура создания новой миссии
CREATE OR REPLACE PROCEDURE proc_create_mission(
    p_mission_type VARCHAR,
    p_reward NUMERIC,
    p_assigned_player INT,
    p_target_station_id INT,
    p_required_good_id INT,
    p_required_qty INT
)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO Missions(mission_type, reward, assigned_player, target_station_id, required_good_id, required_qty)
    VALUES (p_mission_type, p_reward, p_assigned_player, p_target_station_id, p_required_good_id, p_required_qty);
END;
$$;

------------------------------------------------------------------------------
-- Процедура завершения миссии
CREATE OR REPLACE PROCEDURE proc_finish_mission(p_mission_id INT, p_success BOOLEAN)
LANGUAGE plpgsql AS $$
DECLARE
    m_rec RECORD;
    ship_id_found INT;
BEGIN
    SELECT * INTO m_rec FROM Missions WHERE mission_id = p_mission_id;
    IF m_rec IS NULL THEN
        RAISE EXCEPTION 'Mission % does not exist', p_mission_id;
    END IF;
    IF m_rec.status IN ('Failed','Completed') THEN
        RAISE NOTICE 'Mission already finished';
        RETURN;
    END IF;
    IF p_success = FALSE THEN
        UPDATE Missions SET status = 'Failed' WHERE mission_id = p_mission_id;
        RETURN;
    END IF;
    IF m_rec.mission_type = 'Delivery' THEN
        SELECT ps.ship_id INTO ship_id_found
         FROM PlayerShips ps
         JOIN Ships s ON ps.ship_id = s.ship_id
         WHERE ps.owner_player_id = m_rec.assigned_player
           AND s.current_station = m_rec.target_station_id
         LIMIT 1;
        IF ship_id_found IS NULL THEN
            RAISE EXCEPTION 'Нет корабля у игрока % на станции % для доставки', m_rec.assigned_player, m_rec.target_station_id;
        END IF;
        PERFORM fn_remove_cargo(ship_id_found, m_rec.required_good_id, m_rec.required_qty);
    END IF;
    UPDATE Missions SET status = 'Completed' WHERE mission_id = p_mission_id;
    IF m_rec.assigned_player IS NOT NULL THEN
        UPDATE Players SET credits = credits + m_rec.reward WHERE player_id = m_rec.assigned_player;
    END IF;
END;
$$;

------------------------------------------------------------------------------
-- Процедура PvP (упрощенно)
CREATE OR REPLACE PROCEDURE proc_pvp_combat(p_attacker INT, p_defender INT, p_stake NUMERIC)
LANGUAGE plpgsql AS $$
DECLARE
    rand_val NUMERIC;
BEGIN
    IF p_stake <= 0 THEN
        RAISE EXCEPTION 'Stake must be positive';
    END IF;
    rand_val := random();
    IF rand_val < 0.5 THEN
        PERFORM proc_transfer_credits(p_defender, p_attacker, p_stake);
        RAISE NOTICE 'Атакующий победил!';
    ELSE
        PERFORM proc_transfer_credits(p_attacker, p_defender, p_stake);
        RAISE NOTICE 'Защитник победил!';
    END IF;
END;
$$;

------------------------------------------------------------------------------
-- Процедура перевода кредитов
CREATE OR REPLACE PROCEDURE proc_transfer_credits(p_from INT, p_to INT, p_amount NUMERIC)
LANGUAGE plpgsql AS $$
DECLARE
    fromBalance NUMERIC(18,2);
BEGIN
    IF p_amount <= 0 THEN
        RAISE EXCEPTION 'Transfer amount must be > 0';
    END IF;
    SELECT credits INTO fromBalance FROM Players WHERE player_id = p_from;
    IF fromBalance < p_amount THEN
        RAISE EXCEPTION 'Not enough credits for transfer';
    END IF;
    UPDATE Players SET credits = credits - p_amount WHERE player_id = p_from;
    UPDATE Players SET credits = credits + p_amount WHERE player_id = p_to;
END;
$$;
------------------------------------------------------------------------------
-- Функция добавления груза в ShipCargo
CREATE OR REPLACE FUNCTION fn_add_cargo(p_ship_id INT, p_good_id INT, p_quantity INT)
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM ShipCargo WHERE ship_id = p_ship_id AND good_id = p_good_id) THEN
        UPDATE ShipCargo
           SET quantity = quantity + p_quantity
         WHERE ship_id = p_ship_id AND good_id = p_good_id;
    ELSE
        INSERT INTO ShipCargo(ship_id, good_id, quantity)
        VALUES (p_ship_id, p_good_id, p_quantity);
    END IF;
END;
$$;

------------------------------------------------------------------------------
-- Функция удаления груза из ShipCargo
CREATE OR REPLACE FUNCTION fn_remove_cargo(p_ship_id INT, p_good_id INT, p_quantity INT)
RETURNS VOID
LANGUAGE plpgsql AS $$
DECLARE
    current_qty INT;
BEGIN
    SELECT quantity INTO current_qty FROM ShipCargo
     WHERE ship_id = p_ship_id AND good_id = p_good_id;
    IF current_qty IS NULL OR current_qty < p_quantity THEN
        RAISE EXCEPTION 'Not enough cargo on ship % for good %', p_ship_id, p_good_id;
    END IF;
    UPDATE ShipCargo
       SET quantity = quantity - p_quantity
     WHERE ship_id = p_ship_id AND good_id = p_good_id;
    DELETE FROM ShipCargo
     WHERE ship_id = p_ship_id AND good_id = p_good_id AND quantity = 0;
END;
$$;