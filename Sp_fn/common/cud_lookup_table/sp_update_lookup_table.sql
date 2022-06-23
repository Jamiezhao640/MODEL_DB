
/***************************************************** A Query:
Example:


********************************************************/
IF EXISTS (
		SELECT *
		FROM dbo.sysobjects
		WHERE id = object_id(N'sp_update_lookup_table')
			AND OBJECTPROPERTY(id, N'IsProcedure') = 1
		)
	DROP PROCEDURE sp_update_lookup_table
GO

CREATE PROC sp_update_lookup_table
@schema_name varchar(64) = 'lu'
, @table_name varchar(64)
, @id int
, @name varchar(128)
AS

SET nocount ON 
declare @stt varchar(max)

begin try
	set @stt = 'update [' + @schema_name + '].[' + @table_name  + '] set name = ''' + dbo.fn_duplicate_single_quote_in_string(@name) + ''' where id = ' + convert(varchar(10), @id)

	print @stt
	exec (@stt)
end try

BEGIN CATCH  
	throw
END CATCH  

go

