/***************************************************** A Query:
Example:


********************************************************/
IF EXISTS (
		SELECT *
		FROM dbo.sysobjects
		WHERE id = object_id(N'sp_delete_user')
			AND OBJECTPROPERTY(id, N'IsProcedure') = 1
		)
	DROP PROCEDURE sp_delete_user
GO

CREATE PROC sp_delete_user
@id int
AS

SET nocount ON 

begin transaction
begin try
	delete from usr.tbl_permission where user_id = @id
	delete from usr.tbl_user where id = @id
end try

BEGIN CATCH  
    IF @@TRANCOUNT > 0  
        ROLLBACK TRANSACTION;  
	throw
END CATCH  

IF @@TRANCOUNT > 0  
    COMMIT TRANSACTION; 

go


