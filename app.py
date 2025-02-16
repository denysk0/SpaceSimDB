import psycopg2
from flask import Flask, request, redirect, url_for

app = Flask(__name__)

DB_PARAMS = {
    "dbname": "spacesimdb",
    "user": "postgres",
    "password": "postgres",
    "host": "localhost",
    "port": "5432"
}

def get_db_connection():
    return psycopg2.connect(**DB_PARAMS)

def render_page(content):
    return f"""<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>SpaceSim</title>
  <style>
    body {{
      background-color: #121212;
      color: #f0f0f0;
      font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
      margin: 0;
      padding: 20px;
    }}
    h1, h2, h3 {{
      color: #ff8800;
      border-bottom: 2px solid #ff8800;
      padding-bottom: 5px;
    }}
    a {{
      color: #ffa500;
      text-decoration: none;
      border-bottom: 1px dashed #ffa500;
    }}
    a:hover {{
      text-decoration: underline;
    }}
    table {{
      width: 100%;
      border-collapse: collapse;
      margin-bottom: 20px;
    }}
    table, th, td {{
      border: 2px solid #ff8800;
    }}
    th, td {{
      padding: 10px;
      text-align: left;
    }}
    input, select, button {{
      padding: 10px;
      margin: 5px 0;
      border: 2px solid #ff8800;
      border-radius: 4px;
      background: #1e1e1e;
      color: #f0f0f0;
    }}
    button {{
      background: #ff8800;
      color: #121212;
      cursor: pointer;
    }}
    button:hover {{
      opacity: 0.9;
    }}
    form {{
      margin-bottom: 20px;
      border: 2px solid #ff8800;
      padding: 15px;
      border-radius: 8px;
    }}
  </style>
</head>
<body>
{content}
</body>
</html>"""

########################################
# admin-menu
########################################
@app.route("/")
def index():
    content = """
    <h1>SpaceSim</h1>

    <h3>Operations: Create</h3>
    <ul>
      <li><a href='/create_system_form'>Create Star System</a></li>
      <li><a href='/create_planet_form'>Create Planet</a></li>
      <li><a href='/create_station_form'>Create Station</a></li>
      <li><a href='/create_mission_form'>Create Mission</a></li>
      <li><a href='/create_ship_form'>Create Ship (PlayerShip)</a></li>
    </ul>

    <h3>Operations: View</h3>
    <ul>
      <li><a href='/systems'>View Star Systems</a></li>
      <li><a href='/missions'>View Missions</a></li>
      <li><a href='/ships'>View Ships</a></li>
      <li><a href='/npcs'>View NPC Ships</a></li>
      <li><a href='/players'>View Players</a></li>
      <li><a href='/logs'>View Logs</a></li>
    </ul>

    <h3>Other Operations</h3>
    <ul>
      <li><a href='/generate_random_form'>Generate Random Systems/Planets</a></li>
      <li><a href='/test_distance_form'>Calculate Distance between Systems</a></li>
      <li><a href='/find_path_form'>Find Route for Ship</a></li>
      <li><a href='/transfer_credits_form'>Transfer Credits</a></li>
    </ul>

    <hr>
    <h3>Login as Player</h3>
    <form action='/player_menu_redirect' method='GET'>
      PlayerID: <input type='number' name='player_id' value='1' min="0"/>
      <button type='submit'>Go to Player Menu</button>
    </form>
    """
    return render_page(content)

@app.route("/player_menu_redirect")
def player_menu_redirect():
    player_id = request.args.get("player_id", "1")
    return redirect(url_for("player_main_menu", player_id=int(player_id)))

########################################
# tworzenie systemu
########################################
@app.route("/create_system_form")
def create_system_form():
    content = """
    <h2>Create Star System</h2>
    <form method='POST' action='/create_system'>
      System Name: <input type='text' name='system_name' value='SystemName'/><br/>
      Coord X: <input type='number' step='0.1' name='coord_x' value='0'/><br/>
      Coord Y: <input type='number' step='0.1' name='coord_y' value='0'/><br/>
      Coord Z: <input type='number' step='0.1' name='coord_z' value='0'/><br/>
      Star Type: <input type='text' name='star_type' value='BlackHole'/><br/>
      <button type='submit'>Create Star System</button>
    </form>
    <a href='/'>Back</a>
    """
    return render_page(content)

@app.route("/create_system", methods=["POST"])
def create_system():
    system_name = request.form.get("system_name")
    coord_x = float(request.form.get("coord_x"))
    coord_y = float(request.form.get("coord_y"))
    coord_z = float(request.form.get("coord_z"))
    star_type = request.form.get("star_type")
    conn = get_db_connection()
    cur = conn.cursor()
    try:
        cur.execute("""
            INSERT INTO StarSystems(system_name, coord_x, coord_y, coord_z, star_type)
            VALUES (%s, %s, %s, %s, %s) RETURNING system_id
        """, (system_name, coord_x, coord_y, coord_z, star_type))
        system_id = cur.fetchone()[0]
        conn.commit()
        result = f"Star system '{system_name}' created with ID {system_id}!"
    except Exception as e:
        conn.rollback()
        result = f"Error creating system: {e}"
    finally:
        cur.close()
        conn.close()
    return render_page(f"<p>{result}</p><a href='/systems'>View Star Systems</a>")

########################################
# tworzenie planety
########################################
@app.route("/create_planet_form")
def create_planet_form():
    content = """
    <h2>Create Planet</h2>
    <form method='POST' action='/create_planet'>
      Planet Name: <input type='text' name='planet_name' value='Venus'/><br/>
      Planet Type: <input type='text' name='planet_type' value='Rocky'/><br/>
      Planet Size: <input type='number' step='0.1' name='planet_size' value='1'/><br/>
      Population: <input type='number' name='population' value='1000000'/><br/>
      Populated? <select name='is_populated'>
          <option value='true'>Yes</option>
          <option value='false'>No</option>
      </select><br/>
      Star System ID: <input type='number' name='system_id' value='1'/><br/>
      <button type='submit'>Create Planet</button>
    </form>
    <a href='/'>Back</a>
    """
    return render_page(content)

@app.route("/create_planet", methods=["POST"])
def create_planet():
    planet_name = request.form.get("planet_name")
    planet_type = request.form.get("planet_type")
    planet_size = float(request.form.get("planet_size"))
    population = int(request.form.get("population"))
    is_populated = request.form.get("is_populated").lower() == "true"
    system_id = int(request.form.get("system_id"))
    conn = get_db_connection()
    cur = conn.cursor()
    try:
        cur.execute("""
            INSERT INTO Planets(planet_name, planet_type, planet_size, population, is_populated, system_id)
            VALUES (%s, %s, %s, %s, %s, %s) RETURNING planet_id
        """, (planet_name, planet_type, planet_size, population, is_populated, system_id))
        planet_id = cur.fetchone()[0]
        conn.commit()
        result = f"Planet '{planet_name}' created with ID {planet_id}!"
    except Exception as e:
        conn.rollback()
        result = f"Error creating planet: {e}"
    finally:
        cur.close()
        conn.close()
    return render_page(f"<p>{result}</p><a href='/system/{system_id}'>Back to System Details</a>")

########################################
# tworzenie stacji
########################################
@app.route("/create_station_form")
def create_station_form():
    content = """
    <h2>Create Station</h2>
    <form method='POST' action='/create_station'>
      Station Name: <input type='text' name='station_name' value='Orbital One'/><br/>
      Station Type: <input type='text' name='station_type' value='Trading'/><br/>
      Star System ID: <input type='number' name='system_id' value='1'/><br/>
      Planet ID (optional): <input type='text' name='planet_id'/><br/>
      Controlling Faction ID (optional): <input type='text' name='faction_id'/><br/>
      <button type='submit'>Create Station</button>
    </form>
    <a href='/'>Back</a>
    """
    return render_page(content)

@app.route("/create_station", methods=["POST"])
def create_station():
    station_name = request.form.get("station_name")
    station_type = request.form.get("station_type")
    system_id = int(request.form.get("system_id"))
    planet_id = request.form.get("planet_id")
    planet_id = int(planet_id) if planet_id and planet_id.strip() != "" else None
    faction_id = request.form.get("faction_id")
    faction_id = int(faction_id) if faction_id and faction_id.strip() != "" else None
    conn = get_db_connection()
    cur = conn.cursor()
    try:
        cur.execute("""
            INSERT INTO Stations(station_name, station_type, system_id, planet_id, controlling_faction)
            VALUES (%s, %s, %s, %s, %s) RETURNING station_id
        """, (station_name, station_type, system_id, planet_id, faction_id))
        station_id = cur.fetchone()[0]
        conn.commit()
        result = f"Station '{station_name}' created with ID {station_id}!"
    except Exception as e:
        conn.rollback()
        result = f"Error creating station: {e}"
    finally:
        cur.close()
        conn.close()
    return render_page(f"<p>{result}</p><a href='/systems'>Back to Systems</a>")

########################################
# tworzenie "mission" (zadan)
########################################
@app.route("/create_mission_form")
def create_mission_form():
    content = """
    <h2>Create Mission</h2>
    <form method='POST' action='/create_mission'>
      Mission Type: <input type='text' name='mission_type' value='Delivery'/><br/>
      Reward: <input type='number' step='0.01' name='reward' value='500'/><br/>
      Target Station ID: <input type='number' name='target_station_id' value='1'/><br/>
      Required Good ID: <input type='number' name='required_good_id' value='1'/><br/>
      Required Quantity: <input type='number' name='required_qty' value='10'/><br/>
      Assigned Player ID (optional): <input type='text' name='assigned_player'/><br/>
      <button type='submit'>Create Mission</button>
    </form>
    <a href='/'>Back</a>
    """
    return render_page(content)

@app.route("/create_mission", methods=["POST"])
def create_mission():
    mission_type = request.form.get("mission_type")
    reward = float(request.form.get("reward"))
    target_station_id = int(request.form.get("target_station_id"))
    required_good_id = int(request.form.get("required_good_id"))
    required_qty = int(request.form.get("required_qty"))
    assigned_player = request.form.get("assigned_player")
    assigned_player = int(assigned_player) if assigned_player and assigned_player.strip() != "" else None
    conn = get_db_connection()
    cur = conn.cursor()
    try:
        cur.execute("""
            INSERT INTO Missions(mission_type, reward, target_station_id, required_good_id, required_qty, assigned_player, status)
            VALUES (%s, %s, %s, %s, %s, %s, 'Open') RETURNING mission_id
        """, (mission_type, reward, target_station_id, required_good_id, required_qty, assigned_player))
        mission_id = cur.fetchone()[0]
        conn.commit()
        result = f"Mission '{mission_type}' created with ID {mission_id}!"
    except Exception as e:
        conn.rollback()
        result = f"Error creating mission: {e}"
    finally:
        cur.close()
        conn.close()
    return render_page(f"<p>{result}</p><a href='/missions'>View Missions</a>")

########################################
# c
########################################
@app.route("/systems")
def systems():
    conn = get_db_connection()
    cur = conn.cursor()
    try:
        cur.execute("SELECT system_id, system_name, coord_x, coord_y, coord_z, star_type FROM StarSystems ORDER BY system_id")
        systems_list = cur.fetchall()
        html = "<h2>Star Systems</h2>"
        if systems_list:
            html += "<table><tr><th>ID</th><th>Name</th><th>X</th><th>Y</th><th>Z</th><th>Star Type</th></tr>"
            for sys in systems_list:
                html += f"<tr><td>{sys[0]}</td><td><a href='/system/{sys[0]}'>{sys[1]}</a></td><td>{sys[2]}</td><td>{sys[3]}</td><td>{sys[4]}</td><td>{sys[5]}</td></tr>"
            html += "</table>"
        else:
            html += "<p>No star systems found.</p>"
    except Exception as e:
        html = f"<p>Error fetching systems: {e}</p>"
    finally:
        cur.close()
        conn.close()
    html += "<a href='/'>Back</a>"
    return render_page(html)

########################################
# szczegoly systemow
########################################
@app.route("/system/<int:system_id>")
def system_details(system_id):
    conn = get_db_connection()
    cur = conn.cursor()
    try:
        cur.execute("SELECT system_id, system_name, coord_x, coord_y, coord_z, star_type FROM StarSystems WHERE system_id = %s", (system_id,))
        system_row = cur.fetchone()
        if not system_row:
            return render_page(f"<p>System with ID {system_id} not found.</p><a href='/systems'>Back</a>")
        html = f"<h2>System: {system_row[1]} (ID={system_row[0]})</h2>"
        html += f"<p>Coordinates: ({system_row[2]}, {system_row[3]}, {system_row[4]})<br/>Star Type: {system_row[5]}</p>"
        cur.execute("SELECT planet_id, planet_name, planet_type, planet_size, population, is_populated FROM Planets WHERE system_id = %s ORDER BY planet_id", (system_id,))
        planets = cur.fetchall()
        html += "<h3>Planets in the System</h3>"
        if planets:
            html += "<table><tr><th>ID</th><th>Name</th><th>Type</th><th>Size</th><th>Population</th><th>Populated?</th></tr>"
            for p in planets:
                html += f"<tr><td>{p[0]}</td><td>{p[1]}</td><td>{p[2]}</td><td>{p[3]}</td><td>{p[4]}</td><td>{'Yes' if p[5] else 'No'}</td></tr>"
            html += "</table>"
        else:
            html += "<p>No planets in this system.</p>"
        cur.execute("""SELECT s.station_id, s.station_name, s.station_type, s.planet_id, f.faction_name 
                       FROM Stations s 
                       LEFT JOIN Factions f ON s.controlling_faction = f.faction_id 
                       WHERE s.system_id = %s 
                       ORDER BY s.station_id""", (system_id,))
        stations = cur.fetchall()
        html += "<h3>Stations in the System</h3>"
        if stations:
            html += "<table><tr><th>ID</th><th>Name</th><th>Type</th><th>Planet</th><th>Faction</th></tr>"
            for s in stations:
                html += f"<tr><td>{s[0]}</td><td>{s[1]}</td><td>{s[2]}</td><td>{s[3] or '---'}</td><td>{s[4] or '---'}</td></tr>"
            html += "</table>"
        else:
            html += "<p>No stations in this system.</p>"
    except Exception as e:
        html = f"<p>Error fetching system details: {e}</p>"
    finally:
        cur.close()
        conn.close()
    html += "<a href='/systems'>Back to Systems</a>"
    return render_page(html)

########################################
# przegladanie zadan
########################################
@app.route("/missions")
def missions():
    conn = get_db_connection()
    cur = conn.cursor()
    try:
        cur.execute("""
            SELECT mission_id, mission_type, reward, target_station_id, required_good_id, required_qty, assigned_player, status
            FROM Missions
            ORDER BY mission_id
        """)
        mission_rows = cur.fetchall()
        html = "<h2>Missions</h2>"
        if mission_rows:
            html += "<table><tr><th>ID</th><th>Type</th><th>Reward</th><th>Target Station</th><th>Good</th><th>Qty</th><th>Assigned Player</th><th>Status</th></tr>"
            for m in mission_rows:
                html += f"<tr><td>{m[0]}</td><td>{m[1]}</td><td>{m[2]}</td><td>{m[3] or '---'}</td><td>{m[4] or '---'}</td><td>{m[5]}</td><td>{m[6] or '---'}</td><td>{m[7]}</td></tr>"
            html += "</table>"
        else:
            html += "<p>No missions found.</p>"
    except Exception as e:
        html = f"<p>Error fetching missions: {e}</p>"
    finally:
        cur.close()
        conn.close()
    html += "<a href='/'>Back</a>"
    return render_page(html)

########################################
# obliczenie odleglosci miedzy systemami
########################################
@app.route("/test_distance_form")
def test_distance_form():
    content = """
    <h2>Calculate Distance between Systems</h2>
    <form method='GET' action='/test_distance'>
      System A ID: <input type='number' name='systemA' value='1' min="0"/><br/>
      System B ID: <input type='number' name='systemB' value='2' min="0"/><br/>
      <button type='submit'>Calculate Distance</button>
    </form>
    <a href='/'>Back</a>
    """
    return render_page(content)

@app.route("/test_distance")
def test_distance():
    systemA = int(request.args.get("systemA", 1))
    systemB = int(request.args.get("systemB", 2))
    conn = get_db_connection()
    cur = conn.cursor()
    try:
        cur.execute("SELECT public.func_get_distance(%s, %s)", (systemA, systemB))
        distance = cur.fetchone()[0]
        result = f"Distance between systems {systemA} and {systemB} = {distance}"
    except Exception as e:
        result = f"Error: {e}"
    finally:
        cur.close()
        conn.close()
    return render_page(f"<p>{result}</p><a href='/test_distance_form'>Back</a>")

########################################
# szukanie drogi
########################################
@app.route("/find_path_form")
def find_path_form():
    content = """
    <h2>Find Route for Ship</h2>
    <form method='GET' action='/find_path'>
      System A ID (start): <input type='number' name='systemA' value='1' min="0"/><br/>
      System B ID (destination): <input type='number' name='systemB' value='3' min="0"/><br/>
      Ship ID: <input type='number' name='ship_id' value='1' min="0"/><br/>
      <button type='submit'>Find Route</button>
    </form>
    <a href='/'>Back</a>
    """
    return render_page(content)

@app.route("/find_path")
def find_path():
    systemA = int(request.args.get("systemA", 1))
    systemB = int(request.args.get("systemB", 3))
    ship_id = int(request.args.get("ship_id", 1))
    conn = get_db_connection()
    cur = conn.cursor()
    try:
        cur.execute("SELECT public.func_find_path(%s, %s, %s)", (systemA, systemB, ship_id))
        route = cur.fetchone()[0]
        result = f"Route for ship {ship_id}: {route}"
    except Exception as e:
        result = f"Error: {e}"
    finally:
        cur.close()
        conn.close()
    return render_page(f"<p>{result}</p><a href='/find_path_form'>Back</a>")

########################################
# upgrade'y statkow   ----------
########################################
@app.route("/upgrade_ship_form")
def upgrade_ship_form():
    content = """
    <h2>Upgrade Ship</h2>
    <form method='POST' action='/upgrade_ship'>
      Ship ID: <input type='number' name='ship_id' value='1' min="0"/><br/>
      Module Name: <input type='text' name='module_name' value='Shield'/><br/>
      <button type='submit'>Upgrade</button>
    </form>
    <a href='/'>Back</a>
    """
    return render_page(content)

@app.route("/upgrade_ship", methods=["POST"])
def upgrade_ship():
    ship_id = int(request.form.get("ship_id"))
    module_name = request.form.get("module_name")
    conn = get_db_connection()
    cur = conn.cursor()
    try:
        cur.execute("SELECT public.func_upgrade_ship(%s, %s)", (ship_id, module_name))
        result = cur.fetchone()[0]
        conn.commit()
    except Exception as e:
        conn.rollback()
        result = f"Error upgrading ship: {e}"
    finally:
        cur.close()
        conn.close()
    return render_page(f"<p>{result}</p><a href='/'>Back</a>")

########################################
# generowanie randomowych systemow i planet
########################################
@app.route("/generate_random_form")
def generate_random_form():
    content = """
    <h2>Generate Random Star Systems and Planets</h2>
    <form method='POST' action='/generate_random'>
      Number of systems: <input type='number' name='system_count' value='5' min="1"/><br/>
      Planets per system: <input type='number' name='planets_per_system' value='3' min="0"/><br/>
      <button type='submit'>Generate</button>
    </form>
    <a href='/'>Back</a>
    """
    return render_page(content)

@app.route("/generate_random", methods=["POST"])
def generate_random():
    system_count = int(request.form.get("system_count"))
    planets_per_system = int(request.form.get("planets_per_system"))
    conn = get_db_connection()
    cur = conn.cursor()
    try:
        cur.execute("CALL proc_generate_random_systems_and_planets(%s, %s)", (system_count, planets_per_system))
        conn.commit()
        result = f"Generated {system_count} systems with {planets_per_system} planets each."
    except Exception as e:
        conn.rollback()
        result = f"Error: {e}"
    finally:
        cur.close()
        conn.close()
    return render_page(f"<p>{result}</p><a href='/'>Back</a>")

########################################
# operacje gracza : menu, profil, deals, ship moving etc.
########################################
@app.route("/player/<int:player_id>/menu")
def player_main_menu(player_id):
    content = f"""
    <h2>Player Menu {player_id}</h2>
    <ul>
      <li><a href='/player/{player_id}/profile'>Profile (Ships, Credits)</a></li>
      <li><a href='/player/{player_id}/buy_good_form'>Buy Goods</a></li>
      <li><a href='/player/{player_id}/sell_good_form'>Sell Goods</a></li>
      <li><a href='/player/{player_id}/cargo'>View Cargo</a></li>
      <li><a href='/player/{player_id}/move_ship_form'>Move Ship</a></li>
      <li><a href='/player/{player_id}/missions'>My Missions</a></li>
      <li><a href='/player/{player_id}/finish_mission_form'>Finish Mission</a></li>
      <li><a href='/player/{player_id}/calc_profit_form'>Calculate Profit</a></li>
    </ul>
    <a href='/'>Back to Main Menu</a>
    """
    return render_page(content)

@app.route("/player/<int:player_id>/profile")
def player_profile(player_id):
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("SELECT player_name, credits FROM Players WHERE player_id = %s", (player_id,))
    player_info = cur.fetchone()
    if not player_info:
        cur.close()
        conn.close()
        return render_page(f"<p>Player {player_id} not found!</p><a href='/'>Back</a>")
    player_name, credits = player_info
    cur.execute("""
        SELECT ship_id, model_name, max_speed, cargo_capacity, jump_range, current_system, current_station
        FROM ONLY PlayerShips
        WHERE owner_player_id = %s
        ORDER BY ship_id
    """, (player_id,))
    ships = cur.fetchall()
    cur.close()
    conn.close()
    html = f"<h2>Profile: {player_name} (ID={player_id})</h2>"
    html += f"<p>Credits: {credits}</p>"
    html += "<h3>My Ships:</h3>"
    if ships:
        html += "<table><tr><th>ID</th><th>Model</th><th>Speed</th><th>CargoCap</th><th>JumpRange</th><th>System</th><th>Station</th></tr>"
        for s in ships:
            html += f"<tr><td>{s[0]}</td><td>{s[1]}</td><td>{s[2]}</td><td>{s[3]}</td><td>{s[4]}</td><td>{s[5] or '---'}</td><td>{s[6] or '---'}</td></tr>"
        html += "</table>"
    else:
        html += "<p>No ships.</p>"
    html += f"<p><a href='/player/{player_id}/menu'>Back</a></p>"
    return render_page(html)

@app.route("/player/<int:player_id>/buy_good_form")
def player_buy_good_form(player_id):
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("SELECT ship_id, model_name FROM ONLY PlayerShips WHERE owner_player_id = %s", (player_id,))
    ships = cur.fetchall()
    cur.close()
    conn.close()
    if not ships:
        return render_page(f"<p>No ships for player {player_id}!</p><a href='/player/{player_id}/menu'>Back</a>")
    options = "".join([f"<option value='{s[0]}'>{s[0]} - {s[1]}</option>" for s in ships])
    content = f"""
    <h2>Buy Goods (Player {player_id})</h2>
    <form method='POST' action='/player/{player_id}/deal_buy'>
      Ship: <select name='ship_id'>{options}</select><br/><br/>
      Station (ID): <input type='number' name='station_id' value='1' min="0"/><br/>
      Good (ID): <input type='number' name='good_id' value='1' min="0"/><br/>
      Quantity: <input type='number' name='quantity' value='5' min="0"/><br/>
      Price per unit: <input type='number' step='0.01' name='price_per_unit' value='10' min="0"/><br/>
      <button type='submit'>Buy</button>
    </form>
    <a href='/player/{player_id}/menu'>Back</a>
    """
    return render_page(content)

@app.route("/player/<int:player_id>/deal_buy", methods=["POST"])
def player_deal_buy(player_id):
    ship_id = int(request.form.get("ship_id"))
    station_id = int(request.form.get("station_id"))
    good_id = int(request.form.get("good_id"))
    quantity = int(request.form.get("quantity"))
    ppu = float(request.form.get("price_per_unit"))
    conn = get_db_connection()
    cur = conn.cursor()
    try:
        cur.execute("SELECT owner_player_id FROM ONLY PlayerShips WHERE ship_id = %s", (ship_id,))
        row = cur.fetchone()
        if not row or row[0] != player_id:
            return render_page(f"<p>Ship {ship_id} does not belong to player {player_id}!</p><a href='/player/{player_id}/menu'>Back</a>")
        cur.execute("""
            INSERT INTO Deals(player_id, station_id, good_id, quantity, price_per_unit, deal_type, ship_id)
            VALUES (%s, %s, %s, %s, %s, 'BUY', %s)
        """, (player_id, station_id, good_id, quantity, ppu, ship_id))
        conn.commit()
    except Exception as e:
        conn.rollback()
        cur.close()
        conn.close()
        return render_page(f"<p>Error buying goods: {e}</p><a href='/player/{player_id}/menu'>Back</a>")
    cur.close()
    conn.close()
    return render_page(f"<p>Player {player_id} bought {quantity} units of good {good_id} for ship {ship_id} at {ppu} each.</p><a href='/player/{player_id}/menu'>Back</a>")

@app.route("/player/<int:player_id>/sell_good_form")
def player_sell_good_form(player_id):
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("SELECT ship_id, model_name FROM ONLY PlayerShips WHERE owner_player_id = %s", (player_id,))
    ships = cur.fetchall()
    cur.close()
    conn.close()
    if not ships:
        return render_page(f"<p>No ships for player {player_id}!</p><a href='/player/{player_id}/menu'>Back</a>")
    options = "".join([f"<option value='{s[0]}'>{s[0]} - {s[1]}</option>" for s in ships])
    content = f"""
    <h2>Sell Goods (Player {player_id})</h2>
    <form method='POST' action='/player/{player_id}/deal_sell'>
      Ship: <select name='ship_id'>{options}</select><br/><br/>
      Station (ID): <input type='number' name='station_id' value='1' min="0"/><br/>
      Good (ID): <input type='number' name='good_id' value='1' min="0"/><br/>
      Quantity: <input type='number' name='quantity' value='2' min="0"/><br/>
      Price per unit: <input type='number' step='0.01' name='price_per_unit' value='15' min="0"/><br/>
      <button type='submit'>Sell</button>
    </form>
    <a href='/player/{player_id}/menu'>Back</a>
    """
    return render_page(content)

@app.route("/player/<int:player_id>/deal_sell", methods=["POST"])
def player_deal_sell(player_id):
    ship_id = int(request.form.get("ship_id"))
    station_id = int(request.form.get("station_id"))
    good_id = int(request.form.get("good_id"))
    quantity = int(request.form.get("quantity"))
    ppu = float(request.form.get("price_per_unit"))
    conn = get_db_connection()
    cur = conn.cursor()
    try:
        cur.execute("SELECT owner_player_id FROM ONLY PlayerShips WHERE ship_id = %s", (ship_id,))
        row = cur.fetchone()
        if not row or row[0] != player_id:
            return render_page(f"<p>Ship {ship_id} does not belong to player {player_id}!</p><a href='/player/{player_id}/menu'>Back</a>")
        cur.execute("""
            INSERT INTO Deals(player_id, station_id, good_id, quantity, price_per_unit, deal_type, ship_id)
            VALUES (%s, %s, %s, %s, %s, 'SELL', %s)
        """, (player_id, station_id, good_id, quantity, ppu, ship_id))
        conn.commit()
    except Exception as e:
        conn.rollback()
        cur.close()
        conn.close()
        return render_page(f"<p>Error selling goods: {e}</p><a href='/player/{player_id}/menu'>Back</a>")
    cur.close()
    conn.close()
    return render_page(f"<p>Player {player_id} sold {quantity} units of good {good_id} from ship {ship_id} at {ppu} each.</p><a href='/player/{player_id}/menu'>Back</a>")

@app.route("/player/<int:player_id>/cargo")
def player_cargo(player_id):
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("""
      SELECT sc.ship_id, s.model_name, sc.good_id, g.good_name, sc.quantity
      FROM ShipCargo sc
      JOIN Ships s ON sc.ship_id = s.ship_id
      JOIN Goods g ON sc.good_id = g.good_id
      JOIN ONLY PlayerShips ps ON ps.ship_id = sc.ship_id
      WHERE ps.owner_player_id = %s
      ORDER BY sc.ship_id, sc.good_id
    """, (player_id,))
    rows = cur.fetchall()
    cur.close()
    conn.close()
    if not rows:
        return render_page(f"<p>No cargo found for player {player_id}.</p><a href='/player/{player_id}/menu'>Back</a>")
    html = f"<h2>Player {player_id} Cargo</h2>"
    html += "<table><tr><th>ShipID</th><th>Model</th><th>GoodID</th><th>GoodName</th><th>Quantity</th></tr>"
    for (ship_id, model_name, good_id, good_name, qty) in rows:
        html += f"<tr><td>{ship_id}</td><td>{model_name}</td><td>{good_id}</td><td>{good_name}</td><td>{qty}</td></tr>"
    html += f"</table><a href='/player/{player_id}/menu'>Back</a>"
    return render_page(html)

@app.route("/player/<int:player_id>/move_ship_form")
def player_move_ship_form(player_id):
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("SELECT ship_id, model_name FROM ONLY PlayerShips WHERE owner_player_id = %s", (player_id,))
    ships = cur.fetchall()
    cur.close()
    conn.close()
    if not ships:
        return render_page(f"<p>No ships for player {player_id}!</p><a href='/player/{player_id}/menu'>Back</a>")
    options = "".join([f"<option value='{s[0]}'>{s[0]} - {s[1]}</option>" for s in ships])
    content = f"""
    <h2>Move Ship (Player {player_id})</h2>
    <form method='POST' action='/player/{player_id}/move_ship'>
      Ship: <select name='ship_id'>{options}</select><br/><br/>
      New System ID: <input type='number' name='system_id' value='1' min="0"/><br/>
      New Station ID (0 for none): <input type='number' name='station_id' value='1' min="0"/><br/>
      <button type='submit'>Move</button>
    </form>
    <a href='/player/{player_id}/menu'>Back</a>
    """
    return render_page(content)

@app.route("/player/<int:player_id>/move_ship", methods=["POST"])
def player_move_ship(player_id):
    ship_id = int(request.form.get("ship_id"))
    new_system_id = int(request.form.get("system_id"))
    new_station_id = int(request.form.get("station_id"))
    conn = get_db_connection()
    cur = conn.cursor()
    try:
        cur.execute("SELECT owner_player_id FROM ONLY PlayerShips WHERE ship_id = %s", (ship_id,))
        row = cur.fetchone()
        if not row or row[0] != player_id:
            return render_page(f"<p>Ship {ship_id} does not belong to player {player_id}!</p><a href='/player/{player_id}/menu'>Back</a>")
        cur.execute("UPDATE Ships SET current_system = %s, current_station = %s WHERE ship_id = %s",
                    (new_system_id, new_station_id, ship_id))
        conn.commit()
    except Exception as e:
        conn.rollback()
        cur.close()
        conn.close()
        return render_page(f"<p>Error moving ship: {e}</p><a href='/player/{player_id}/menu'>Back</a>")
    cur.close()
    conn.close()
    return render_page(f"<p>Ship {ship_id} moved to system {new_system_id} and station {new_station_id}.</p><a href='/player/{player_id}/menu'>Back</a>")

@app.route("/player/<int:player_id>/missions")
def player_missions(player_id):
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("""
        SELECT mission_id, mission_type, reward, target_station_id, required_good_id, required_qty, status
        FROM Missions
        WHERE assigned_player = %s
        ORDER BY mission_id
    """, (player_id,))
    missions_list = cur.fetchall()
    cur.close()
    conn.close()
    html = f"<h2>Player {player_id} Missions</h2>"
    if not missions_list:
        html += "<p>No missions.</p>"
    else:
        html += "<table><tr><th>ID</th><th>Type</th><th>Reward</th><th>Target Station</th><th>Good</th><th>Quantity</th><th>Status</th></tr>"
        for m in missions_list:
            html += f"<tr><td>{m[0]}</td><td>{m[1]}</td><td>{m[2]}</td><td>{m[3] or '---'}</td><td>{m[4] or '---'}</td><td>{m[5]}</td><td>{m[6]}</td></tr>"
        html += "</table>"
    html += f"<p><a href='/player/{player_id}/menu'>Back</a></p>"
    return render_page(html)

@app.route("/player/<int:player_id>/finish_mission_form")
def finish_mission_form(player_id):
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("""
        SELECT mission_id, mission_type, status
        FROM Missions
        WHERE assigned_player = %s AND status IN ('Open','InProgress')
        ORDER BY mission_id
    """, (player_id,))
    missions = cur.fetchall()
    cur.close()
    conn.close()
    if not missions:
        return render_page(f"<p>No active missions for player {player_id}!</p><a href='/player/{player_id}/menu'>Back</a>")
    options = "".join([f"<option value='{m[0]}'>{m[0]} - {m[1]} ({m[2]})</option>" for m in missions])
    content = f"""
    <h2>Finish Mission (Player {player_id})</h2>
    <form method='POST' action='/player/{player_id}/finish_mission'>
      Select Mission:
      <select name='mission_id'>{options}</select><br/><br/>
      Success? <select name='success'>
        <option value='true'>Yes</option>
        <option value='false'>No</option>
      </select><br/><br/>
      <button type='submit'>Finish Mission</button>
    </form>
    <a href='/player/{player_id}/menu'>Back</a>
    """
    return render_page(content)

@app.route("/player/<int:player_id>/finish_mission", methods=["POST"])
def finish_mission(player_id):
    mission_id = int(request.form.get("mission_id"))
    success_str = request.form.get("success", "true").lower()
    success_bool = (success_str == "true")
    conn = get_db_connection()
    cur = conn.cursor()
    try:
        cur.execute("CALL proc_finish_mission(%s, %s)", (mission_id, success_bool))
        conn.commit()
    except Exception as e:
        conn.rollback()
        cur.close()
        conn.close()
        return render_page(f"<p>Error finishing mission {mission_id}: {e}</p><a href='/player/{player_id}/menu'>Back</a>")
    cur.close()
    conn.close()
    return render_page(f"<p>Mission {mission_id} finished. Success = {success_bool}.</p><a href='/player/{player_id}/menu'>Back</a>")

@app.route("/player/<int:player_id>/calc_profit_form")
def player_calc_profit_form(player_id):
    content = f"""
    <h2>Calculate Profit (Player {player_id})</h2>
    <form action='/player/{player_id}/calc_profit' method='GET'>
      <button type='submit'>Calculate</button>
    </form>
    <a href='/player/{player_id}/menu'>Back</a>
    """
    return render_page(content)

@app.route("/player/<int:player_id>/calc_profit")
def player_calc_profit(player_id):
    conn = get_db_connection()
    cur = conn.cursor()
    try:
        cur.execute("SELECT func_calc_player_profit(%s)", (player_id,))
        profit = cur.fetchone()[0]
    except Exception as e:
        profit = f"Error: {e}"
    finally:
        cur.close()
        conn.close()
    return render_page(f"<p>Player {player_id} net profit = {profit}</p><a href='/player/{player_id}/menu'>Back</a>")

########################################
# Дополнительные маршруты: просмотр всех кораблей, NPC, станций, игроков, логов, создание игрока, перевод кредитов
########################################
@app.route("/create_ship_form")
def create_ship_form():
    content = """
    <h2>Create Ship (PlayerShip)</h2>
    <form method='POST' action='/create_ship'>
      Model: <input type='text' name='model_name' value='Eagle'/><br/>
      Speed: <input type='number' name='max_speed' value='250' min="0"/><br/>
      Cargo Capacity: <input type='number' name='cargo_capacity' value='16' min="0"/><br/>
      Jump Range: <input type='number' step='0.1' name='jump_range' value='10' min="0"/><br/>
      Player ID: <input type='number' name='player_id' value='1' min="0"/><br/>
      Current System (ID): <input type='number' name='system_id' value='1' min="0"/><br/>
      Current Station (ID, optional): <input type='text' name='station_id'/><br/>
      <button type='submit'>Create Ship</button>
    </form>
    <a href='/'>Back</a>
    """
    return render_page(content)

@app.route("/create_ship", methods=["POST"])
def create_ship():
    model_name = request.form.get("model_name")
    max_speed = int(request.form.get("max_speed"))
    cargo_capacity = int(request.form.get("cargo_capacity"))
    jump_range = float(request.form.get("jump_range"))
    player_id = int(request.form.get("player_id"))
    system_id = int(request.form.get("system_id"))
    station_id = request.form.get("station_id")
    station_id = int(station_id) if station_id and station_id.strip() != "" else None
    conn = get_db_connection()
    cur = conn.cursor()
    try:
        cur.execute("""
            INSERT INTO PlayerShips(owner_player_id, model_name, max_speed, cargo_capacity, jump_range, current_system, current_station, is_destroyed)
            VALUES (%s, %s, %s, %s, %s, %s, %s, FALSE) RETURNING ship_id
        """, (player_id, model_name, max_speed, cargo_capacity, jump_range, system_id, station_id))
        ship_id = cur.fetchone()[0]
        conn.commit()
    except Exception as e:
        conn.rollback()
        cur.close()
        conn.close()
        return render_page(f"<p>Error creating ship: {e}</p><a href='/'>Back</a>")
    cur.close()
    conn.close()
    return render_page(f"<p>Ship '{model_name}' created with ID {ship_id}!</p><a href='/ships'>View Ships</a>")

@app.route("/ships")
def ships():
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("""
        SELECT ship_id, model_name, max_speed, cargo_capacity, jump_range, current_system, current_station, is_destroyed
        FROM Ships
        ORDER BY ship_id
    """)
    rows = cur.fetchall()
    cur.close()
    conn.close()
    html = "<h2>All Ships</h2><table><tr><th>ID</th><th>Model</th><th>Speed</th><th>CargoCap</th><th>JumpRange</th><th>System</th><th>Station</th><th>Destroyed?</th></tr>"
    for r in rows:
        html += f"<tr><td>{r[0]}</td><td>{r[1]}</td><td>{r[2]}</td><td>{r[3]}</td><td>{r[4]}</td><td>{r[5] or '---'}</td><td>{r[6] or '---'}</td><td>{'YES' if r[7] else 'NO'}</td></tr>"
    html += "</table><a href='/'>Back</a>"
    return render_page(html)

@app.route("/npcs")
def npcs():
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("""
        SELECT ns.ship_id, ns.model_name, ns.max_speed, ns.cargo_capacity, ns.jump_range,
               ns.current_system, ns.current_station, ns.is_destroyed, ns.npc_name, f.faction_name
        FROM ONLY NPCShips ns
        LEFT JOIN Factions f ON ns.faction_id = f.faction_id
        ORDER BY ns.ship_id
    """)
    rows = cur.fetchall()
    cur.close()
    conn.close()
    html = "<h2>NPC Ships</h2>"
    if rows:
        html += ("<table><tr><th>ID</th><th>Model</th><th>Speed</th><th>CargoCap</th><th>JumpRange</th>"
                 "<th>System</th><th>Station</th><th>Destroyed?</th><th>NPC Name</th><th>Faction</th></tr>")
        for r in rows:
            (ship_id, model_name, speed, cargo_cap, jump_range,
             system_id, station_id, is_destroyed, npc_name, faction_name) = r
            html += (f"<tr><td>{ship_id}</td><td>{model_name}</td><td>{speed}</td>"
                     f"<td>{cargo_cap}</td><td>{jump_range}</td><td>{system_id or '---'}</td>"
                     f"<td>{station_id or '---'}</td><td>{'YES' if is_destroyed else 'NO'}</td>"
                     f"<td>{npc_name or '---'}</td><td>{faction_name or '---'}</td></tr>")
        html += "</table>"
    else:
        html += "<p>No NPC ships.</p>"
    html += "<p><a href='/'>Back</a></p>"
    return render_page(html)

@app.route("/stations")
def stations():
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("""
        SELECT s.station_id, s.station_name, f.faction_name AS controlling_faction
        FROM Stations s
        LEFT JOIN Factions f ON s.controlling_faction = f.faction_id
        ORDER BY s.station_id
    """)
    rows = cur.fetchall()
    cur.close()
    conn.close()
    html = "<h2>Stations</h2><table><tr><th>ID</th><th>Name</th><th>Controlling Faction</th></tr>"
    for r in rows:
        html += f"<tr><td>{r[0]}</td><td>{r[1]}</td><td>{r[2] or '---'}</td></tr>"
    html += "</table><a href='/'>Back</a>"
    return render_page(html)

@app.route("/logs")
def logs():
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("SELECT log_id, event_type, description, created_at FROM Logs ORDER BY log_id DESC")
    rows = cur.fetchall()
    cur.close()
    conn.close()
    html = "<h2>Logs</h2><table><tr><th>ID</th><th>Event</th><th>Description</th><th>Created At</th></tr>"
    for r in rows:
        html += f"<tr><td>{r[0]}</td><td>{r[1]}</td><td>{r[2]}</td><td>{r[3]}</td></tr>"
    html += "</table><a href='/'>Back</a>"
    return render_page(html)

@app.route("/create_player_form")
def create_player_form():
    content = """
    <h2>Create Player</h2>
    <form method='POST' action='/create_player'>
      Player Name: <input type='text' name='player_name' value='NewPlayer'/><br/>
      Initial Credits: <input type='number' step='0.01' name='credits' value='1000' min="0"/><br/>
      <button type='submit'>Create</button>
    </form>
    <a href='/'>Back</a>
    """
    return render_page(content)

@app.route("/create_player", methods=["POST"])
def create_player():
    player_name = request.form.get("player_name")
    credits = float(request.form.get("credits"))
    conn = get_db_connection()
    cur = conn.cursor()
    try:
        cur.execute("INSERT INTO Players(player_name, credits) VALUES (%s, %s)", (player_name, credits))
        conn.commit()
    except Exception as e:
        conn.rollback()
        cur.close()
        conn.close()
        return render_page(f"<p>Error creating player: {e}</p><a href='/'>Back</a>")
    cur.close()
    conn.close()
    return render_page(f"<p>Player {player_name} created!</p><a href='/players'>View Players</a>")

@app.route("/players")
def players():
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("SELECT player_id, player_name, credits FROM Players ORDER BY player_id")
    rows = cur.fetchall()
    cur.close()
    conn.close()
    html = "<h2>Players</h2><table><tr><th>ID</th><th>Name</th><th>Credits</th></tr>"
    for r in rows:
        html += f"<tr><td>{r[0]}</td><td>{r[1]}</td><td>{r[2]}</td></tr>"
    html += "</table><a href='/'>Back</a>"
    return render_page(html)

@app.route("/transfer_credits_form")
def transfer_credits_form():
    content = """
    <h2>Transfer Credits</h2>
    <form method='POST' action='/transfer_credits'>
      From (player_id): <input type='number' name='from_id' value='1' min="0"/><br/>
      To (player_id): <input type='number' name='to_id' value='2' min="0"/><br/>
      Amount: <input type='number' step='0.01' name='amount' value='100' min="0"/><br/>
      <button type='submit'>Transfer</button>
    </form>
    <a href='/'>Back</a>
    """
    return render_page(content)

@app.route("/transfer_credits", methods=["POST"])
def transfer_credits():
    from_id = int(request.form.get("from_id"))
    to_id = int(request.form.get("to_id"))
    amount = float(request.form.get("amount"))
    conn = get_db_connection()
    cur = conn.cursor()
    try:
        cur.execute("CALL proc_transfer_credits(%s, %s, %s)", (from_id, to_id, amount))
        conn.commit()
    except Exception as e:
        conn.rollback()
        cur.close()
        conn.close()
        return render_page(f"<p>Error transferring credits: {e}</p><a href='/'>Back</a>")
    cur.close()
    conn.close()
    return render_page(f"<p>Transferred {amount} credits from player {from_id} to player {to_id}.</p><a href='/'>Back</a>")

if __name__ == "__main__":
    app.run(debug=True)