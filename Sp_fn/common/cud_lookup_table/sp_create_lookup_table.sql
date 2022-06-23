/***************************************************** A Query:
Example:


********************************************************/
IF EXISTS (
		SELECT *
		FROM dbo.sysobjects
		WHERE id = object_id(N'sp_create_lookup_table')
			AND OBJECTPROPERTY(id, N'IsProcedure') = 1
		)
	DROP PROCEDURE sp_create_lookup_table
GO

CREATE PROC sp_create_lookup_table
@schema_name varchar(64) = 'lu'
, @table_name varchar(64)
, @name varchar(128)
AS

SET nocount ON 
declare @stt varchar(max)

begin transaction
begin try
	set @stt = 'insert into [' + @schema_name + '].[' + @table_name  + '] (name) values (''' + dbo.fn_duplicate_single_quote_in_string(@name) + ''')'
	print @stt
	exec (@stt)

	set @stt = 'select max(id) as [id] from ['+ @schema_name + '].[' + @table_name  + ']'
	exec (@stt)
end try

BEGIN CATCH  
    IF @@TRANCOUNT > 0  
        ROLLBACK TRANSACTION;  
	throw
END CATCH;  
  
IF @@TRANCOUNT > 0  
    COMMIT TRANSACTION; 

go
