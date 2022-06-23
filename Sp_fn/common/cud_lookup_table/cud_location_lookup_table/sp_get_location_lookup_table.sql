
/***************************************************** A Query:
Example:


********************************************************/
IF EXISTS (
		SELECT *
		FROM dbo.sysobjects
		WHERE id = object_id(N'sp_get_location_lookup_table')
			AND OBJECTPROPERTY(id, N'IsProcedure') = 1
		)
	DROP PROCEDURE sp_get_location_lookup_table
GO

CREATE PROC sp_get_location_lookup_table
@schema_name varchar(64) = 'lu'
, @table_name varchar(64)
, @site_id int
AS

SET nocount ON 
declare @stt varchar(max)

begin try
	set @stt = 'select id, name from [' + @schema_name + '].[' + @table_name + '] where site_id = ' + convert(varchar(10), @site_id)

	print @stt
	exec (@stt)
end try

BEGIN CATCH  
	throw
END CATCH  

go

