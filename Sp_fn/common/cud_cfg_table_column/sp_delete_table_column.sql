/***************************************************** A Query:
Example:


********************************************************/
IF EXISTS (
		SELECT *
		FROM dbo.sysobjects
		WHERE id = object_id(N'sp_delete_table_column')
			AND OBJECTPROPERTY(id, N'IsProcedure') = 1
		)
	DROP PROCEDURE sp_delete_table_column
GO

CREATE PROC sp_delete_table_column
@id int
AS

SET nocount ON 

begin try
	delete from cfg.[page_table_column] where id = @id
end try

BEGIN CATCH  
	throw
END CATCH  

go

