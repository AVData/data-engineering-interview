-- Example data
-- People
INSERT INTO person (full_name) VALUES
('Ricardo'),
('Shanaya'),
('Daniel');

-- Tasks
-- Task 1: repeats monthly and ends after 12 occurrences
INSERT INTO task (title, description, start_date, recurrence, recurrence_count, recurrence_end_date)
VALUES ('Task 1', 'Monthly task, 12 occurrences', '2026-01-01', 'monthly', 12, '2026-12-01');

-- Task 2: single occurrence
INSERT INTO task (title, description, start_date, recurrence, recurrence_count, recurrence_end_date)
VALUES ('Task 2', 'One-time task', '2026-01-01', 'none', 1, '2026-01-01');

-- Task 3: daily, ends after 30 occurrences
INSERT INTO task (title, description, start_date, recurrence, recurrence_count, recurrence_end_date)
VALUES ('Task 3', 'Daily task, 30 occurrences', '2026-01-01', 'daily', 30, '2026-01-30');

-- Occurrences
-- Task 1 occurrences (monthly, 12)
WITH t AS (
    SELECT id, start_date, recurrence_count FROM task WHERE title = 'Task 1' AND recurrence_count IS NOT NULL
)
INSERT INTO task_occurrence (task_id, occurrence_date)
SELECT t.id, (t.start_date + (g.n * INTERVAL '1 month'))::date
FROM t
CROSS JOIN LATERAL generate_series(0, t.recurrence_count - 1) AS g(n);

-- Task 2 occurrence (single)
WITH t AS (
    SELECT id, start_date FROM task WHERE title = 'Task 2'
)
INSERT INTO task_occurrence (task_id, occurrence_date)
SELECT id, start_date FROM t;

-- Task 3 occurrences (daily, 30)
WITH t AS (
    SELECT id, start_date, recurrence_count FROM task WHERE title = 'Task 3' AND recurrence_count IS NOT NULL
)
INSERT INTO task_occurrence (task_id, occurrence_date)
SELECT t.id, (t.start_date + (g.n * INTERVAL '1 day'))::date
FROM t
CROSS JOIN LATERAL generate_series(0, t.recurrence_count - 1) AS g(n);


-- Assign Schedule
INSERT INTO task_assignment (task_id, person_id, assigned_from, assigned_to)
WITH RECURSIVE schedule AS (
    -- Task 1: Once Monthly for 12 months
    SELECT 
        1 AS task_id,
        floor(random() * 3 + 1)::int AS person_id,
        ('2026-01-01'::date + (m || ' month')::interval)::date AS assigned_from,
        ('2026-01-01'::date + (m || ' month')::interval + interval '5 days')::date AS assigned_to
    FROM generate_series(0, 11) AS m

    UNION ALL

    -- Task 2: Exactly One Time
    SELECT 
        2, 
        floor(random() * 3 + 1)::int, 
        '2026-01-01'::date, 
        ('2026-01-01'::date + interval '7 days')::date

    UNION ALL

    -- Task 3: Daily for 30 total occurrences
    SELECT 
        3, 
        floor(random() * 3 + 1)::int, 
        ('2026-01-01'::date + (d || ' day')::interval)::date, 
        ('2026-01-01'::date + (d || ' day')::interval)::date
    FROM generate_series(0, 29) AS d
)
SELECT task_id, person_id, assigned_from, assigned_to 
FROM schedule
ORDER BY task_id, assigned_from;

-- End of data insertion