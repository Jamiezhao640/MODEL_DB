if exists (select * from dbo.sysobjects where id = object_id(N'sp_trigger_disabled_by_table') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure sp_trigger_disabled_by_table
GO

create   proc sp_trigger_disabled_by_table
@table_name varchar(256) = null
as
DECLARE @sql NVARCHAR(MAX) = N'';

SELECT @sql += 
    N'DISABLE TRIGGER ' + 
    QUOTENAME(OBJECT_SCHEMA_NAME(t.object_id)) + N'.' + QUOTENAME(t.name) 
    + ' on ' + QUOTENAME(OBJECT_SCHEMA_NAME(tbl.object_id))  + N'.' + QUOTENAME(tbl.name) 
    + N'; ' + NCHAR(13)
FROM sys.triggers AS t join sys.tables tbl on t.parent_id=tbl.object_id
WHERE tbl.name = @table_name or @table_name is null

-- PRINT @sql;
exec (@sql);


GO
