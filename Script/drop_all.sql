--- drop all triggers

DECLARE @sql NVARCHAR(MAX) = N'';

SELECT @sql += 
    N'DROP TRIGGER ' + 
    QUOTENAME(OBJECT_SCHEMA_NAME(t.object_id)) + N'.' + QUOTENAME(t.name) 
    + N'; ' + NCHAR(13)
FROM sys.triggers AS t join sys.tables tbl on t.parent_id=tbl.object_id


PRINT @sql;
exec (@sql);



--- drop all views

declare @stt varchar(max)
select @stt = STRING_AGG ('drop view ' + name, ';'+char(10)) from sys.views where schema_id = 1
print @stt
exec (@stt)



-- drop all Stored Procedures
DECLARE @sql NVARCHAR(MAX) = N'';

SELECT @sql += N'DROP procedure if exists ' + ROUTINE_NAME  + N'; ' + NCHAR(13)
  FROM INFORMATION_SCHEMA.ROUTINES
 WHERE ROUTINE_TYPE = 'PROCEDURE'
   order by ROUTINE_NAME

select @sql


---- list schemas and owners

select * from INFORMATION_SCHEMA.SCHEMATA