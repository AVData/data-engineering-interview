-- Task management data model

-- Recurrence type and status enums
CREATE TYPE task_recurrence_type AS ENUM ('none', 'daily', 'weekly', 'monthly');
CREATE TYPE task_status AS ENUM ('Not Started', 'In Progress', 'Completed');

-- People who can be assigned tasks
CREATE TABLE IF NOT EXISTS person (
    id SERIAL PRIMARY KEY,
    full_name VARCHAR(255) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Task definition
CREATE TABLE IF NOT EXISTS task (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description VARCHAR(255),
    start_date DATE NOT NULL,
    recurrence task_recurrence_type NOT NULL DEFAULT 'none',
    recurrence_count INTEGER, -- optional: number of occurrences (null = open-ended)
    recurrence_end_date DATE,  -- optional: explicit end date
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Assignment of people to a Task (task-level assignment). Optional dates allow assignment windows.
CREATE TABLE IF NOT EXISTS task_assignment (
    id SERIAL PRIMARY KEY,
    task_id INTEGER NOT NULL REFERENCES task(id) ON DELETE CASCADE,
    person_id INTEGER NOT NULL REFERENCES person(id) ON DELETE CASCADE,
    assigned_from DATE,
    assigned_to DATE,
    UNIQUE (task_id, person_id, assigned_from, assigned_to)
);

-- Unique index replicating the intended uniqueness constraint from the original PK
CREATE UNIQUE INDEX task_assignment_unique ON task_assignment (
  task_id, person_id, COALESCE(assigned_from, DATE '1900-01-01')
);

-- Each occurrence of a Task (one row per scheduled instance)
CREATE TABLE IF NOT EXISTS task_occurrence (
    id SERIAL PRIMARY KEY,
    task_id INTEGER REFERENCES task(id) ON DELETE CASCADE,
    occurrence_date DATE NOT NULL,
    status task_status NOT NULL DEFAULT 'Not Started',
    assigned_person_id INTEGER REFERENCES person(id), -- optional per-occurrence assignee
    completed_at TIMESTAMPTZ,
    UNIQUE (task_id, occurrence_date)
);

-- Indexes
CREATE INDEX idx_task_start_date ON task (start_date);
CREATE INDEX idx_task_occurrence_date ON task_occurrence (occurrence_date);
CREATE INDEX idx_task_occurrence_task_status ON task_occurrence (task_id, status);
CREATE INDEX idx_task_assignment_task_from ON task_assignment (task_id, assigned_from);

-- Column level documentation
COMMENT ON COLUMN "task"."title" IS 'Task name';
COMMENT ON COLUMN "task"."description" IS 'Describes the task and respective requirements';
COMMENT ON COLUMN "task"."start_date" IS 'Date the task is set to start';
COMMENT ON COLUMN "task"."recurrence" IS 'Recurrence pattern (daily, weekly, monthly)';
COMMENT ON COLUMN "task"."recurrence_count" IS 'Number of occurrences for respective task';
COMMENT ON COLUMN "task"."recurrence_end_date" IS 'End date for recurring tasks';

COMMENT ON COLUMN "person"."name" IS 'Full name of the person who can be assigned tasks';

COMMENT ON COLUMN "task_assignment"."assigned_from" IS 'Assignment date window for a given person for a given task';
COMMENT ON COLUMN "task_assignment"."assigned_to" IS 'Assignment end date for a given person for a given task';

COMMENT ON COLUMN "task_occurrence"."occurrence_date" IS 'Expected due date for this task occurrence';
COMMENT ON COLUMN "task_occurrence"."assigned_person_id" IS 'Person assigned to this task for this a specific occurrence';
COMMENT ON COLUMN "task_occurrence"."status" IS 'Status of the task occurrence (Not Started, In Progress, Completed)';
COMMENT ON COLUMN "task_occurrence"."completed_at" IS 'Timestamp when the task occurrence was completed';

-- End of model SQL
