INSERT INTO database_schema_changelog(id, author) VALUES (2, 'author.name');
if @@ROWCOUNT = 0 raiserror('This change is already applied, skipping', 20, 1) with log;

CREATE TABLE table_name (
    foo INT,
    bar INT
);

INSERT INTO table_name(foo, bar) VALUES (1, 2);

ALTER TABLE table_name ADD bor INT;

-- Included functions and stored-procedures

-- #include functions\SomeFunction.sql
