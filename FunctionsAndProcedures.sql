------------------------------------------------------------------------------
-- 3_FunctionsAndProcedures.sql
------------------------------------------------------------------------------

-----------------------------
-- 1) Функция: расчёт дистанции между системами (3D)
-----------------------------
CREATE OR REPLACE FUNCTION func_get_distance(systemA INT, systemB INT)
RETURNS NUMERIC(10,4)
LANGUAGE plpgsql
AS $$
DECLARE
    cA record;
    cB record;
    dist NUMERIC(10,4);
BEGIN
    SELECT coord_x, coord_y, coord_z
      INTO cA
      FROM StarSystems
     WHERE system_id = systemA;
    
    SELECT coord_x, coord_y, coord_z
      INTO cB
      FROM StarSystems
     WHERE system_id = systemB;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'One or both StarSystems not found!';
    END IF;

    dist := sqrt(
             power(cB.coord_x - cA.coord_x, 2) +
             power(cB.coord_y - cA.coord_y, 2) +
             power(cB.coord_z - cA.coord_z, 2)
            );
    RETURN dist;
END;
$$;

-----------------------------
-- 2) Функция: поиск маршрута (упрощённая)
--    Ищем путь от systemA к systemB, учитывая max_jump корабля (жадно идём по RouteEdges)
-----------------------------
CREATE OR REPLACE FUNCTION func_find_path(systemA INT, systemB INT, ship_id INT)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    maxJump NUMERIC(8,2);
    path TEXT := '';
    currentSystem INT := systemA;
    distToGoal NUMERIC;
    nextSystem INT;
    finished BOOLEAN := FALSE;

BEGIN
    -- 1) Берём jump_range корабля
    SELECT jump_range
      INTO maxJump
      FROM Ships
      WHERE ship_id = ship_id;  -- !! watch for name collision, better rename local var or param

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Ship not found!';
    END IF;

    path := path || 'Start=' || systemA || ' -> ';

    -- 2) Простой (очень упрощённый) цикл: ищем любой edge (current -> X) с dist <= maxJump
    --    и двигаемся, пока не дойдём до systemB или не застрянем
    WHILE NOT finished LOOP
        IF currentSystem = systemB THEN
            finished := TRUE;
            EXIT;
        END IF;

        -- Найдём любой подходящий RouteEdges
        SELECT system_to
          INTO nextSystem
          FROM RouteEdges
         WHERE system_from = currentSystem
           AND distance_ly <= maxJump
         LIMIT 1;

        IF NOT FOUND THEN
            RETURN 'No route found!';
        END IF;

        path := path || nextSystem || ' -> ';
        currentSystem := nextSystem;

        IF currentSystem = systemB THEN
            finished := TRUE;
        END IF;
    END LOOP;

    path := path || 'End';
    RETURN path;
END;
$$;

-----------------------------
-- 3) Процедура: генерация N случайных систем
-----------------------------
CREATE OR REPLACE PROCEDURE proc_generate_random_systems(p_count INT)
LANGUAGE plpgsql
AS $$
DECLARE
    i INT;
    rndX NUMERIC(8,2);
    rndY NUMERIC(8,2);
    rndZ NUMERIC(8,2);
    starType TEXT;
BEGIN
    FOR i IN 1..p_count LOOP
        rndX := random() * 1000;  -- just example
        rndY := random() * 1000;
        rndZ := random() * 1000;

        IF random() < 0.5 THEN
            starType := 'RedDwarf';
        ELSE
            starType := 'YellowStar';
        END IF;

        INSERT INTO StarSystems(system_name, coord_x, coord_y, coord_z, star_type)
        VALUES (
            'RandSys_'||i,
            rndX, rndY, rndZ,
            starType
        );
    END LOOP;
END;
$$;


-----------------------------
-- 4) Процедура: transfer credits
-----------------------------
CREATE OR REPLACE PROCEDURE proc_transfer_credits(p_from INT, p_to INT, p_amount NUMERIC)
LANGUAGE plpgsql
AS $$
DECLARE
    fromBalance NUMERIC(18,2);
BEGIN
    IF p_amount <= 0 THEN
        RAISE EXCEPTION 'Transfer amount must be > 0';
    END IF;

    SELECT credits INTO fromBalance FROM Players WHERE player_id = p_from;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Source Player not found';
    END IF;

    IF fromBalance < p_amount THEN
        RAISE EXCEPTION 'Not enough credits';
    END IF;

    -- Списываем
    UPDATE Players
       SET credits = credits - p_amount
     WHERE player_id = p_from;

    -- Начисляем
    UPDATE Players
       SET credits = credits + p_amount
     WHERE player_id = p_to;
END;
$$;


-----------------------------
-- 5) Процедура: завершение миссии (миссия id, успех/неуспех)
-----------------------------
CREATE OR REPLACE PROCEDURE proc_finish_mission(p_mission_id INT, p_success BOOLEAN)
LANGUAGE plpgsql
AS $$
DECLARE
    m_rec RECORD;
BEGIN
    SELECT * INTO m_rec
      FROM Missions
     WHERE mission_id = p_mission_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Mission does not exist';
    END IF;

    IF m_rec.status IN ('Failed', 'Completed') THEN
        RAISE NOTICE 'Mission is already finished!';
        RETURN;
    END IF;

    IF p_success THEN
        UPDATE Missions
           SET status = 'Completed'
         WHERE mission_id = p_mission_id;

        -- выдать награду, если assigned_player не NULL
        IF m_rec.assigned_player IS NOT NULL THEN
            UPDATE Players
               SET credits = credits + m_rec.reward
             WHERE player_id = m_rec.assigned_player;
        END IF;
    ELSE
        UPDATE Missions
           SET status = 'Failed'
         WHERE mission_id = p_mission_id;
    END IF;
END;
$$;

--------------------------------------------------------------------------------
-- Другие функции/процедуры по желанию (upgrade_ship, update_faction_rep и т.п.)
--------------------------------------------------------------------------------
