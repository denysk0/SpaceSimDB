# SpaceSimDB: Database for a Space MMO/Simulator Project

## Project Overview
This project is part of a university assignment on database design and implementation. The database is designed for a space-themed MMO/simulation game, inspired by the genre of Elite Dangerous-like games (without direct reference). It serves as the backend for storing and managing data related to:
- Star systems, planets, and space stations
- Players, their ships, transactions, and missions
- Goods, prices, and dynamic market behavior
- NPC factions, reputations, and interactions

## Features
The database fulfills the project requirements with the following key elements:
- **16 Tables**: Core database tables representing the game entities and their relationships.
- **10+ Objects**: Includes views, functions, and procedures (5 views, 2 functions, 5 procedures = 12 objects).
- **5+ Triggers**: Automation for ensuring data integrity and enabling game mechanics.
- **Inheritance**: Implementation of table inheritance (`Ships` as a parent table with `PlayerShips` and `NPCShips` as child tables).
- **Time-Variant Attributes**: Tracking temporal changes with `GoodsPriceHistory` and `PilotsReputationHistory`.
- **Backup Strategy**: Defined procedure for regular database backups.
- **Typical Queries**: Demonstration of common queries for gameplay mechanics and administration.

---

## Key Components

### 1. **ER Diagram** (TODO)
An entity-relationship diagram illustrating the connections between core entities:
- `StarSystems`, `Planets`, `Stations`, `Factions`, `Players`, `Ships`, `Goods`, and others.

### 2. **Database Schema** (TODO)
Detailed schema for the 16 tables, including primary keys, foreign key relationships, and constraints:
- Examples:
  - `StarSystems` ↔ `Planets` (1-to-many)
  - `Players` ↔ `Ships` (1-to-many)
  - `Stations` ↔ `Goods` (many-to-many via a junction table)

### 3. **Additional Constraints**
Business logic enforced through constraints:
- Missions with status `Open` cannot be deleted.
- Purchases require a balance check before completion.

### 4. **Time-Variant Attributes**
- `GoodsPriceHistory`: Tracks fluctuations in market prices over time.
- `PilotsReputationHistory`: Maintains historical reputation data for players and NPC factions.

### 5. **Table Inheritance**
- `Ships` (Parent): General attributes for all ships.
- `PlayerShips`: Specific to player-owned ships.
- `NPCShips`: Specific to non-player character ships.

### 6. **Backup Strategy**
Backup and restore processes are automated using `pg_dump` and `pg_restore`

### 6. **GUI** (TODO)
Web-GUI which helps navigating and modfying the DB