import csv
import re
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent

def sql_string(value):
    if value is None:
        return "NULL"

    return "'" + str(value).replace("'", "''") + "'"

def read_movies():
    result = []

    with open(BASE_DIR / "movies.csv", encoding="utf-8", newline="") as file:
        reader = csv.reader(file)
        next(reader)

        for movie_id, title, genres in reader:
            match = re.search(r"\((\d{4})\)", title)
            year = match.group(1) if match else "NULL"

            result.append(
                f"INSERT INTO movies (id, title, year, genres) VALUES "
                f"({movie_id}, {sql_string(title)}, {year}, {sql_string(genres)});"
            )

    return result

def read_ratings():
    result = []

    with open(BASE_DIR / "ratings.csv", encoding="utf-8", newline="") as file:
        reader = csv.reader(file)
        next(reader)

        for row_id, (user_id, movie_id, rating, timestamp) in enumerate(reader, 1):
            result.append(
                f"INSERT INTO ratings "
                f"(id, user_id, movie_id, rating, timestamp) VALUES "
                f"({row_id}, {user_id}, {movie_id}, {rating}, {timestamp});"
            )

    return result


def read_tags():
    result = []

    with open(BASE_DIR / "tags.csv", encoding="utf-8", newline="") as file:
        reader = csv.reader(file)
        next(reader)

        for row_id, (user_id, movie_id, tag, timestamp) in enumerate(reader, 1):
            result.append(
                f"INSERT INTO tags "
                f"(id, user_id, movie_id, tag, timestamp) VALUES "
                f"({row_id}, {user_id}, {movie_id}, "
                f"{sql_string(tag)}, {timestamp});"
            )

    return result


def read_users():
    result = []

    with open(BASE_DIR / "users.txt", encoding="utf-8") as file:
        for line in file:
            line = line.rstrip("\r\n")

            if not line:
                continue

            user_id, name, email, gender, register_date, occupation = line.split("|")

            result.append(
                f"INSERT INTO users "
                f"(id, name, email, gender, register_date, occupation) VALUES "
                f"({user_id}, {sql_string(name)}, {sql_string(email)}, "
                f"{sql_string(gender)}, {sql_string(register_date)}, "
                f"{sql_string(occupation)});"
            )

    return result


def main():
    movies = read_movies()
    users = read_users()
    ratings = read_ratings()
    tags = read_tags()

    sql = []

    sql.append("PRAGMA foreign_keys = OFF;")
    sql.append("")
    
    sql.append("BEGIN TRANSACTION;")
    sql.append("")

    sql.append("DROP TABLE IF EXISTS ratings;")
    sql.append("DROP TABLE IF EXISTS tags;")
    sql.append("DROP TABLE IF EXISTS movies;")
    sql.append("DROP TABLE IF EXISTS users;")
    sql.append("")

    sql.append("""
CREATE TABLE movies (
    id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    year INTEGER,
    genres TEXT
);

CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT,
    email TEXT,
    gender TEXT,
    register_date TEXT,
    occupation TEXT
);

CREATE TABLE ratings (
    id INTEGER PRIMARY KEY,
    user_id INTEGER,
    movie_id INTEGER,
    rating REAL,
    timestamp INTEGER
);

CREATE TABLE tags (
    id INTEGER PRIMARY KEY,
    user_id INTEGER,
    movie_id INTEGER,
    tag TEXT,
    timestamp INTEGER
);
""".strip())

    sql.append("")
    sql.extend(movies)
    sql.extend(users)
    sql.extend(ratings)
    sql.extend(tags)

    sql.append("")
    sql.append("COMMIT;")
    sql.append("PRAGMA foreign_keys = ON;")
    sql.append("")

    with open(BASE_DIR / "db_init.sql", "w", encoding="utf-8", newline="\n") as file:
        file.write("\n".join(sql))

    print("db_init.sql created successfully.")


if __name__ == "__main__":
    main()