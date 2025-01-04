------------------------------------------------------------------------------
-- 4_Triggers.sql
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

-- Итого 5 триггеров
