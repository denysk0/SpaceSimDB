------------------------------------------------------------------------------
-- 7_ExampleQueries.sql
------------------------------------------------------------------------------

-- 1) Список активных игроков
SELECT * FROM vw_active_players;

-- 2) Посмотреть, кто контролирует станции
SELECT * FROM vw_stations_with_faction;

-- 3) Посмотреть детальную инфу о кораблях
SELECT * FROM vw_ships_details;

-- 4) Сводка сделок
SELECT * FROM vw_deals_summary;

-- 5) Последние цены товаров
SELECT * FROM vw_goods_prices;

-- 6) Рассчитать дистанцию между Sol(1) и AlphaCentauri(2)
SELECT func_get_distance(1,2) as dist;

-- 7) Протестировать поиск пути (упрощённого) для корабля id=2 (PlayerShip)
SELECT func_find_path(1, 3, 2) as route;
