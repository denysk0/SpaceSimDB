-- functionsandprocedures.sql

-- funkcje:
-- 1. funkcja func_get_distance
-- oblicza 3d odleglosc miedzy dwoma systemami
CREATE OR REPLACE FUNCTION func_get_distance(systemA INT, systemB INT)
    RETURNS NUMERIC(10, 4)
    LANGUAGE plpgsql AS
$$
DECLARE
    a RECORD;
    b RECORD;
    dist NUMERIC(10, 4);
BEGIN
    SELECT coord_x, coord_y, coord_z INTO a FROM StarSystems WHERE system_id = systemA;
    SELECT coord_x, coord_y, coord_z INTO b FROM StarSystems WHERE system_id = systemB;
    IF a IS NULL OR b IS NULL THEN
        RAISE EXCEPTION 'jeden lub oba systemy nie zostaly znalezione';
    END IF;
    dist := sqrt(power(b.coord_x - a.coord_x, 2) +
                 power(b.coord_y - a.coord_y, 2) +
                 power(b.coord_z - a.coord_z, 2));
    RETURN dist;
END;
$$;

-- 2. funkcja func_find_path
-- szuka trasy dla statku uwzgledniajac zasieg skoku
CREATE OR REPLACE FUNCTION func_find_path(p_systemA INT, p_systemB INT, p_ship_id INT)
RETURNS TEXT
LANGUAGE plpgsql AS $$
DECLARE
    maxJump NUMERIC(8,2);
    route TEXT;
BEGIN
    -- pobieram zasieg skoku statku
    SELECT jump_range INTO maxJump FROM Ships WHERE ship_id = p_ship_id;
    IF maxJump IS NULL THEN
         RAISE EXCEPTION 'statek o id % nie znaleziony', p_ship_id;
    END IF;

    IF p_systemA = p_systemB THEN
         RETURN 'start( ' || p_systemA || ') -> end';
    END IF;

    WITH RECURSIVE
    available_edges AS (
         -- generacja krawedzi miedzy systemami
         SELECT
            a.system_id AS system_from,
            b.system_id AS system_to,
            sqrt( power(b.coord_x - a.coord_x, 2) +
                  power(b.coord_y - a.coord_y, 2) +
                  power(b.coord_z - a.coord_z, 2) ) AS distance_ly
         FROM StarSystems a
         CROSS JOIN StarSystems b
         WHERE a.system_id <> b.system_id
    ),
    paths AS (
         -- poczatkowy poziom sciezki
         SELECT
            system_from,
            system_to,
            ARRAY[system_from, system_to] AS path,
            1 AS hops
         FROM available_edges
         WHERE system_from = p_systemA
           AND distance_ly <= maxJump

         UNION ALL

         -- czesc rekurencyjna
         SELECT
            ae.system_from,
            ae.system_to,
            p.path || ae.system_to,
            p.hops + 1
         FROM available_edges ae
         JOIN paths p ON ae.system_from = p.system_to
         WHERE ae.distance_ly <= maxJump
           AND NOT ae.system_to = ANY(p.path)
    )
    SELECT 'start(' || array_to_string(path, ' -> ') || ') -> end'
      INTO route
    FROM paths
    WHERE system_to = p_systemB
    ORDER BY hops ASC
    LIMIT 1;

    IF route IS NULL THEN
         RETURN 'nie znaleziono trasy';
    ELSE
         RETURN route;
    END IF;
END;
$$;

-- 3. funkcja func_calc_player_profit
-- oblicza czysty zysk gracza (sprzedaz minus kupno)
CREATE OR REPLACE FUNCTION func_calc_player_profit(p_player_id INT)
    RETURNS NUMERIC(18, 2)
    LANGUAGE plpgsql AS
$$
DECLARE
    total_buy  NUMERIC(18, 2);
    total_sell NUMERIC(18, 2);
BEGIN
    SELECT COALESCE(SUM(price_per_unit * quantity), 0)
    INTO total_buy
    FROM Deals
    WHERE player_id = p_player_id
      AND deal_type = 'BUY';
    SELECT COALESCE(SUM(price_per_unit * quantity), 0)
    INTO total_sell
    FROM Deals
    WHERE player_id = p_player_id
      AND deal_type = 'SELL';
    RETURN total_sell - total_buy;
END;
$$;

-- 4. funkcja func_upgrade_ship
-- ulepsza modul statku (zwieksza poziom modulu)
CREATE OR REPLACE FUNCTION func_upgrade_ship(p_ship_id INT, p_module_name VARCHAR)
    RETURNS TEXT
    LANGUAGE plpgsql AS
$$
DECLARE
    existing RECORD;
    new_level INT;
BEGIN
    SELECT * INTO existing FROM ShipUpgrades WHERE ship_id = p_ship_id AND module_name = p_module_name;
    IF NOT FOUND THEN
        INSERT INTO ShipUpgrades(ship_id, module_name, module_level)
        VALUES (p_ship_id, p_module_name, 1);
        RETURN 'nowy modul "' || p_module_name || '" zainstalowany (poziom 1)';
    ELSE
        new_level := existing.module_level + 1;
        UPDATE ShipUpgrades SET module_level = new_level WHERE upgrade_id = existing.upgrade_id;
        RETURN 'modul "' || p_module_name || '" ulepszony do poziomu ' || new_level;
    END IF;
END;
$$;

-- 5. funkcja fn_add_cargo
-- dodaje ladunek do statku, jezeli juz istnieje, zwieksza ilosc
CREATE OR REPLACE FUNCTION fn_add_cargo(p_ship_id INT, p_good_id INT, p_quantity INT)
    RETURNS VOID
    LANGUAGE plpgsql AS
$$
BEGIN
    IF EXISTS (SELECT 1 FROM ShipCargo WHERE ship_id = p_ship_id AND good_id = p_good_id) THEN
        UPDATE ShipCargo SET quantity = quantity + p_quantity WHERE ship_id = p_ship_id AND good_id = p_good_id;
    ELSE
        INSERT INTO ShipCargo(ship_id, good_id, quantity) VALUES (p_ship_id, p_good_id, p_quantity);
    END IF;
END;
$$;

-- 6. funkcja fn_remove_cargo
-- usuwa ladunek ze statku; rzuca wyjatek, jezeli ilosc jest niewystarczajaca
CREATE OR REPLACE FUNCTION fn_remove_cargo(p_ship_id INT, p_good_id INT, p_quantity INT)
    RETURNS VOID
    LANGUAGE plpgsql AS
$$
DECLARE
    current_qty INT;
BEGIN
    SELECT quantity INTO current_qty FROM ShipCargo WHERE ship_id = p_ship_id AND good_id = p_good_id;
    IF current_qty IS NULL OR current_qty < p_quantity THEN
        RAISE EXCEPTION 'niewystarczajaca ilosc ladunku na statku % dla towaru %', p_ship_id, p_good_id;
    END IF;
    UPDATE ShipCargo SET quantity = quantity - p_quantity WHERE ship_id = p_ship_id AND good_id = p_good_id;
    DELETE FROM ShipCargo WHERE ship_id = p_ship_id AND good_id = p_good_id AND quantity = 0;
END;
$$;





-- procedury:

-- 1. procedure proc_generate_random_systems_and_planets
-- generuje losowe systemy gwiezdne i planety
CREATE OR REPLACE PROCEDURE proc_generate_random_systems_and_planets(p_system_count INT, p_planets_per_system INT)
LANGUAGE plpgsql AS $$
DECLARE
    i INT;
    j INT;
    r DOUBLE PRECISION;
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
        r := random();
        IF r <= 0.1 THEN
            starType := 'RedDwarf';
        ELSIF r > 0.1 AND r <= 0.2 THEN
            starType := 'WhiteDwarf';
        ELSIF r > 0.2 AND r <= 0.3 THEN
            starType := 'YellowDwarf';
        ELSIF r > 0.3 AND r <= 0.4 THEN
            starType := 'YellowGiant';
        ELSIF r > 0.4 AND r <= 0.5 THEN
            starType := 'WhiteGiant';
        ELSIF r > 0.5 AND r <= 0.6 THEN
            starType := 'RedGiant';
        ELSIF r > 0.6 AND r <= 0.7 THEN
            starType := 'CarbonStarC';
        ELSIF r > 0.7 AND r <= 0.8 THEN
            starType := 'WhiteSupergiant';
        ELSIF r > 0.8 AND r <= 0.9 THEN
            starType := 'YellowSupergiant';
        ELSE
            starType := 'RedGiant';
        END IF;
        INSERT INTO StarSystems(system_name, coord_x, coord_y, coord_z, star_type)
         VALUES ('SYS' || i || '_' || floor(random()*1000)::int, rndX, rndY, rndZ, starType)
         RETURNING system_id INTO new_sys_id;
        FOR j IN 1..p_planets_per_system LOOP
            INSERT INTO Planets(planet_name, planet_type, planet_size, population, is_populated, system_id)
             VALUES ('Planet_' || i || '_' || j || '_' || floor(random()*1000)::int,
                     'Rocky',
                     5000 + floor(random()*1000)::int,
                     (random()*10000000)::BIGINT,
                     (random() < 0.5),
                     new_sys_id);
        END LOOP;
    END LOOP;
END;
$$;

-- 2. procedure proc_create_system
-- tworzy nowy system gwiezdny
CREATE OR REPLACE PROCEDURE proc_create_system(p_system_name VARCHAR, p_coord_x NUMERIC, p_coord_y NUMERIC,
                                               p_coord_z NUMERIC, p_star_type VARCHAR)
    LANGUAGE plpgsql AS
$$
BEGIN
    INSERT INTO StarSystems(system_name, coord_x, coord_y, coord_z, star_type)
    VALUES (p_system_name, p_coord_x, p_coord_y, p_coord_z, p_star_type);
END;
$$;

-- 3. procedure proc_create_planet
-- tworzy nowa planeta
CREATE OR REPLACE PROCEDURE proc_create_planet(p_planet_name VARCHAR, p_planet_type VARCHAR, p_planet_size NUMERIC,
                                               p_population BIGINT, p_is_populated BOOLEAN, p_system_id INT)
    LANGUAGE plpgsql AS
$$
BEGIN
    INSERT INTO Planets(planet_name, planet_type, planet_size, population, is_populated, system_id)
    VALUES (p_planet_name, p_planet_type, p_planet_size, p_population, p_is_populated, p_system_id);
END;
$$;

-- 4. procedure proc_create_station
-- tworzy nowa stacje
CREATE OR REPLACE PROCEDURE proc_create_station(p_station_name VARCHAR, p_station_type VARCHAR, p_system_id INT,
                                                p_planet_id INT, p_controlling_faction INT)
    LANGUAGE plpgsql AS
$$
BEGIN
    INSERT INTO Stations(station_name, station_type, system_id, planet_id, controlling_faction)
    VALUES (p_station_name, p_station_type, p_system_id, p_planet_id, p_controlling_faction);
END;
$$;

-- 5. procedure proc_create_mission
-- tworzy nowa misje
CREATE OR REPLACE PROCEDURE proc_create_mission(
    p_mission_type VARCHAR,
    p_reward NUMERIC,
    p_assigned_player INT,
    p_target_station_id INT,
    p_required_good_id INT,
    p_required_qty INT
)
    LANGUAGE plpgsql AS
$$
BEGIN
    INSERT INTO Missions(mission_type, reward, assigned_player, target_station_id, required_good_id, required_qty)
    VALUES (p_mission_type, p_reward, p_assigned_player, p_target_station_id, p_required_good_id, p_required_qty);
END;
$$;

-- 6. procedure proc_finish_mission
-- konczy misje; w razie sukcesu usuwa ladunek i przyznaje nagrode
CREATE OR REPLACE PROCEDURE proc_finish_mission(p_mission_id INT, p_success BOOLEAN)
    LANGUAGE plpgsql AS
$$
DECLARE
    m_rec RECORD;
    ship_id_found INT;
BEGIN
    SELECT * INTO m_rec FROM Missions WHERE mission_id = p_mission_id;
    IF m_rec IS NULL THEN
        RAISE EXCEPTION 'misja % nie istnieje', p_mission_id;
    END IF;
    IF m_rec.status IN ('Failed', 'Completed') THEN
        RAISE NOTICE 'misja juz zakonczona';
        RETURN;
    END IF;
    IF p_success = FALSE THEN
        UPDATE Missions SET status = 'Failed' WHERE mission_id = p_mission_id;
        RETURN;
    END IF;
    IF m_rec.mission_type = 'Delivery' THEN
        SELECT ps.ship_id
        INTO ship_id_found
        FROM PlayerShips ps
                 JOIN Ships s ON ps.ship_id = s.ship_id
        WHERE ps.owner_player_id = m_rec.assigned_player
          AND s.current_station = m_rec.target_station_id
        LIMIT 1;
        IF ship_id_found IS NULL THEN
            RAISE EXCEPTION 'brak statku gracza % na stacji % do dostawy', m_rec.assigned_player, m_rec.target_station_id;
        END IF;
        PERFORM fn_remove_cargo(ship_id_found, m_rec.required_good_id, m_rec.required_qty);
    END IF;
    UPDATE Missions SET status = 'Completed' WHERE mission_id = p_mission_id;
    IF m_rec.assigned_player IS NOT NULL THEN
        UPDATE Players SET credits = credits + m_rec.reward WHERE player_id = m_rec.assigned_player;
    END IF;
END;
$$;

-- 7. procedure proc_pvp_combat
-- symuluje walke pvp, losowo przenosi kredyty
CREATE OR REPLACE PROCEDURE proc_pvp_combat(p_attacker INT, p_defender INT, p_stake NUMERIC)
    LANGUAGE plpgsql AS
$$
DECLARE
    rand_val NUMERIC;
BEGIN
    IF p_stake <= 0 THEN
        RAISE EXCEPTION 'stawka musi byc dodatnia';
    END IF;
    rand_val := random();
    IF rand_val < 0.5 THEN
        PERFORM proc_transfer_credits(p_defender, p_attacker, p_stake);
        RAISE NOTICE 'atakujacy zwyciezyl';
    ELSE
        PERFORM proc_transfer_credits(p_attacker, p_defender, p_stake);
        RAISE NOTICE 'obronca zwyciezyl';
    END IF;
END;
$$;

-- 8. procedure proc_transfer_credits
-- przenosi kredyty miedzy graczami
CREATE OR REPLACE PROCEDURE proc_transfer_credits(p_from INT, p_to INT, p_amount NUMERIC)
    LANGUAGE plpgsql AS
$$
DECLARE
    fromBalance NUMERIC(18, 2);
BEGIN
    IF p_amount <= 0 THEN
        RAISE EXCEPTION 'kwota transferu musi byc dodatnia';
    END IF;
    SELECT credits INTO fromBalance FROM Players WHERE player_id = p_from;
    IF fromBalance < p_amount THEN
        RAISE EXCEPTION 'niewystarczajace kredyty do transferu';
    END IF;
    UPDATE Players SET credits = credits - p_amount WHERE player_id = p_from;
    UPDATE Players SET credits = credits + p_amount WHERE player_id = p_to;
END;
$$;
