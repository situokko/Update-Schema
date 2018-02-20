# Update-Schema
Simple SQLServer schema migration and version control

A bit similar than Liquibase for Java, but not as feature-rich.

## Instructions
1. For each new DB schema change create new 00x_change_description.sql file in the root directory, see 002_your_next_change.sql for example. The 2 first lines are needed for all the files.
1. Update the update-ID and author-name inside the file (2 first lanes). Next lines are your actual change. 
1. INSERT/UPDATE/CREATE TABLE/ALTER TABLE etc commands should be included here, Note if you need to delete or change existing rows that their IDs will not necessary be same between each environment
1. If you create or change functions/stored-procedures always write them into separate file, and only create -- #include filename -reference into this change-file, so that you can have separate version control for those files and their changes.
1. Write included function-files so that in the beginning they are dropped if they exist, and the declaration ends to "GO"
