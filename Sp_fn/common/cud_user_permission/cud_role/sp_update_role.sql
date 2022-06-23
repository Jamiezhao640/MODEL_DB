
/***************************************************** A Query:
Example:


********************************************************/
IF EXISTS (
		SELECT *
		FROM dbo.sysobjects
		WHERE id = object_id(N'sp_update_role')
			AND OBJECTPROPERTY(id, N'IsProcedure') = 1
		)
	DROP PROCEDURE sp_update_role
GO

CREATE PROC sp_update_role
@id int, 
@name varchar(128)
AS

SET nocount ON 

begin try
	update usr.tbl_role
	set  name = case when @name is null then name else @name end
	where id = @id

end try

BEGIN CATCH  
	throw
END CATCH  

go

