.bail on

PRAGMA foreign_keys = ON;

BEGIN TRANSACTION;

-- Добавляем пять пользователей
INSERT INTO users (
    first_name, last_name, email, gender, occupation_id
)
SELECT
    'Сергей', 'Бобро', 'sergey.bobro@example.com',
    'мужской', occupation_id
FROM occupations
WHERE occupation_name = 'other'
AND NOT EXISTS (
    SELECT 1 FROM users
    WHERE email = 'sergey.bobro@example.com'
);

INSERT INTO users (
    first_name, last_name, email, gender, occupation_id
)
SELECT
    'Данила', 'Агеев', 'danila.ageev@example.com',
    'мужской', occupation_id
FROM occupations
WHERE occupation_name = 'other'
AND NOT EXISTS (
    SELECT 1 FROM users
    WHERE email = 'danila.ageev@example.com'
);

INSERT INTO users (
    first_name, last_name, email, gender, occupation_id
)
SELECT
    'Роман', 'Бахлов', 'roman.bahlov@example.com',
    'мужской', occupation_id
FROM occupations
WHERE occupation_name = 'other'
AND NOT EXISTS (
    SELECT 1 FROM users
    WHERE email = 'roman.bahlov@example.com'
);

INSERT INTO users (
    first_name, last_name, email, gender, occupation_id
)
SELECT
    'Самира', 'Булатова', 'samira.bulatova@example.com',
    'женский', occupation_id
FROM occupations
WHERE occupation_name = 'other'
AND NOT EXISTS (
    SELECT 1 FROM users
    WHERE email = 'samira.bulatova@example.com'
);

INSERT INTO users (
    first_name, last_name, email, gender, occupation_id
)
SELECT
    'Анна', 'Вашуркина', 'anna.vashurkina@example.com',
    'женский', occupation_id
FROM occupations
WHERE occupation_name = 'other'
AND NOT EXISTS (
    SELECT 1 FROM users
    WHERE email = 'anna.vashurkina@example.com'
);

-- Добавляем жанры, если их ещё нет
INSERT OR IGNORE INTO genres (genre_name)
VALUES ('Sci-Fi'), ('Drama'), ('Thriller');

-- Добавляем три фильма
INSERT INTO movies (title, release_year)
SELECT 'Moonfall', 2022
WHERE NOT EXISTS (
    SELECT 1 FROM movies
    WHERE title = 'Moonfall' AND release_year = 2022
);

INSERT INTO movies (title, release_year)
SELECT 'The Father', 2020
WHERE NOT EXISTS (
    SELECT 1 FROM movies
    WHERE title = 'The Father' AND release_year = 2020
);

INSERT INTO movies (title, release_year)
SELECT 'The Guilty', 2021
WHERE NOT EXISTS (
    SELECT 1 FROM movies
    WHERE title = 'The Guilty' AND release_year = 2021
);

-- Связываем фильмы с жанрами
INSERT INTO movie_genres (movie_id, genre_id)
SELECT m.movie_id, g.genre_id
FROM movies m, genres g
WHERE m.title = 'Moonfall'
  AND m.release_year = 2022
  AND g.genre_name = 'Sci-Fi'
  AND NOT EXISTS (
      SELECT 1 FROM movie_genres mg
      WHERE mg.movie_id = m.movie_id
        AND mg.genre_id = g.genre_id
  );

INSERT INTO movie_genres (movie_id, genre_id)
SELECT m.movie_id, g.genre_id
FROM movies m, genres g
WHERE m.title = 'The Father'
  AND m.release_year = 2020
  AND g.genre_name = 'Drama'
  AND NOT EXISTS (
      SELECT 1 FROM movie_genres mg
      WHERE mg.movie_id = m.movie_id
        AND mg.genre_id = g.genre_id
  );

INSERT INTO movie_genres (movie_id, genre_id)
SELECT m.movie_id, g.genre_id
FROM movies m, genres g
WHERE m.title = 'The Guilty'
  AND m.release_year = 2021
  AND g.genre_name = 'Thriller'
  AND NOT EXISTS (
      SELECT 1 FROM movie_genres mg
      WHERE mg.movie_id = m.movie_id
        AND mg.genre_id = g.genre_id
  );

-- Добавляем три оценки от Сергея Бобро
INSERT INTO ratings (user_id, movie_id, rating, timestamp)
SELECT
    u.user_id,
    m.movie_id,
    5.0,
    CAST(strftime('%s', 'now') AS INTEGER)
FROM users u, movies m
WHERE u.email = 'sergey.bobro@example.com'
  AND m.title = 'Moonfall'
  AND m.release_year = 2022
  AND NOT EXISTS (
      SELECT 1 FROM ratings r
      WHERE r.user_id = u.user_id
        AND r.movie_id = m.movie_id
  );

INSERT INTO ratings (user_id, movie_id, rating, timestamp)
SELECT
    u.user_id,
    m.movie_id,
    4.5,
    CAST(strftime('%s', 'now') AS INTEGER)
FROM users u, movies m
WHERE u.email = 'sergey.bobro@example.com'
  AND m.title = 'The Father'
  AND m.release_year = 2020
  AND NOT EXISTS (
      SELECT 1 FROM ratings r
      WHERE r.user_id = u.user_id
        AND r.movie_id = m.movie_id
  );

INSERT INTO ratings (user_id, movie_id, rating, timestamp)
SELECT
    u.user_id,
    m.movie_id,
    4.0,
    CAST(strftime('%s', 'now') AS INTEGER)
FROM users u, movies m
WHERE u.email = 'sergey.bobro@example.com'
  AND m.title = 'The Guilty'
  AND m.release_year = 2021
  AND NOT EXISTS (
      SELECT 1 FROM ratings r
      WHERE r.user_id = u.user_id
        AND r.movie_id = m.movie_id
  );

COMMIT;
