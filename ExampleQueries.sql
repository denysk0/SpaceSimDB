-- ExampleQueries.sql

------------------------------------------------------------------------------
-- Query 1: Lista aktywnych graczy
SELECT * FROM vw_active_players;

------------------------------------------------------------------------------
-- Query 2: Stacje z frakcja
SELECT * FROM vw_stations_with_faction;

------------------------------------------------------------------------------
-- Query 3: Szczegoly statkow
SELECT * FROM vw_ships_details;

------------------------------------------------------------------------------
-- Query 4: Podsumowanie transakcji
SELECT * FROM vw_deals_summary;

------------------------------------------------------------------------------
-- Query 5: Ostatnie ceny towarow
SELECT * FROM vw_goods_prices;

------------------------------------------------------------------------------
-- Query 6: Oblicz dystans miedzy Sol(1) a AlphaCentauri(2)
SELECT func_get_distance(1,2) AS dist;

------------------------------------------------------------------------------
-- Query 7: Test wyszukiwania trasy (dla statku id=2)
SELECT func_find_path(1, 3, 2) AS route;