
/***************************************************** A Query:
Example:


********************************************************/
IF EXISTS (
		SELECT *
		FROM dbo.sysobjects
		WHERE id = object_id(N'sp_get_project_lookup_table')
			AND OBJECTPROPERTY(id, N'IsProcedure') = 1
		)
	DROP PROCEDURE sp_get_project_lookup_table
GO

CREATE PROC sp_get_project_lookup_table
@schema_name varchar(64) = 'lu'
, @table_name varchar(64)
, @project_id int
, @search_string varchar(128) = null
AS

SET nocount ON 
declare @stt varchar(max)

begin try
	set @stt = 'select id, name from [' + @schema_name + '].[' + @table_name + '] where project_id = ' + convert(varchar(10), @project_id) 
			+ ' and name like ''%' + @search_string + '%'''

	print @stt
	exec (@stt)
end try

BEGIN CATCH  
	throw
END CATCH  

go

