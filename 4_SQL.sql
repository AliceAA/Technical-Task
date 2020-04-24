-- Task 1:
-- number of registered users by country

-- Comment:
-- I assume, that each row represent registered user with a unique id
-- if so, to find number of registered users by country
-- I only need to group table by country and return count of ids

-- Solution
SELECT COUNT(id), country_code
FROM "user"
GROUP BY country_code;


-- Task 2:
-- % of users, who made their first payment in 3 days after registration by country

-- Comment:
-- a relation between users, who made their first payment during 3 days after registration
-- and all users. Grouped by user's country

-- Solution:
SELECT u.country_code, round(COUNT(DISTINCT(p.user_id) )*100/ COUNT(DISTINCT(u.id))::numeric, 2)
    FROM "user" "u"
        LEFT JOIN "payment" "p" --join only suitable payments
            ON  p.user_id = u.id
            AND p.created_at > u.date_joined
            AND p.created_at <= u.date_joined + INTERVAL '3 DAY'
GROUP BY u.country_code;


-- Task 3:
-- % of users, who made their first payment in 3 days after registration and had 2
-- confirmed lessons in 7 days after registration by country

-- Comment:
-- a relation between users, who made their first payment during 3 days after registration,
-- had 2 confirmed lessons in 7 days after registration
-- and all users. Grouped by user's country

-- Solution:
SELECT joined.country_code, round(COUNT(DISTINCT(CASE WHEN paid>0 AND lessons>1 THEN joined.id END*100))/COUNT(DISTINCT(joined.id))::numeric, 2)
FROM (
    SELECT u.id, u.country_code,
           COUNT(DISTINCT(p.user_id) ) paid,
           COUNT(DISTINCT(l.id)) lessons
    FROM "user" "u"
        LEFT JOIN "payment" "p" --join only suitable payments
            ON  p.user_id = u.id
            AND p.created_at > u.date_joined
            AND p.created_at <= u.date_joined + INTERVAL '3 DAY'
        LEFT JOIN "lesson" "l" --join only suitable lessons
            ON l.user_id = u.id
            AND l.status = '{CONFIRMED}'
            AND l.created_at <= u.date_joined + INTERVAL '7 DAY'
    GROUP BY u.id, u.country_code) joined
GROUP BY joined.country_code;


-- Task 4:
-- % of weekly new users that never have done a payment

-- Comment:
-- a relation between new users that never have done a payment and all new users
-- grouped by week of their registration;
-- a week is represented as a date of first day of a week

-- Solution:
SELECT DATE_TRUNC('week', u.date_joined)::date,
       round(COUNT(DISTINCT(p.user_id))*100/ COUNT(DISTINCT(u.id))::numeric, 2)
FROM "user" "u"
    LEFT JOIN "payment" "p"
        ON  p.user_id = u.id
GROUP BY DATE_TRUNC('week', u.date_joined)::date;


-- Task 5:
-- how many hours of confirmed lessons a specific user (for example user_id=1)
-- has taken between payments.

-- Comment:
-- to talk about specific user I wrote a function that takes id as a parameter
-- for now it computes a number how many hours of confirmed lessons user has between last payments
-- if we want to set specific payments we can modify parameters of function

-- Solution:
CREATE FUNCTION hours_between (id_ integer, OUT hours bigint)
AS 'SELECT SUM(l.hours)
   FROM "lesson" "l",
        (SELECT MAX(p.created_at)
        FROM "payment" "p"
        WHERE p.user_id = id_) as "m"
   WHERE l.status = '{CONFIRMED}'
     AND l.created_at< m.max
     AND l.created_at> (SELECT MAX(p.created_at)
                        FROM "payment" "p"
                        WHERE p.user_id = id_
                            AND p.created_at<m.max)
                            AND l.user_id = id_'
LANGUAGE SQL;

SELECT * FROM hours_between (1);