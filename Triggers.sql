-- Triggers.sql

------------------------------------------------------------------------------
-- Trigger 1: trg_deals_after_insert
-- Uruchamiany po INSERT na Deals; sprawdza kredyty, ladunek i loguje transakcje
CREATE OR REPLACE FUNCTION trg_deals_after_insert()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
DECLARE
    playerBalance NUMERIC(18,2);
    totalCost     NUMERIC(18,2);
    currentCargo  INT;
    capacityLeft  INT;
    maxCap        INT;
BEGIN
    SELECT credits INTO playerBalance FROM Players WHERE player_id = NEW.player_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Gracz % nie zostal znaleziony!', NEW.player_id;
    END IF;
    IF NEW.ship_id IS NULL THEN
        RAISE EXCEPTION 'Brak statku dla tej transakcji!';
    END IF;
    SELECT cargo_capacity INTO maxCap FROM Ships WHERE ship_id = NEW.ship_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Statek % nie istnieje!', NEW.ship_id;
    END IF;
    totalCost := NEW.price_per_unit * NEW.quantity;
    IF NEW.deal_type = 'BUY' THEN
        IF playerBalance < totalCost THEN
            RAISE EXCEPTION 'Niewystarczajace kredyty do zakupu!';
        END IF;
        SELECT COALESCE(SUM(quantity),0) INTO currentCargo FROM ShipCargo WHERE ship_id = NEW.ship_id;
        capacityLeft := maxCap - currentCargo;
        IF capacityLeft < NEW.quantity THEN
            RAISE EXCEPTION 'Niewystarczajaca pojemnosc statku %! Pozostalo=%, potrzebne=%', NEW.ship_id, capacityLeft, NEW.quantity;
        END IF;
        UPDATE Players SET credits = credits - totalCost WHERE player_id = NEW.player_id;
        PERFORM fn_add_cargo(NEW.ship_id, NEW.good_id, NEW.quantity);
        INSERT INTO Logs(event_type, description)
        VALUES('BUY', 'Gracz '||NEW.player_id||' kupil '||NEW.quantity||' jednostek towaru '||NEW.good_id||' dla statku '||NEW.ship_id);
    ELSIF NEW.deal_type = 'SELL' THEN
        PERFORM fn_remove_cargo(NEW.ship_id, NEW.good_id, NEW.quantity);
        UPDATE Players SET credits = credits + totalCost WHERE player_id = NEW.player_id;
        INSERT INTO Logs(event_type, description)
        VALUES('SELL', 'Gracz '||NEW.player_id||' sprzedal '||NEW.quantity||' jednostek towaru '||NEW.good_id||' dla statku '||NEW.ship_id);
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS deals_after_insert ON Deals;
CREATE TRIGGER deals_after_insert
AFTER INSERT ON Deals
FOR EACH ROW
EXECUTE FUNCTION trg_deals_after_insert();

------------------------------------------------------------------------------
-- Trigger 2: trg_ship_destroyed_log
-- Loguje, gdy statek zostanie zniszczony
CREATE OR REPLACE FUNCTION trg_ship_destroyed_log()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.is_destroyed = TRUE AND OLD.is_destroyed = FALSE THEN
        INSERT INTO Logs(event_type, description)
        VALUES('SHIP_DESTROYED', 'Statek '||NEW.ship_id||' zostal zniszczony.');
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS ship_destroyed_trigger ON Ships;
CREATE TRIGGER ship_destroyed_trigger
AFTER UPDATE ON Ships
FOR EACH ROW
EXECUTE FUNCTION trg_ship_destroyed_log();

------------------------------------------------------------------------------
-- Trigger 3: trg_check_player_name
-- Sprawdza, czy player_name zawiera tylko dozwolone znaki (alphanumeryczne oraz _)
CREATE OR REPLACE FUNCTION trg_check_player_name()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.player_name ~ '[^a-zA-Z0-9_]' THEN
        RAISE EXCEPTION 'player_name zawiera niedozwolone znaki. Dozwolone: a-z, A-Z, 0-9, _';
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS check_player_name_trigger ON Players;
CREATE TRIGGER check_player_name_trigger
BEFORE INSERT OR UPDATE ON Players
FOR EACH ROW
EXECUTE FUNCTION trg_check_player_name();

------------------------------------------------------------------------------
-- Trigger 4: trg_gph_insert_log
-- Loguje zmiane ceny towaru
-- Trigger: trg_gph_insert_log для GoodsPriceHistory
CREATE OR REPLACE FUNCTION trg_gph_insert_log()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO Logs(event_type, description)
    VALUES('PRICE_UPDATE', 'Station=' || NEW.station_id || ', Good=' || NEW.good_id || ', Price=' || NEW.price);
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS goods_price_history_trigger ON GoodsPriceHistory;
CREATE TRIGGER goods_price_history_trigger
AFTER INSERT ON GoodsPriceHistory
FOR EACH ROW
EXECUTE FUNCTION trg_gph_insert_log();

------------------------------------------------------------------------------
-- Trigger 5: trg_block_delete_open_mission
-- Blokuje usuniecie misji o statusie Open lub InProgress
CREATE OR REPLACE FUNCTION trg_block_delete_open_mission()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
BEGIN
    IF OLD.status IN ('Open','InProgress') THEN
        RAISE EXCEPTION 'Nie mozna usunac aktywnej misji!';
    END IF;
    RETURN OLD;
END;
$$;

DROP TRIGGER IF EXISTS block_delete_open_mission_trigger ON Missions;
CREATE TRIGGER block_delete_open_mission_trigger
BEFORE DELETE ON Missions
FOR EACH ROW
EXECUTE FUNCTION trg_block_delete_open_mission();

------------------------------------------------------------------------------
-- Trigger 6: trg_validate_ship_id
-- Sprawdza, czy ship_id istnieje w tabeli Ships (uwzglednia dziedziczenie)
CREATE OR REPLACE FUNCTION trg_validate_ship_id()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.ship_id IS NULL OR NEW.ship_id <= 0 THEN
        RAISE EXCEPTION 'Niepoprawne ship_id: %', NEW.ship_id;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM Ships WHERE ship_id = NEW.ship_id) THEN
        RAISE EXCEPTION 'Statek o id=% nie istnieje', NEW.ship_id;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS validate_ship_in_deals ON Deals;
CREATE TRIGGER validate_ship_in_deals
BEFORE INSERT OR UPDATE ON Deals
FOR EACH ROW
EXECUTE FUNCTION trg_validate_ship_id();

DROP TRIGGER IF EXISTS validate_ship_in_cargo ON ShipCargo;
CREATE TRIGGER validate_ship_in_cargo
BEFORE INSERT OR UPDATE ON ShipCargo
FOR EACH ROW
EXECUTE FUNCTION trg_validate_ship_id();