#!/bin/bash

# Команда chcp есть в Windows, но отсутствует в Linux.
if command -v chcp >/dev/null 2>&1; then
    chcp 65001
fi

# Создание базы данных из SQL-файла лабораторной работы 2.
sqlite3 movies_rating.db < db_init.sql

echo "1. Для каждого фильма вывести название, год выпуска и средний рейтинг. Добавить ранг по убыванию среднего рейтинга. Одинаковые рейтинги получают одинаковый ранг. Вывести 10 фильмов с лучшими средними рейтингами."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "WITH movie_averages AS (
    SELECT m.id, m.title, m.year, AVG(r.rating) AS avg_rating
    FROM movies AS m
    JOIN ratings AS r ON r.movie_id = m.id
    GROUP BY m.id, m.title, m.year
),
ranked_movies AS (
    SELECT title, year, avg_rating,
           RANK() OVER (ORDER BY avg_rating DESC) AS rank_by_avg_rating
    FROM movie_averages
)
SELECT title, year, ROUND(avg_rating, 3) AS avg_rating,
       rank_by_avg_rating
FROM ranked_movies
ORDER BY rank_by_avg_rating, title
LIMIT 10;"
echo " "

echo "2. С помощью рекурсивного CTE выделить все жанры фильмов. Для каждого жанра рассчитать средний рейтинг фильмов и ранг жанра по убыванию среднего рейтинга с помощью RANK()."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "WITH RECURSIVE genre_parts(movie_id, rest, genre) AS (
    SELECT id, genres || '|', ''
    FROM movies
    WHERE genres IS NOT NULL
      AND genres <> ''
      AND genres <> '(no genres listed)'

    UNION ALL

    SELECT movie_id,
           substr(rest, instr(rest, '|') + 1),
           substr(rest, 1, instr(rest, '|') - 1)
    FROM genre_parts
    WHERE rest <> ''
),
movie_genres AS (
    SELECT DISTINCT movie_id, genre
    FROM genre_parts
    WHERE genre <> ''
),
genre_averages AS (
    SELECT mg.genre, AVG(r.rating) AS avg_rating
    FROM movie_genres AS mg
    LEFT JOIN ratings AS r ON r.movie_id = mg.movie_id
    GROUP BY mg.genre
)
SELECT genre,
       ROUND(avg_rating, 3) AS avg_rating,
       RANK() OVER (ORDER BY avg_rating DESC) AS genre_rank
FROM genre_averages
ORDER BY genre_rank, genre;"
echo " "

echo "3. Посчитать количество фильмов в каждом жанре. Вывести genre и movie_count, отсортировав по убыванию количества фильмов."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "WITH RECURSIVE genre_parts(movie_id, rest, genre) AS (
    SELECT id, genres || '|', ''
    FROM movies
    WHERE genres IS NOT NULL
      AND genres <> ''
      AND genres <> '(no genres listed)'
    UNION ALL
    SELECT movie_id,
           substr(rest, instr(rest, '|') + 1),
           substr(rest, 1, instr(rest, '|') - 1)
    FROM genre_parts
    WHERE rest <> ''
),
movie_genres AS (
    SELECT DISTINCT movie_id, genre
    FROM genre_parts
    WHERE genre <> ''
)
SELECT genre, COUNT(*) AS movie_count
FROM movie_genres
GROUP BY genre
ORDER BY movie_count DESC, genre;"
echo " "

echo "4. Найти жанры, в которых чаще всего оставляют теги. Вывести genre, tag_count и долю жанра в общем числе записей таблицы tags в процентах."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "WITH RECURSIVE genre_parts(movie_id, rest, genre) AS (
    SELECT id, genres || '|', ''
    FROM movies
    WHERE genres IS NOT NULL
      AND genres <> ''
      AND genres <> '(no genres listed)'
    UNION ALL
    SELECT movie_id,
           substr(rest, instr(rest, '|') + 1),
           substr(rest, 1, instr(rest, '|') - 1)
    FROM genre_parts
    WHERE rest <> ''
),
movie_genres AS (
    SELECT DISTINCT movie_id, genre
    FROM genre_parts
    WHERE genre <> ''
),
genre_tag_counts AS (
    SELECT mg.genre, COUNT(t.id) AS tag_count
    FROM movie_genres AS mg
    JOIN tags AS t ON t.movie_id = mg.movie_id
    GROUP BY mg.genre
)
SELECT genre, tag_count,
       ROUND(100.0 * tag_count /
             NULLIF((SELECT COUNT(*) FROM tags), 0), 2) AS tag_share
FROM genre_tag_counts
ORDER BY tag_count DESC, genre;"
echo " "

echo "5. Для каждого пользователя рассчитать количество оценок, средний рейтинг, дату первой и последней оценки. Отсортировать по убыванию количества оценок и вывести первые 10 строк."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "SELECT
    u.id AS user_id,
    COUNT(r.id) AS rating_count,
    ROUND(AVG(r.rating), 3) AS avg_rating,
    date(MIN(r.timestamp), 'unixepoch') AS first_rating_date,
    date(MAX(r.timestamp), 'unixepoch') AS last_rating_date
FROM users AS u
LEFT JOIN ratings AS r ON r.user_id = u.id
GROUP BY u.id
ORDER BY rating_count DESC, u.id
LIMIT 10;"
echo " "

echo "6. Сегментировать пользователей по поведению с помощью CASE: Комментаторы — тегов больше оценок; Оценщики — оценок больше тегов; Активные — и оценок, и тегов не менее 10; Пассивные — и оценок, и тегов меньше 5."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "WITH rating_counts AS (
    SELECT user_id, COUNT(*) AS rating_count
    FROM ratings
    GROUP BY user_id
),
tag_counts AS (
    SELECT user_id, COUNT(*) AS tag_count
    FROM tags
    GROUP BY user_id
),
user_activity AS (
    SELECT
        u.id AS user_id,
        COALESCE(rc.rating_count, 0) AS rating_count,
        COALESCE(tc.tag_count, 0) AS tag_count
    FROM users AS u
    LEFT JOIN rating_counts AS rc ON rc.user_id = u.id
    LEFT JOIN tag_counts AS tc ON tc.user_id = u.id
)
SELECT user_id, rating_count, tag_count,
       CASE
           WHEN rating_count >= 10 AND tag_count >= 10 THEN 'Активные'
           WHEN rating_count < 5 AND tag_count < 5 THEN 'Пассивные'
           WHEN tag_count > rating_count THEN 'Комментаторы'
           WHEN rating_count > tag_count THEN 'Оценщики'
           ELSE 'Сбалансированные'
       END AS behavior_category
FROM user_activity
ORDER BY user_id;"
echo " "

echo "7. Для каждого пользователя вывести имя и последний фильм, который он оценил, по времени ratings.timestamp. Пользователи без оценок также должны присутствовать, с NULL в полях фильма."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "WITH ranked_user_ratings AS (
    SELECT
        u.id AS user_id,
        u.name,
        m.title AS last_rated_movie_title,
        r.timestamp AS last_rating_timestamp,
        ROW_NUMBER() OVER (
            PARTITION BY u.id
            ORDER BY r.timestamp DESC, r.id DESC
        ) AS row_num
    FROM users AS u
    LEFT JOIN ratings AS r ON r.user_id = u.id
    LEFT JOIN movies AS m ON m.id = r.movie_id
)
SELECT user_id, name, last_rated_movie_title, last_rating_timestamp
FROM ranked_user_ratings
WHERE row_num = 1
ORDER BY user_id;"
echo " "

echo "TASK05 ЗАВЕРШЁН"
