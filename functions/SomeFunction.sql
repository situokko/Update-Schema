--Note. Always first drop the function if it already exists
if object_id('dbo.SomeFunction') is not null
  drop function dbo.SomeFunction
go

create function dbo.SomeFunction() returns int
as
begin
  --Do functioning

  return 1
end

go
grant execute on dbo.SomeFunction to public
go

--Note. Last command in these files needs to be GO
