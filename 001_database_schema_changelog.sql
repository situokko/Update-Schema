CREATE TABLE database_schema_changelog (
  id INT NOT NULL,
  author VARCHAR(100) NOT NULL,
  created DATETIME CONSTRAINT c_database_schema_changelog_created DEFAULT GETDATE(),
  PRIMARY KEY (id, author)
);

INSERT INTO database_schema_changelog(id, author) VALUES (1, 'author.name');
if @@ROWCOUNT = 0 raiserror('This change is already applied, skipping', 20, 1) with log;
