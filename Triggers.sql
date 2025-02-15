------------------------------------------------------------------------------
-- Triggers.sql
------------------------------------------------------------------------------

-----------------------------
-- 1) Триггер после вставки сделки (Deals): 
--    если deal_type='BUY', то списать credits у игрока, увеличить лог;
--    если 'SELL' - наоборот.
-----------------------------
CREATE OR REPLACE FUNCTION trg_deals_after_insert()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    playerBalance NUMERIC(18,2);
    totalCost NUMERIC(18,2);
BEGIN
    SELECT credits INTO playerBalance FROM Players WHERE player_id = NEW.player_id;

    IF NEW.deal_type = 'BUY' THEN
        totalCost := NEW.price_per_unit * NEW.quantity;

        IF playerBalance < totalCost THEN
            RAISE EXCEPTION 'Not enough credits to buy goods!';
        END IF;

        UPDATE Players
           SET credits = credits - totalCost
         WHERE player_id = NEW.player_id;

        INSERT INTO Logs(event_type, description)
        VALUES('BUY', 'Player '||NEW.player_id||' bought '||NEW.quantity||' of good '||NEW.good_id);

    ELSIF NEW.deal_type = 'SELL' THEN
        totalCost := NEW.price_per_unit * NEW.quantity;
        UPDATE Players
           SET credits = credits + totalCost
         WHERE player_id = NEW.player_id;

        INSERT INTO Logs(event_type, description)
        VALUES('SELL', 'Player '||NEW.player_id||' sold '||NEW.quantity||' of good '||NEW.good_id);
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER deals_after_insert
AFTER INSERT ON Deals
FOR EACH ROW
EXECUTE FUNCTION trg_deals_after_insert();


-----------------------------
-- 2) Триггер: после обновления Ships.is_destroyed = TRUE
--    Запишем в логи, что корабль уничтожен
-----------------------------
CREATE OR REPLACE FUNCTION trg_ship_destroyed_log()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.is_destroyed = TRUE AND OLD.is_destroyed = FALSE THEN
        INSERT INTO Logs(event_type, description)
        VALUES('SHIP_DESTROYED', 'Ship '||NEW.ship_id||' destroyed.');
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER ship_destroyed_trigger
AFTER UPDATE ON Ships
FOR EACH ROW
EXECUTE FUNCTION trg_ship_destroyed_log();


-----------------------------
-- 3) Триггер: проверка корректности имени игрока при вставке/обновлении
-----------------------------
CREATE OR REPLACE FUNCTION trg_check_player_name()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.player_name ~ '[^a-zA-Z0-9_]' THEN
        RAISE EXCEPTION 'player_name has invalid characters. Allowed [a-zA-Z0-9_] only.';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER check_player_name_trigger
BEFORE INSERT OR UPDATE ON Players
FOR EACH ROW
EXECUTE FUNCTION trg_check_player_name();

-----------------------------
-- 4) Триггер: на вставку в GoodsPriceHistory
--    Можно проверить, нет ли дублирования record_id, либо писать log
-----------------------------
CREATE OR REPLACE FUNCTION trg_gph_insert_log()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO Logs(event_type, description)
    VALUES('PRICE_UPDATE', 'Station='||NEW.station_id||', Good='||NEW.good_id||', Price='||NEW.price);
    RETURN NEW;
END;
$$;

CREATE TRIGGER goods_price_history_trigger
AFTER INSERT ON GoodsPriceHistory
FOR EACH ROW
EXECUTE FUNCTION trg_gph_insert_log();


-----------------------------
-- 5) Триггер: перед удалением Mission (чтобы запретить удалять открытые миссии)
-----------------------------
CREATE OR REPLACE FUNCTION trg_block_delete_open_mission()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF OLD.status IN ('Open', 'InProgress') THEN
        RAISE EXCEPTION 'Cannot delete mission that is still active!';
    END IF;
    RETURN OLD;
END;
$$;

CREATE TRIGGER block_delete_open_mission_trigger
BEFORE DELETE ON Missions
FOR EACH ROW
EXECUTE FUNCTION trg_block_delete_open_mission();

CREATE OR REPLACE FUNCTION trg_deals_after_insert()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    playerBalance NUMERIC(18,2);
    totalCost     NUMERIC(18,2);
    currentCargo  INT;
    capacityLeft  INT;
    maxCap        INT;
BEGIN
    -- Проверяем, есть ли такой игрок
    SELECT credits INTO playerBalance
      FROM Players WHERE player_id = NEW.player_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Player % not found!', NEW.player_id;
    END IF;

    -- Проверяем, выбран ли корабль для сделки
    IF NEW.ship_id IS NULL THEN
        RAISE EXCEPTION 'No ship selected for this deal!';
    END IF;

    -- Получаем вместимость корабля
    SELECT cargo_capacity INTO maxCap FROM Ships WHERE ship_id = NEW.ship_id;
    IF NOT FOUND THEN
          RAISE EXCEPTION 'Ship % does not exist!', NEW.ship_id;
    END IF;

    totalCost := NEW.price_per_unit * NEW.quantity;

    IF NEW.deal_type = 'BUY' THEN
        -- Проверяем, достаточно ли кредитов
        IF playerBalance < totalCost THEN
            RAISE EXCEPTION 'Not enough credits to buy goods!';
        END IF;

        -- Проверяем, можно ли разместить груз на корабле (вместимость)
        SELECT COALESCE(SUM(quantity), 0)
          INTO currentCargo
          FROM ShipCargo
         WHERE ship_id = NEW.ship_id;

        capacityLeft := maxCap - currentCargo;
        IF capacityLeft < NEW.quantity THEN
            RAISE EXCEPTION 'Not enough cargo capacity on ship %! Capacity left=%, needed=%',
                            NEW.ship_id, capacityLeft, NEW.quantity;
        END IF;

        -- Списываем кредиты
        UPDATE Players
           SET credits = credits - totalCost
         WHERE player_id = NEW.player_id;

        -- Добавляем груз в ShipCargo (INSERT или UPDATE)
        PERFORM fn_add_cargo(NEW.ship_id, NEW.good_id, NEW.quantity);

        -- Записываем лог
        INSERT INTO Logs(event_type, description)
        VALUES ('BUY',
                'Player '||NEW.player_id||' bought '||NEW.quantity||' of good '||NEW.good_id
                ||' on ship '||NEW.ship_id);

    ELSIF NEW.deal_type = 'SELL' THEN
        -- Проверяем, что груз есть на корабле
        PERFORM fn_remove_cargo(NEW.ship_id, NEW.good_id, NEW.quantity);

        -- Начисляем кредиты
        UPDATE Players
           SET credits = credits + totalCost
         WHERE player_id = NEW.player_id;

        -- Записываем лог
        INSERT INTO Logs(event_type, description)
        VALUES ('SELL',
                'Player '||NEW.player_id||' sold '||NEW.quantity||' of good '||NEW.good_id
                ||' from ship '||NEW.ship_id);
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER deals_after_insert
AFTER INSERT ON Deals
FOR EACH ROW
EXECUTE FUNCTION trg_deals_after_insert();

------------------------------------------------------------------------------
-- Триггер для проверки ship_id в таблице Deals
CREATE OR REPLACE FUNCTION trg_validate_ship_id()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM Ships WHERE ship_id = NEW.ship_id
        UNION
        SELECT 1 FROM PlayerShips WHERE ship_id = NEW.ship_id
        UNION
        SELECT 1 FROM NPCShips WHERE ship_id = NEW.ship_id
    ) THEN
        RAISE EXCEPTION 'Ship id % does not exist in any table', NEW.ship_id;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS validate_ship_id_trigger ON Deals;
CREATE TRIGGER validate_ship_id_trigger
BEFORE INSERT OR UPDATE ON Deals
FOR EACH ROW EXECUTE FUNCTION trg_validate_ship_id();
