-- examplequeries.sql

-- lista aktywnych graczy
SELECT * FROM vw_active_players;

-- stacje z frakcja
SELECT * FROM vw_stations_with_faction;

-- szczegoly statkow
SELECT * FROM vw_ships_details;

-- podsumowanie transakcji
SELECT * FROM vw_deals_summary;

-- ostatnie ceny towarow
SELECT * FROM vw_goods_prices;

-- oblicz odleglosc miedzy Sol(1) a AlphaCentauri(2)
SELECT func_get_distance(1,2) AS dist;

-- test wyszukiwania trasy (dla statku id=2)
SELECT func_find_path(1, 3, 2) AS route;
