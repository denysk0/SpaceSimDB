import random
import psycopg2
import uuid


def main():
    # Параметры подключения к БД
    conn = psycopg2.connect(
        dbname="spacesimdb",
        user="postgres",
        password="postgres",
        host="127.0.0.1",
        port="5432",
        sslmode="disable",
        options="-c tcp_keepalives_idle=60"
    )
    cursor = conn.cursor()

    # Пример: сгенерируем 5 систем:
    for i in range(30):
        name = f"System_{uuid.uuid4().hex[:6]}"  # Уникальное имя
        coord_x = random.uniform(0, 1000)
        coord_y = random.uniform(0, 1000)
        coord_z = random.uniform(0, 1000)
        star_type = random.choice(["RedDwarf", "YellowStar", "WhiteStar"])

        cursor.execute("""
            INSERT INTO StarSystems(system_name, coord_x, coord_y, coord_z, star_type)
            VALUES (%s, %s, %s, %s, %s)
        """, (name, coord_x, coord_y, coord_z, star_type))

    # Сгенерируем 3 новых товара:
    goods_list = ["Spices","RareMetals","AlienArtifacts","LuxuryFoods"]
    for g in goods_list:
        base_price = random.randint(50, 2000)
        category = random.choice(["Metals","Foodstuffs","Tech","Mystery"])
        cursor.execute("""
            INSERT INTO Goods(good_name, category, base_price)
            VALUES (%s, %s, %s)
        """, (g, category, base_price))

    conn.commit()
    cursor.close()
    conn.close()
    print("Генерация завершена!")

if __name__ == "__main__":
    main()