/***************************************************** A Query:
Example:


********************************************************/
IF EXISTS (
		SELECT *
		FROM dbo.sysobjects
		WHERE id = object_id(N'sp_delete_role')
			AND OBJECTPROPERTY(id, N'IsProcedure') = 1
		)
	DROP PROCEDURE sp_delete_role
GO

CREATE PROC sp_delete_role
@id int
AS

SET nocount ON 

begin try
	delete from usr.tbl_role_menu where role_id = @id
	delete from usr.tbl_role where id = @id
end try

BEGIN CATCH  
	throw
END CATCH  

go


