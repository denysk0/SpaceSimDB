**SpaceSim Database**

## 1. Basic Project Assumptions

**Objective:**  
The goal of the project is to create a database that supports a game world simulating space exploration and trade (SpaceSim). The database stores information about star systems, planets, stations, ships (both player and NPC), trade transactions, missions, factions, and other key gameplay elements.

**Main Assumptions and Features:**

- Support for multiple star systems with their positions (3D coordinates).
- Storage of planets and stations within specific systems.
- Differentiation between player ships (PlayerShips) and NPC ships (NPCShips), inheriting from a base **Ships** table.
- Player and resource management (credits, cargo in ships).
- Recording of transactions (buying and selling goods).
- Storage of missions with completion tracking and reward allocation.
- Integration of functions and procedures for route calculation, distance measurement, cargo management, etc.
- Integrity mechanisms (triggers) to automatically verify and log actions (e.g., buying/selling, ship destruction, player name validation).
- Views presenting key reports (e.g., active players, transactions).

**Design Constraints:**

- Each ship can belong to only one owner (player or NPC).
- For simplicity, all financial operations are conducted in a single currency, and player credit balances use `NUMERIC(18,2)`.
- Complex combat mechanics are not considered, aside from a simple example procedure `proc_pvp_combat`.
- Distances and coordinates are stored in **INT** numeric types with limited precision (instead of float/double types).

## 2. ER Diagram  
The ER diagram is available in the file **ER.png**.  

## 3. Database Schema  
The database schema is available in the file **schemat.png**.  

## 4. Data Integrity  

**Examples of additional integrity constraints (implemented in triggers/functions rather than just in the schema):**

1. **Triggers verifying:**
   - Player credit availability in **transactions** (BUY).
   - Ship cargo capacity when adding goods.
   - Ship ownership (whether it belongs to a given player).
   - Changes to the `is_destroyed` field (logging ship destruction).
   - Player name validation (only alphanumeric characters and `_` allowed).

2. **Cargo state validation:**
   - Functions `fn_add_cargo` and `fn_remove_cargo` raise exceptions if the cargo quantity is insufficient.

3. **ON DELETE Mechanisms:**
   - **ON DELETE CASCADE** (e.g., deleting a star system removes associated planets).
   - **ON DELETE SET NULL** (e.g., a station loses its faction if the faction is deleted).

---

## 5. Indexes  

Indexes are created on primary keys (`PRIMARY KEY`).  
Examples (from **tables.sql** file):

- `PRIMARY KEY` on `id` columns (e.g., `system_id`, `player_id`, `ship_id`, `deal_id`).
- `PRIMARY KEY(ship_id, good_id)` in the **ShipCargo** table.

Additional indexes may be created as needed (e.g., on `deal_type`, `player_id` in `Deals`), but default indexes on primary keys are sufficient for this project.

---

## 6. Views and Procedures  

### **Views**  
Defined in **views.sql**, including:
- **vw_active_players** — filters players with a positive credit balance.
- **vw_stations_with_faction** — displays stations along with their controlling faction.
- **vw_ships_details** — merges player and NPC ship information into a unified logical table.
- **vw_deals_summary** — summarizes transactions (transaction type, station, player, goods, price).
- **vw_goods_prices** — last known price of a good at a given station (from price history).

### **Procedures (Examples)**  
1. **proc_generate_random_systems_and_planets**  
   Randomly generates a specified number of systems and planets in each system.
2. **proc_transfer_credits**  
   Transfers a specified amount of credits from one player to another while validating account balance.
3. **proc_finish_mission**  
   Completes a mission by removing required cargo, awarding a reward, and updating the mission status.
4. **proc_create_system**, **proc_create_planet**, **proc_create_station**, **proc_create_mission**  
   Simple procedures for inserting records into respective tables.
5. **proc_pvp_combat**  
   A sample PvP simulation procedure — randomly determines the winner and transfers a credit stake.

### **Functions (Examples)**  
- **func_get_distance(systemA, systemB)** — calculates the 3D distance between two star systems.  
- **func_find_path(systemA, systemB, ship_id)** — finds a route considering the ship’s maximum jump range.  
- **func_calc_player_profit(player_id)** — calculates net profit (`SUM(SELL) - SUM(BUY)`) for a player.  
- **func_upgrade_ship(ship_id, module_name)** — adds a new module to a ship or upgrades an existing one.  

---

## 7. Triggers  

Defined in **triggers.sql**:

1. **deals_after_insert**  
   - Verifies if a player has enough credits when purchasing (BUY).  
   - Checks ship cargo capacity.  
   - Adds or removes cargo using `fn_add_cargo` / `fn_remove_cargo`.  
   - Updates player account balance.  
   - Logs purchases/sales in the **Logs** table.

2. **ship_destroyed_trigger**  
   - When a ship's `is_destroyed` field changes from **FALSE** to **TRUE**, logs the destruction event.

3. **check_player_name_trigger**  
   - Before inserting/updating a player, ensures the name meets the required regex format (`[a-zA-Z0-9_]`).

4. **goods_price_history_trigger**  
   - Logs new price entries for goods at stations into the **Logs** table.

5. **block_delete_open_mission_trigger**  
   - Prevents the deletion of missions in `Open` or `InProgress` status.

6. **validate_ship_in_deals** and **validate_ship_in_cargo**  
   - Before inserting/updating, check if `ship_id` exists in the **Ships** table.

---

## 8. Database Creation Script  

The script **create_database.sql** contains the following commands:

- **DROP DATABASE IF EXISTS spacesimdb;**  
- **CREATE DATABASE spacesimdb ...**  

After changing the context in `psql` (`\c spacesimdb`), the following `.sql` files should be executed in sequence:

1. **tables.sql** (table structure)  
2. **triggers.sql** (trigger definitions)  
3. **functionsandprocedures.sql** (functions and procedures)  
4. **views.sql** (views)  
5. **inserts.sql** (sample data)  

This results in a fully operational **spacesimdb** database for the **app.py** application.

**setup_from_files.py description:**  
This script (not fully shown here but intended for use) executes a sequence of `psql` commands or uses `psycopg2` to:

1. Create or reset the database.  
2. Load `.sql` files in the correct order.
3. Ensure `spacesimdb` is ready for application use.

---

## 9. Queries (Examples)  

The file **examplequeries.sql** contains queries such as:

```sql
-- List of active players
SELECT * FROM vw_active_players;

-- Stations with faction information
SELECT * FROM vw_stations_with_faction;

-- Ship details
SELECT * FROM vw_ships_details;

-- Transaction summary
SELECT * FROM vw_deals_summary;

-- Latest known goods prices
SELECT * FROM vw_goods_prices;

-- Calculate distance between Sol(1) and AlphaCentauri(2)
SELECT func_get_distance(1, 2) AS dist;

-- Test pathfinding (for ship id=2)
SELECT func_find_path(1, 3, 2) AS route;
```

Other queries can be executed for logs, missions, ship cargo, etc.

---

## Project Execution  

Assuming **Python, pip**, and a **PostgreSQL server** (with user `postgres` and password `postgres`) are installed:

1. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   ```
2. **Run setup script**:
   ```bash
   python setup_from_files.py
   ```
   - This script creates `spacesimdb`, loads `.sql` files, and inserts test data.
3. **Run the Flask application**:
   ```bash
   python app.py
   ```
   - The app will be available at [http://127.0.0.1:5000/](http://127.0.0.1:5000/).

This setup allows testing of database functionality, data management via a web interface, and execution of procedures (e.g., generating systems, completing missions, calculating distances, etc.).